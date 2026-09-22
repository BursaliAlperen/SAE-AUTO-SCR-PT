-- ScriptVault — Steal an Egg 6.2 modular profile
-- Thin orchestrator: config / runtime / safety / UI / core are separated.
-- The core remains self-contained for compatibility with executor loadstring environments.

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
        function()
            if type(game.HttpGet) == "function" then return game:HttpGet(url) end
        end,
        function()
            if type(game.HttpGetAsync) == "function" then return game:HttpGetAsync(url) end
        end,
        function()
            local req = rawget(_G,"request") or rawget(_G,"http_request")
            if type(req) == "function" then
                local r = req({Url=url,Method="GET"})
                if type(r)=="table" then return r.Body or r.body end
            end
        end,
        function()
            local syn = rawget(_G,"syn")
            if type(syn)=="table" and type(syn.request)=="function" then
                local r=syn.request({Url=url,Method="GET"})
                if type(r)=="table" then return r.Body or r.body end
            end
        end,
    }
    for _,attempt in ipairs(attempts) do
        local ok, body = pcall(attempt)
        if ok and type(body)=="string" and #body>0 then return body end
    end
    return nil, "HTTP request failed: "..path
end

local function loadModule(path)
    if not current() then return nil, "profile superseded" end
    local source,err=httpGet(path)
    if not source then return nil,err end
    local chunk,compileErr=loadstring(source)
    if type(chunk)~="function" then return nil,compileErr end
    local ok,result=pcall(chunk)
    if not ok then return nil,result end
    return result
end

local Config, Runtime, Safety, UI
Config = loadModule("config.lua")
Runtime = loadModule("runtime.lua")
Safety = loadModule("safety.lua")
UI = loadModule("ui.lua")

if not Config then Config = {VERSION="6.2.0",REMOTE_COOLDOWN=0.35} end
if ENV then
    ENV.SV_SAE_CONFIG = Config
    ENV.SV_SAE_RUNTIME_MODULE = Runtime
    ENV.SV_SAE_SAFETY_MODULE = Safety
    ENV.SV_SAE_UI_MODULE = UI
end

local coreSource, err = httpGet("core.lua")
if not coreSource then
    warn("[ScriptVault SAE 6.2] "..tostring(err))
    return false, err
end

local core, compileErr = loadstring(coreSource)
if type(core) ~= "function" then
    warn("[ScriptVault SAE 6.2] Core compile error: "..tostring(compileErr))
    return false, compileErr
end

local ok, runtimeErr = pcall(core)
if not ok then
    warn("[ScriptVault SAE 6.2] Core runtime error: "..tostring(runtimeErr))
    return false, runtimeErr
end

return true
