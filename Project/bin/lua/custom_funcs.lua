-- AGGRESSIVE HTTP BYPASS for stubborn DPI (like porno365)
-- Combines multiple techniques: fake flood + disorder + host splitting
-- standard args : direction, payload, fooling, ip_id, rawsend, reconstruct
-- arg : fakes=N - number of fake packets to send (default 5)
-- arg : ttl_start=N - starting TTL for fakes (default 1)
-- arg : ttl_step=N - TTL increment for each fake (default 1)
-- arg : split_host - additionally split inside hostname
-- arg : disorder - send parts in reverse order
function http_aggressive(ctx, desync)
	if not desync.dis.tcp then
		instance_cutoff(ctx)
		return
	end
	direction_cutoff_opposite(ctx, desync)
	
	local data = desync.reasm_data or desync.dis.payload
	if #data>0 and desync.l7payload=="http_req" and direction_check(desync) then
		if replay_first(desync) then
			-- Parse HTTP request
			local hdis = http_dissect_req(data)
			if not hdis or not hdis.headers.host then
				DLOG("http_aggressive: cannot parse HTTP request or no Host header")
				return
			end
			
			local host_pos = hdis.headers.host
			-- pos_end points to end of line (before \r\n), pos_value_start to start of value
			local host_value = string.sub(data, host_pos.pos_value_start, host_pos.pos_end)
			
			DLOG("http_aggressive: detected Host: "..host_value)
			
			-- Options for fake packets (will die before reaching server)
			local opts_fake = {
				rawsend = rawsend_opts(desync), 
				reconstruct = reconstruct_opts(desync), 
				ipfrag = {}, 
				ipid = desync.arg, 
				fooling = desync.arg
			}
			
			-- Options for real packets (no fooling except tcp_ts_up)
			local opts_orig = {
				rawsend = rawsend_opts_base(desync), 
				reconstruct = {}, 
				ipfrag = {}, 
				ipid = desync.arg, 
				fooling = {tcp_ts_up = desync.arg.tcp_ts_up}
			}
			
			local num_fakes = tonumber(desync.arg.fakes) or 5
			local ttl_start = tonumber(desync.arg.ttl_start) or 1
			local ttl_step = tonumber(desync.arg.ttl_step) or 1
			
			-- Generate fake HTTP request with different host
			local fake_host = "www.google.com"
			local fake_data = string.sub(data, 1, host_pos.pos_value_start-1) .. 
							  fake_host .. 
							  string.sub(data, host_pos.pos_end+1)
			
			-- STEP 1: Send multiple fake packets with low TTL (will die before DPI or server)
			for i=1,num_fakes do
				local fake_dis = deepcopy(desync.dis)
				fake_dis.payload = fake_data
				
				-- Set low TTL so packet dies before reaching server
				local ttl = ttl_start + (i-1) * ttl_step
				if fake_dis.ip then
					fake_dis.ip.ip_ttl = ttl
				end
				if fake_dis.ip6 then
					fake_dis.ip6.ip6_hlim = ttl
				end
				
				-- Add badseq to confuse DPI further
				if fake_dis.tcp then
					fake_dis.tcp.th_ack = fake_dis.tcp.th_ack - 66000
				end
				
				if b_debug then DLOG("http_aggressive: sending fake #"..i.." TTL="..ttl) end
				rawsend_dissect(fake_dis, opts_fake.rawsend)
			end
			
			-- STEP 2: Split real request into parts
			-- Split points: before "Host:", middle of host, after host value
			local split_positions = {}
			
			-- Always split before "Host:" header
			table.insert(split_positions, host_pos.pos_start)
			
			-- Optionally split in the middle of hostname
			if desync.arg.split_host then
				local host_mid = host_pos.pos_value_start + math.floor(#host_value / 2)
				if host_mid > host_pos.pos_value_start and host_mid < host_pos.pos_end then
					table.insert(split_positions, host_mid)
				end
			end
			
			-- Split after Host header value
			table.insert(split_positions, host_pos.pos_end + 1)
			
			-- Sort positions
			table.sort(split_positions)
			
			-- Create parts
			local parts = {}
			local prev_pos = 1
			for i, pos in ipairs(split_positions) do
				if pos > prev_pos and pos <= #data then
					table.insert(parts, {
						data = string.sub(data, prev_pos, pos-1),
						offset = prev_pos - 1
					})
					prev_pos = pos
				end
			end
			-- Add remaining part
			if prev_pos <= #data then
				table.insert(parts, {
					data = string.sub(data, prev_pos),
					offset = prev_pos - 1
				})
			end
			
			if b_debug then 
				DLOG("http_aggressive: split into "..#parts.." parts")
				for i, p in ipairs(parts) do
					DLOG("http_aggressive: part "..i.." offset="..p.offset.." len="..#p.data)
				end
			end
			
			-- STEP 3: Send parts (optionally in disorder)
			if desync.arg.disorder and #parts > 1 then
				-- Send in reverse order (disorder)
				for i=#parts,1,-1 do
					if b_debug then DLOG("http_aggressive: sending part "..i.." (disorder)") end
					if not rawsend_payload_segmented(desync, parts[i].data, parts[i].offset, opts_orig) then
						return VERDICT_PASS
					end
				end
			else
				-- Send in normal order
				for i=1,#parts do
					if b_debug then DLOG("http_aggressive: sending part "..i) end
					if not rawsend_payload_segmented(desync, parts[i].data, parts[i].offset, opts_orig) then
						return VERDICT_PASS
					end
				end
			end
			
			-- STEP 4: Send more fakes after real data (sandwich technique)
			for i=1,math.floor(num_fakes/2) do
				local fake_dis = deepcopy(desync.dis)
				fake_dis.payload = fake_data
				if fake_dis.ip then
					fake_dis.ip.ip_ttl = ttl_start
				end
				if fake_dis.ip6 then
					fake_dis.ip6.ip6_hlim = ttl_start
				end
				if fake_dis.tcp then
					fake_dis.tcp.th_ack = fake_dis.tcp.th_ack - 66000
				end
				if b_debug then DLOG("http_aggressive: sending trailing fake #"..i) end
				rawsend_dissect(fake_dis, opts_fake.rawsend)
			end
			
			replay_drop_set(desync)
			return VERDICT_DROP
		else
			DLOG("http_aggressive: not acting on further replay pieces")
		end
		
		if replay_drop(desync) then
			return VERDICT_DROP
		end
	end
end

-- HTTP SYNDATA - Send HTTP request in SYN packet (most aggressive)
-- This bypasses DPI that only inspects data after handshake
-- standard args : fooling, rawsend, reconstruct, ipfrag
-- arg : blob=<blob> - HTTP request template (optional, will use current payload if available)
function http_syndata(ctx, desync)
	if desync.dis.tcp then
		if bitand(desync.dis.tcp.th_flags, TH_SYN + TH_ACK)==TH_SYN then
			local dis = deepcopy(desync.dis)
			
			-- Try to get HTTP request from conntrack or use template
			local http_req = desync.arg.blob and blob(desync, desync.arg.blob) or 
				"GET / HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n"
			
			dis.payload = http_req
			apply_fooling(desync, dis)
			
			if b_debug then DLOG("http_syndata: sending SYN with HTTP payload len="..#http_req) end
			if rawsend_dissect_ipfrag(dis, desync_opts(desync)) then
				return VERDICT_DROP
			end
		else
			instance_cutoff(ctx)
		end
	else
		instance_cutoff(ctx)
	end
end

-- HTTP with multiple disorder splits at critical positions
-- standard args : direction, payload, fooling, ip_id, rawsend, reconstruct
-- Splits at: method, path, host header name, host value (multiple cuts)
function http_multidisorder(ctx, desync)
	if not desync.dis.tcp then
		instance_cutoff(ctx)
		return
	end
	direction_cutoff_opposite(ctx, desync)
	
	local data = desync.reasm_data or desync.dis.payload
	if #data>0 and desync.l7payload=="http_req" and direction_check(desync) then
		if replay_first(desync) then
			-- Generate split positions for HTTP
			local positions = {}
			
			-- Split at position 1 (after first byte)
			table.insert(positions, 2)
			
			-- Find key positions in HTTP request
			local method_end = string.find(data, " ")
			if method_end then
				table.insert(positions, method_end)
				table.insert(positions, method_end + 1)
			end
			
			-- Find Host: header
			local host_start = string.find(data, "\r\nHost: ", 1, true)
			if host_start then
				table.insert(positions, host_start + 2) -- before "Host:"
				table.insert(positions, host_start + 8) -- after "Host: "
				
				-- Find end of host value
				local host_end = string.find(data, "\r\n", host_start + 8, true)
				if host_end then
					-- Split in middle of host value
					local mid = host_start + 8 + math.floor((host_end - host_start - 8) / 2)
					table.insert(positions, mid)
					table.insert(positions, host_end)
				end
			end
			
			-- Remove duplicates and sort
			local unique_pos = {}
			local seen = {}
			for _, p in ipairs(positions) do
				if p > 1 and p <= #data and not seen[p] then
					table.insert(unique_pos, p)
					seen[p] = true
				end
			end
			table.sort(unique_pos)
			
			if b_debug then DLOG("http_multidisorder: split positions: "..table.concat(unique_pos, ",")) end
			
			local opts_orig = {
				rawsend = rawsend_opts_base(desync), 
				reconstruct = {}, 
				ipfrag = {}, 
				ipid = desync.arg, 
				fooling = {tcp_ts_up = desync.arg.tcp_ts_up}
			}
			
			-- Create and send parts in reverse order
			local parts = {}
			local prev = 1
			for _, pos in ipairs(unique_pos) do
				if pos > prev then
					table.insert(parts, {string.sub(data, prev, pos-1), prev-1})
					prev = pos
				end
			end
			if prev <= #data then
				table.insert(parts, {string.sub(data, prev), prev-1})
			end
			
			-- Send in reverse order (disorder)
			for i=#parts,1,-1 do
				if b_debug then DLOG("http_multidisorder: sending part "..i.." offset="..parts[i][2].." len="..#parts[i][1]) end
				if not rawsend_payload_segmented(desync, parts[i][1], parts[i][2], opts_orig) then
					return VERDICT_PASS
				end
			end
			
			replay_drop_set(desync)
			return VERDICT_DROP
		else
			DLOG("http_multidisorder: not acting on further replay pieces")
		end
		
		if replay_drop(desync) then
			return VERDICT_DROP
		end
	end
end

-- Улучшенный methodeol - добавляет больше мусора в начало
function http_methodeol_v2(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    if desync.l7payload=="http_req" and direction_check(desync) then
        local hdis = http_dissect_req(desync.dis.payload)
        local ua = hdis.headers["user-agent"]
        if ua then
            -- Добавляем несколько пустых строк и пробелы
            local garbage = "\r\n \r\n\t\r\n"
            desync.dis.payload = garbage .. string.sub(desync.dis.payload,1,ua.pos_end-2) .. (string.sub(desync.dis.payload,ua.pos_end+1) or "")
            DLOG("http_methodeol_v2: applied with extra garbage")
            return VERDICT_MODIFY
        end
    end
end

-- Methodeol + изменение регистра Host
function http_methodeol_hostcase(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    if desync.l7payload=="http_req" and direction_check(desync) then
        local payload = desync.dis.payload
        
        -- Меняем Host: на HoSt:
        payload = string.gsub(payload, "\r\nHost:", "\r\nHoSt:")
        
        -- Добавляем мусор в начало
        payload = "\r\n" .. payload
        
        desync.dis.payload = payload
        DLOG("http_methodeol_hostcase: applied")
        return VERDICT_MODIFY
    end
end

-- AGGRESSIVE TLS BYPASS for stubborn DPI (like browserleaks.com)
-- Combines multiple techniques: fake flood + SNI split + disorder + seqovl
-- standard args : direction, payload, fooling, ip_id, rawsend, reconstruct
-- arg : fakes=N - number of fake packets to send (default 6)
-- arg : ttl_start=N - starting TTL for fakes (default 1)
-- arg : ttl_step=N - TTL increment for each fake (default 1)
-- arg : seqovl=N - sequence overlap size (default 0)
-- arg : seqovl_pattern=<blob> - pattern for seqovl
-- arg : fake_sni=<str> - SNI for fake packets (default www.google.com)
-- arg : split_sni - split inside SNI
-- arg : badseq - use badseq fooling on fakes
-- arg : md5sig - use md5sig fooling on fakes
function tls_aggressive(ctx, desync)
	if not desync.dis.tcp then
		instance_cutoff(ctx)
		return
	end
	direction_cutoff_opposite(ctx, desync)
	
	local data = desync.reasm_data or desync.dis.payload
	if #data>0 and desync.l7payload=="tls_client_hello" and direction_check(desync) then
		if replay_first(desync) then
			DLOG("tls_aggressive: processing TLS Client Hello len="..#data)
			
			-- Options for fake packets (will die before reaching server)
			local opts_fake = {
				rawsend = rawsend_opts(desync), 
				reconstruct = reconstruct_opts(desync), 
				ipfrag = {}, 
				ipid = desync.arg, 
				fooling = desync.arg
			}
			
			-- Options for real packets (no fooling except tcp_ts_up)
			local opts_orig = {
				rawsend = rawsend_opts_base(desync), 
				reconstruct = {}, 
				ipfrag = {}, 
				ipid = desync.arg, 
				fooling = {tcp_ts_up = desync.arg.tcp_ts_up}
			}
			
			local num_fakes = tonumber(desync.arg.fakes) or 6
			local ttl_start = tonumber(desync.arg.ttl_start) or 1
			local ttl_step = tonumber(desync.arg.ttl_step) or 1
			local fake_sni = desync.arg.fake_sni or "www.google.com"
			
			-- Generate fake TLS Client Hello with different SNI using tls_mod
			local fake_blob = desync.arg.blob and blob(desync, desync.arg.blob) or blob(desync, "fake_default_tls")
			local fake_data = fake_blob
			if desync.arg.tls_mod then
				fake_data = tls_mod(fake_data, desync.arg.tls_mod, desync.reasm_data)
			else
				-- Default: randomize and set fake SNI
				fake_data = tls_mod(fake_data, "rnd,dupsid,sni="..fake_sni, desync.reasm_data)
			end
			
			-- STEP 1: Send multiple fake packets with low TTL
			for i=1,num_fakes do
				local fake_dis = deepcopy(desync.dis)
				fake_dis.payload = fake_data
				
				local ttl = ttl_start + (i-1) * ttl_step
				if fake_dis.ip then
					fake_dis.ip.ip_ttl = ttl
				end
				if fake_dis.ip6 then
					fake_dis.ip6.ip6_hlim = ttl
				end
				
				-- Apply fooling based on args
				if fake_dis.tcp then
					if desync.arg.badseq then
						fake_dis.tcp.th_ack = fake_dis.tcp.th_ack - 66000
					end
				end
				
				if b_debug then DLOG("tls_aggressive: sending fake #"..i.." TTL="..ttl.." len="..#fake_data) end
				rawsend_dissect(fake_dis, opts_fake.rawsend)
			end
			
			-- STEP 2: Determine split positions for TLS Client Hello
			-- Key positions: start, after record header, SNI positions
			local split_positions = {}
			
			-- Always split at position 1 (minimal split)
			table.insert(split_positions, 2)
			
			-- Try to find SNI in TLS Client Hello using resolve_multi_pos
			local sni_positions = resolve_multi_pos(data, "tls_client_hello", "host,midsld,endhost")
			if sni_positions and #sni_positions >= 2 then
				for _, pos in ipairs(sni_positions) do
					if pos > 1 and pos <= #data then
						table.insert(split_positions, pos)
					end
				end
				if b_debug then DLOG("tls_aggressive: found SNI positions: "..table.concat(sni_positions, ",")) end
			else
				-- Fallback: split at fixed positions
				local tls_header_end = 6 -- After TLS record header
				if tls_header_end < #data then
					table.insert(split_positions, tls_header_end)
				end
				-- Split at ~1/3 and ~2/3 of data
				local third = math.floor(#data / 3)
				if third > 5 then
					table.insert(split_positions, third)
					table.insert(split_positions, third * 2)
				end
			end
			
			-- Also try sniext positions
			local sniext_positions = resolve_multi_pos(data, "tls_client_hello", "sniext,sniext+1,sniext+2")
			if sniext_positions then
				for _, pos in ipairs(sniext_positions) do
					if pos > 1 and pos <= #data then
						table.insert(split_positions, pos)
					end
				end
			end
			
			-- Remove duplicates and sort
			local unique_pos = {}
			local seen = {}
			for _, p in ipairs(split_positions) do
				if p > 1 and p <= #data and not seen[p] then
					table.insert(unique_pos, p)
					seen[p] = true
				end
			end
			table.sort(unique_pos)
			
			if b_debug then DLOG("tls_aggressive: split positions: "..table.concat(unique_pos, ",")) end
			
			-- Create parts
			local parts = {}
			local prev = 1
			for _, pos in ipairs(unique_pos) do
				if pos > prev then
					table.insert(parts, {string.sub(data, prev, pos-1), prev-1})
					prev = pos
				end
			end
			if prev <= #data then
				table.insert(parts, {string.sub(data, prev), prev-1})
			end
			
			if b_debug then DLOG("tls_aggressive: created "..#parts.." parts") end
			
			-- STEP 3: Send parts in reverse order (disorder) with optional seqovl
			local seqovl = tonumber(desync.arg.seqovl) or 0
			local seqovl_pat = desync.arg.seqovl_pattern and blob(desync, desync.arg.seqovl_pattern) or "\x00"
			
			for i=#parts,1,-1 do
				local part_data = parts[i][1]
				local part_offset = parts[i][2]
				
				-- Apply seqovl to second part (in original order, which is second-to-last in disorder)
				if i == (#parts - 1) and seqovl > 0 and part_offset >= seqovl then
					part_data = pattern(seqovl_pat, 1, seqovl) .. part_data
					part_offset = part_offset - seqovl
					if b_debug then DLOG("tls_aggressive: applied seqovl="..seqovl.." to part "..i) end
				end
				
				if b_debug then DLOG("tls_aggressive: sending part "..i.." offset="..part_offset.." len="..#part_data) end
				if not rawsend_payload_segmented(desync, part_data, part_offset, opts_orig) then
					return VERDICT_PASS
				end
			end
			
			-- STEP 4: Send trailing fakes (sandwich)
			for i=1,math.floor(num_fakes/2) do
				local fake_dis = deepcopy(desync.dis)
				fake_dis.payload = fake_data
				if fake_dis.ip then
					fake_dis.ip.ip_ttl = ttl_start
				end
				if fake_dis.ip6 then
					fake_dis.ip6.ip6_hlim = ttl_start
				end
				if fake_dis.tcp and desync.arg.badseq then
					fake_dis.tcp.th_ack = fake_dis.tcp.th_ack - 66000
				end
				if b_debug then DLOG("tls_aggressive: sending trailing fake #"..i) end
				rawsend_dissect(fake_dis, opts_fake.rawsend)
			end
			
			replay_drop_set(desync)
			return VERDICT_DROP
		else
			DLOG("tls_aggressive: not acting on further replay pieces")
		end
		
		if replay_drop(desync) then
			return VERDICT_DROP
		end
	end
end

-- TLS with extreme multi-split at SNI and surrounding areas
-- Splits TLS Client Hello into many small pieces around SNI
-- standard args : direction, payload, fooling, ip_id, rawsend, reconstruct
-- arg : seqovl=N - sequence overlap (default 211)
-- arg : seqovl_pattern=<blob> - pattern for seqovl
function tls_multisplit_sni(ctx, desync)
	if not desync.dis.tcp then
		instance_cutoff(ctx)
		return
	end
	direction_cutoff_opposite(ctx, desync)
	
	local data = desync.reasm_data or desync.dis.payload
	if #data>0 and desync.l7payload=="tls_client_hello" and direction_check(desync) then
		if replay_first(desync) then
			-- Get extensive split positions around SNI
			local spos = "1,host-2,host,host+1,host+2,midsld-1,midsld,midsld+1,sld,sld+1,sld+2,endhost-2,endhost-1,endhost,sniext,sniext+1,sniext+2"
			
			if b_debug then DLOG("tls_multisplit_sni: split pos: "..spos) end
			local pos = resolve_multi_pos(data, desync.l7payload, spos)
			if b_debug then DLOG("tls_multisplit_sni: resolved split pos: "..table.concat(zero_based_pos(pos)," ")) end
			delete_pos_1(pos)
			
			if #pos>0 then
				local seqovl = tonumber(desync.arg.seqovl) or 211
				local seqovl_pat = desync.arg.seqovl_pattern and blob(desync, desync.arg.seqovl_pattern) or blob(desync, "fake_default_tls")
				
				-- Send in disorder order (last to first)
				for i=#pos,0,-1 do
					local pos_start = pos[i] or 1
					local pos_end = i<#pos and pos[i+1]-1 or #data
					local part = string.sub(data,pos_start,pos_end)
					local part_seqovl = 0
					
					-- Apply seqovl to second part (in original order)
					if i==1 and seqovl > 0 then
						part_seqovl = seqovl
						if part_seqovl >= (pos[1]-1) then
							DLOG("tls_multisplit_sni: seqovl cancelled, too large")
							part_seqovl = 0
						else
							part = pattern(seqovl_pat, 1, part_seqovl) .. part
						end
					end
					
					if b_debug then DLOG("tls_multisplit_sni: sending part "..(i+1).." "..(pos_start-1).."-"..(pos_end-1).." len="..#part.." seqovl="..part_seqovl) end
					if not rawsend_payload_segmented(desync, part, pos_start-1-part_seqovl) then
						return VERDICT_PASS
					end
				end
				replay_drop_set(desync)
				return VERDICT_DROP
			else
				DLOG("tls_multisplit_sni: no valid split positions")
			end
		else
			DLOG("tls_multisplit_sni: not acting on further replay pieces")
		end
		
		if replay_drop(desync) then
			return VERDICT_DROP
		end
	end
end

-- TLS Fake flood + standard multidisorder
-- Sends many fakes before applying standard multidisorder
-- standard args : direction, payload, fooling, ip_id, rawsend, reconstruct
-- arg : fakes=N - number of fakes (default 11)
-- arg : pos=<posmarker list> - split positions for multidisorder
-- arg : badseq/md5sig - fooling for fakes
function tls_fake_flood(ctx, desync)
	if not desync.dis.tcp then
		instance_cutoff(ctx)
		return
	end
	direction_cutoff_opposite(ctx, desync)
	
	local data = desync.reasm_data or desync.dis.payload
	if #data>0 and desync.l7payload=="tls_client_hello" and direction_check(desync) then
		if replay_first(desync) then
			local num_fakes = tonumber(desync.arg.fakes) or 11
			local fake_blob = desync.arg.blob and blob(desync, desync.arg.blob) or blob(desync, "fake_default_tls")
			
			-- Apply tls_mod to make fake look real but with different SNI
			local fake_data = tls_mod(fake_blob, "rnd,dupsid,sni=www.google.com", desync.reasm_data)
			
			local opts_fake = {rawsend = rawsend_opts(desync), reconstruct = reconstruct_opts(desync)}
			
			-- Send fake flood with varying TTL
			for i=1,num_fakes do
				local fake_dis = deepcopy(desync.dis)
				fake_dis.payload = fake_data
				
				-- Vary TTL: 1,2,3,1,2,3,1,2,3...
				local ttl = ((i-1) % 3) + 1
				if fake_dis.ip then fake_dis.ip.ip_ttl = ttl end
				if fake_dis.ip6 then fake_dis.ip6.ip6_hlim = ttl end
				
				-- Apply fooling
				if fake_dis.tcp then
					if desync.arg.badseq then
						fake_dis.tcp.th_ack = fake_dis.tcp.th_ack - 66000
					end
					if desync.arg.md5sig then
						-- md5sig applied through reconstruct
					end
				end
				
				if b_debug then DLOG("tls_fake_flood: sending fake #"..i.." TTL="..ttl) end
				rawsend_dissect(fake_dis, opts_fake.rawsend)
			end
			
			-- Now send real data with multidisorder
			local spos = desync.arg.pos or "1,midsld"
			local pos = resolve_multi_pos(data, desync.l7payload, spos)
			delete_pos_1(pos)
			
			local opts_orig = {
				rawsend = rawsend_opts_base(desync), 
				reconstruct = {}, 
				ipfrag = {}, 
				ipid = desync.arg, 
				fooling = {tcp_ts_up = desync.arg.tcp_ts_up}
			}
			
			if #pos>0 then
				for i=#pos,0,-1 do
					local pos_start = pos[i] or 1
					local pos_end = i<#pos and pos[i+1]-1 or #data
					local part = string.sub(data,pos_start,pos_end)
					
					if b_debug then DLOG("tls_fake_flood: sending part "..(i+1).." len="..#part) end
					if not rawsend_payload_segmented(desync, part, pos_start-1, opts_orig) then
						return VERDICT_PASS
					end
				end
			else
				-- No valid positions, send as-is
				if not rawsend_payload_segmented(desync, data, 0, opts_orig) then
					return VERDICT_PASS
				end
			end
			
			-- Send more fakes after (sandwich)
			for i=1,math.floor(num_fakes/3) do
				local fake_dis = deepcopy(desync.dis)
				fake_dis.payload = fake_data
				if fake_dis.ip then fake_dis.ip.ip_ttl = 1 end
				if fake_dis.ip6 then fake_dis.ip6.ip6_hlim = 1 end
				if b_debug then DLOG("tls_fake_flood: sending trailing fake #"..i) end
				rawsend_dissect(fake_dis, opts_fake.rawsend)
			end
			
			replay_drop_set(desync)
			return VERDICT_DROP
		else
			DLOG("tls_fake_flood: not acting on further replay pieces")
		end
		
		if replay_drop(desync) then
			return VERDICT_DROP
		end
	end
end

-- ============================================================================
-- SOFT/GENTLE TLS STRATEGIES - less aggressive, won't break sites
-- ============================================================================

-- Simple fake only - no splitting, just send fakes before real data
-- Works for many sites without breaking TLS
-- standard args : direction, payload, fooling, ip_id, rawsend, reconstruct
-- arg : fakes=N - number of fakes (default 6)
-- arg : ttl=N - TTL for fakes (default 3)
-- arg : sni=<str> - SNI for fakes (default www.google.com)
function tls_fake_simple(ctx, desync)
	if not desync.dis.tcp then
		instance_cutoff(ctx)
		return
	end
	direction_cutoff_opposite(ctx, desync)
	
	local data = desync.reasm_data or desync.dis.payload
	if #data>0 and desync.l7payload=="tls_client_hello" and direction_check(desync) then
		if replay_first(desync) then
			local num_fakes = tonumber(desync.arg.fakes) or 6
			local ttl = tonumber(desync.arg.ttl) or 3
			local fake_sni = desync.arg.sni or "www.google.com"
			
			local fake_blob = desync.arg.blob and blob(desync, desync.arg.blob) or blob(desync, "fake_default_tls")
			local fake_data = tls_mod(fake_blob, "rnd,dupsid,sni="..fake_sni, desync.reasm_data)
			
			local opts_fake = {rawsend = rawsend_opts(desync), reconstruct = reconstruct_opts(desync)}
			
			-- Send fakes
			for i=1,num_fakes do
				local fake_dis = deepcopy(desync.dis)
				fake_dis.payload = fake_data
				if fake_dis.ip then fake_dis.ip.ip_ttl = ttl end
				if fake_dis.ip6 then fake_dis.ip6.ip6_hlim = ttl end
				
				if b_debug then DLOG("tls_fake_simple: sending fake #"..i.." TTL="..ttl) end
				rawsend_dissect(fake_dis, opts_fake.rawsend)
			end
			
			-- Send real data as-is (no splitting!)
			DLOG("tls_fake_simple: sending real data len="..#data)
			-- Don't drop, let original packet through
		else
			DLOG("tls_fake_simple: not acting on further replay pieces")
		end
	end
end

-- Gentle split - only 2 parts, no disorder
-- Splits at midsld position only
-- standard args : direction, payload, fooling, ip_id, rawsend, reconstruct
-- arg : pos=<posmarker> - single split position (default midsld)
function tls_split_gentle(ctx, desync)
	if not desync.dis.tcp then
		instance_cutoff(ctx)
		return
	end
	direction_cutoff_opposite(ctx, desync)
	
	local data = desync.reasm_data or desync.dis.payload
	if #data>0 and desync.l7payload=="tls_client_hello" and direction_check(desync) then
		if replay_first(desync) then
			local spos = desync.arg.pos or "midsld"
			local pos = resolve_pos(data, desync.l7payload, spos)
			
			if pos and pos > 1 and pos < #data then
				if b_debug then DLOG("tls_split_gentle: split at "..spos.." = "..(pos-1)) end
				
				local opts_orig = {
					rawsend = rawsend_opts_base(desync), 
					reconstruct = {}, 
					ipfrag = {}, 
					ipid = desync.arg, 
					fooling = {tcp_ts_up = desync.arg.tcp_ts_up}
				}
				
				-- Part 1: start to split pos
				local part1 = string.sub(data, 1, pos-1)
				if b_debug then DLOG("tls_split_gentle: sending part 1 len="..#part1) end
				if not rawsend_payload_segmented(desync, part1, 0, opts_orig) then
					return VERDICT_PASS
				end
				
				-- Part 2: split pos to end
				local part2 = string.sub(data, pos)
				if b_debug then DLOG("tls_split_gentle: sending part 2 len="..#part2) end
				if not rawsend_payload_segmented(desync, part2, pos-1, opts_orig) then
					return VERDICT_PASS
				end
				
				replay_drop_set(desync)
				return VERDICT_DROP
			else
				DLOG("tls_split_gentle: cannot resolve pos '"..spos.."' or invalid")
			end
		else
			DLOG("tls_split_gentle: not acting on further replay pieces")
		end
		
		if replay_drop(desync) then
			return VERDICT_DROP
		end
	end
end

-- Fake + gentle split combo
-- Send fakes then split at one position
-- standard args : direction, payload, fooling, ip_id, rawsend, reconstruct
-- arg : fakes=N - number of fakes (default 4)
-- arg : ttl=N - TTL for fakes (default 2)
-- arg : pos=<posmarker> - split position (default midsld)
function tls_fake_split(ctx, desync)
	if not desync.dis.tcp then
		instance_cutoff(ctx)
		return
	end
	direction_cutoff_opposite(ctx, desync)
	
	local data = desync.reasm_data or desync.dis.payload
	if #data>0 and desync.l7payload=="tls_client_hello" and direction_check(desync) then
		if replay_first(desync) then
			local num_fakes = tonumber(desync.arg.fakes) or 4
			local ttl = tonumber(desync.arg.ttl) or 2
			local spos = desync.arg.pos or "midsld"
			
			local fake_blob = desync.arg.blob and blob(desync, desync.arg.blob) or blob(desync, "fake_default_tls")
			local fake_data = tls_mod(fake_blob, "rnd,dupsid,sni=www.google.com", desync.reasm_data)
			
			local opts_fake = {rawsend = rawsend_opts(desync), reconstruct = reconstruct_opts(desync)}
			local opts_orig = {
				rawsend = rawsend_opts_base(desync), 
				reconstruct = {}, 
				ipfrag = {}, 
				ipid = desync.arg, 
				fooling = {tcp_ts_up = desync.arg.tcp_ts_up}
			}
			
			-- Send fakes first
			for i=1,num_fakes do
				local fake_dis = deepcopy(desync.dis)
				fake_dis.payload = fake_data
				if fake_dis.ip then fake_dis.ip.ip_ttl = ttl end
				if fake_dis.ip6 then fake_dis.ip6.ip6_hlim = ttl end
				if b_debug then DLOG("tls_fake_split: sending fake #"..i) end
				rawsend_dissect(fake_dis, opts_fake.rawsend)
			end
			
			-- Now split at one position
			local pos = resolve_pos(data, desync.l7payload, spos)
			if pos and pos > 1 and pos < #data then
				local part1 = string.sub(data, 1, pos-1)
				local part2 = string.sub(data, pos)
				
				if b_debug then DLOG("tls_fake_split: sending part 1 len="..#part1) end
				if not rawsend_payload_segmented(desync, part1, 0, opts_orig) then
					return VERDICT_PASS
				end
				
				if b_debug then DLOG("tls_fake_split: sending part 2 len="..#part2) end
				if not rawsend_payload_segmented(desync, part2, pos-1, opts_orig) then
					return VERDICT_PASS
				end
				
				replay_drop_set(desync)
				return VERDICT_DROP
			else
				-- Can't split, send as-is
				DLOG("tls_fake_split: can't split, sending as-is")
				if not rawsend_payload_segmented(desync, data, 0, opts_orig) then
					return VERDICT_PASS
				end
				replay_drop_set(desync)
				return VERDICT_DROP
			end
		else
			DLOG("tls_fake_split: not acting on further replay pieces")
		end
		
		if replay_drop(desync) then
			return VERDICT_DROP
		end
	end
end

-- Disorder with only 3 parts (gentle)
-- Less fragmentation = works with more servers
-- standard args : direction, payload, fooling, ip_id, rawsend, reconstruct
-- arg : pos1=<posmarker> - first split (default host)
-- arg : pos2=<posmarker> - second split (default endhost)
function tls_disorder_gentle(ctx, desync)
	if not desync.dis.tcp then
		instance_cutoff(ctx)
		return
	end
	direction_cutoff_opposite(ctx, desync)
	
	local data = desync.reasm_data or desync.dis.payload
	if #data>0 and desync.l7payload=="tls_client_hello" and direction_check(desync) then
		if replay_first(desync) then
			local spos1 = desync.arg.pos1 or "host"
			local spos2 = desync.arg.pos2 or "endhost"
			
			local pos1 = resolve_pos(data, desync.l7payload, spos1)
			local pos2 = resolve_pos(data, desync.l7payload, spos2)
			
			local opts_orig = {
				rawsend = rawsend_opts_base(desync), 
				reconstruct = {}, 
				ipfrag = {}, 
				ipid = desync.arg, 
				fooling = {tcp_ts_up = desync.arg.tcp_ts_up}
			}
			
			if pos1 and pos2 and pos1 > 1 and pos2 > pos1 and pos2 <= #data then
				if b_debug then DLOG("tls_disorder_gentle: split at "..spos1.."="..(pos1-1)..", "..spos2.."="..(pos2-1)) end
				
				local part1 = string.sub(data, 1, pos1-1)
				local part2 = string.sub(data, pos1, pos2-1)
				local part3 = string.sub(data, pos2)
				
				-- Send in disorder: 3, 2, 1
				if b_debug then DLOG("tls_disorder_gentle: sending part 3 (last) len="..#part3) end
				if not rawsend_payload_segmented(desync, part3, pos2-1, opts_orig) then
					return VERDICT_PASS
				end
				
				if b_debug then DLOG("tls_disorder_gentle: sending part 2 (middle) len="..#part2) end
				if not rawsend_payload_segmented(desync, part2, pos1-1, opts_orig) then
					return VERDICT_PASS
				end
				
				if b_debug then DLOG("tls_disorder_gentle: sending part 1 (first) len="..#part1) end
				if not rawsend_payload_segmented(desync, part1, 0, opts_orig) then
					return VERDICT_PASS
				end
				
				replay_drop_set(desync)
				return VERDICT_DROP
			else
				DLOG("tls_disorder_gentle: can't resolve positions, falling back to simple split")
				-- Fallback: split at position 2
				local part1 = string.sub(data, 1, 1)
				local part2 = string.sub(data, 2)
				
				-- Disorder: 2, 1
				if not rawsend_payload_segmented(desync, part2, 1, opts_orig) then
					return VERDICT_PASS
				end
				if not rawsend_payload_segmented(desync, part1, 0, opts_orig) then
					return VERDICT_PASS
				end
				
				replay_drop_set(desync)
				return VERDICT_DROP
			end
		else
			DLOG("tls_disorder_gentle: not acting on further replay pieces")
		end
		
		if replay_drop(desync) then
			return VERDICT_DROP
		end
	end
end

-- ============================================================================
-- MGTS HTTP BYPASS STRATEGIES - специально для обхода умного DPI МГТС
-- ============================================================================

-- HTTP seqovl Host Override
-- Отправляем фейковый Host с seqovl, потом реальный который "перезаписывает"
-- DPI видит первый (фейковый), сервер принимает второй (реальный) по TCP reassembly
-- standard args : direction, payload, rawsend, reconstruct
-- arg : fake_host=<str> - фейковый хост (default google.com)
-- arg : seqovl=N - размер перекрытия (default = длина Host value)
function http_seqovl_host(ctx, desync)
	if not desync.dis.tcp then
		instance_cutoff(ctx)
		return
	end
	direction_cutoff_opposite(ctx, desync)
	
	local data = desync.reasm_data or desync.dis.payload
	if #data>0 and desync.l7payload=="http_req" and direction_check(desync) then
		if replay_first(desync) then
			local hdis = http_dissect_req(data)
			if not hdis or not hdis.headers.host then
				DLOG("http_seqovl_host: no Host header found")
				return
			end
			
			local host_pos = hdis.headers.host
			local real_host = string.sub(data, host_pos.pos_value_start, host_pos.pos_end)
			local fake_host = desync.arg.fake_host or "google.com"
			
			DLOG("http_seqovl_host: real_host='"..real_host.."' fake_host='"..fake_host.."'")
			
			-- Создаём фейковый HTTP запрос с fake_host
			-- Нужно чтобы fake_host был той же длины что и real_host для точного seqovl
			if #fake_host < #real_host then
				fake_host = fake_host .. string.rep("x", #real_host - #fake_host)
			elseif #fake_host > #real_host then
				fake_host = string.sub(fake_host, 1, #real_host)
			end
			
			local fake_data = string.sub(data, 1, host_pos.pos_value_start-1) .. 
							  fake_host .. 
							  string.sub(data, host_pos.pos_end+1)
			
			local opts_orig = {
				rawsend = rawsend_opts_base(desync), 
				reconstruct = {}, 
				ipfrag = {}, 
				fooling = {}
			}
			
			-- Позиция начала Host value
			local host_value_pos = host_pos.pos_value_start - 1  -- 0-based
			
			-- STEP 1: Отправляем часть ДО Host value
			local before_host = string.sub(data, 1, host_pos.pos_value_start-1)
			if b_debug then DLOG("http_seqovl_host: sending before_host len="..#before_host) end
			if not rawsend_payload_segmented(desync, before_host, 0, opts_orig) then
				return VERDICT_PASS
			end
			
			-- STEP 2: Отправляем ФЕЙКОВЫЙ Host value (DPI увидит это первым)
			if b_debug then DLOG("http_seqovl_host: sending FAKE host '"..fake_host.."'") end
			if not rawsend_payload_segmented(desync, fake_host, host_value_pos, opts_orig) then
				return VERDICT_PASS
			end
			
			-- STEP 3: Отправляем РЕАЛЬНЫЙ Host value с тем же offset (seqovl!)
			-- TCP стек сервера должен принять этот пакет и перезаписать фейковый
			if b_debug then DLOG("http_seqovl_host: sending REAL host '"..real_host.."' (seqovl)") end
			if not rawsend_payload_segmented(desync, real_host, host_value_pos, opts_orig) then
				return VERDICT_PASS
			end
			
			-- STEP 4: Отправляем остаток ПОСЛЕ Host value
			local after_host = string.sub(data, host_pos.pos_end+1)
			if b_debug then DLOG("http_seqovl_host: sending after_host len="..#after_host) end
			if not rawsend_payload_segmented(desync, after_host, host_pos.pos_end, opts_orig) then
				return VERDICT_PASS
			end
			
			replay_drop_set(desync)
			return VERDICT_DROP
		else
			DLOG("http_seqovl_host: not acting on further replay pieces")
		end
		
		if replay_drop(desync) then
			return VERDICT_DROP
		end
	end
end

-- HTTP with IP fragmentation
-- Разбивает IP пакет на фрагменты - DPI может не уметь их собирать
-- standard args : direction, payload, rawsend
-- arg : frag_size=N - размер первого фрагмента (default 24 - разрежет внутри Host)
function http_ipfrag(ctx, desync)
	if not desync.dis.tcp then
		instance_cutoff(ctx)
		return
	end
	direction_cutoff_opposite(ctx, desync)
	
	local data = desync.reasm_data or desync.dis.payload
	if #data>0 and desync.l7payload=="http_req" and direction_check(desync) then
		if replay_first(desync) then
			local frag_size = tonumber(desync.arg.frag_size) or 24
			
			DLOG("http_ipfrag: fragmenting at IP level, frag_size="..frag_size)
			
			-- Используем встроенную IP фрагментацию
			local opts = {
				rawsend = rawsend_opts(desync),
				reconstruct = {},
				ipfrag = {
					ipfrag_pos_tcp = frag_size
				}
			}
			
			if rawsend_dissect_ipfrag(desync.dis, opts) then
				replay_drop_set(desync)
				return VERDICT_DROP
			end
		else
			DLOG("http_ipfrag: not acting on further replay pieces")
		end
		
		if replay_drop(desync) then
			return VERDICT_DROP
		end
	end
end

-- HTTP Host case modification
-- Меняет регистр "Host:" header - некоторые DPI чувствительны к регистру
-- standard args : direction, payload
-- arg : case=<str> - "lower", "upper", "mixed", "space" (default mixed)
function http_hostmod(ctx, desync)
	if not desync.dis.tcp then
		instance_cutoff(ctx)
		return
	end
	direction_cutoff_opposite(ctx, desync)
	
	if desync.l7payload=="http_req" and direction_check(desync) then
		local case_type = desync.arg.case or "mixed"
		local new_host_header
		
		if case_type == "lower" then
			new_host_header = "host"
		elseif case_type == "upper" then
			new_host_header = "HOST"
		elseif case_type == "mixed" then
			new_host_header = "HoSt"
		elseif case_type == "space" then
			new_host_header = "Host "  -- пробел после
		elseif case_type == "tab" then
			new_host_header = "Host\t"  -- таб после
		else
			new_host_header = case_type  -- custom
		end
		
		-- Найти и заменить "Host:" на новый вариант
		local host_start = string.find(desync.dis.payload, "\r\nHost:", 1, true)
		if host_start then
			host_start = host_start + 2  -- skip \r\n
			local new_payload = string.sub(desync.dis.payload, 1, host_start-1) ..
							   new_host_header .. ":" ..
							   string.sub(desync.dis.payload, host_start + 5)  -- skip "Host:"
			desync.dis.payload = new_payload
			DLOG("http_hostmod: changed 'Host:' to '"..new_host_header..":' ")
			return VERDICT_MODIFY
		else
			DLOG("http_hostmod: Host header not found")
		end
	end
end

-- HTTP with absolute URL
-- Использует абсолютный URL в запросе: GET http://host/path HTTP/1.1
-- Некоторые DPI не парсят URL, только Host header
-- standard args : direction, payload
-- arg : fake_host=<str> - фейковый хост для Host header (default google.com)
function http_absolute_url(ctx, desync)
	if not desync.dis.tcp then
		instance_cutoff(ctx)
		return
	end
	direction_cutoff_opposite(ctx, desync)
	
	if desync.l7payload=="http_req" and direction_check(desync) then
		local hdis = http_dissect_req(desync.dis.payload)
		if not hdis or not hdis.headers.host then
			DLOG("http_absolute_url: cannot parse HTTP")
			return
		end
		
		local real_host = string.sub(desync.dis.payload, hdis.headers.host.pos_value_start, hdis.headers.host.pos_end)
		local fake_host = desync.arg.fake_host or "google.com"
		local path = hdis.path or "/"
		
		-- Создаём новый запрос с абсолютным URL
		-- GET http://real_host/path HTTP/1.1\r\nHost: fake_host\r\n...
		local abs_url = "http://" .. real_host .. path
		local new_request = hdis.method .. " " .. abs_url .. " " .. hdis.version .. "\r\n"
		
		-- Добавляем headers, но меняем Host на фейковый
		for name, header in pairs(hdis.headers) do
			if name == "host" then
				new_request = new_request .. "Host: " .. fake_host .. "\r\n"
			else
				local header_value = string.sub(desync.dis.payload, header.pos_value_start, header.pos_end)
				new_request = new_request .. header.name .. ": " .. header_value .. "\r\n"
			end
		end
		new_request = new_request .. "\r\n"
		
		-- Добавляем body если есть
		if hdis.body_start and hdis.body_start <= #desync.dis.payload then
			new_request = new_request .. string.sub(desync.dis.payload, hdis.body_start)
		end
		
		desync.dis.payload = new_request
		DLOG("http_absolute_url: rewrote to absolute URL, Host header now '"..fake_host.."'")
		return VERDICT_MODIFY
	end
end

-- HTTP Triple seqovl attack
-- Отправляет 3 версии Host value с одинаковым seq number
-- 1. Fake host (DPI кеширует)
-- 2. Garbage (сбивает DPI)
-- 3. Real host (сервер принимает последний по TCP)
-- standard args : direction, payload, rawsend, reconstruct
-- arg : fake_host=<str> - фейковый хост
function http_triple_seqovl(ctx, desync)
	if not desync.dis.tcp then
		instance_cutoff(ctx)
		return
	end
	direction_cutoff_opposite(ctx, desync)
	
	local data = desync.reasm_data or desync.dis.payload
	if #data>0 and desync.l7payload=="http_req" and direction_check(desync) then
		if replay_first(desync) then
			local hdis = http_dissect_req(data)
			if not hdis or not hdis.headers.host then
				DLOG("http_triple_seqovl: no Host header")
				return
			end
			
			local host_pos = hdis.headers.host
			local real_host = string.sub(data, host_pos.pos_value_start, host_pos.pos_end)
			local host_len = #real_host
			local fake_host = desync.arg.fake_host or "www.google.com"
			
			-- Подгоняем длину
			if #fake_host < host_len then
				fake_host = fake_host .. string.rep(".", host_len - #fake_host)
			else
				fake_host = string.sub(fake_host, 1, host_len)
			end
			
			local garbage = string.rep("X", host_len)
			
			local opts_orig = {
				rawsend = rawsend_opts_base(desync), 
				reconstruct = {}, 
				ipfrag = {}, 
				fooling = {}
			}
			
			local host_value_pos = host_pos.pos_value_start - 1
			
			-- Отправляем часть ДО Host value
			local before_host = string.sub(data, 1, host_pos.pos_value_start-1)
			if not rawsend_payload_segmented(desync, before_host, 0, opts_orig) then
				return VERDICT_PASS
			end
			
			-- АТАКА: 3 пакета с одинаковым seq
			-- 1. Fake host
			if b_debug then DLOG("http_triple_seqovl: [1] FAKE host '"..fake_host.."'") end
			if not rawsend_payload_segmented(desync, fake_host, host_value_pos, opts_orig) then
				return VERDICT_PASS
			end
			
			-- 2. Garbage (сбивает кеш DPI)
			if b_debug then DLOG("http_triple_seqovl: [2] GARBAGE") end
			if not rawsend_payload_segmented(desync, garbage, host_value_pos, opts_orig) then
				return VERDICT_PASS
			end
			
			-- 3. Real host (последний - сервер примет его)
			if b_debug then DLOG("http_triple_seqovl: [3] REAL host '"..real_host.."'") end
			if not rawsend_payload_segmented(desync, real_host, host_value_pos, opts_orig) then
				return VERDICT_PASS
			end
			
			-- Отправляем остаток
			local after_host = string.sub(data, host_pos.pos_end+1)
			if not rawsend_payload_segmented(desync, after_host, host_pos.pos_end, opts_orig) then
				return VERDICT_PASS
			end
			
			replay_drop_set(desync)
			return VERDICT_DROP
		end
		
		if replay_drop(desync) then
			return VERDICT_DROP
		end
	end
end

-- HTTP Disorder + seqovl combo for MGTS
-- Комбинирует disorder с seqovl специально для Host header
-- standard args : direction, payload, rawsend
-- arg : fake_host=<str>
function http_mgts_combo(ctx, desync)
	if not desync.dis.tcp then
		instance_cutoff(ctx)
		return
	end
	direction_cutoff_opposite(ctx, desync)
	
	local data = desync.reasm_data or desync.dis.payload
	if #data>0 and desync.l7payload=="http_req" and direction_check(desync) then
		if replay_first(desync) then
			local hdis = http_dissect_req(data)
			if not hdis or not hdis.headers.host then
				DLOG("http_mgts_combo: no Host header")
				return
			end
			
			local host_pos = hdis.headers.host
			local real_host = string.sub(data, host_pos.pos_value_start, host_pos.pos_end)
			local fake_host = desync.arg.fake_host or "www.google.com"
			
			-- Подгоняем длину
			local host_len = #real_host
			if #fake_host < host_len then
				fake_host = fake_host .. string.rep("x", host_len - #fake_host)
			else
				fake_host = string.sub(fake_host, 1, host_len)
			end
			
			local opts = {
				rawsend = rawsend_opts_base(desync), 
				reconstruct = {}, 
				ipfrag = {}, 
				fooling = {}
			}
			
			-- Разбиваем на 4 части:
			-- 1. До "Host: "
			-- 2. "Host: " + fake_host (seqovl с реальным)
			-- 3. real_host (перезаписывает)
			-- 4. После host value до конца
			
			local part1 = string.sub(data, 1, host_pos.pos_start - 1)  -- до "Host:"
			local part2_fake = "Host: " .. fake_host
			local part3_real = real_host
			local part4 = string.sub(data, host_pos.pos_end + 1)  -- после host value
			
			local pos_host_start = host_pos.pos_start - 1  -- 0-based
			local pos_host_value = host_pos.pos_value_start - 1
			local pos_after_host = host_pos.pos_end  -- 0-based (после последнего символа host)
			
			-- DISORDER: отправляем в обратном порядке
			-- 4 -> 3 -> 2 -> 1
			
			if b_debug then DLOG("http_mgts_combo: [4] after_host len="..#part4) end
			if not rawsend_payload_segmented(desync, part4, pos_after_host, opts) then
				return VERDICT_PASS
			end
			
			-- Реальный host (будет принят сервером)
			if b_debug then DLOG("http_mgts_combo: [3] REAL '"..part3_real.."'") end
			if not rawsend_payload_segmented(desync, part3_real, pos_host_value, opts) then
				return VERDICT_PASS
			end
			
			-- Фейковый "Host: fake" с seqovl (DPI увидит)
			if b_debug then DLOG("http_mgts_combo: [2] FAKE '"..part2_fake.."' (seqovl)") end
			if not rawsend_payload_segmented(desync, part2_fake, pos_host_start, opts) then
				return VERDICT_PASS
			end
			
			-- Начало запроса
			if b_debug then DLOG("http_mgts_combo: [1] before_host len="..#part1) end
			if not rawsend_payload_segmented(desync, part1, 0, opts) then
				return VERDICT_PASS
			end
			
			replay_drop_set(desync)
			return VERDICT_DROP
		end
		
		if replay_drop(desync) then
			return VERDICT_DROP
		end
	end
end

-- Combined: Fake + gentle disorder
-- Best of both: fakes confuse DPI, gentle disorder doesn't break server
-- standard args : direction, payload, fooling, ip_id, rawsend, reconstruct
-- arg : fakes=N - number of fakes (default 3)
-- arg : ttl=N - TTL for fakes (default 2)
function tls_fake_disorder_gentle(ctx, desync)
	if not desync.dis.tcp then
		instance_cutoff(ctx)
		return
	end
	direction_cutoff_opposite(ctx, desync)
	
	local data = desync.reasm_data or desync.dis.payload
	if #data>0 and desync.l7payload=="tls_client_hello" and direction_check(desync) then
		if replay_first(desync) then
			local num_fakes = tonumber(desync.arg.fakes) or 3
			local ttl = tonumber(desync.arg.ttl) or 2
			
			local fake_blob = desync.arg.blob and blob(desync, desync.arg.blob) or blob(desync, "fake_default_tls")
			local fake_data = tls_mod(fake_blob, "rnd,dupsid,sni=www.google.com", desync.reasm_data)
			
			local opts_fake = {rawsend = rawsend_opts(desync), reconstruct = reconstruct_opts(desync)}
			local opts_orig = {
				rawsend = rawsend_opts_base(desync), 
				reconstruct = {}, 
				ipfrag = {}, 
				ipid = desync.arg, 
				fooling = {tcp_ts_up = desync.arg.tcp_ts_up}
			}
			
			-- Send fakes
			for i=1,num_fakes do
				local fake_dis = deepcopy(desync.dis)
				fake_dis.payload = fake_data
				if fake_dis.ip then fake_dis.ip.ip_ttl = ttl end
				if fake_dis.ip6 then fake_dis.ip6.ip6_hlim = ttl end
				if b_debug then DLOG("tls_fake_disorder_gentle: sending fake #"..i) end
				rawsend_dissect(fake_dis, opts_fake.rawsend)
			end
			
			-- Gentle disorder: split at host and endhost only
			local pos1 = resolve_pos(data, desync.l7payload, "host")
			local pos2 = resolve_pos(data, desync.l7payload, "endhost")
			
			if pos1 and pos2 and pos1 > 1 and pos2 > pos1 and pos2 <= #data then
				local part1 = string.sub(data, 1, pos1-1)
				local part2 = string.sub(data, pos1, pos2-1)
				local part3 = string.sub(data, pos2)
				
				-- Disorder: 3, 2, 1
				if not rawsend_payload_segmented(desync, part3, pos2-1, opts_orig) then return VERDICT_PASS end
				if not rawsend_payload_segmented(desync, part2, pos1-1, opts_orig) then return VERDICT_PASS end
				if not rawsend_payload_segmented(desync, part1, 0, opts_orig) then return VERDICT_PASS end
			else
				-- Fallback: just split at position 2
				local part1 = string.sub(data, 1, 1)
				local part2 = string.sub(data, 2)
				if not rawsend_payload_segmented(desync, part2, 1, opts_orig) then return VERDICT_PASS end
				if not rawsend_payload_segmented(desync, part1, 0, opts_orig) then return VERDICT_PASS end
			end
			
			replay_drop_set(desync)
			return VERDICT_DROP
		else
			DLOG("tls_fake_disorder_gentle: not acting on further replay pieces")
		end
		
		if replay_drop(desync) then
			return VERDICT_DROP
		end
	end
end

--[[
    multisplit_tls - multisplit с динамической генерацией TLS паттерна
    
    Вместо статичного файла seqovl_pattern генерирует fake TLS на лету
    с помощью tls_mod, подставляя нужный SNI (например www.google.com)
    
    ВАЖНО: Если payload не является валидным TLS, функция НЕ применяет
    tls_mod и использует fallback-паттерн или пропускает пакет без изменений.
    
    Аргументы:
        pos         - позиции разреза (как в обычном multisplit): "2", "1,midsld", etc.
        seqovl      - размер overlap в байтах (рекомендуется 650-700)
        sni         - SNI для fake TLS (по умолчанию "www.google.com")
        tls_rnd     - если указан, рандомизировать random/session_id в fake TLS
        tls_dupsid  - если указан, скопировать session_id из реального пакета
        nodrop      - не дропать оригинальный пакет
        fallback    - что делать если payload не TLS: "pass" (пропустить), "split" (резать без seqovl), "pattern" (использовать raw pattern)
        
    Пример использования:
        --lua-desync=multisplit_tls:seqovl=680:sni=www.google.com:tls_rnd:tls_dupsid:pos=2

┌─────────────────────────────────────────────────────────────────┐
│                    КАК РАБОТАЕТ SEQOVL                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Обычный пакет:    [TLS ClientHello с реальным SNI]            │
│                     seq=1000, len=500                           │
│                                                                 │
│  С seqovl=650:     [FAKE TLS (650 байт)][Реальный TLS]        │
│                     seq=350, len=1150                           │
│                                                                 │
│  ТСПУ видит:       SNI из FAKE TLS (www.google.com)            │
│  Сервер получает:  Реальный TLS (ТСПУ не может заблокировать) │
│                                                                 │
│  Почему? TCP overlap - сервер берёт данные с большим seq       │
└─────────────────────────────────────────────────────────────────┘
--]]

-- Вспомогательная функция: проверяет, является ли payload валидным TLS Client Hello
local function is_valid_tls_client_hello(data)
    if not data or #data < 6 then
        return false
    end
    
    -- TLS Record Header: ContentType (1 byte) + Version (2 bytes) + Length (2 bytes)
    -- ContentType = 0x16 (Handshake)
    -- Version = 0x0301 (TLS 1.0), 0x0302 (TLS 1.1), 0x0303 (TLS 1.2), 0x0304 (TLS 1.3)
    local content_type = string.byte(data, 1)
    local version_major = string.byte(data, 2)
    local version_minor = string.byte(data, 3)
    
    -- Проверяем что это Handshake record
    if content_type ~= 0x16 then
        return false
    end
    
    -- Проверяем версию TLS (0x03 0x01-0x04)
    if version_major ~= 0x03 then
        return false
    end
    
    if version_minor < 0x01 or version_minor > 0x04 then
        return false
    end
    
    -- Проверяем Handshake Type (должен быть 0x01 = Client Hello)
    -- Handshake header начинается с позиции 6 (после TLS record header)
    if #data >= 6 then
        local handshake_type = string.byte(data, 6)
        if handshake_type ~= 0x01 then
            return false
        end
    end
    
    return true
end

function multisplit_tls(ctx, desync)
    -- Только для TCP
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    
    direction_cutoff_opposite(ctx, desync)
    
    -- Получаем данные для обработки (reassembled TLS или текущий payload)
    local data = desync.reasm_data or desync.dis.payload
    
    -- ============================================
    -- ЗАЩИТА: Пропускаем MTProto и Telegram
    -- seqovl ломает соединения с Telegram!
    -- ============================================
    
    -- 1. Пропускаем MTProto (это НЕ TLS, seqovl его ломает)
    if desync.l7payload == "mtproto_initial" or desync.l7payload == "mtproto" then
        if b_debug then
            DLOG("multisplit_tls: SKIP MTProto traffic - not compatible with seqovl")
        end
        return  -- Выходим без вердикта, пакет пройдёт как есть
    end
    
    -- 2. Пропускаем домены Telegram (seqovl с ними не работает)
    if desync.hostname then
        local telegram_domains = {
            "telegram.org",
            "t.me", 
            "telegram.me",
            "tdesktop.com",
            "telegra.ph"
        }
        for _, domain in ipairs(telegram_domains) do
            if string.find(desync.hostname, domain, 1, true) then
                if b_debug then
                    DLOG("multisplit_tls: SKIP Telegram domain: " .. desync.hostname)
                end
                return  -- Выходим без вердикта
            end
        end
    end
    
    -- Проверяем условия: есть данные, правильное направление, нужный payload
    if #data > 0 and direction_check(desync) and payload_check(desync) then
        if replay_first(desync) then
            -- Позиции для разреза (по умолчанию "2" = после 1-го байта)
            local spos = desync.arg.pos or "2"
            
            if b_debug then 
                DLOG("multisplit_tls: split pos: " .. spos) 
            end
            
            -- Вычисляем реальные позиции разреза
            local pos = resolve_multi_pos(data, desync.l7payload, spos)
            
            if b_debug then 
                DLOG("multisplit_tls: resolved: " .. table.concat(zero_based_pos(pos), " ")) 
            end
            
            -- Нельзя резать на позиции 1
            delete_pos_1(pos)
            
            if #pos > 0 then
                -- ============================================
                -- КЛЮЧЕВАЯ ПРОВЕРКА: является ли payload TLS?
                -- ============================================
                local payload_is_tls = is_valid_tls_client_hello(data)
                local reasm_is_tls = desync.reasm_data and is_valid_tls_client_hello(desync.reasm_data)
                local can_apply_tls_mod = payload_is_tls or reasm_is_tls
                
                -- Также проверяем l7payload от движка
                if desync.l7payload == "tls_client_hello" then
                    can_apply_tls_mod = true
                end
                
                if b_debug then
                    DLOG("multisplit_tls: payload_is_tls=" .. tostring(payload_is_tls) .. 
                         " reasm_is_tls=" .. tostring(reasm_is_tls) ..
                         " l7payload=" .. tostring(desync.l7payload) ..
                         " can_apply_tls_mod=" .. tostring(can_apply_tls_mod))
                end
                
                -- Отправляем части пакета
                for i = 0, #pos do
                    local pos_start = pos[i] or 1
                    local pos_end = i < #pos and pos[i + 1] - 1 or #data
                    local part = string.sub(data, pos_start, pos_end)
                    local seqovl = 0
                    
                    -- SEQOVL применяется только к ПЕРВОЙ части (i == 0)
                    if i == 0 and desync.arg.seqovl and tonumber(desync.arg.seqovl) > 0 then
                        seqovl = tonumber(desync.arg.seqovl)
                        
                        -- ============================================
                        -- БЕЗОПАСНАЯ ГЕНЕРАЦИЯ ПАТТЕРНА
                        -- ============================================
                        local pat = nil
                        
                        if can_apply_tls_mod then
                            -- Payload IS TLS - можем применять tls_mod
                            
                            -- Берём базовый fake TLS (встроенный, ~680 байт)
                            local base_tls = blob(desync, "fake_default_tls")
                            
                            -- Собираем список модификаций
                            local mods = {}
                            
                            -- SNI (по умолчанию www.google.com)
                            local sni = desync.arg.sni or "www.google.com"
                            table.insert(mods, "sni=" .. sni)
                            
                            -- Рандомизация random bytes и session id
                            if desync.arg.tls_rnd then
                                table.insert(mods, "rnd")
                            end
                            
                            -- Копирование session id из реального пакета
                            -- ТОЛЬКО если reasm_data валидный TLS
                            if desync.arg.tls_dupsid and reasm_is_tls then
                                table.insert(mods, "dupsid")
                            elseif desync.arg.tls_dupsid and not reasm_is_tls then
                                -- dupsid запрошен но reasm_data не TLS - пропускаем dupsid
                                if b_debug then
                                    DLOG("multisplit_tls: skipping dupsid - reasm_data is not valid TLS")
                                end
                            end
                            
                            local modlist = table.concat(mods, ",")
                            
                            if b_debug then
                                DLOG("multisplit_tls: applying tls_mod: " .. modlist)
                            end
                            
                            -- Применяем модификации к fake TLS
                            -- Третий параметр нужен для dupsid - передаём только если это TLS
                            local reasm_for_mod = reasm_is_tls and desync.reasm_data or nil
                            local fake_tls = tls_mod(base_tls, modlist, reasm_for_mod)
                            
                            if fake_tls and #fake_tls > 0 then
                                -- Создаём паттерн нужной длины (seqovl байт)
                                pat = pattern(fake_tls, 1, seqovl)
                                
                                if b_debug then
                                    DLOG("multisplit_tls: seqovl=" .. seqovl .. 
                                         " fake_tls_len=" .. #fake_tls .. 
                                         " sni=" .. sni)
                                end
                            else
                                -- tls_mod вернул nil или пустую строку - используем fallback
                                if b_debug then
                                    DLOG("multisplit_tls: tls_mod returned empty, using raw blob")
                                end
                                pat = pattern(base_tls, 1, seqovl)
                            end
                        else
                            -- ============================================
                            -- PAYLOAD НЕ TLS - FALLBACK РЕЖИМ
                            -- ============================================
                            local fallback_mode = desync.arg.fallback or "pass"
                            
                            if b_debug then
                                DLOG("multisplit_tls: payload is NOT valid TLS, fallback=" .. fallback_mode)
                            end
                            
                            if fallback_mode == "pass" then
                                -- Пропускаем пакет без изменений
                                DLOG("multisplit_tls: fallback=pass, letting packet through unchanged")
                                return VERDICT_PASS
                                
                            elseif fallback_mode == "split" then
                                -- Делаем split но без seqovl
                                DLOG("multisplit_tls: fallback=split, splitting without seqovl")
                                seqovl = 0
                                -- pat остаётся nil, seqovl = 0 - просто разрежем без overlap
                                
                            else  -- "pattern" или любое другое значение
                                -- Используем raw blob без tls_mod модификаций
                                -- Это безопасно - просто добавляем байты перед пакетом
                                local raw_blob = blob(desync, "fake_default_tls")
                                if raw_blob and #raw_blob > 0 then
                                    pat = pattern(raw_blob, 1, seqovl)
                                    DLOG("multisplit_tls: fallback=pattern, using raw blob without tls_mod")
                                else
                                    -- Даже blob не доступен - делаем split без seqovl
                                    DLOG("multisplit_tls: no blob available, splitting without seqovl")
                                    seqovl = 0
                                end
                            end
                        end
                        
                        -- Добавляем паттерн ПЕРЕД реальными данными (если есть)
                        if pat and #pat > 0 then
                            part = pat .. part
                        else
                            -- Нет паттерна - обнуляем seqovl
                            seqovl = 0
                        end
                    end
                    
                    if b_debug then 
                        DLOG("multisplit_tls: sending part " .. (i + 1) .. 
                             " pos=" .. (pos_start - 1) .. "-" .. (pos_end - 1) .. 
                             " len=" .. #part .. " seqovl=" .. seqovl)
                    end
                    
                    -- Отправляем сегмент с уменьшенным seq (для overlap)
                    if not rawsend_payload_segmented(desync, part, pos_start - 1 - seqovl) then
                        return VERDICT_PASS
                    end
                end
                
                replay_drop_set(desync)
                return desync.arg.nodrop and VERDICT_PASS or VERDICT_DROP
            else
                DLOG("multisplit_tls: no valid split positions")
            end
        else
            DLOG("multisplit_tls: not acting on further replay pieces")
        end
        
        -- Дропаем replayed пакеты если успешно отправили split
        if replay_drop(desync) then
            return desync.arg.nodrop and VERDICT_PASS or VERDICT_DROP
        end
    end
end

-- ============================================================================
-- NEW HTTP BYPASS STRATEGIES - Для обхода умного DPI (MTS/MGTS)
-- ============================================================================

-- HTTP Garbage Prefix - Много мусора перед запросом
-- DPI часто парсит только начало пакета, мусор может сбить парсер
-- standard args : direction, payload
-- arg : mode=<str> - "crlf", "spaces", "tabs", "mixed", "nulls" (default mixed)
-- arg : amount=N - количество мусора в байтах (default 50)
function http_garbage_prefix(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        local mode = desync.arg.mode or "mixed"
        local amount = tonumber(desync.arg.amount) or 50
        local garbage = ""
        
        if mode == "crlf" then
            -- Много \r\n подряд
            garbage = string.rep("\r\n", math.floor(amount / 2))
        elseif mode == "spaces" then
            -- Пробелы с \r\n
            garbage = string.rep(" \r\n", math.floor(amount / 3))
        elseif mode == "tabs" then
            -- Табы с \r\n  
            garbage = string.rep("\t\r\n", math.floor(amount / 3))
        elseif mode == "mixed" then
            -- Смешанный мусор: пробелы, табы, \r\n
            for i = 1, math.floor(amount / 4) do
                local r = i % 4
                if r == 0 then garbage = garbage .. "\r\n"
                elseif r == 1 then garbage = garbage .. " \r\n"
                elseif r == 2 then garbage = garbage .. "\t\r\n"
                else garbage = garbage .. "  \r\n"
                end
            end
        elseif mode == "headers" then
            -- Фейковые заголовки в начале (невалидные)
            garbage = "X-Fake: garbage\r\n" .. 
                      "X-Ignore: me\r\n" ..
                      string.rep("\r\n", 5)
        end
        
        desync.dis.payload = garbage .. desync.dis.payload
        DLOG("http_garbage_prefix: added "..#garbage.." bytes of '"..mode.."' garbage")
        return VERDICT_MODIFY
    end
end

-- HTTP Pipeline Fake - Отправить два запроса, первый фейковый
-- DPI может кэшировать домен из первого запроса
-- standard args : direction, payload, rawsend
-- arg : fake_host=<str> - хост для фейкового запроса (default www.google.com)
function http_pipeline_fake(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff(ctx)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    local data = desync.reasm_data or desync.dis.payload
    if #data>0 and desync.l7payload=="http_req" and direction_check(desync) then
        if replay_first(desync) then
            local fake_host = desync.arg.fake_host or "www.google.com"
            
            -- Создаём фейковый HTTP запрос (очень короткий)
            local fake_request = "GET / HTTP/1.1\r\n" ..
                                "Host: " .. fake_host .. "\r\n" ..
                                "Connection: keep-alive\r\n" ..
                                "\r\n"
            
            local opts = {
                rawsend = rawsend_opts_base(desync), 
                reconstruct = {}, 
                ipfrag = {}, 
                fooling = {}
            }
            
            -- Отправляем ФЕЙКОВЫЙ запрос сначала
            if b_debug then DLOG("http_pipeline_fake: sending FAKE request to "..fake_host) end
            if not rawsend_payload_segmented(desync, fake_request, 0, opts) then
                return VERDICT_PASS
            end
            
            -- Потом РЕАЛЬНЫЙ запрос с offset = длина фейкового
            if b_debug then DLOG("http_pipeline_fake: sending REAL request") end
            if not rawsend_payload_segmented(desync, data, #fake_request, opts) then
                return VERDICT_PASS
            end
            
            replay_drop_set(desync)
            return VERDICT_DROP
        end
        
        if replay_drop(desync) then
            return VERDICT_DROP
        end
    end
end

-- HTTP Header Shuffle - Перемешать заголовки и добавить фейковые Host
-- Добавляет фейковый Host ДО реального, надеясь что DPI возьмёт первый
-- standard args : direction, payload
-- arg : fake_host=<str>
-- arg : add_x_host - также добавить X-Host с реальным хостом
function http_header_shuffle(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        local hdis = http_dissect_req(desync.dis.payload)
        if not hdis or not hdis.headers.host then
            DLOG("http_header_shuffle: no Host header")
            return
        end
        
        local host_pos = hdis.headers.host
        local real_host = string.sub(desync.dis.payload, host_pos.pos_value_start, host_pos.pos_end)
        local fake_host = desync.arg.fake_host or "www.google.com"
        
        -- Находим конец первой строки (после GET / HTTP/1.1)
        local first_line_end = string.find(desync.dis.payload, "\r\n", 1, true)
        if not first_line_end then
            DLOG("http_header_shuffle: cannot find end of first line")
            return
        end
        
        -- Собираем новый запрос:
        -- 1. Первая строка (GET / HTTP/1.1)
        -- 2. FAKE Host header
        -- 3. Остальные заголовки (включая реальный Host)
        local new_payload = string.sub(desync.dis.payload, 1, first_line_end + 1) ..  -- включая \r\n
                           "Host: " .. fake_host .. "\r\n" ..  -- Фейковый Host ПЕРВЫМ
                           string.sub(desync.dis.payload, first_line_end + 2)  -- остаток
        
        -- Опционально добавить X-Host с реальным хостом
        if desync.arg.add_x_host then
            -- Вставляем перед реальным Host
            local real_host_pos = string.find(new_payload, "\r\nHost: "..real_host, 1, true)
            if real_host_pos then
                new_payload = string.sub(new_payload, 1, real_host_pos + 1) ..
                             "X-Real-Host: " .. real_host .. "\r\n" ..
                             string.sub(new_payload, real_host_pos + 2)
            end
        end
        
        desync.dis.payload = new_payload
        DLOG("http_header_shuffle: added fake Host '"..fake_host.."' before real '"..real_host.."'")
        return VERDICT_MODIFY
    end
end

-- HTTP Method Obfuscation - Обфускация HTTP метода
-- Некоторые DPI парсят только GET/POST, другие методы могут не блокироваться
-- standard args : direction, payload
-- arg : method=<str> - "lowercase", "padding", "fake" (default lowercase)
function http_method_obfuscate(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        local mode = desync.arg.method or "lowercase"
        local payload = desync.dis.payload
        
        if mode == "lowercase" then
            -- GET -> get (некоторые серверы принимают)
            payload = string.gsub(payload, "^GET ", "get ")
            payload = string.gsub(payload, "^POST ", "post ")
            payload = string.gsub(payload, "^HEAD ", "head ")
        elseif mode == "padding" then
            -- GET -> GET  (доп пробелы)
            payload = string.gsub(payload, "^GET ", "GET  ")
            payload = string.gsub(payload, "^POST ", "POST  ")
        elseif mode == "fake" then
            -- Добавить фейковый метод перед реальным
            payload = "X " .. payload
        elseif mode == "case" then
            -- GET -> GeT
            payload = string.gsub(payload, "^GET ", "GeT ")
            payload = string.gsub(payload, "^POST ", "PoSt ")
        end
        
        desync.dis.payload = payload
        DLOG("http_method_obfuscate: applied mode '"..mode.."'")
        return VERDICT_MODIFY
    end
end

-- HTTP Absolute URI - Использовать абсолютный URI в запросе
-- GET http://real-host.com/ HTTP/1.1 вместо GET / HTTP/1.1
-- Host header ставим фейковый
-- standard args : direction, payload
-- arg : fake_host=<str>
function http_absolute_uri_v2(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        local hdis = http_dissect_req(desync.dis.payload)
        if not hdis or not hdis.headers.host then
            DLOG("http_absolute_uri_v2: cannot parse")
            return
        end
        
        local host_pos = hdis.headers.host
        local real_host = string.sub(desync.dis.payload, host_pos.pos_value_start, host_pos.pos_end)
        local fake_host = desync.arg.fake_host or "www.google.com"
        
        -- Ищем начало пути (после GET )
        local method_end = string.find(desync.dis.payload, " ", 1, true)
        local path_end = string.find(desync.dis.payload, " HTTP/", 1, true)
        
        if method_end and path_end and path_end > method_end then
            local method = string.sub(desync.dis.payload, 1, method_end - 1)
            local path = string.sub(desync.dis.payload, method_end + 1, path_end - 1)
            
            -- Создаём абсолютный URI
            local abs_uri = "http://" .. real_host .. path
            
            -- Новый запрос с абсолютным URI и фейковым Host
            local new_payload = method .. " " .. abs_uri .. 
                               string.sub(desync.dis.payload, path_end)
            
            -- Заменяем Host на фейковый
            new_payload = string.gsub(new_payload, 
                                     "\r\nHost: " .. real_host, 
                                     "\r\nHost: " .. fake_host)
            
            desync.dis.payload = new_payload
            DLOG("http_absolute_uri_v2: uri="..abs_uri.." fake_host="..fake_host)
            return VERDICT_MODIFY
        end
    end
end

-- HTTP Split At Host Byte - Побайтовый split внутри Host value
-- Разрезает Host value на отдельные байты и отправляет с задержкой
-- standard args : direction, payload, rawsend
-- arg : max_parts=N - максимум частей для Host (default 5)
function http_host_bytesplit(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff(ctx)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    local data = desync.reasm_data or desync.dis.payload
    if #data>0 and desync.l7payload=="http_req" and direction_check(desync) then
        if replay_first(desync) then
            local hdis = http_dissect_req(data)
            if not hdis or not hdis.headers.host then
                DLOG("http_host_bytesplit: no Host header")
                return
            end
            
            local host_pos = hdis.headers.host
            local max_parts = tonumber(desync.arg.max_parts) or 5
            
            local opts = {
                rawsend = rawsend_opts_base(desync), 
                reconstruct = {}, 
                ipfrag = {}, 
                fooling = {}
            }
            
            -- Часть 1: До Host value
            local before = string.sub(data, 1, host_pos.pos_value_start - 1)
            if b_debug then DLOG("http_host_bytesplit: [1] before len="..#before) end
            if not rawsend_payload_segmented(desync, before, 0, opts) then
                return VERDICT_PASS
            end
            
            -- Части 2..N: Host value побайтово
            local host_value = string.sub(data, host_pos.pos_value_start, host_pos.pos_end)
            local chunk_size = math.max(1, math.floor(#host_value / max_parts))
            local pos = 0
            local part_num = 2
            
            while pos < #host_value do
                local chunk_end = math.min(pos + chunk_size, #host_value)
                local chunk = string.sub(host_value, pos + 1, chunk_end)
                local offset = host_pos.pos_value_start - 1 + pos
                
                if b_debug then DLOG("http_host_bytesplit: ["..part_num.."] chunk='"..chunk.."'") end
                if not rawsend_payload_segmented(desync, chunk, offset, opts) then
                    return VERDICT_PASS
                end
                
                pos = chunk_end
                part_num = part_num + 1
            end
            
            -- Последняя часть: После Host value
            local after = string.sub(data, host_pos.pos_end + 1)
            if b_debug then DLOG("http_host_bytesplit: ["..part_num.."] after len="..#after) end
            if not rawsend_payload_segmented(desync, after, host_pos.pos_end, opts) then
                return VERDICT_PASS
            end
            
            replay_drop_set(desync)
            return VERDICT_DROP
        end
        
        if replay_drop(desync) then
            return VERDICT_DROP
        end
    end
end

-- HTTP Fake Continuation - Отправить фейковый "продолжение" соединения
-- DPI может не парсить keep-alive запросы
-- standard args : direction, payload, rawsend
-- arg : fake_host=<str>
function http_fake_continuation(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff(ctx)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    local data = desync.reasm_data or desync.dis.payload
    if #data>0 and desync.l7payload=="http_req" and direction_check(desync) then
        if replay_first(desync) then
            local fake_host = desync.arg.fake_host or "www.google.com"
            
            local opts = {
                rawsend = rawsend_opts_base(desync), 
                reconstruct = {}, 
                ipfrag = {}, 
                fooling = {}
            }
            
            -- Отправляем "фейковый ответ" (DPI может подумать что это продолжение)
            local fake_response = "HTTP/1.1 200 OK\r\n" ..
                                 "Content-Length: 0\r\n" ..
                                 "Connection: keep-alive\r\n" ..
                                 "\r\n"
            
            -- Сначала "ответ"
            if b_debug then DLOG("http_fake_continuation: sending fake response") end
            if not rawsend_payload_segmented(desync, fake_response, 0, opts) then
                return VERDICT_PASS
            end
            
            -- Потом реальный запрос
            if b_debug then DLOG("http_fake_continuation: sending real request") end
            if not rawsend_payload_segmented(desync, data, #fake_response, opts) then
                return VERDICT_PASS
            end
            
            replay_drop_set(desync)
            return VERDICT_DROP
        end
        
        if replay_drop(desync) then
            return VERDICT_DROP
        end
    end
end

-- HTTP Version Downgrade - Понизить версию HTTP
-- Некоторые DPI не парсят HTTP/1.0
-- standard args : direction, payload
-- arg : version=<str> - "1.0" или "0.9" (default 1.0)
function http_version_downgrade(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        local version = desync.arg.version or "1.0"
        local payload = desync.dis.payload
        
        if version == "1.0" then
            payload = string.gsub(payload, "HTTP/1.1", "HTTP/1.0")
            -- Убираем Host header для HTTP/1.0 (опционально)
            -- payload = string.gsub(payload, "\r\nHost: [^\r\n]+", "")
        elseif version == "0.9" then
            -- HTTP/0.9: только "GET /path" без версии и заголовков
            local path_start = string.find(payload, " ", 1, true)
            local path_end = string.find(payload, " HTTP/", 1, true)
            if path_start and path_end then
                local method = string.sub(payload, 1, path_start - 1)
                local path = string.sub(payload, path_start + 1, path_end - 1)
                payload = method .. " " .. path .. "\r\n"
            end
        end
        
        desync.dis.payload = payload
        DLOG("http_version_downgrade: changed to HTTP/"..version)
        return VERDICT_MODIFY
    end
end

-- HTTP Pipeline Fake v2 - Фейковый запрос умирает, реальный доходит
-- Фейковый запрос отправляется с badsum/низким TTL - сервер его отбросит
-- DPI видит фейковый хост, сервер получает только реальный запрос
-- standard args : direction, payload, rawsend, fooling
-- arg : fake_host=<str> - хост для фейкового запроса (default www.google.com)
-- arg : ttl=N - TTL для фейкового пакета (default 1)
-- arg : badsum - использовать неверную checksum для fake (рекомендуется)
function http_pipeline_fake_v2(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff(ctx)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    local data = desync.reasm_data or desync.dis.payload
    if #data>0 and desync.l7payload=="http_req" and direction_check(desync) then
        if replay_first(desync) then
            local fake_host = desync.arg.fake_host or "www.google.com"
            local fake_ttl = tonumber(desync.arg.ttl) or 1
            
            -- Создаём фейковый HTTP запрос
            local fake_request = "GET / HTTP/1.1\r\n" ..
                                "Host: " .. fake_host .. "\r\n" ..
                                "Connection: keep-alive\r\n" ..
                                "\r\n"
            
            -- Опции для ФЕЙКОВОГО пакета (badsum/низкий TTL - не дойдёт до сервера)
            local opts_fake = {
                rawsend = rawsend_opts(desync),
                reconstruct = reconstruct_opts(desync),
                ipfrag = {},
                fooling = {
                    badsum = desync.arg.badsum or true,  -- неверная checksum
                }
            }
            
            -- Опции для РЕАЛЬНОГО пакета (нормальные)
            local opts_real = {
                rawsend = rawsend_opts_base(desync), 
                reconstruct = {}, 
                ipfrag = {}, 
                fooling = {}
            }
            
            -- Отправляем ФЕЙКОВЫЙ запрос (с badsum - сервер отбросит, DPI увидит)
            local fake_dis = deepcopy(desync.dis)
            fake_dis.payload = fake_request
            
            -- Устанавливаем низкий TTL
            if fake_dis.ip then
                fake_dis.ip.ip_ttl = fake_ttl
            end
            if fake_dis.ip6 then
                fake_dis.ip6.ip6_hlim = fake_ttl
            end
            
            if b_debug then DLOG("http_pipeline_fake_v2: sending FAKE (TTL="..fake_ttl..", badsum) to "..fake_host) end
            rawsend_dissect(fake_dis, opts_fake.rawsend)
            
            -- Отправляем РЕАЛЬНЫЙ запрос (нормальный, дойдёт до сервера)
            if b_debug then DLOG("http_pipeline_fake_v2: sending REAL request") end
            if not rawsend_payload_segmented(desync, data, 0, opts_real) then
                return VERDICT_PASS
            end
            
            replay_drop_set(desync)
            return VERDICT_DROP
        end
        
        if replay_drop(desync) then
            return VERDICT_DROP
        end
    end
end

-- HTTP Fake Header Inject - Добавляет фейковый X-Host заголовок
-- Сервер игнорирует X-Host, но DPI может его прочитать
-- standard args : direction, payload
-- arg : fake_host=<str>
function http_fake_xhost(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        local fake_host = desync.arg.fake_host or "www.google.com"
        local payload = desync.dis.payload
        
        -- Находим конец первой строки
        local first_line_end = string.find(payload, "\r\n", 1, true)
        if first_line_end then
            -- Вставляем X-Host ПЕРЕД настоящим Host (DPI может взять первый "Host"-подобный)
            -- Некоторые DPI ищут просто "Host:" без проверки что это заголовок
            local fake_header = "X-Host: " .. fake_host .. "\r\n" ..
                               "X-Forwarded-Host: " .. fake_host .. "\r\n"
            
            payload = string.sub(payload, 1, first_line_end + 1) ..
                     fake_header ..
                     string.sub(payload, first_line_end + 2)
            
            desync.dis.payload = payload
            DLOG("http_fake_xhost: added fake X-Host: "..fake_host)
            return VERDICT_MODIFY
        end
    end
end

-- HTTP with OOB byte - Добавляет TCP OOB байт перед запросом
-- Некоторые DPI не обрабатывают urgent data правильно
-- standard args : direction, payload
function http_oob_prefix(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        -- Добавляем мусорный байт в начало - сервера часто игнорируют лишние байты
        -- перед GET/POST
        desync.dis.payload = "\n" .. desync.dis.payload
        DLOG("http_oob_prefix: added \\n prefix")
        return VERDICT_MODIFY
    end
end

-- Безопасный methodeol - только добавляет \r\n в начало, ничего не обрезает
-- Некоторые серверы принимают \r\n перед GET
function http_methodeol_safe(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        -- Просто добавляем \r\n в начало (без обрезания User-Agent)
        desync.dis.payload = "\r\n" .. desync.dis.payload
        DLOG("http_methodeol_safe: added \\r\\n prefix only")
        return VERDICT_MODIFY
    end
end

-- Ещё безопаснее - добавить пустую строку внутри заголовков (не в начале)
-- Вставляет пустой X-заголовок который nginx игнорирует
function http_inject_safe_header(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        local payload = desync.dis.payload
        
        -- Находим позицию перед Host:
        local host_pos = string.find(payload, "\r\nHost:", 1, true)
        if host_pos then
            -- Вставляем безопасный заголовок перед Host
            payload = string.sub(payload, 1, host_pos + 1) ..
                     "X-Padding: " .. string.rep("x", 50) .. "\r\n" ..
                     string.sub(payload, host_pos + 2)
            desync.dis.payload = payload
            DLOG("http_inject_safe_header: added X-Padding header")
            return VERDICT_MODIFY
        end
    end
end

-- ============================================================================
-- SAFE METHODEOL VARIANTS - обходят DPI, не ломают сервер
-- ============================================================================

-- Вариант 1: Только \r\n в начало (без обрезания User-Agent)
-- Многие HTTP серверы игнорируют \r\n перед GET
function http_methodeol_safe(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        -- Только \r\n в начало, ничего не обрезаем
        desync.dis.payload = "\r\n" .. desync.dis.payload
        DLOG("http_methodeol_safe: added \\r\\n prefix")
        return VERDICT_MODIFY
    end
end

-- Вариант 2: Пробел перед GET (некоторые серверы принимают)
-- " GET / HTTP/1.1" вместо "GET / HTTP/1.1"
function http_space_prefix(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        desync.dis.payload = " " .. desync.dis.payload
        DLOG("http_space_prefix: added space prefix")
        return VERDICT_MODIFY
    end
end

-- Вариант 3: \n вместо \r\n (Unix-style line ending)
function http_lf_prefix(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        desync.dis.payload = "\n" .. desync.dis.payload
        DLOG("http_lf_prefix: added \\n prefix")
        return VERDICT_MODIFY
    end
end

-- Вариант 4: Таб перед GET
function http_tab_prefix(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        desync.dis.payload = "\t" .. desync.dis.payload
        DLOG("http_tab_prefix: added tab prefix")
        return VERDICT_MODIFY
    end
end

-- Вариант 5: Добавить безопасный X-заголовок (100% совместимо)
-- X-Padding header игнорируется сервером но сбивает парсер DPI
function http_xpadding(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        local payload = desync.dis.payload
        
        -- Находим конец первой строки (GET / HTTP/1.1\r\n)
        local first_line_end = string.find(payload, "\r\n", 1, true)
        if first_line_end then
            -- Вставляем длинный X-заголовок сразу после первой строки
            local padding = string.rep("x", 100)  -- 100 символов мусора
            payload = string.sub(payload, 1, first_line_end + 1) ..
                     "X-Pad: " .. padding .. "\r\n" ..
                     string.sub(payload, first_line_end + 2)
            desync.dis.payload = payload
            DLOG("http_xpadding: added X-Pad header with 100 bytes")
            return VERDICT_MODIFY
        end
    end
end

-- Вариант 6: Несколько \r\n подряд (агрессивнее)
-- arg : count=N - количество \r\n (default 3)
function http_multi_crlf(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        local count = tonumber(desync.arg.count) or 3
        local prefix = string.rep("\r\n", count)
        desync.dis.payload = prefix .. desync.dis.payload
        DLOG("http_multi_crlf: added "..count.." x \\r\\n prefix")
        return VERDICT_MODIFY
    end
end

-- Вариант 7: Комбинация - \r\n + пробелы
function http_mixed_prefix(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        -- \r\n потом пробелы потом таб
        desync.dis.payload = "\r\n \t" .. desync.dis.payload
        DLOG("http_mixed_prefix: added mixed whitespace prefix")
        return VERDICT_MODIFY
    end
end

-- HTTP combo bypass v2 - исправлена ошибка с tcp_seq
function http_combo_bypass(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff(ctx)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    local data = desync.reasm_data or desync.dis.payload
    if #data>0 and desync.l7payload=="http_req" and direction_check(desync) then
        if replay_first(desync) then
            local fake_host = desync.arg.fake_host or "www.iana.org"
            local repeats = tonumber(desync.arg.repeats) or 15
            local prefix = desync.arg.prefix or "\r\n"
            local hostcase = desync.arg.hostcase or "HoSt"
            
            -- 1. ОТПРАВЛЯЕМ FAKE ПАКЕТЫ
            local fake_http = "GET / HTTP/1.1\r\nHost: " .. fake_host .. 
                             "\r\nUser-Agent: Mozilla/5.0\r\nAccept: */*\r\n" ..
                             "Connection: keep-alive\r\n\r\n"
            
            local opts_fake = {
                rawsend = rawsend_opts(desync),
                reconstruct = reconstruct_opts(desync),
                ipfrag = {},
                fooling = { badsum = true }
            }
            opts_fake.rawsend.repeats = repeats
            
            local fake_dis = deepcopy(desync.dis)
            fake_dis.payload = fake_http
            if fake_dis.ip then fake_dis.ip.ip_ttl = 2 end
            if fake_dis.ip6 then fake_dis.ip6.ip6_hlim = 2 end
            
            DLOG("http_combo_bypass: sending "..repeats.." fake packets")
            rawsend_dissect(fake_dis, opts_fake.rawsend)
            
            -- 2. МОДИФИЦИРУЕМ PAYLOAD
            local modified = data
            
            if prefix and #prefix > 0 then
                modified = prefix .. modified
            end
            
            if hostcase then
                modified = string.gsub(modified, "Host:", hostcase..":", 1)
            end
            
            -- 3. ОТПРАВЛЯЕМ КАК ЕДИНЫЙ ПАКЕТ (без split)
            local opts_real = {
                rawsend = rawsend_opts_base(desync),
                reconstruct = {},
                ipfrag = {},
                fooling = {}
            }
            
            local real_dis = deepcopy(desync.dis)
            real_dis.payload = modified
            
            DLOG("http_combo_bypass: sending modified request, len="..#modified)
            rawsend_dissect(real_dis, opts_real.rawsend)
            
            replay_drop_set(desync)
            return VERDICT_DROP
        end
        
        if replay_drop(desync) then
            return VERDICT_DROP
        end
    end
end

-- Упрощённая версия - только \r\n + hostcase, без split
-- Для серверов которые чувствительны к split
function http_simple_bypass(ctx, desync)
    if not desync.dis.tcp then
        instance_cutoff_shim(ctx, desync)
        return
    end
    direction_cutoff_opposite(ctx, desync)
    
    if desync.l7payload=="http_req" and direction_check(desync) then
        local prefix = desync.arg.prefix or "\r\n"
        local hostcase = desync.arg.hostcase or "HoSt"
        
        local payload = desync.dis.payload
        
        -- Добавляем \r\n в начало
        payload = prefix .. payload
        
        -- Меняем Host: на HoSt:
        payload = string.gsub(payload, "Host:", hostcase..":", 1)
        
        desync.dis.payload = payload
        DLOG("http_simple_bypass: prefix + hostcase applied")
        return VERDICT_MODIFY
    end
end