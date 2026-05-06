-- blocked-auto.lua
-- Passive auto-classifier for domains/IPs seen by winws2 Lua profiles.
--
-- States:
--   SEEN      - target was observed, never written to bypass lists by itself
--   SUSPECT   - failure score is non-zero but not high enough
--   BLOCKED   - confirmed and written to blocked-auto.txt/ipset-blocked-auto.txt
--   RECOVERED - was blocked before, then enough successful traffic removed it

BLOCKED_AUTO_VERSION = "2.2.1"

BLOCKED_AUTO_DEFAULT_HOST_FILE = BLOCKED_AUTO_DEFAULT_HOST_FILE or "lists/blocked-auto.txt"
BLOCKED_AUTO_DEFAULT_IP_FILE = BLOCKED_AUTO_DEFAULT_IP_FILE or "lists/ipset-blocked-auto.txt"
BLOCKED_AUTO_DEFAULT_LOG_FILE = BLOCKED_AUTO_DEFAULT_LOG_FILE or "tools/blocked-auto.log"
BLOCKED_AUTO_DEFAULT_STATE_FILE = BLOCKED_AUTO_DEFAULT_STATE_FILE or "tools/blocked-auto-state.txt"
BLOCKED_AUTO_DEFAULT_RECOVERED_FILE = BLOCKED_AUTO_DEFAULT_RECOVERED_FILE or "tools/blocked-auto-recovered.txt"
BLOCKED_AUTO_DEFAULT_EXCLUDE_FILE = BLOCKED_AUTO_DEFAULT_EXCLUDE_FILE or "lists/exclude-autohostlist.txt"

BLOCKED_AUTO_STATE = BLOCKED_AUTO_STATE or {}
BLOCKED_AUTO_LISTS_LOADED = BLOCKED_AUTO_LISTS_LOADED or false
BLOCKED_AUTO_EXCLUDES_LOADED = BLOCKED_AUTO_EXCLUDES_LOADED or false
BLOCKED_AUTO_EXTERNAL_EXCLUDES = BLOCKED_AUTO_EXTERNAL_EXCLUDES or {}
BLOCKED_AUTO_LAST_EVENT = BLOCKED_AUTO_LAST_EVENT or {}
BLOCKED_AUTO_SAVE_LAST = BLOCKED_AUTO_SAVE_LAST or 0
BLOCKED_AUTO_RECOVERY_LAST_PROBE = BLOCKED_AUTO_RECOVERY_LAST_PROBE or {}
BLOCKED_AUTO_NEEDS_SAVE = BLOCKED_AUTO_NEEDS_SAVE or false

local function ba_log_dlog(msg)
	if type(DLOG) == "function" then
		DLOG("blocked-auto: " .. tostring(msg))
	end
end

local function ba_now()
	if os and os.time then
		return os.time()
	end
	return 0
end

local function ba_trim(s)
	return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function ba_lower(s)
	return tostring(s or ""):lower()
end

local function ba_strip_quotes(s)
	s = ba_trim(s)
	if #s >= 2 then
		local first = s:sub(1, 1)
		local last = s:sub(-1)
		if (first == '"' and last == '"') or (first == "'" and last == "'") then
			return s:sub(2, -2)
		end
	end
	return s
end

local function ba_path_from_arg(arg, key, default_value)
	arg = arg or {}
	local v = arg[key]
	if not v or #tostring(v) == 0 then
		v = default_value
	end
	v = ba_strip_quotes(v)
	if type(writeable_file_name) == "function" then
		local ok, resolved = pcall(writeable_file_name, v)
		if ok and resolved and #resolved > 0 then
			return resolved
		end
	end
	return v
end

local function ba_host_file(arg)
	return ba_path_from_arg(arg, "file", BLOCKED_AUTO_DEFAULT_HOST_FILE)
end

local function ba_ip_file(arg)
	return ba_path_from_arg(arg, "ip_file", BLOCKED_AUTO_DEFAULT_IP_FILE)
end

local function ba_log_file(arg)
	return ba_path_from_arg(arg, "log_file", BLOCKED_AUTO_DEFAULT_LOG_FILE)
end

local function ba_state_file(arg)
	return ba_path_from_arg(arg, "state_file", BLOCKED_AUTO_DEFAULT_STATE_FILE)
end

local function ba_recovered_file(arg)
	return ba_path_from_arg(arg, "recovered_file", BLOCKED_AUTO_DEFAULT_RECOVERED_FILE)
end

local function ba_exclude_file(arg)
	return ba_path_from_arg(arg, "exclude_file", BLOCKED_AUTO_DEFAULT_EXCLUDE_FILE)
end

local function ba_read_all(path)
	local f = io.open(path, "rb")
	if not f then
		return ""
	end
	local data = f:read("*a") or ""
	f:close()
	return data
end

