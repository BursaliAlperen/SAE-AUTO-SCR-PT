-- ScriptVault multi-game direct loader
-- Game-specific profiles are isolated under /games; unknown places use generic.lua.
local BASE_URL = "https://raw.githubusercontent.com/BursaliAlperen/SAE-AUTO-SCR-PT/main/"
local GAME_PROFILES = {
    [920587237] = "games/adopt_me.lua",
    [107778070777162] = "games/steal_an_egg.lua",
}
local DEFAULT_PROFILE = "games/generic.lua"

local function getScriptPath()
    local id = tonumber(game.PlaceId)
    return GAME_PROFILES[id] or DEFAULT_PROFILE
end

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
    for _,attempt in ipairs(attempts) do
        local ok,body=pcall(attempt)
        if ok and type(body)=="string" and #body>0 then return body end
    end
    return nil,"HTTP request failed in all supported modes"
end

local function run()
    local path=getScriptPath()
    local url=BASE_URL..path.."?v="..tostring(os.time())
    print("[ScriptVault] Loading profile:",path)
    local source,err=httpGet(url)
    if not source then warn("[ScriptVault] "..tostring(err)); return false,err end

    local chunk,compileErr=loadstring(source)
    if type(chunk)~="function" then warn("[ScriptVault] Compile error: "..tostring(compileErr)); return false,compileErr end

    local ok,result,resultErr=pcall(chunk)
    if not ok then warn("[ScriptVault] Runtime error: "..tostring(result)); return false,result end
    if result==false then warn("[ScriptVault] Profile failed: "..tostring(resultErr)); return false,resultErr end
    return true
end

return run()
