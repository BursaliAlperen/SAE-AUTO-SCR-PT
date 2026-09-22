-- ScriptVault — Steal an Egg 6.4 modular profile
-- Runtime discovery + prompt-driven automation. No RemoteEvent/RemoteFunction calls.

local BASE = "https://raw.githubusercontent.com/BursaliAlperen/SAE-AUTO-SCR-PT/main/games/steal_an_egg/"
local ENV = (type(getgenv) == "function" and getgenv()) or _G
local TOKEN = tostring({})
if ENV then ENV.SV_SAE_PROFILE_TOKEN = TOKEN end

local function current()
    return not ENV or ENV.SV_SAE_PROFILE_TOKEN == TOKEN
end

local function httpGet(path)
    local url = BASE .. path .. "?v=" .. tostring(os.time())
    local attempts = {
        function() if type(game.HttpGet) == "function" then return game:HttpGet(url) end end,
        function() if type(game.HttpGetAsync) == "function" then return game:HttpGetAsync(url) end end,
        function()
            local req = rawget(_G, "request") or rawget(_G, "http_request")
            if type(req) == "function" then
                local r = req({Url=url, Method="GET"})
                if type(r) == "table" then return r.Body or r.body end
            end
        end,
        function()
            local syn = rawget(_G, "syn")
            if type(syn) == "table" and type(syn.request) == "function" then
                local r = syn.request({Url=url, Method="GET"})
                if type(r) == "table" then return r.Body or r.body end
            end
        end,
    }
    for _, attempt in ipairs(attempts) do
        local ok, body = pcall(attempt)
        if ok and type(body) == "string" and #body > 0 then return body end
    end
    return nil, "HTTP request failed: " .. path
end

local function loadModule(path)
    if not current() then return nil, "profile superseded" end
    local source, err = httpGet(path)
    if not source then return nil, err end
    local chunk, compileErr = loadstring(source)
    if type(chunk) ~= "function" then return nil, compileErr end
    local ok, result = pcall(chunk)
    if not ok then return nil, result end
    return result
end

local Config = loadModule("config.lua")
local Runtime = loadModule("runtime.lua")
local Safety = loadModule("safety.lua")
local UI = loadModule("ui.lua")
local Diagnostics = loadModule("diagnostics.lua")
local Automation = loadModule("automation.lua")

if not Config then Config = {VERSION="6.4.0", REMOTE_COOLDOWN=0.35, PRIMARY_PLACE_IDS={107778070777162}} end

if Diagnostics then
    local ok, report = pcall(function()
        local result = Diagnostics.scan()
        Diagnostics.publish(result)
        return result
    end)
    if ok and report and not Diagnostics.isTargetPlace(Config) then
        warn("[ScriptVault SAE 6.4] Wrong PlaceId: " .. tostring(report.placeId))
        return false, "Wrong Steal an Egg place"
    end
    if not ok then warn("[ScriptVault SAE 6.4] Diagnostics failed: " .. tostring(report)) end
end

if ENV then
    ENV.SV_SAE_CONFIG = Config
    ENV.SV_SAE_RUNTIME_MODULE = Runtime
    ENV.SV_SAE_SAFETY_MODULE = Safety
    ENV.SV_SAE_UI_MODULE = UI
    ENV.SV_SAE_DIAGNOSTICS_MODULE = Diagnostics
    ENV.SV_SAE_AUTOMATION_MODULE = Automation
end

if Runtime and type(Runtime.stopPrevious) == "function" then
    pcall(Runtime.stopPrevious)
end

local coreSource, err = httpGet("core.lua")
if not coreSource then
    warn("[ScriptVault SAE 6.4] " .. tostring(err))
    return false, err
end

local core, compileErr = loadstring(coreSource)
if type(core) ~= "function" then
    warn("[ScriptVault SAE 6.4] Core compile error: " .. tostring(compileErr))
    return false, compileErr
end

local ok, runtimeErr = pcall(core)
if not ok then
    warn("[ScriptVault SAE 6.4] Core runtime error: " .. tostring(runtimeErr))
    return false, runtimeErr
end

if Automation and type(Automation.start) == "function" and Config.AUTO_AUTOMATION then
    local started, automationErr = Automation.start()
    if not started then
        warn("[ScriptVault SAE 6.4] Automation: " .. tostring(automationErr))
    end
end

return true