local function ba_write_all(path, data)
	local tmp = tostring(path) .. ".tmp"
	local f = io.open(tmp, "wb")
	if not f then
		ba_log_dlog("cannot open '" .. tostring(tmp) .. "' for write")
		return false
	end
	local ok, err = f:write(data or "")
	local close_ok, close_err = f:close()
	if not ok or not close_ok then
		ba_log_dlog("cannot write '" .. tostring(tmp) .. "': " .. tostring(err or close_err))
		if os and os.remove then os.remove(tmp) end
		return false
	end
	if not (os and os.rename) then
		ba_log_dlog("cannot rename temporary file for '" .. tostring(path) .. "'")
		if os and os.remove then os.remove(tmp) end
		return false
	end
	local renamed, rename_err = os.rename(tmp, path)
	if not renamed and os.remove then
		os.remove(path)
		renamed, rename_err = os.rename(tmp, path)
	end
	if not renamed then
		ba_log_dlog("cannot replace '" .. tostring(path) .. "': " .. tostring(rename_err))
		if os.remove then os.remove(tmp) end
		return false
	end
	return true
end

local function ba_append_line(path, value)
	local f = io.open(path, "ab")
	if not f then
		ba_log_dlog("cannot open '" .. tostring(path) .. "' for append")
		return false
	end
	local ok, err = f:write(tostring(value) .. "\r\n")
	local close_ok, close_err = f:close()
	if not ok or not close_ok then
		ba_log_dlog("cannot append '" .. tostring(path) .. "': " .. tostring(err or close_err))
		return false
	end
	return true
end

local function ba_log(arg, target, event, detail)
	local path = ba_log_file(arg)
	if not path or path == "" then
		return
	end
	ba_append_line(path, tostring(ba_now()) .. " " .. tostring(target or "-") .. " " .. tostring(event or "-") .. " " .. tostring(detail or ""))
end

local function ba_is_ipv4(s)
	local a, b, c, d = tostring(s or ""):match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
	if not a then return false end
	a, b, c, d = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
	return a and b and c and d and a <= 255 and b <= 255 and c <= 255 and d <= 255
end

local function ba_is_ipv6(s)
	s = tostring(s or "")
	return s:find(":", 1, true) ~= nil and s:match("^[0-9a-fA-F:%.]+$") ~= nil
end

local function ba_is_ip(s)
	return ba_is_ipv4(s) or ba_is_ipv6(s)
end

local function ba_is_private_ipv4(s)
	local a, b = tostring(s or ""):match("^(%d+)%.(%d+)%.%d+%.%d+$")
	a, b = tonumber(a), tonumber(b)
	if not a or not b then return false end
	return a == 0 or a == 10 or a == 127 or a >= 224 or
		(a == 100 and b >= 64 and b <= 127) or
		(a == 169 and b == 254) or
		(a == 172 and b >= 16 and b <= 31) or
		(a == 192 and b == 168)
end

local function ba_is_private_ipv6(s)
	s = ba_lower(s)
	return s == "::1" or s:match("^fe80:") or s:match("^fc") or s:match("^fd")
end

