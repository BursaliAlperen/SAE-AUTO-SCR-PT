-- ScriptVault — Steal an Egg only
local BASE_URL = "https://raw.githubusercontent.com/BursaliAlperen/SAE-AUTO-SCRIPT/main/"
local PROFILE = "games/steal_an_egg.lua"

local function httpGet(url)
    local attempts = {
        function() if type(game.HttpGet) == "function" then return game:HttpGet(url) end end,
        function() if type(game.HttpGetAsync) == "function" then return game:HttpGetAsync(url) end end,
        function()
            local req = rawget(_G, "request") or rawget(_G, "http_request")
            if type(req) == "function" then
                local res = req({Url=url, Method="GET"})
                if type(res) == "table" then return res.Body or res.body end
            end
        end,
        function()
            local syn = rawget(_G, "syn")
            if type(syn) == "table" and type(syn.request) == "function" then
                local res = syn.request({Url=url, Method="GET"})
                if type(res) == "table" then return res.Body or res.body end
            end
        end,
    }
    for _, attempt in ipairs(attempts) do
        local ok, body = pcall(attempt)
        if ok and type(body) == "string" and #body > 0 then return body end
    end
    return nil, "HTTP request failed in all supported modes"
end

local function run()
    if tonumber(game.PlaceId) ~= 107778070777162 then
        warn("[ScriptVault] This loader is only for Steal an Egg.")
        return false, "Wrong PlaceId"
    end

    local url = BASE_URL .. PROFILE .. "?v=" .. tostring(os.time())
    print("[ScriptVault] Loading Steal an Egg")
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

    local ok, result, resultErr = pcall(chunk)
    if not ok then
        warn("[ScriptVault] Runtime error: " .. tostring(result))
        return false, result
    end
    if result == false then
        warn("[ScriptVault] SAE profile failed: " .. tostring(resultErr))
        return false, resultErr
    end
    return true
end

return run()
