-- GoodbyeZapret experimental Discord-only desync functions.
-- These are intentionally not aliases for known-good strategies.

local function gz_copy_desync(desync, overrides)
	local d = deepcopy(desync)
	d.arg = deepcopy(desync.arg or {})
	for k, v in pairs(overrides or {}) do
		d.arg[k] = v
	end
	return d
end

local function gz_num(desync, name, default)
	local v = desync.arg and desync.arg[name]
	return tonumber(v) or default
end

local function gz_str(desync, name, default)
	local v = desync.arg and desync.arg[name]
	if v == nil or v == "" then return default end
	return v
end

local function gz_fake_once(ctx, desync, overrides)
	return fake(ctx, gz_copy_desync(desync, overrides))
end

local function gz_clamp(v, minv, maxv)
	if v < minv then return minv end
	if v > maxv then return maxv end
	return v
end

local function gz_host_chunks(host_len, parts)
	local chunks = {}
	local base = math.floor(host_len / parts)
	local rem = host_len % parts
	local start_pos = 1
	for i = 1, parts do
		local len = base + (i <= rem and 1 or 0)
		if len > 0 then
			chunks[#chunks + 1] = { first = start_pos, last = start_pos + len - 1 }
			start_pos = start_pos + len
		end
	end
	return chunks
end

local function gz_middleout_order(n)
	local order = {}
	local left = math.floor((n + 1) / 2)
	local right = left + 1
	while left >= 1 or right <= n do
		if left >= 1 then
			order[#order + 1] = left
			left = left - 1
		end
		if right <= n then
			order[#order + 1] = right
			right = right + 1
		end
	end
	return order
end

local function gz_shadow_braid_order(n)
	local order = {}
	local used = {}
	local center = math.floor((n + 1) / 2)
	local function push(i)
		if i >= 1 and i <= n and not used[i] then
			order[#order + 1] = i
			used[i] = true
		end
	end
	for r = 0, n do
		push(center - r)
		push(center + r)
		push(1 + r)
		push(n - r)
	end
	return order
end

local function gz_fake_opts(desync, default_ts)
	local fake_arg = deepcopy(desync.arg or {})
	if fake_arg.tcp_ts == nil and not fake_arg.tcp_ts_up and not fake_arg.tcp_md5 and not fake_arg.tcp_md5sig and
	   not fake_arg.badsum and not fake_arg.ip_ttl and not fake_arg.ip6_ttl and
	   not fake_arg.ip_autottl and not fake_arg.ip6_autottl then
		fake_arg.tcp_ts = default_ts
	end
	return {
		rawsend = {
			repeats = fake_arg.repeats,
			ifout = fake_arg.ifout or desync.ifout,
			fwmark = fake_arg.fwmark or desync.fwmark
		},
		reconstruct = {badsum = fake_arg.badsum},
		ipfrag = {},
		ipid = fake_arg,
		fooling = fake_arg
	}
end

local function gz_parse_hosts(s, defaults)
	local hosts = {}
	local src = (s and s ~= "") and s or defaults or ""
	for host in string.gmatch(src, "([^,]+)") do
		if host and host ~= "" then hosts[#hosts + 1] = host end
	end
	return hosts
end

local function gz_edgein_order(n)
	local order = {}
	for i = 1, math.ceil(n / 2) do
		order[#order + 1] = i
		local j = n - i + 1
		if j ~= i then order[#order + 1] = j end
	end
	return order
end

local function gz_chunk_order(n, mode)
	if mode == "middleout" then
		return gz_middleout_order(n)
	elseif mode == "edgein" then
		return gz_edgein_order(n)
	elseif mode == "reverse" then
		local order = {}
		for i = n, 1, -1 do order[#order + 1] = i end
		return order
	elseif mode == "normal" then
		local order = {}
		for i = 1, n do order[#order + 1] = i end
		return order
	end
	return gz_shadow_braid_order(n)
end

-- Experimental: Discord media cascade.
-- Discord media/CDN traffic is mostly sensitive to early host/SNI inspection.
-- This sends the real suffix early, poisons the host range with several
-- media-like fake hosts, then rebuilds the real host edge-in.
--
-- standard args: direction, payload, fooling, ip_id, rawsend, reconstruct
-- arg: hosts=<list>       fake host templates, comma separated
-- arg: parts=N            host chunk count, default 4
-- arg: halo=N             bytes before/after host included in fake halo, default 1
-- arg: fake_passes=N      fake chunk passes, default 2
-- arg: fake_tcp_ts=N      default fake-only tcp_ts when no fooling is set
-- arg: range=<range>      protected range, default host,endhost-1
-- arg: nodrop
function gz_dm_media_cascade(ctx, desync)
	if not desync.dis.tcp then
		if not desync.dis.icmp then instance_cutoff_shim(ctx, desync) end
		return
	end
	direction_cutoff_opposite(ctx, desync)
	if desync.arg.optional and desync.arg.blob and not blob_exist(desync, desync.arg.blob) then
		DLOG("gz_dm_media_cascade: blob '"..desync.arg.blob.."' not found. skipped")
		return
	end
	local data = blob_or_def(desync, desync.arg.blob) or desync.reasm_data or desync.dis.payload
	if #data > 0 and direction_check(desync) and payload_check(desync) then
		if replay_first(desync) then
			local pos = resolve_range(data, desync.l7payload, gz_str(desync, "range", "host,endhost-1"), true)
			if pos then
				local host_len = pos[2] - pos[1] + 1
				if host_len <= 0 then
					DLOG("gz_dm_media_cascade: empty host range")
					return
				end

				local parts = math.floor(gz_clamp(gz_num(desync, "parts", 4), 1, host_len))
				local halo = math.floor(gz_clamp(gz_num(desync, "halo", 1), 0, 12))
				local fake_passes = math.floor(gz_clamp(gz_num(desync, "fake_passes", 2), 0, 8))
				local hosts = gz_parse_hosts(desync.arg and desync.arg.hosts, "cdn.discordapp.com,media.discordapp.net,www.google.com")
				local real_host = string.sub(data, pos[1], pos[2])
				local chunks = gz_host_chunks(host_len, parts)
				local order = gz_edgein_order(#chunks)
				local opts_orig = {rawsend = rawsend_opts_base(desync), reconstruct = {}, ipfrag = {}, ipid = desync.arg, fooling = {tcp_ts_up = desync.arg.tcp_ts_up}}
				local opts_fake = gz_fake_opts(desync, gz_num(desync, "fake_tcp_ts", -300000))

				if b_debug then
					DLOG("gz_dm_media_cascade: range="..table.concat(zero_based_pos(pos), " ").." parts="..#chunks.." fake_passes="..fake_passes)
				end

				local prefix = string.sub(data, 1, pos[1] - 1)
				if #prefix > 0 then
					if not rawsend_payload_segmented(desync, prefix, 0, opts_orig) then return VERDICT_PASS end
				end

				local suffix = string.sub(data, pos[2] + 1)
				if #suffix > 0 then
					if b_debug then DLOG("gz_dm_media_cascade: sending suffix early offset="..pos[2].." len="..#suffix) end
					if not rawsend_payload_segmented(desync, suffix, pos[2], opts_orig) then return VERDICT_PASS end
				end

				local span_first = gz_clamp(pos[1] - halo, 1, #data)
				local span_last = gz_clamp(pos[2] + halo, 1, #data)
				local fake_prefix = string.sub(data, span_first, pos[1] - 1)
				local fake_suffix = string.sub(data, pos[2] + 1, span_last)
				for pass = 1, fake_passes do
					local host = hosts[((pass - 1) % #hosts) + 1]
					local fake_host = genhost(host_len, host)
					local fake_span = fake_prefix .. fake_host .. fake_suffix
					if #fake_span > 0 then
						if b_debug then DLOG("gz_dm_media_cascade: fake halo pass="..pass.." host="..host.." len="..#fake_span) end
						if not rawsend_payload_segmented(desync, fake_span, span_first - 1, opts_fake) then return VERDICT_PASS end
					end
					for _, idx in ipairs(order) do
						local chunk = chunks[idx]
						local chunk_data = string.sub(fake_host, chunk.first, chunk.last)
						local offset = pos[1] + chunk.first - 2
						if not rawsend_payload_segmented(desync, chunk_data, offset, opts_fake) then return VERDICT_PASS end
					end
				end

				for _, idx in ipairs(order) do
					local chunk = chunks[idx]
					local chunk_data = string.sub(real_host, chunk.first, chunk.last)
					local offset = pos[1] + chunk.first - 2
					if b_debug then DLOG("gz_dm_media_cascade: real chunk="..idx.." offset="..offset.." len="..#chunk_data) end
					if not rawsend_payload_segmented(desync, chunk_data, offset, opts_orig) then return VERDICT_PASS end
				end

				replay_drop_set(desync)
				return desync.arg.nodrop and VERDICT_PASS or VERDICT_DROP
			else
				DLOG("gz_dm_media_cascade: host range cannot be resolved")
			end
		else
			DLOG("gz_dm_media_cascade: not acting on further replay pieces")
		end
		if replay_drop(desync) then
			return desync.arg.nodrop and VERDICT_PASS or VERDICT_DROP
		end
	end
end

local function gz_send_payload_with_args(desync, payload, overrides)
	local d = gz_copy_desync(desync, overrides)
	return rawsend_payload_segmented(d, payload, nil, desync_opts(d))
end

local function gz_mutate_udp_shadow(data, salt)
	if not data or #data == 0 then return "\x00" end
	local keep = #data >= 20 and 8 or 4
	if #data <= keep then keep = 0 end
	local out = {}
	for i = 1, #data do
		local b = string.byte(data, i)
		if i > keep then
			b = bitxor(b, (salt * 37 + i * 13) % 256)
		end
		out[i] = string.char(b)
	end
	return table.concat(out)
end

-- Experimental: STUN QUIC constellation.
-- Designed around STUN strategy 34: keep the real UDP packet untouched, but
-- pre-seed DPI with QUIC Initial decoys and short STUN-like shadow packets.
-- QUIC remains the main signal; STUN shadows only add classifier noise.
--
-- standard args: direction, payload, fooling, ip_id, rawsend, reconstruct
-- arg: blob=<blob>              QUIC Initial fake, default quic_google
-- arg: q_repeats=N              main QUIC fake repeats, default payload-aware
-- arg: ip_autottl=<autottl>     main QUIC fake autottl, default 0,3-20
-- arg: ip6_autottl=<autottl>    main QUIC fake IPv6 autottl, default 0,3-20
-- arg: pre_satellite_repeats=N  QUIC fake repeats before main, default payload-aware
-- arg: post_satellite_repeats=N QUIC fake repeats after shadows, default payload-aware
-- arg: satellite_repeats=N      legacy fallback for both pre/post satellite repeats
-- arg: satellite_autottl=<ttl>  side QUIC fake autottl, default -1,3-20
-- arg: shadow_repeats=N         STUN-like shadow packets, default payload-aware
-- arg: pad=N                    bytes appended to shadow, default 8
-- arg: pattern=<blob>           shadow padding pattern, default 0x0F0F0E0F
function gz_stun_quic_constellation(ctx, desync)
	if not desync.dis.udp then
		if not desync.dis.icmp then instance_cutoff_shim(ctx, desync) end
		return
	end
	direction_cutoff_opposite(ctx, desync)
	if direction_check(desync) and payload_check(desync) then
		if replay_first(desync) then
			local qblob = gz_str(desync, "blob", "quic_google")
			if desync.arg.optional and not blob_exist(desync, qblob) then
				DLOG("gz_stun_quic_constellation: blob '"..qblob.."' not found. skipped")
				return
			end

			local quic = blob(desync, qblob)
			local l7payload = desync.l7payload or "unknown"
			local default_q_repeats = 10
			local default_pre_satellite_repeats = 2
			local default_post_satellite_repeats = 1
			local default_shadow_repeats = 2
			if l7payload == "discord_ip_discovery" then
				default_q_repeats = 8
				default_pre_satellite_repeats = 1
				default_post_satellite_repeats = 0
				default_shadow_repeats = 1
			elseif l7payload == "stun" then
				default_q_repeats = 10
				default_pre_satellite_repeats = 1
				default_post_satellite_repeats = 1
				default_shadow_repeats = 2
			end

			local legacy_satellite_repeats = desync.arg and desync.arg.satellite_repeats
			local main_repeats = math.floor(gz_clamp(gz_num(desync, "q_repeats", default_q_repeats), 1, 32))
			local pre_satellite_repeats = math.floor(gz_clamp(gz_num(desync, "pre_satellite_repeats", legacy_satellite_repeats and tonumber(legacy_satellite_repeats) or default_pre_satellite_repeats), 0, 12))
			local post_satellite_repeats = math.floor(gz_clamp(gz_num(desync, "post_satellite_repeats", legacy_satellite_repeats and tonumber(legacy_satellite_repeats) or default_post_satellite_repeats), 0, 12))
			local shadow_repeats = math.floor(gz_clamp(gz_num(desync, "shadow_repeats", default_shadow_repeats), 0, 8))
			local pad_len = math.floor(gz_clamp(gz_num(desync, "pad", 8), 0, 64))
			local main_autottl = gz_str(desync, "ip_autottl", "0,3-20")
			local main6_autottl = gz_str(desync, "ip6_autottl", main_autottl)
			local satellite_autottl = gz_str(desync, "satellite_autottl", "-1,3-20")
			local satellite6_autottl = gz_str(desync, "satellite6_autottl", satellite_autottl)
			local pad_pattern = blob(desync, gz_str(desync, "pattern", "0x0F0F0E0F"))

			if b_debug then
				DLOG("gz_stun_quic_constellation: payload="..l7payload.." q_repeats="..main_repeats.." pre_satellite_repeats="..pre_satellite_repeats.." post_satellite_repeats="..post_satellite_repeats.." shadow_repeats="..shadow_repeats)
			end

			if pre_satellite_repeats > 0 then
				if not gz_send_payload_with_args(desync, quic, {
					repeats = pre_satellite_repeats,
					ip_autottl = satellite_autottl,
					ip6_autottl = satellite6_autottl,
					ip_id = "rnd"
				}) then return VERDICT_PASS end
			end

			if not gz_send_payload_with_args(desync, quic, {
				repeats = main_repeats,
				ip_autottl = main_autottl,
				ip6_autottl = main6_autottl,
				ip_id = "seq"
			}) then return VERDICT_PASS end

			for i = 1, shadow_repeats do
				local shadow = gz_mutate_udp_shadow(desync.dis.payload, i)
				if pad_len > 0 then
					shadow = shadow .. pattern(pad_pattern, i, pad_len)
				end
				if b_debug then DLOG("gz_stun_quic_constellation: shadow "..i.." len="..#shadow) end
				if not gz_send_payload_with_args(desync, shadow, {
					repeats = 1,
					ip_autottl = main_autottl,
					ip6_autottl = main6_autottl,
					ip_id = "rnd",
					badsum = true
				}) then return VERDICT_PASS end
			end

			if post_satellite_repeats > 0 then
				if not gz_send_payload_with_args(desync, quic, {
					repeats = post_satellite_repeats,
					ip_autottl = satellite_autottl,
					ip6_autottl = satellite6_autottl,
					ip_id = "rnd"
				}) then return VERDICT_PASS end
			end
		else
			DLOG("gz_stun_quic_constellation: not acting on further replay pieces")
		end
	end
end

-- Experimental: SNI shadow braid.
-- More aggressive than gz_sni_mirror_ladder: it sends the real prefix first,
-- poisons a small halo around the SNI with layered fake hosts, optionally sends
-- the suffix early, and finally rebuilds the real SNI in a selected chunk order.
--
-- standard args: direction, payload, fooling, ip_id, rawsend, reconstruct
-- arg: host=<str>         first fake host template, default www.google.com
-- arg: host2=<str>        second fake host template, default cloudflare.com
-- arg: hosts=<list>       fake host templates, comma separated. overrides host/host2
-- arg: parts=N            SNI chunk count, default 5
-- arg: layers=N           fake layered passes, default 3
-- arg: halo=N             bytes before/after SNI included in fake halo, default 2
-- arg: fake_tcp_ts=N      default fake-only tcp_ts when no fooling is set
-- arg: range=<range>      protected range, default host,endhost-1
-- arg: suffix_first       send the real suffix before rebuilding the real SNI
-- arg: real_order=<mode>  braid|middleout|edgein|reverse|normal, default braid
-- arg: nodrop
function gz_sni_shadow_braid(ctx, desync)
	if not desync.dis.tcp then
		if not desync.dis.icmp then instance_cutoff_shim(ctx, desync) end
		return
	end
	direction_cutoff_opposite(ctx, desync)
	if desync.arg.optional and desync.arg.blob and not blob_exist(desync, desync.arg.blob) then
		DLOG("gz_sni_shadow_braid: blob '"..desync.arg.blob.."' not found. skipped")
		return
	end
	local data = blob_or_def(desync, desync.arg.blob) or desync.reasm_data or desync.dis.payload
	if #data > 0 and direction_check(desync) and payload_check(desync) then
		if replay_first(desync) then
			local range = gz_str(desync, "range", "host,endhost-1")
			local pos = resolve_range(data, desync.l7payload, range, true)
			if pos then
				local host_len = pos[2] - pos[1] + 1
				if host_len <= 0 then
					DLOG("gz_sni_shadow_braid: empty host range")
					return
				end

				local parts = math.floor(gz_clamp(gz_num(desync, "parts", 5), 1, host_len))
				local layers = math.floor(gz_clamp(gz_num(desync, "layers", 3), 0, 8))
				local halo = math.floor(gz_clamp(gz_num(desync, "halo", 2), 0, 12))
				local hosts_default = gz_str(desync, "host", "www.google.com")..","..gz_str(desync, "host2", "cloudflare.com")
				local hosts = gz_parse_hosts(desync.arg and desync.arg.hosts, hosts_default)
				local real_host = string.sub(data, pos[1], pos[2])
				local chunks = gz_host_chunks(host_len, parts)
				local real_order = gz_chunk_order(#chunks, gz_str(desync, "real_order", "braid"))

				local opts_orig = {rawsend = rawsend_opts_base(desync), reconstruct = {}, ipfrag = {}, ipid = desync.arg, fooling = {tcp_ts_up = desync.arg.tcp_ts_up}}
				local opts_fake = gz_fake_opts(desync, gz_num(desync, "fake_tcp_ts", -300000))

				if b_debug then
					DLOG("gz_sni_shadow_braid: range="..table.concat(zero_based_pos(pos), " ").." parts="..#chunks.." layers="..layers.." halo="..halo.." real_order="..gz_str(desync, "real_order", "braid"))
				end

				local part = string.sub(data, 1, pos[1] - 1)
				if #part > 0 then
					if b_debug then DLOG("gz_sni_shadow_braid: sending prefix len="..#part) end
					if not rawsend_payload_segmented(desync, part, 0, opts_orig) then return VERDICT_PASS end
				end

				local suffix = string.sub(data, pos[2] + 1)
				if desync.arg.suffix_first and #suffix > 0 then
					if b_debug then DLOG("gz_sni_shadow_braid: sending suffix early offset="..pos[2].." len="..#suffix) end
					if not rawsend_payload_segmented(desync, suffix, pos[2], opts_orig) then return VERDICT_PASS end
				end

				local span_first = gz_clamp(pos[1] - halo, 1, #data)
				local span_last = gz_clamp(pos[2] + halo, 1, #data)
				local fake_prefix = string.sub(data, span_first, pos[1] - 1)
				local fake_suffix = string.sub(data, pos[2] + 1, span_last)

				for layer = 1, layers do
					local host = hosts[((layer - 1) % #hosts) + 1]
					local fake_host = genhost(host_len, host)
					local fake_span = fake_prefix .. fake_host .. fake_suffix
					if #fake_span > 0 then
						if b_debug then DLOG("gz_sni_shadow_braid: fake halo layer="..layer.." host="..host.." offset="..(span_first - 1).." len="..#fake_span) end
						if not rawsend_payload_segmented(desync, fake_span, span_first - 1, opts_fake) then return VERDICT_PASS end
					end
				end

				for layer = 1, layers do
					local host = hosts[((layer - 1) % #hosts) + 1]
					local alt_host = hosts[(layer % #hosts) + 1]
					local fake_host = genhost(host_len, host)
					local fake_alt_host = genhost(host_len, alt_host)
					for step = 1, #chunks do
						local idx = layer % 2 == 1 and (#chunks - step + 1) or step
						local chunk = chunks[idx]
						local chunk_host = (idx + layer) % 2 == 0 and fake_host or fake_alt_host
						local chunk_data = string.sub(chunk_host, chunk.first, chunk.last)
						local offset = pos[1] + chunk.first - 2
						if b_debug then DLOG("gz_sni_shadow_braid: fake layer="..layer.." chunk="..idx.." offset="..offset.." len="..#chunk_data) end
						if not rawsend_payload_segmented(desync, chunk_data, offset, opts_fake) then return VERDICT_PASS end
					end
				end

				for _, idx in ipairs(real_order) do
					local chunk = chunks[idx]
					local chunk_data = string.sub(real_host, chunk.first, chunk.last)
					local offset = pos[1] + chunk.first - 2
					if b_debug then DLOG("gz_sni_shadow_braid: real chunk="..idx.." offset="..offset.." len="..#chunk_data) end
					if not rawsend_payload_segmented(desync, chunk_data, offset, opts_orig) then return VERDICT_PASS end
				end

				if not desync.arg.suffix_first and #suffix > 0 then
					if b_debug then DLOG("gz_sni_shadow_braid: sending suffix offset="..pos[2].." len="..#suffix) end
					if not rawsend_payload_segmented(desync, suffix, pos[2], opts_orig) then return VERDICT_PASS end
				end

				replay_drop_set(desync)
				return desync.arg.nodrop and VERDICT_PASS or VERDICT_DROP
			else
				DLOG("gz_sni_shadow_braid: host range cannot be resolved")
			end
		else
			DLOG("gz_sni_shadow_braid: not acting on further replay pieces")
		end
		if replay_drop(desync) then
			return desync.arg.nodrop and VERDICT_PASS or VERDICT_DROP
		end
	end
end

-- Experimental: SNI mirror ladder.
-- Fake SNI chunks are sent from both edges toward the center, then the real SNI
-- is sent middle-out. This targets DPI overlap/order heuristics while keeping
-- the valid stream complete for the server.
--
-- standard args: direction, payload, fooling, ip_id, rawsend, reconstruct
-- arg: host=<str>         fake host template, default www.google.com
-- arg: hosts=<list>       fake host templates, comma separated
-- arg: parts=N            SNI chunk count, default 4
-- arg: fake_passes=N      0 disables fake prelude, default 2
-- arg: halo=N             bytes before/after SNI included in fake prelude, default 0
-- arg: fake_tcp_ts=N      default fake-only tcp_ts when no fooling is set
-- arg: range=<range>      protected range, default host,endhost-1
-- arg: real_order=normal  send real chunks in normal order instead of middle-out
-- arg: nodrop
function gz_sni_mirror_ladder(ctx, desync)
	if not desync.dis.tcp then
		if not desync.dis.icmp then instance_cutoff_shim(ctx, desync) end
		return
	end
	direction_cutoff_opposite(ctx, desync)
	if desync.arg.optional and desync.arg.blob and not blob_exist(desync, desync.arg.blob) then
		DLOG("gz_sni_mirror_ladder: blob '"..desync.arg.blob.."' not found. skipped")
		return
	end
	local data = blob_or_def(desync, desync.arg.blob) or desync.reasm_data or desync.dis.payload
	if #data > 0 and direction_check(desync) and payload_check(desync) then
		if replay_first(desync) then
			local range = gz_str(desync, "range", "host,endhost-1")
			local pos = resolve_range(data, desync.l7payload, range, true)
			if pos then
				local host_len = pos[2] - pos[1] + 1
				if host_len <= 0 then
					DLOG("gz_sni_mirror_ladder: empty host range")
					return
				end
				local parts = math.floor(gz_clamp(gz_num(desync, "parts", 4), 1, host_len))
				local fake_passes = math.floor(gz_clamp(gz_num(desync, "fake_passes", 2), 0, 8))
				local halo = math.floor(gz_clamp(gz_num(desync, "halo", 0), 0, 12))
				local hosts = gz_parse_hosts(desync.arg and desync.arg.hosts, gz_str(desync, "host", "www.google.com"))
				local real_host = string.sub(data, pos[1], pos[2])
				local chunks = gz_host_chunks(host_len, parts)
				local fake_order = gz_edgein_order(#chunks)

				if b_debug then
					DLOG("gz_sni_mirror_ladder: range="..table.concat(zero_based_pos(pos), " ").." parts="..#chunks.." fake_passes="..fake_passes.." halo="..halo)
				end

				local opts_orig = {rawsend = rawsend_opts_base(desync), reconstruct = {}, ipfrag = {}, ipid = desync.arg, fooling = {tcp_ts_up = desync.arg.tcp_ts_up}}
				local opts_fake = gz_fake_opts(desync, gz_num(desync, "fake_tcp_ts", -300000))

				local part = string.sub(data, 1, pos[1] - 1)
				if #part > 0 then
					if b_debug then DLOG("gz_sni_mirror_ladder: sending prefix len="..#part) end
					if not rawsend_payload_segmented(desync, part, 0, opts_orig) then return VERDICT_PASS end
				end

				for pass = 1, fake_passes do
					local host = hosts[((pass - 1) % #hosts) + 1]
					local fake_host = genhost(host_len, host)
					if halo > 0 then
						local span_first = gz_clamp(pos[1] - halo, 1, #data)
						local span_last = gz_clamp(pos[2] + halo, 1, #data)
						local fake_span = string.sub(data, span_first, pos[1] - 1) .. fake_host .. string.sub(data, pos[2] + 1, span_last)
						if #fake_span > 0 then
							if b_debug then DLOG("gz_sni_mirror_ladder: fake halo pass="..pass.." host="..host.." offset="..(span_first - 1).." len="..#fake_span) end
							if not rawsend_payload_segmented(desync, fake_span, span_first - 1, opts_fake) then return VERDICT_PASS end
						end
					end
					for step = 1, #fake_order do
						local i = pass % 2 == 1 and fake_order[step] or fake_order[#fake_order - step + 1]
						local chunk = chunks[i]
						local chunk_data = string.sub(fake_host, chunk.first, chunk.last)
						local offset = pos[1] + chunk.first - 2
						if b_debug then DLOG("gz_sni_mirror_ladder: fake pass="..pass.." host="..host.." chunk="..i.." offset="..offset.." len="..#chunk_data) end
						if not rawsend_payload_segmented(desync, chunk_data, offset, opts_fake) then return VERDICT_PASS end
					end
				end

				local real_order
				if gz_str(desync, "real_order", "middleout") == "normal" then
					real_order = {}
					for i = 1, #chunks do real_order[#real_order + 1] = i end
				else
					real_order = gz_middleout_order(#chunks)
				end

				for _, i in ipairs(real_order) do
					local chunk = chunks[i]
					local chunk_data = string.sub(real_host, chunk.first, chunk.last)
					local offset = pos[1] + chunk.first - 2
					if b_debug then DLOG("gz_sni_mirror_ladder: real chunk="..i.." offset="..offset.." len="..#chunk_data) end
					if not rawsend_payload_segmented(desync, chunk_data, offset, opts_orig) then return VERDICT_PASS end
				end

				part = string.sub(data, pos[2] + 1)
				if #part > 0 then
					if b_debug then DLOG("gz_sni_mirror_ladder: sending suffix offset="..pos[2].." len="..#part) end
					if not rawsend_payload_segmented(desync, part, pos[2], opts_orig) then return VERDICT_PASS end
				end

				replay_drop_set(desync)
				return desync.arg.nodrop and VERDICT_PASS or VERDICT_DROP
			else
				DLOG("gz_sni_mirror_ladder: host range cannot be resolved")
			end
		else
			DLOG("gz_sni_mirror_ladder: not acting on further replay pieces")
		end
		if replay_drop(desync) then
			return desync.arg.nodrop and VERDICT_PASS or VERDICT_DROP
		end
	end
end

-- Experimental: poison with a fake, then modify the real TLS ClientHello into
-- two TLS records. This attacks TLS-record parsing rather than only TCP state.
function gz_discord_tlsrec_probe(ctx, desync)
	gz_fake_once(ctx, desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		repeats = gz_num(desync, "fake_repeats", 3),
		tcp_ts = gz_num(desync, "tcp_ts", -300000)
	})
	return tlsrec(ctx, gz_copy_desync(desync, {
		pos = gz_str(desync, "tlsrec_pos", "host")
	}))
end

-- Experimental: split the real TLS ClientHello into two TLS records without
-- any fake prelude. This is a cleaner TLS-layer-only probe.
function gz_discord_tlsrec_clean(ctx, desync)
	return tlsrec(ctx, gz_copy_desync(desync, {
		pos = gz_str(desync, "tlsrec_pos", "midsld")
	}))
end

-- Experimental: send low-TTL decoy ClientHello packets only, without modifying
-- the real ClientHello. If record/segment tricks are too fragile, this should
-- fail softer because the original packet still goes through normally.
function gz_discord_decoy_only(ctx, desync)
	return decoy_hello(ctx, gz_copy_desync(desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		repeats = gz_num(desync, "decoy_repeats", 4),
		ip_ttl = gz_num(desync, "decoy_ttl", 2),
		ip6_ttl = gz_num(desync, "decoy_ttl", 2),
		tls_mod = gz_str(desync, "tls_mod", "rnd,dupsid,sni=www.google.com")
	}))
end

-- Experimental: fake the SNI/host range using the stealth hostfakesplit path.
-- This is a different family from timestamp fakes, decoys, TLS record splitting,
-- and segment interlace. It rewrites only what DPI sees around SNI.
function gz_discord_host_stealth(ctx, desync)
	return hostfakesplit_stealth(ctx, gz_copy_desync(desync, {
		host = gz_str(desync, "host", "www.google.com"),
		mode = gz_str(desync, "mode", "soft"),
		midhost = gz_str(desync, "midhost", "midsld"),
		repeats = gz_num(desync, "repeats", 2),
		tcp_ts = gz_num(desync, "tcp_ts", -1000)
	}))
end

-- Experimental: send the real ClientHello in interlaced segment order around SNI.
-- Unlike the timestamp-only strategies, this changes real segment ordering.
function gz_discord_sni_interlace(ctx, desync)
	return multisplitdisorder(ctx, gz_copy_desync(desync, {
		mode = gz_str(desync, "mode", "interlace"),
		pos = gz_str(desync, "pos", "1,host,midsld,endhost-1"),
		seqovl = gz_num(desync, "seqovl", 1),
		seqovl_pattern = gz_str(desync, "seqovl_pattern", "tls_google")
	}))
end

-- Experimental: first a fake timestamped ClientHello, then an OOB/urgent-byte
-- disturbance near SNI. This targets TCP urgent handling in DPI.
function gz_discord_oob_sni(ctx, desync)
	gz_fake_once(ctx, desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		repeats = gz_num(desync, "fake_repeats", 3),
		tcp_ts = gz_num(desync, "tcp_ts", -600000)
	})
	return oob(ctx, gz_copy_desync(desync, {
		pos = gz_str(desync, "pos", "host"),
		byte = gz_num(desync, "byte", 0),
		urp = gz_str(desync, "urp", "b")
	}))
end

-- Experimental: timestamp fake first, then interlace the real ClientHello
-- without seqovl. Softer than gz_discord_sni_interlace, but still changes
-- real segment order.
function gz_discord_fake_interlace(ctx, desync)
	gz_fake_once(ctx, desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		repeats = gz_num(desync, "fake_repeats", 3),
		tcp_ts = gz_num(desync, "tcp_ts", -300000)
	})
	return multisplitdisorder(ctx, gz_copy_desync(desync, {
		mode = gz_str(desync, "mode", "interlace"),
		pos = gz_str(desync, "pos", "host,midsld,endhost-1"),
		seqovl = 0
	}))
end

-- DiscordUpdate experiments.
function gz_du_split_tail(ctx, desync)
	gz_fake_once(ctx, desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		repeats = gz_num(desync, "fake_repeats", 4),
		tcp_ts = gz_num(desync, "tcp_ts", -600000)
	})
	return fakedsplit(ctx, gz_copy_desync(desync, {
		pattern = gz_str(desync, "pattern", "0x00"),
		repeats = gz_num(desync, "split_repeats", 2),
		tcp_ts = gz_num(desync, "split_tcp_ts", -300000)
	}))
end

function gz_du_host_stealth(ctx, desync)
	return hostfakesplit_stealth(ctx, gz_copy_desync(desync, {
		host = gz_str(desync, "host", "www.google.com"),
		mode = gz_str(desync, "mode", "soft"),
		midhost = gz_str(desync, "midhost", "midsld"),
		repeats = gz_num(desync, "repeats", 2),
		tcp_ts = gz_num(desync, "tcp_ts", -600000)
	}))
end

function gz_du_tlsrec_probe(ctx, desync)
	gz_fake_once(ctx, desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		repeats = gz_num(desync, "fake_repeats", 3),
		tcp_ts = gz_num(desync, "tcp_ts", -600000)
	})
	return tlsrec(ctx, gz_copy_desync(desync, {
		pos = gz_str(desync, "tlsrec_pos", "host")
	}))
end

function gz_du_fake_multisplit(ctx, desync)
	gz_fake_once(ctx, desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		repeats = gz_num(desync, "fake_repeats", 4),
		tcp_ts = gz_num(desync, "tcp_ts", -600000)
	})
	return multisplit(ctx, gz_copy_desync(desync, {
		pos = gz_str(desync, "pos", "2,midsld"),
		seqovl = gz_num(desync, "seqovl", 1),
		seqovl_pattern = gz_str(desync, "seqovl_pattern", "tls_google")
	}))
end

-- DiscordMedia experiments.
function gz_dm_ts_probe(ctx, desync)
	return gz_fake_once(ctx, desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		repeats = gz_num(desync, "repeats", 8),
		tcp_ts = gz_num(desync, "tcp_ts", -300000)
	})
end

function gz_dm_host_stealth(ctx, desync)
	return hostfakesplit_stealth(ctx, gz_copy_desync(desync, {
		host = gz_str(desync, "host", "www.google.com"),
		mode = gz_str(desync, "mode", "soft"),
		midhost = gz_str(desync, "midhost", "midsld"),
		repeats = gz_num(desync, "repeats", 2),
		tcp_ts = gz_num(desync, "tcp_ts", -1000)
	}))
end

function gz_dm_fake_multisplit(ctx, desync)
	gz_fake_once(ctx, desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		repeats = gz_num(desync, "fake_repeats", 4),
		tcp_ts = gz_num(desync, "tcp_ts", -300000)
	})
	return multisplit(ctx, gz_copy_desync(desync, {
		pos = gz_str(desync, "pos", "2,midsld"),
		seqovl = gz_num(desync, "seqovl", 1),
		seqovl_pattern = gz_str(desync, "seqovl_pattern", "tls_google")
	}))
end

function gz_dm_oob_sni(ctx, desync)
	gz_fake_once(ctx, desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		repeats = gz_num(desync, "fake_repeats", 3),
		tcp_ts = gz_num(desync, "tcp_ts", -300000)
	})
	return oob(ctx, gz_copy_desync(desync, {
		pos = gz_str(desync, "pos", "host"),
		byte = gz_num(desync, "byte", 0),
		urp = gz_str(desync, "urp", "b")
	}))
end

-- YouTubeGoogleVideo experiments.
function gz_ytgv_37_tight(ctx, desync)
	send(ctx, gz_copy_desync(desync, {
		repeats = gz_num(desync, "send_repeats", 1),
		ip_id = gz_str(desync, "ip_id", "seq")
	}))
	syndata(ctx, gz_copy_desync(desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		ip_autottl = gz_str(desync, "ip_autottl", "-2,3-20"),
		ip6_autottl = gz_str(desync, "ip6_autottl", "-2,3-20")
	}))
	gz_fake_once(ctx, desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		ip_autottl = gz_str(desync, "fake_autottl", "-1,3-20"),
		ip6_autottl = gz_str(desync, "fake6_autottl", "-1,3-20"),
		repeats = gz_num(desync, "fake_repeats", 6),
		tcp_ack = gz_num(desync, "tcp_ack", -66000),
		seqovl = gz_num(desync, "seqovl", 680),
		seqovl_pattern = gz_str(desync, "seqovl_pattern", "tls_google")
	})
	gz_fake_once(ctx, desync, {
		blob = gz_str(desync, "second_blob", "fake_default_tls"),
		repeats = gz_num(desync, "second_repeats", 7),
		tcp_ack = gz_num(desync, "tcp_ack", -66000),
		tcp_ts_up = true,
		tls_mod = gz_str(desync, "tls_mod", "rnd,dupsid"),
		sni = gz_str(desync, "sni", "sun6-21.userapi.com"),
		payload = gz_str(desync, "payload", "tls_client_hello")
	})
	return multidisorder(ctx, gz_copy_desync(desync, {
		pos = gz_str(desync, "pos", "1,midsld,sniext+1,endhost-2"),
		tcp_ack = gz_num(desync, "tcp_ack", -66000),
		tcp_ts_up = true
	}))
end

function gz_ytgv_ts_multisplit(ctx, desync)
	send(ctx, gz_copy_desync(desync, {
		repeats = gz_num(desync, "send_repeats", 2)
	}))
	gz_fake_once(ctx, desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		repeats = gz_num(desync, "fake_repeats", 8),
		tcp_ts = gz_num(desync, "tcp_ts", -300000)
	})
	return multisplit(ctx, gz_copy_desync(desync, {
		pos = gz_str(desync, "pos", "1,midsld,sniext+1"),
		seqovl = gz_num(desync, "seqovl", 680),
		seqovl_pattern = gz_str(desync, "seqovl_pattern", "tls_google"),
		tcp_ack = gz_num(desync, "tcp_ack", -66000),
		tcp_ts_up = true
	}))
end

function gz_ytgv_tlsrec_probe(ctx, desync)
	gz_fake_once(ctx, desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		repeats = gz_num(desync, "fake_repeats", 5),
		tcp_ack = gz_num(desync, "tcp_ack", -66000),
		tcp_ts = gz_num(desync, "tcp_ts", -600000)
	})
	tlsrec(ctx, gz_copy_desync(desync, {
		pos = gz_str(desync, "tlsrec_pos", "sniext+1")
	}))
	return multidisorder(ctx, gz_copy_desync(desync, {
		pos = gz_str(desync, "pos", "1,midsld,endhost-2"),
		seqovl = gz_num(desync, "seqovl", 680),
		seqovl_pattern = gz_str(desync, "seqovl_pattern", "tls_google"),
		tcp_ack = gz_num(desync, "tcp_ack", -66000)
	}))
end

function gz_ytgv_host_stealth(ctx, desync)
	gz_fake_once(ctx, desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		repeats = gz_num(desync, "fake_repeats", 4),
		tcp_ts = gz_num(desync, "tcp_ts", -600000)
	})
	return hostfakesplit_stealth(ctx, gz_copy_desync(desync, {
		host = gz_str(desync, "host", "www.google.com"),
		mode = gz_str(desync, "mode", "soft"),
		midhost = gz_str(desync, "midhost", "midsld"),
		repeats = gz_num(desync, "repeats", 2),
		tcp_ack = gz_num(desync, "tcp_ack", -66000)
	}))
end

-- YouTube / GoogleVideo TCP experiment.
-- Performs a light SYN/data prelude, sends one timestamped fake ClientHello, then
-- rebuilds the real ClientHello around SNI with either faked disorder or split.
function gz_yt_sni_resync(ctx, desync)
	send(ctx, gz_copy_desync(desync, {
		repeats = gz_num(desync, "send_repeats", 1),
		ip_id = gz_str(desync, "ip_id", "seq")
	}))

	syndata(ctx, gz_copy_desync(desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		ip_autottl = gz_str(desync, "syn_autottl", "-2,3-20"),
		ip6_autottl = gz_str(desync, "syn6_autottl", "-2,3-20")
	}))

	gz_fake_once(ctx, desync, {
		blob = gz_str(desync, "fake_blob", gz_str(desync, "blob", "tls_google")),
		repeats = gz_num(desync, "fake_repeats", 6),
		tcp_ack = gz_num(desync, "tcp_ack", -66000),
		tcp_ts = gz_num(desync, "fake_tcp_ts", -500000),
		seqovl = gz_num(desync, "fake_seqovl", 680),
		seqovl_pattern = gz_str(desync, "fake_seqovl_pattern", gz_str(desync, "blob", "tls_google")),
		tls_mod = gz_str(desync, "fake_tls_mod", "rnd,dupsid"),
		sni = gz_str(desync, "fake_sni", "www.google.com")
	})

	local common = {
		pattern = gz_str(desync, "pattern", "0x00"),
		pos = gz_str(desync, "pos", "1,midsld+1,sniext+1"),
		seqovl = gz_num(desync, "seqovl", 1),
		seqovl_pattern = gz_str(desync, "seqovl_pattern", gz_str(desync, "pattern", "0x00")),
		tcp_ack = gz_num(desync, "tcp_ack", -66000),
		tcp_ts_up = desync.arg.split_tcp_ts_up or desync.arg.tcp_ts_up,
		ip_autottl = gz_str(desync, "split_autottl", "1,3-20"),
		ip6_autottl = gz_str(desync, "split6_autottl", "1,3-20")
	}

	if gz_str(desync, "mode", "disorder") == "split" then
		return fakedsplit(ctx, gz_copy_desync(desync, common))
	end
	return fakeddisorder(ctx, gz_copy_desync(desync, common))
end

-- Hostlists TCP experiments.
-- One entry point for several broader hostlist probes: interlaced SNI rebuild,
-- TLS-record split probe, and a softer hostfakesplit path.
function gz_bl_tls_probe(ctx, desync)
	send(ctx, gz_copy_desync(desync, {
		repeats = gz_num(desync, "send_repeats", 2),
		ip_id = gz_str(desync, "ip_id", "seq")
	}))

	syndata(ctx, gz_copy_desync(desync, {
		blob = gz_str(desync, "blob", "tls_google"),
		ip_autottl = gz_str(desync, "syn_autottl", "-2,3-20"),
		ip6_autottl = gz_str(desync, "syn6_autottl", "-2,3-20")
	}))

	gz_fake_once(ctx, desync, {
		blob = gz_str(desync, "fake_blob", gz_str(desync, "blob", "tls_google")),
		repeats = gz_num(desync, "fake_repeats", 5),
		tcp_ack = gz_num(desync, "tcp_ack", -66000),
		tcp_ts = gz_num(desync, "fake_tcp_ts", -300000),
		tls_mod = gz_str(desync, "fake_tls_mod", "rnd,dupsid"),
		sni = gz_str(desync, "fake_sni", "www.google.com")
	})

	local action = gz_str(desync, "action", "interlace")
	if action == "host" then
		return hostfakesplit_stealth(ctx, gz_copy_desync(desync, {
			host = gz_str(desync, "host", "www.google.com"),
			mode = gz_str(desync, "stealth_mode", "soft"),
			midhost = gz_str(desync, "midhost", "midsld"),
			repeats = gz_num(desync, "repeats", 2),
			tcp_ack = gz_num(desync, "tcp_ack", -66000),
			tcp_ts = gz_num(desync, "split_tcp_ts", -1000)
		}))
	end

	if action == "tlsrec" then
		tlsrec(ctx, gz_copy_desync(desync, {
			pos = gz_str(desync, "tlsrec_pos", "host")
		}))
		return multidisorder(ctx, gz_copy_desync(desync, {
			pos = gz_str(desync, "pos", "1,midsld,endhost-2"),
			seqovl = gz_num(desync, "seqovl", 680),
			seqovl_pattern = gz_str(desync, "seqovl_pattern", gz_str(desync, "blob", "tls_google")),
			tcp_ack = gz_num(desync, "tcp_ack", -66000),
			tcp_ts_up = desync.arg.tcp_ts_up
		}))
	end

	return multisplitdisorder(ctx, gz_copy_desync(desync, {
		mode = gz_str(desync, "order", "interlace"),
		pos = gz_str(desync, "pos", "1,host,midsld,endhost-1"),
		seqovl = gz_num(desync, "seqovl", 680),
		seqovl_pattern = gz_str(desync, "seqovl_pattern", gz_str(desync, "blob", "tls_google")),
		tcp_ack = gz_num(desync, "tcp_ack", -66000)
	}))
end

DLOG("goodbyezapret-presets.lua loaded")