local function ba_domain_has_suffix(domain, suffix)
	return domain == suffix or domain:sub(-#suffix - 1) == "." .. suffix
end

local BA_SKIP_DOMAINS = {
	"localhost",
	"local",
	"lan",
	"arpa",
}

local BA_NOISY_SEEN_SUFFIXES = {
	"msftconnecttest.com",
	"msftncsi.com",
	"microsoft.com",
	"cloud.microsoft",
	"windows.com",
	"windows.net",
	"office.com",
	"office.net",
	"skype.com",
	"visualstudio.com",
	"vscode-cdn.net",
	"github.com",
	"githubusercontent.com",
	"statsigapi.net",
}

local BA_AUTO_EXCLUDE_SUFFIXES = {
	"msftconnecttest.com",
	"msftncsi.com",
	"microsoft.com",
	"cloud.microsoft",
	"windows.com",
	"windows.net",
	"office.com",
	"office.net",
	"skype.com",
	"visualstudio.com",
	"vscode-cdn.net",
	"github.com",
	"githubusercontent.com",
	"statsigapi.net",
	"apple.com",
	"icloud.com",
	"mzstatic.com",
	"itunes.com",
	"msn.com",
	"bing.com",
	"scorecardresearch.com",
	"doubleclick.net",
	"googlesyndication.com",
	"googleadservices.com",
	"googletagmanager.com",
	"google-analytics.com",
	"facebook.net",
	"fbcdn.net",
	"amazon.com",
	"appcenter.ms",
	"applicationinsights.azure.com",
	"azure.com",
	"azureedge.net",
	"azurewebsites.net",
	"bingapis.com",
	"cloudflare.com",
	"cloudflare-dns.com",
	"datadoghq.com",
	"githubcopilot.com",
	"opendns.com",
	"sentry.io",
}

local BA_WEAK_BLOCK_REASONS = {
	TCP_STALL = true,
	UDP_SILENT = true,
}

local function ba_blocked_base_reason(reason)
	return tostring(reason or ""):gsub("^RECOVERY_", "")
end

local function ba_is_weak_block_reason(reason)
	return BA_WEAK_BLOCK_REASONS[ba_blocked_base_reason(reason)] or false
end

local function ba_weak_min_failures(arg)
	local explicit = tonumber(arg and (arg.weak_min_failures or arg.blocked_weak_min_failures))
	if explicit then return explicit end
	local min_failures = tonumber(arg and (arg.min_failures or arg.blocked_min_failures)) or 2
	return math.max(4, min_failures)
end

local function ba_normalize_target(raw)
	local s = ba_lower(ba_trim(raw))
	if s == "" or s == "-" then return nil, nil end

	s = s:gsub("^https?://", "")
	s = s:gsub("^%[", ""):gsub("%]$", "")
	local slash = s:find("/", 1, true)
	if slash then s = s:sub(1, slash - 1) end
	local q = s:find("?", 1, true)
	if q then s = s:sub(1, q - 1) end
	if s:match("^.+:%d+$") and not ba_is_ipv6(s) then
		s = s:gsub(":%d+$", "")
	end
	s = s:gsub("%.+$", "")
	if s == "" then return nil, nil end

	if ba_is_ip(s) then
		if ba_is_ipv4(s) and ba_is_private_ipv4(s) then return nil, nil end
		if ba_is_ipv6(s) and ba_is_private_ipv6(s) then return nil, nil end
		return s, "ip"
	end

	if not s:find(".", 1, true) then return nil, nil end
	for _, suffix in ipairs(BA_SKIP_DOMAINS) do
		if ba_domain_has_suffix(s, suffix) then return nil, nil end
	end

	if type(slm_normalize_hostkey) == "function" then
		local ok, normalized = pcall(slm_normalize_hostkey, s)
		if ok and normalized and #normalized > 0 then
			s = normalized
		end
	end
	return s, "host"
end

local function ba_target_from_desync(desync)
	if not desync then return nil, nil end

	local host = desync.track and desync.track.hostname
	local target, kind = ba_normalize_target(host)
	if target then return target, kind end

	local ip
	if type(host_ip) == "function" then
		local ok, value = pcall(host_ip, desync)
		if ok then ip = value end
	elseif desync.target and type(ntop) == "function" then
		if desync.target.ip then
			ip = ntop(desync.target.ip)
		elseif desync.target.ip6 then
			ip = ntop(desync.target.ip6)
		end
	end
	return ba_normalize_target(ip)
end

local function ba_key(kind, target)
	return tostring(kind) .. ":" .. tostring(target)
end

local function ba_record(kind, target)
	local key = ba_key(kind, target)
	local rec = BLOCKED_AUTO_STATE[key]
	if not rec then
		rec = {
			kind = kind,
			target = target,
			seen = 0,
			failures = 0,
			weak_failures = 0,
			strong_failures = 0,
			successes = 0,
			score = 0,
			status = "SEEN",
			first_seen = ba_now(),
			last_seen = 0,
			last_reason = "",
		}
		BLOCKED_AUTO_STATE[key] = rec
	end
	return rec
end

local ba_is_auto_excluded

local function ba_split_tab(line)
	local parts = {}
	line = tostring(line or "")
	local start = 1
	while true do
		local pos = line:find("\t", start, true)
		if not pos then
			table.insert(parts, line:sub(start))
			break
		end
		table.insert(parts, line:sub(start, pos - 1))
		start = pos + 1
	end
	return parts
end

local function ba_load_excludes(arg)
	if BLOCKED_AUTO_EXCLUDES_LOADED then return end
	BLOCKED_AUTO_EXCLUDES_LOADED = true

	local data = ba_read_all(ba_exclude_file(arg))
	for line in data:gmatch("[^\r\n]+") do
		local item = ba_trim(line:match("^([^#%s]+)") or "")
		if item ~= "" then
			local target, kind = ba_normalize_target(item)
			if target and kind == "host" then
				BLOCKED_AUTO_EXTERNAL_EXCLUDES[target] = true
			end
		end
	end
end

local function ba_parse_state_line(line, arg)
	local parts = ba_split_tab(line)
	if #parts < 11 then return end

	local target, kind = ba_normalize_target(parts[2])
	if not target or not kind then return end
	if parts[1] == "ip" or parts[1] == "host" then
		if kind ~= parts[1] then return end
		kind = parts[1]
	end
	if ba_is_auto_excluded(target, kind, arg) then
		BLOCKED_AUTO_NEEDS_SAVE = true
		return
	end
	local rec = ba_record(kind, target)
	rec.status = parts[3] or rec.status
	rec.score = tonumber(parts[4]) or rec.score
	rec.seen = tonumber(parts[5]) or rec.seen
	rec.failures = tonumber(parts[6]) or rec.failures
	rec.successes = tonumber(parts[7]) or rec.successes
	rec.first_seen = tonumber(parts[8]) or rec.first_seen
	rec.last_seen = tonumber(parts[9]) or rec.last_seen
	rec.last_reason = parts[10] or rec.last_reason
	rec.last_saved = tonumber(parts[11]) or rec.last_saved
	rec.weak_failures = tonumber(parts[12]) or rec.weak_failures or 0
	rec.strong_failures = tonumber(parts[13]) or rec.strong_failures or 0

	local base_reason = ba_blocked_base_reason(rec.last_reason)
	if #parts < 12 and (rec.failures or 0) > 0 and (rec.successes or 0) == 0 then
		if ba_is_weak_block_reason(base_reason) or base_reason == "SEEN" then
			rec.weak_failures = rec.failures or 0
			rec.strong_failures = 0
		end
	end

	local min_failures = tonumber(arg and (arg.min_failures or arg.blocked_min_failures)) or 2
	local threshold = tonumber(arg and (arg.blocked_score or arg.threshold_score)) or 4
	local weak_limited = (rec.weak_failures or 0) > 0 and (rec.strong_failures or 0) == 0
	if rec.status == "BLOCKED" and weak_limited and (rec.weak_failures or 0) < ba_weak_min_failures(arg) then
		rec.status = (rec.score or 0) > 0 and "SUSPECT" or "SEEN"
		rec.score = math.min(rec.score or 0, math.max(0, threshold - 1))
		rec.auto_migrated_weak = true
		BLOCKED_AUTO_NEEDS_SAVE = true
	elseif rec.status == "BLOCKED" and (rec.failures or 0) < min_failures and
		base_reason ~= "RST" and base_reason ~= "BLOCK_PAGE" and
		(rec.score or 0) <= threshold then
		rec.status = (rec.score or 0) > 0 and "SUSPECT" or "SEEN"
		rec.score = math.min(rec.score or 0, math.max(0, threshold - 1))
		rec.auto_migrated_weak = true
		BLOCKED_AUTO_NEEDS_SAVE = true
	end
end

local function ba_load_state(arg)
	local data = ba_read_all(ba_state_file(arg))
	for line in data:gmatch("[^\r\n]+") do
		if line ~= "" and not line:match("^#") then
			ba_parse_state_line(line, arg)
		end
	end
end

local function ba_load_list(path, kind, arg)
	local data = ba_read_all(path)
	for line in data:gmatch("[^\r\n]+") do
		local item = ba_trim(line:match("^([^#%s]+)") or "")
		if item ~= "" then
			local target, normalized_kind = ba_normalize_target(item)
			normalized_kind = normalized_kind or kind
			if target and normalized_kind == kind then
				if ba_is_auto_excluded(target, kind, arg) then
					BLOCKED_AUTO_NEEDS_SAVE = true
				else
					local rec = ba_record(kind, target)
					if not rec.auto_migrated_weak then
						rec.status = "BLOCKED"
						if rec.score < 4 then rec.score = 4 end
					end
				end
			end
		end
	end
end

local function ba_load_lists(arg)
	if BLOCKED_AUTO_LISTS_LOADED then return end
	BLOCKED_AUTO_LISTS_LOADED = true
	ba_load_excludes(arg)
	ba_load_state(arg)
	ba_load_list(ba_host_file(arg), "host", arg)
	ba_load_list(ba_ip_file(arg), "ip", arg)
end

local function ba_is_noisy_seen(target, kind)
	if kind == "ip" then return true end
	for _, suffix in ipairs(BA_NOISY_SEEN_SUFFIXES) do
		if ba_domain_has_suffix(target, suffix) then
			return true
		end
	end
	return false
end

ba_is_auto_excluded = function(target, kind, arg)
	if kind ~= "host" then return false end
	ba_load_excludes(arg)
	for suffix in pairs(BLOCKED_AUTO_EXTERNAL_EXCLUDES) do
		if ba_domain_has_suffix(target, suffix) then return true end
	end
	for _, suffix in ipairs(BA_AUTO_EXCLUDE_SUFFIXES) do
		if ba_domain_has_suffix(target, suffix) then
			return true
		end
	end
	return false
end

local BA_REASON_SCORE = {
	RST = 4,
	TLS_ALERT = 3,
	BLOCK_PAGE = 5,
	HTTP_ERROR = 1,
	HTTP_REDIRECT = 3,
	TCP_STALL = 1,
	UDP_SILENT = 1,
	FAILURE_DETECTOR = 3,
	COMBINED_FAILURE = 3,
	STANDARD_FAILURE = 3,
}

local BA_STRONG_REASONS = {
	RST = true,
	BLOCK_PAGE = true,
}

local function ba_base_reason(reason)
	return ba_blocked_base_reason(reason)
end

local function ba_reason_score(reason)
	return BA_REASON_SCORE[reason] or BA_REASON_SCORE[ba_base_reason(reason)] or 1
end

local function ba_threshold(arg)
	return tonumber(arg and (arg.blocked_score or arg.threshold_score)) or 4
end

local function ba_min_failures(arg)
	return tonumber(arg and (arg.min_failures or arg.blocked_min_failures)) or 2
end

local function ba_min_seen(arg)
	return tonumber(arg and (arg.min_seen or arg.blocked_min_seen)) or 0
end

local function ba_recover_score(arg)
	return tonumber(arg and arg.recover_score) or 0
end

local function ba_recover_successes(arg)
	return tonumber(arg and (arg.recover_successes or arg.recovery_successes)) or 0
end

local function ba_max_score(arg)
	return tonumber(arg and arg.max_score) or 10
end

local function ba_event_interval(arg)
	return tonumber(arg and arg.min_interval) or 3
end

local function ba_allow_ip(arg)
	return arg and (arg.allow_ip or arg.ip_enabled or arg.record_ip)
end

local function ba_should_track(target, kind, event, arg)
	if not target or not kind then return false end
	if not (arg and arg.allow_noise) and ba_is_auto_excluded(target, kind, arg) then return false end
	if kind == "ip" and not ba_allow_ip(arg) and event == "SEEN" then return false end
	if event == "SEEN" and ba_is_noisy_seen(target, kind) then return false end
	return true
end

local function ba_status_for_score(rec, arg)
	local strong_reason = BA_STRONG_REASONS[ba_base_reason(rec.last_reason)]
	local weak_limited = ((rec.weak_failures or 0) > 0 and (rec.strong_failures or 0) == 0) or
		ba_is_weak_block_reason(rec.last_reason)
	local enough_history = strong_reason or (
		(rec.failures or 0) >= ba_min_failures(arg) and
		(rec.seen or 0) >= ba_min_seen(arg) and
		(not weak_limited or (rec.weak_failures or 0) >= ba_weak_min_failures(arg))
	)
	if rec.score >= ba_threshold(arg) and enough_history then return "BLOCKED" end
	if rec.status == "BLOCKED" and rec.score > ba_recover_score(arg) and enough_history then return "BLOCKED" end
	if rec.score <= ba_recover_score(arg) and rec.status == "BLOCKED" then return "RECOVERED" end
	if rec.score > 0 then return "SUSPECT" end
	return "SEEN"
end

local function ba_sorted_records(kind, status)
	local out = {}
	for _, rec in pairs(BLOCKED_AUTO_STATE) do
		if rec.kind == kind and rec.status == status then
			table.insert(out, rec.target)
		end
	end
	table.sort(out)
	return out
end

local function ba_list_text(kind, status)
	local items = ba_sorted_records(kind, status)
	local text = ""
	for _, item in ipairs(items) do
		text = text .. item .. "\r\n"
	end
	return text
end

local function ba_save_state(arg)
	local now = ba_now()
	if now > 0 and BLOCKED_AUTO_SAVE_LAST > 0 and now - BLOCKED_AUTO_SAVE_LAST < 2 then
		return
	end
	BLOCKED_AUTO_SAVE_LAST = now

	ba_write_all(ba_host_file(arg), ba_list_text("host", "BLOCKED"))
	ba_write_all(ba_ip_file(arg), ba_list_text("ip", "BLOCKED"))

	local lines = "# kind\ttarget\tstatus\tscore\tseen\tfailures\tsuccesses\tfirst_seen\tlast_seen\tlast_reason\tlast_saved\tweak_failures\tstrong_failures\r\n"
	local keys = {}
	for key in pairs(BLOCKED_AUTO_STATE) do table.insert(keys, key) end
	table.sort(keys)
	for _, key in ipairs(keys) do
		local rec = BLOCKED_AUTO_STATE[key]
		lines = lines .. table.concat({
			rec.kind,
			rec.target,
			rec.status,
			tostring(rec.score or 0),
			tostring(rec.seen or 0),
			tostring(rec.failures or 0),
			tostring(rec.successes or 0),
			tostring(rec.first_seen or 0),
			tostring(rec.last_seen or 0),
			tostring(rec.last_reason or ""),
			tostring(now),
			tostring(rec.weak_failures or 0),
			tostring(rec.strong_failures or 0),
		}, "\t") .. "\r\n"
	end
	ba_write_all(ba_state_file(arg), lines)

	local recovered = ba_list_text("host", "RECOVERED") .. ba_list_text("ip", "RECOVERED")
	ba_write_all(ba_recovered_file(arg), recovered)
end

local function ba_apply_event(target, kind, event, reason, arg)
	arg = arg or {}
	ba_load_lists(arg)
	local needs_save = BLOCKED_AUTO_NEEDS_SAVE
	BLOCKED_AUTO_NEEDS_SAVE = false
	if not ba_should_track(target, kind, event, arg) then
		if needs_save then ba_save_state(arg) end
		return false
	end

	local key = ba_key(kind, target) .. ":" .. event .. ":" .. tostring(reason or "")
	local now = ba_now()
	local last = BLOCKED_AUTO_LAST_EVENT[key] or 0
	if now > 0 and last > 0 and now - last < ba_event_interval(arg) then
		return false
	end
	BLOCKED_AUTO_LAST_EVENT[key] = now

	local rec = ba_record(kind, target)
	rec.seen = (rec.seen or 0) + 1
	rec.last_seen = now

	if event == "FAILURE" then
		local delta = ba_reason_score(reason)
		rec.failures = (rec.failures or 0) + 1
		if ba_is_weak_block_reason(reason) then
			rec.weak_failures = (rec.weak_failures or 0) + 1
		else
			rec.strong_failures = (rec.strong_failures or 0) + 1
		end
		rec.recovery_successes = 0
		rec.score = math.min(ba_max_score(arg), (rec.score or 0) + delta)
		rec.last_reason = reason or "FAILURE"
	elseif event == "SUCCESS" then
		local delta = tonumber(arg.success_score) or 1
		rec.successes = (rec.successes or 0) + 1
		rec.recovery_successes = (rec.recovery_successes or 0) + 1
		rec.score = math.max(0, (rec.score or 0) - delta)
		if rec.score == 0 then
			rec.weak_failures = 0
			rec.strong_failures = 0
		elseif (rec.weak_failures or 0) > 0 then
			rec.weak_failures = math.max(0, (rec.weak_failures or 0) - 1)
		end
		rec.last_reason = reason or "SUCCESS"
	else
		rec.last_reason = "SEEN"
	end

	local old_status = rec.status
	rec.status = ba_status_for_score(rec, arg)
	if event == "SUCCESS" and old_status == "BLOCKED" and ba_recover_successes(arg) > 0 and
		(rec.recovery_successes or 0) >= ba_recover_successes(arg) then
		rec.score = ba_recover_score(arg)
		rec.status = "RECOVERED"
	end

	if old_status ~= rec.status or event ~= "SEEN" or
		(arg.log_seen and event == "SEEN" and (rec.seen or 0) == 1) or
		arg.log_blocked_seen then
		ba_log(arg, target, rec.status .. "/" .. event, "reason=" .. tostring(rec.last_reason) .. " score=" .. tostring(rec.score))
	end

	if old_status ~= rec.status or event == "FAILURE" or event == "SUCCESS" or needs_save then
		ba_save_state(arg)
	end
	return true
end

function blocked_auto_record(desync, reason)
	local target, kind = ba_target_from_desync(desync)
	if not target then return false end
	return ba_apply_event(target, kind, "FAILURE", reason or "FAILURE", desync and desync.arg or nil)
end

local function ba_conn_record(desync)
	if not desync or not desync.track then return nil end
	desync.track.lua_state = desync.track.lua_state or {}
	desync.track.lua_state.blocked_auto = desync.track.lua_state.blocked_auto or {}
	return desync.track.lua_state.blocked_auto
end

local function ba_band(a, b)
	if type(bitand) == "function" then return bitand(a, b) end
	local result, bit = 0, 1
	a, b = tonumber(a) or 0, tonumber(b) or 0
	while a > 0 and b > 0 do
		if a % 2 == 1 and b % 2 == 1 then result = result + bit end
		a = math.floor(a / 2)
		b = math.floor(b / 2)
		bit = bit * 2
	end
	return result
end

local function ba_has_tcp_rst(desync)
	if not desync or not desync.dis or not desync.dis.tcp or desync.outgoing then return false end
	return ba_band(desync.dis.tcp.th_flags or 0, TH_RST or 4) ~= 0
end

local function ba_is_tls_alert(payload)
	return payload and #payload >= 7 and payload:byte(1) == 0x15 and payload:byte(2) == 0x03
end

local function ba_http_status(payload)
	if not payload or #payload < 12 then return nil end
	return tonumber(payload:match("^HTTP/1%.[01] (%d%d%d)"))
end

local BA_BLOCK_PAGE_MARKERS = {
	"eais.rkn.gov.ru",
	"vigruzki.rkn.gov.ru",
	"blocklist.rkn.gov.ru",
	"rkn.gov.ru",
	"reestr.rublacklist.net",
	"zapret-info.gov.ru",
	"blocked.beeline.ru",
	"blocked.tele2.ru",
	"warning.rt.ru",
	"block.mts.ru",
	"zapret.mts.ru",
	"blocked by",
	"access blocked",
	"website blocked",
	"content blocked",
	"resource blocked",
	"access denied",
	"restricted content",
}

local function ba_has_block_page(payload)
	if not payload or #payload < 40 then return false end
	local s = ba_lower(payload:sub(1, math.min(#payload, 16384)))
	for _, marker in ipairs(BA_BLOCK_PAGE_MARKERS) do
		if s:find(marker, 1, true) then return true end
	end
	return false
end

local function ba_success_reason(desync, crec)
	if not desync or not desync.dis then return nil end
	crec = crec or {}
	if desync.dis.tcp and not desync.outgoing then
		local payload = desync.dis.payload
		if payload and #payload > 0 then
			crec.tcp_in_payload = (crec.tcp_in_payload or 0) + 1
			local code = ba_http_status(payload)
			if code and code >= 200 and code < 400 then return "HTTP_" .. tostring(code) end
			if #payload >= 32 and not ba_is_tls_alert(payload) and not ba_has_block_page(payload) then return "IN_DATA" end
		end
	elseif desync.dis.udp and not desync.outgoing then
		crec.udp_in = (crec.udp_in or 0) + 1
		if crec.udp_in >= 2 then return "UDP_IN" end
	end
	return nil
end

local function ba_failure_reason(desync, crec)
	if not desync or not desync.dis then return nil end
	crec = crec or {}

	if ba_has_tcp_rst(desync) then return "RST" end

	if desync.dis.tcp then
		local payload = desync.dis.payload
		if desync.outgoing then
			if payload and #payload > 0 then
				crec.tcp_out_payload = (crec.tcp_out_payload or 0) + 1
			end
			local stall_out = tonumber(desync.arg and desync.arg.blocked_stall_out) or 4
			local stall_in = tonumber(desync.arg and desync.arg.blocked_stall_in) or 0
			if (crec.tcp_out_payload or 0) >= stall_out and (crec.tcp_in_payload or 0) <= stall_in and not crec.blocked_auto_stall then
				crec.blocked_auto_stall = true
				return "TCP_STALL"
			end
		else
			if payload and #payload > 0 then
				crec.tcp_in_payload = (crec.tcp_in_payload or 0) + 1
				if ba_is_tls_alert(payload) then return "TLS_ALERT" end
				if ba_has_block_page(payload) then return "BLOCK_PAGE" end
				local code = ba_http_status(payload)
				if code and code >= 400 then return "HTTP_ERROR" end
			end
		end
	elseif desync.dis.udp then
		if desync.outgoing then
			crec.udp_out = (crec.udp_out or 0) + 1
			local udp_out = tonumber(desync.arg and desync.arg.blocked_udp_out) or 5
			local udp_in = tonumber(desync.arg and desync.arg.blocked_udp_in) or 0
			if (crec.udp_out or 0) >= udp_out and (crec.udp_in or 0) <= udp_in and not crec.blocked_auto_udp then
				crec.blocked_auto_udp = true
				return "UDP_SILENT"
			end
		else
			crec.udp_in = (crec.udp_in or 0) + 1
		end
	end
	return nil
end

function blocked_auto_probe(ctx, desync)
	local crec = ba_conn_record(desync)
	local target, kind = ba_target_from_desync(desync)
	if target then
		ba_apply_event(target, kind, "SEEN", "SEEN", desync and desync.arg or nil)
	end

	local success = ba_success_reason(desync, crec)
	if success and target then
		ba_apply_event(target, kind, "SUCCESS", success, desync and desync.arg or nil)
	end

	local failure = ba_failure_reason(desync, crec)
	if failure and target then
		ba_apply_event(target, kind, "FAILURE", failure, desync and desync.arg or nil)
	end
	return VERDICT_PASS
end

local function ba_recovery_probe_interval(arg)
	return tonumber(arg and (arg.recover_test_interval or arg.recovery_probe_interval or arg.probe_interval)) or 3600
end

local function ba_recovery_probe_packet(desync)
	if not desync or not desync.outgoing or not desync.dis then return false end
	if desync.dis.tcp then
		return desync.dis.payload and #desync.dis.payload > 0
	end
	return desync.dis.udp ~= nil
end

local function ba_recovery_probe_clear_plan(ctx, desync)
	if type(orchestrate) == "function" and type(plan_clear) == "function" then
		orchestrate(ctx, desync)
		plan_clear(desync)
	end
end

function blocked_auto_recovery_probe(ctx, desync)
	local crec = ba_conn_record(desync)
	local target, kind = ba_target_from_desync(desync)
	if not target or not kind then return VERDICT_PASS end

	local arg = desync and desync.arg or nil
	ba_load_lists(arg)
	local rec = ba_record(kind, target)

	if crec and crec.recovery_probe then
		ba_recovery_probe_clear_plan(ctx, desync)
		local success = ba_success_reason(desync, crec)
		if success then
			ba_apply_event(target, kind, "SUCCESS", "RECOVERY_" .. success, arg)
			crec.recovery_probe_done = true
		end
		local failure = ba_failure_reason(desync, crec)
		if failure then
			ba_apply_event(target, kind, "FAILURE", "RECOVERY_" .. failure, arg)
			crec.recovery_probe_done = true
		end
		return VERDICT_PASS
	end

	if rec.status ~= "BLOCKED" then
		ba_recovery_probe_clear_plan(ctx, desync)
		return blocked_auto_probe(ctx, desync)
	end

	if not ba_recovery_probe_packet(desync) then
		return VERDICT_PASS
	end

	local key = ba_key(kind, target)
	local now = ba_now()
	local last = BLOCKED_AUTO_RECOVERY_LAST_PROBE[key] or 0
	local interval = ba_recovery_probe_interval(arg)
	if now > 0 and last > 0 and now - last < interval then
		return VERDICT_PASS
	end

	BLOCKED_AUTO_RECOVERY_LAST_PROBE[key] = now
	if crec then
		crec.recovery_probe = true
	end
	ba_log(arg, target, "RECOVERY_PROBE", "interval=" .. tostring(interval))
	ba_recovery_probe_clear_plan(ctx, desync)
	return VERDICT_PASS
end

function blocked_collect(ctx, desync)
	return blocked_auto_probe(ctx, desync)
end

local function ba_call_detector(fn, desync, crec)
	if type(fn) ~= "function" then return false end
	local ok, result = pcall(fn, desync, crec)
	if not ok then
		ba_log_dlog("base detector error: " .. tostring(result))
		return false
	end
	return result and true or false
end

function blocked_auto_failure_detector(desync, crec)
	local base = BLOCKED_AUTO_ORIGINAL_COMBINED_FAILURE_DETECTOR or
		BLOCKED_AUTO_ORIGINAL_STANDARD_FAILURE_DETECTOR or
		(type(combined_failure_detector) == "function" and combined_failure_detector) or
		(type(standard_failure_detector) == "function" and standard_failure_detector)

	local failed = ba_call_detector(base, desync, crec)
	if failed then
		blocked_auto_record(desync, "FAILURE_DETECTOR")
		return true
	end

	local reason = ba_failure_reason(desync, crec)
	if reason then
		blocked_auto_record(desync, reason)
		return true
	end
	return false
end

function blocked_auto_combined_failure_detector(desync, crec)
	local base = BLOCKED_AUTO_ORIGINAL_COMBINED_FAILURE_DETECTOR or combined_failure_detector
	local failed = ba_call_detector(base, desync, crec)
	if failed then blocked_auto_record(desync, "COMBINED_FAILURE") end
	return failed
end

function blocked_auto_standard_failure_detector(desync, crec)
	local base = BLOCKED_AUTO_ORIGINAL_STANDARD_FAILURE_DETECTOR or standard_failure_detector
	local failed = ba_call_detector(base, desync, crec)
	if failed then blocked_auto_record(desync, "STANDARD_FAILURE") end
	return failed
end

function blocked_auto_install()
	if type(combined_failure_detector) == "function" and not BLOCKED_AUTO_COMBINED_WRAPPED then
		BLOCKED_AUTO_ORIGINAL_COMBINED_FAILURE_DETECTOR = combined_failure_detector
		combined_failure_detector = function(desync, crec)
			local failed = BLOCKED_AUTO_ORIGINAL_COMBINED_FAILURE_DETECTOR(desync, crec)
			if failed then blocked_auto_record(desync, "COMBINED_FAILURE") end
			return failed
		end
		BLOCKED_AUTO_COMBINED_WRAPPED = true
	elseif type(standard_failure_detector) == "function" and not BLOCKED_AUTO_STANDARD_WRAPPED then
		BLOCKED_AUTO_ORIGINAL_STANDARD_FAILURE_DETECTOR = standard_failure_detector
		standard_failure_detector = function(desync, crec)
			local failed = BLOCKED_AUTO_ORIGINAL_STANDARD_FAILURE_DETECTOR(desync, crec)
			if failed then blocked_auto_record(desync, "STANDARD_FAILURE") end
			return failed
		end
		BLOCKED_AUTO_STANDARD_WRAPPED = true
	end
end

blocked_auto_install()
local ba_boot_log = "tools/blocked-auto-boot.log"
if type(writeable_file_name) == "function" then
	local ok, resolved = pcall(writeable_file_name, ba_boot_log)
	if ok and resolved and #resolved > 0 then ba_boot_log = resolved end
end
ba_append_line(ba_boot_log, tostring(ba_now()) .. " loaded v" .. BLOCKED_AUTO_VERSION)
ba_log_dlog("loaded v" .. BLOCKED_AUTO_VERSION)
