--[[
    Mega Circular - Independent HTTP/TLS Learning

    HTTP и TLS обучаются независимо.
    Каждый домен имеет раздельное состояние для HTTP и TLS.

    Режимы для каждого домена+протокола:
    - LEARNING: пробуем стратегии, считаем успехи
    - WORKING: используем лучшие из файла
    - AUTO_ROTATE: для проблемных доменов в WORKING режиме
]]

-- Проверяем что стратегии загружены
if not TLS_STRATEGIES or #TLS_STRATEGIES == 0 then
    error("mega_circular: TLS_STRATEGIES not loaded!")
end
if not HTTP_STRATEGIES or #HTTP_STRATEGIES == 0 then
    error("mega_circular: HTTP_STRATEGIES not loaded!")
end

DLOG("mega_circular: loaded " .. #TLS_STRATEGIES .. " TLS, " .. #HTTP_STRATEGIES .. " HTTP strategies")

-- ============== НАСТРОЙКИ ==============
-- Используем путь из base_path.lua (генерируется config_builder.py) или дефолтный
local BASE_PATH = ORCHESTRA_BASE_PATH or ""
DLOG("mega_circular: BASE_PATH = " .. BASE_PATH)

local CONFIG = {
    -- Раздельные файлы для TLS и HTTP
    tls_learned_file = BASE_PATH .. "learned_tls.txt",
    http_learned_file = BASE_PATH .. "learned_http.txt",

    -- Сколько раз пробовать каждую стратегию при обучении
    tests_per_strategy_tls = 2,  -- TLS: 2 теста (было 3)
    tests_per_strategy_http = 1, -- HTTP: 1 тест (быстрее обучение)

    -- Сколько лучших стратегий сохранять на домен
    top_strategies_count = 5,

    -- Порог неудач для переобучения домена (подряд)
    relearn_threshold = 15,

    -- Cooldown после смены стратегии (игнорировать фейлы N соединений)
    -- Даёт стратегии время показать себя на нескольких соединениях
    cooldown_connections_tls = 2,   -- TLS: 2 соединения cooldown
    cooldown_connections_http = 4,  -- HTTP: 4 соединения cooldown (HTTP медленнее)

    -- AUTO_ROTATE домены в WORKING режиме (для TLS)
    auto_rotate_tls = {
        ["googlevideo.com"] = 5,
    },
    -- AUTO_ROTATE для HTTP
    auto_rotate_http = {
        ["porno365.plus"] = 2,
        ["porno365.sexy"] = 2,
    },

    -- Для HTTP: любой ответ сервера = успех (DPI не заблокировал)
    -- Это важно потому что HTTP сайты часто редиректят на HTTPS
    http_any_reply_is_success = true,

    -- Известные работающие стратегии (пропускают обучение)
    -- Формат: domain = {strategy_ids...}
    -- Номера стратегий:
    --   #40-49: fakeddisorder pos=host+1
    --   #80-84: http_seqovl_host, http_triple_seqovl, http_mgts_combo
    --   #92: http_hostcase HoSt
    --   #93: http_methodeol
    --   #99-101: http_garbage_prefix
    --   #108, #117: http_methodeol_safe
    --   #113-114: http_simple_bypass HoSt
    known_good_http = {
        ["porno365.plus"] = {
            83,                                       -- http_mgts_combo (лучшая!)
            92, 93,                                   -- hostcase HoSt, methodeol
            108, 117,                                 -- methodeol_safe
            113, 114,                                 -- simple_bypass HoSt
            99, 100, 101,                             -- garbage_prefix
            80, 81, 82, 84,                           -- seqovl_host, triple_seqovl
            40, 41, 42, 43, 44,                       -- fakeddisorder host (часть)
        },
        ["porno365.sexy"] = {
            83,                                       -- http_mgts_combo (лучшая!)
            92, 93,
            108, 117,
            113, 114,
            99, 100, 101,
            80, 81, 82, 84,
            40, 41, 42, 43, 44,
        },
    },
}

-- ============== СОСТОЯНИЕ ==============
-- Раздельные данные для TLS и HTTP
local tls_learned = {}   -- {domain: {strategies: [1,2,3], ...}}
local http_learned = {}
local tls_state = {}     -- runtime состояние
local http_state = {}

-- ============== РАБОТА С ФАЙЛОМ ==============

-- Загрузить данные из файла (универсальная)
local function load_learned_file(filepath, strategies_array, proto_name)
    local f = io.open(filepath, "r")
    if not f then
        DLOG("mega_circular: no " .. proto_name .. " learned file")
        return {}
    end

    local data = {}
    local max_strat = #strategies_array
    for line in f:lines() do
        local domain, strats_str = line:match("^([^:]+):(.+)$")
        if domain and strats_str then
            local strategies = {}
            for num in strats_str:gmatch("(%d+)") do
                local n = tonumber(num)
                if n and n >= 1 and n <= max_strat then
                    table.insert(strategies, n)
                end
            end
            if #strategies > 0 then
                data[domain] = {strategies = strategies}
                DLOG("mega_circular: " .. proto_name .. " loaded " .. domain)
            end
        end
    end
    f:close()
    return data
end

-- Сохранить данные в файл (универсальная)
local function save_learned_file(filepath, learned_data, proto_name)
    local f = io.open(filepath, "w")
    if not f then
        DLOG("mega_circular: ERROR cannot write " .. proto_name .. " file!")
        return false
    end

    for domain, data in pairs(learned_data) do
        if data.strategies and #data.strategies > 0 then
            f:write(domain .. ":" .. table.concat(data.strategies, ",") .. "\n")
        end
    end
    f:close()
    DLOG("mega_circular: saved " .. proto_name .. " data")
    return true
end

-- ============== ИНИЦИАЛИЗАЦИЯ ==============

-- Загружаем при старте
tls_learned = load_learned_file(CONFIG.tls_learned_file, TLS_STRATEGIES, "TLS")
http_learned = load_learned_file(CONFIG.http_learned_file, HTTP_STRATEGIES, "HTTP")

-- Получить или создать состояние хоста для протокола
local function get_host_state(hostname, is_http)
    local state_table = is_http and http_state or tls_state
    local learned_table = is_http and http_learned or tls_learned
    local strategies_array = is_http and HTTP_STRATEGIES or TLS_STRATEGIES
    local proto = is_http and "HTTP" or "TLS"

    if not state_table[hostname] then
        local learned = learned_table[hostname]

        -- Проверяем known_good для HTTP
        local known_good = is_http and CONFIG.known_good_http and CONFIG.known_good_http[hostname]

        if known_good and #known_good > 0 then
            -- Используем известные хорошие стратегии (пропускаем обучение)
            state_table[hostname] = {
                mode = "WORKING",
                strategies = known_good,
                current_index = 1,
                successes = 0,
                consecutive_fails = 0,
                connections = 0,
                known_good = true,  -- флаг что это из known_good
                cooldown_remaining = 0,  -- cooldown после смены стратегии
            }
            DLOG("mega_circular: " .. proto .. " " .. hostname .. " KNOWN_GOOD [" .. table.concat(known_good, ",") .. "]")
        elseif learned and learned.strategies and #learned.strategies > 0 then
            state_table[hostname] = {
                mode = "WORKING",
                strategies = learned.strategies,
                current_index = 1,
                successes = 0,
                consecutive_fails = 0,
                connections = 0,
                cooldown_remaining = 0,  -- cooldown после смены стратегии
            }
            DLOG("mega_circular: " .. proto .. " " .. hostname .. " WORKING")
        else
            state_table[hostname] = {
                mode = "LEARNING",
                current_strategy = 1,
                tests_done = 0,
                strategy_scores = {},
                strategies = {},
                current_index = 1,
                successes = 0,
                consecutive_fails = 0,
                connections = 0,
                cooldown_remaining = 0,  -- cooldown после смены стратегии
            }
            for i = 1, #strategies_array do
                state_table[hostname].strategy_scores[i] = 0
            end
            DLOG("mega_circular: " .. proto .. " " .. hostname .. " LEARNING")
        end
    end
    return state_table[hostname]
end

-- ============== ОБУЧЕНИЕ ==============

-- Завершить обучение для домена
local function finish_learning(hostname, hrec, is_http)
    local proto = is_http and "HTTP" or "TLS"
    local learned_table = is_http and http_learned or tls_learned
    local filepath = is_http and CONFIG.http_learned_file or CONFIG.tls_learned_file

    DLOG("mega_circular: " .. proto .. " " .. hostname .. " LEARNING complete!")

    -- Сортируем по успехам
    local sorted = {}
    for i, score in pairs(hrec.strategy_scores) do
        table.insert(sorted, {id = i, score = score})
    end
    table.sort(sorted, function(a, b) return a.score > b.score end)

    -- Берём топ
    hrec.strategies = {}
    for i = 1, math.min(CONFIG.top_strategies_count, #sorted) do
        if sorted[i].score > 0 then
            table.insert(hrec.strategies, sorted[i].id)
            DLOG("mega_circular: " .. proto .. " " .. hostname .. " TOP " .. i ..
                 ": strat " .. sorted[i].id .. " (score=" .. sorted[i].score .. ")")
        end
    end

    -- Если ничего не нашли - первые 5
    if #hrec.strategies == 0 then
        DLOG("mega_circular: " .. proto .. " " .. hostname .. " no success, using defaults")
        for i = 1, CONFIG.top_strategies_count do
            table.insert(hrec.strategies, i)
        end
    end

    -- Сохраняем в глобальные данные и файл
    learned_table[hostname] = {strategies = hrec.strategies}
    save_learned_file(filepath, learned_table, proto)

    -- Persist preload for strategy-stats so orchestrator can apply it on restart
    if persist_add_preload then
        -- Pick top strategy to preload (first in list)
        local top = hrec.strategies[1]
        if top then
            local ptype = is_http and "http" or "tls"
            persist_add_preload(hostname, top, ptype)
        end
    end

    -- Переключаемся в WORKING
    hrec.mode = "WORKING"
    hrec.current_index = 1
    hrec.consecutive_fails = 0
    hrec.successes = 0

    DLOG("mega_circular: " .. proto .. " " .. hostname .. " -> WORKING")
end

-- Обработать результат в режиме обучения
local function process_learning(hostname, hrec, success, is_http)
    local strategies_array = is_http and HTTP_STRATEGIES or TLS_STRATEGIES
    local tests_needed = is_http and CONFIG.tests_per_strategy_http or CONFIG.tests_per_strategy_tls

    if success then
        hrec.strategy_scores[hrec.current_strategy] =
            (hrec.strategy_scores[hrec.current_strategy] or 0) + 1
    end

    hrec.tests_done = hrec.tests_done + 1

    -- Переход к следующей стратегии
    if hrec.tests_done >= tests_needed then
        hrec.current_strategy = hrec.current_strategy + 1
        hrec.tests_done = 0

        -- Проверяем завершение
        if hrec.current_strategy > #strategies_array then
            finish_learning(hostname, hrec, is_http)
        end
    end
end

-- ============== РАБОЧИЙ РЕЖИМ ==============

-- Переобучить домен
local function trigger_relearn(hostname, hrec, is_http)
    local proto = is_http and "HTTP" or "TLS"
    local learned_table = is_http and http_learned or tls_learned
    local filepath = is_http and CONFIG.http_learned_file or CONFIG.tls_learned_file
    local strategies_array = is_http and HTTP_STRATEGIES or TLS_STRATEGIES

    DLOG("mega_circular: " .. proto .. " " .. hostname .. " RELEARNING!")

    -- Удаляем из сохранённых данных
    learned_table[hostname] = nil
    save_learned_file(filepath, learned_table, proto)
    -- Remove persisted preload so it can be re-learned
    if persist_remove_preload then
        persist_remove_preload(hostname)
    end

    -- Сбрасываем в LEARNING режим
    hrec.mode = "LEARNING"
    hrec.current_strategy = 1
    hrec.tests_done = 0
    hrec.strategy_scores = {}
    for i = 1, #strategies_array do
        hrec.strategy_scores[i] = 0
    end
    hrec.consecutive_fails = 0
    hrec.successes = 0
end

-- Обработать результат в рабочем режиме
local function process_working(hostname, hrec, success, is_http)
    local proto = is_http and "HTTP" or "TLS"
    local cooldown_needed = is_http and CONFIG.cooldown_connections_http or CONFIG.cooldown_connections_tls

    -- Уменьшаем cooldown если активен
    if hrec.cooldown_remaining and hrec.cooldown_remaining > 0 then
        hrec.cooldown_remaining = hrec.cooldown_remaining - 1
        if not success then
            -- Во время cooldown игнорируем фейлы - даём стратегии шанс
            DLOG("mega_circular: " .. proto .. " " .. hostname .. " fail IGNORED (cooldown=" .. hrec.cooldown_remaining .. ")")
            return
        end
    end

    if success then
        hrec.consecutive_fails = 0
        hrec.successes = (hrec.successes or 0) + 1
        hrec.cooldown_remaining = 0  -- Успех сбрасывает cooldown
    else
        hrec.consecutive_fails = (hrec.consecutive_fails or 0) + 1
        hrec.successes = 0

        -- Пробуем следующую стратегию из топа
        hrec.current_index = (hrec.current_index % #hrec.strategies) + 1
        local strat_id = hrec.strategies[hrec.current_index]

        -- Устанавливаем cooldown после смены стратегии
        hrec.cooldown_remaining = cooldown_needed

        DLOG("mega_circular: " .. proto .. " " .. hostname .. " fail -> strat " .. strat_id ..
             " (cooldown=" .. cooldown_needed .. ")" ..
             (hrec.known_good and " (KNOWN_GOOD)" or ""))

        -- Проверяем нужно ли переобучение (не для known_good)
        if not hrec.known_good and hrec.consecutive_fails >= CONFIG.relearn_threshold then
            trigger_relearn(hostname, hrec, is_http)
        end
    end
end

-- ============== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==============

local function parse_args(arg_str)
    local args = {}
    if not arg_str then return args end
    for part in string.gmatch(arg_str, "[^:]+") do
        local key, value = string.match(part, "^([^=]+)=(.+)$")
        if key and value then
            args[key] = value
        elseif part ~= "" then
            args[part] = true
        end
    end
    return args
end

local function execute_strategy(ctx, desync, strat_info, is_http)
    local func_name = strat_info.func
    local func = _G[func_name]
    if not func then
        return VERDICT_PASS
    end

    local orig_arg = desync.arg
    desync.arg = parse_args(strat_info.args)
    desync.arg.payload = desync.arg.payload or (is_http and "http_req" or "tls_client_hello")
    desync.arg.dir = desync.arg.dir or "out"

    local ok, result = pcall(func, ctx, desync)
    desync.arg = orig_arg

    if not ok then
        return VERDICT_PASS
    end
    return result or VERDICT_PASS
end

local function get_hostname(desync)
    local full = host_or_ip(desync) or "unknown"
    return dissect_nld(full, 2) or full
end

-- Определить протокол по payload
local function is_http_payload(desync)
    local payload = desync.l7payload
    return payload == "http_req" or payload == "http_reply"
end

-- Детектор для HTTP редиректоров: успех = получили http_reply
local function redirector_success_detector(desync, crec)
    -- Если видим http_reply от сервера - успех (включая 301/302)
    if crec and crec.http_reply_seen then
        return true
    end
    -- Проверяем incoming payload
    if desync.l7payload == "http_reply" then
        return true
    end
    return false
end

-- ============== ГЛАВНАЯ ФУНКЦИЯ ==============

function mega_circular(ctx, desync)
    orchestrate(ctx, desync)

    if not desync.track then
        return VERDICT_PASS
    end

    local hostname = get_hostname(desync)
    local is_http = is_http_payload(desync)
    local proto = is_http and "HTTP" or "TLS"
    local strategies_array = is_http and HTTP_STRATEGIES or TLS_STRATEGIES
    local auto_rotate_table = is_http and CONFIG.auto_rotate_http or CONFIG.auto_rotate_tls

    local hrec = get_host_state(hostname, is_http)
    local crec = automate_conn_record(desync)

    -- Определяем стратегию
    local strategy_id
    local auto_rotate = auto_rotate_table[hostname]

    if hrec.mode == "LEARNING" then
        strategy_id = hrec.current_strategy

    elseif auto_rotate then
        hrec.connections = (hrec.connections or 0) + 1
        if hrec.connections >= auto_rotate then
            hrec.current_index = (hrec.current_index % #hrec.strategies) + 1
            hrec.connections = 0
            DLOG("mega_circular: " .. proto .. " " .. hostname .. " ROTATE -> " ..
                 hrec.strategies[hrec.current_index])
        end
        strategy_id = hrec.strategies[hrec.current_index]

    else
        strategy_id = hrec.strategies[hrec.current_index]
    end

    -- Детекция успеха/неудачи
    local failure
    if is_http and CONFIG.http_any_reply_is_success then
        -- Для HTTP: любой ответ сервера = успех (DPI не заблокировал)
        local got_reply = redirector_success_detector(desync, crec)
        failure = not got_reply and standard_failure_detector(desync, crec, desync.arg or {})
    else
        failure = standard_failure_detector(desync, crec, desync.arg or {})
    end

    -- Обрабатываем результат
    if hrec.mode == "LEARNING" then
        process_learning(hostname, hrec, not failure, is_http)
    elseif not auto_rotate then
        process_working(hostname, hrec, not failure, is_http)
    end

    -- Выполняем стратегию
    if not direction_check(desync) or not payload_check(desync) then
        return VERDICT_PASS
    end

    local strat = strategies_array[strategy_id]
    if strat then
        DLOG("mega_circular: " .. proto .. " [" .. hrec.mode .. "] " .. hostname ..
             " strat " .. strategy_id .. " (" .. strat.func .. ")")
        return execute_strategy(ctx, desync, strat, is_http)
    end

    return VERDICT_PASS
end

DLOG("mega_circular v7 (HTTP/TLS independent, cooldown after strategy switch) loaded")

