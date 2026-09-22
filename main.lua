-- ScriptVault direct loader
local SCRIPT_URL = "https://raw.githubusercontent.com/BursaliAlperen/SAE-AUTO-SCR-PT/main/script.lua"

local function httpGet(url)
    local ok, body = pcall(function()
        if game.HttpGet then
            return game:HttpGet(url)
        end
        return game:HttpGetAsync(url)
    end)
    if not ok or type(body) ~= "string" or #body == 0 then
        return nil, "HTTP request failed"
    end
    return body
end

local function run()
    local url = SCRIPT_URL .. "?v=" .. tostring(os.time())
    local source, err = httpGet(url)
    if not source then
        warn("[ScriptVault] " .. tostring(err))
        return false, err
    end

    local chunk, compileErr = loadstring(source)
    if type(chunk) ~= "function" then
        warn("[ScriptVault] Compile error: " .. tostring(compileErr))
        return false, compileErr
    end

    local ok, runtimeErr = pcall(chunk)
    if not ok then
        warn("[ScriptVault] Runtime error: " .. tostring(runtimeErr))
        return false, runtimeErr
    end

    return true
end

return run()
