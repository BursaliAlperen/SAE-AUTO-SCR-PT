-- ScriptVault Key System
-- Usage:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/BursaliAlperen/SAE-AUTO-SCR-PT/main/keysystem.lua"))()

return (function()
    local VERSION = "1.0.0"

    local KEYS_URL = "https://raw.githubusercontent.com/BursaliAlperen/SAE-AUTO-SCR-PT/main/keys.json"
    local GET_KEY_URL = "https://github.com/BursaliAlperen/SAE-AUTO-SCR-PT"
    local DISCORD_URL = "https://discord.gg/YOURINVITE"

    local CACHE_SECONDS = 24 * 60 * 60
    local FILE_HWID, FILE_KEY, FILE_VERIFY = "sv_hwid.txt", "sv_key.txt", "sv_verify.json"

    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local TweenService = game:GetService("TweenService")
    local UIS = game:GetService("UserInputService")
    local CoreGui = game:GetService("CoreGui")
    local Player = Players.LocalPlayer

    local function safe(fn, ...)
        local ok, a, b, c = pcall(fn, ...)
        return ok, a, b, c
    end

    local function has(name)
        return type(getgenv()[name]) == "function" or type(_G[name]) == "function"
    end

    local function callGlobal(name, ...)
        local f = getgenv()[name] or _G[name]
        if type(f) ~= "function" then return nil end
        return safe(f, ...)
    end

    local function readFile(path)
        if not has("readfile") then return nil end
        local ok, v = callGlobal("readfile", path)
        return ok and v or nil
    end

    local function writeFile(path, data)
        if not has("writefile") then return false end
        local ok = callGlobal("writefile", path, data)
        return ok
    end

    local function decode(s)
        if not s then return nil end
        local ok, v = pcall(function() return HttpService:JSONDecode(s) end)
        return ok and v or nil
    end

    local function encode(v)
        local ok, s = pcall(function() return HttpService:JSONEncode(v) end)
        return ok and s or nil
    end

    local function saveJson(path, value)
        local s = encode(value)
        return s and writeFile(path, s) or false
    end

    local function now()
        return os.time()
    end

    local function genUUID()
        math.randomseed(now() + math.floor(os.clock() * 100000))
        local t = {}
        for i = 1, 32 do t[i] = string.format("%x", math.random(0, 15)) end
        return table.concat(t)
    end

    local function fnv32(str, seed)
        local hash = seed or 2166136261
        for i = 1, #str do
            hash = bit32.bxor(hash, string.byte(str, i))
            hash = (hash * 16777619) % 4294967296
        end
        return hash
    end

    local function hashFNV1a(str)
        local out = {}
        local seeds = {2166136261, 2166136261 + 17, 2166136261 + 31, 2166136261 + 47}
        for i = 1, 4 do
            out[i] = string.format("%08x", fnv32(str .. ":" .. i, seeds[i]))
        end
        return table.concat(out)
    end

    local function getHWID()
        local cached = readFile(FILE_HWID)
        if cached and #cached >= 32 then return cached end

        local raw
        if has("gethwid") then
            local ok, v = callGlobal("gethwid")
            if ok and type(v) == "string" and #v > 0 then raw = v end
        end

        if not raw then
            local clientId = ""
            safe(function()
                clientId = game:GetService("RbxAnalyticsService"):GetClientId()
            end)

            local executor = "unknown"
            if has("identifyexecutor") then
                local ok, name, version = callGlobal("identifyexecutor")
                if ok then executor = tostring(name or "") .. ":" .. tostring(version or "") end
            end

            raw = clientId .. ":" .. tostring(Player.UserId) .. ":" .. executor
        end

        local hwid = hashFNV1a(raw):sub(1, 32)
        writeFile(FILE_HWID, hwid)
        return hwid
    end

    local function httpGet(url)
        local ok, body = safe(function()
            if game.HttpGet then return game:HttpGet(url) end
            return game:HttpGetAsync(url)
        end)
        return ok and body or nil
    end

    local function fetchKeys()
        local body = httpGet(KEYS_URL .. "?t=" .. tostring(now()))
        if not body then return nil, "NETWORK_ERROR" end
        local data = decode(body)
        if type(data) ~= "table" then return nil, "INVALID_JSON" end
        return data
    end

    local function findKey(keys, key)
        for _, item in ipairs(keys) do
            if type(item) == "table" and tostring(item.key or ""):upper() == key then
                return item
            end
        end
        return nil
    end

    local function validFormat(key)
        return type(key) == "string" and key:match("^SV%-%w%w%w%w%-%w%w%w%w%-%w%w%w%w$") ~= nil
    end

    local function verifyKey(key, hwid, keys)
        if not validFormat(key) then return false, "KEY_INVALID" end

        local info = findKey(keys, key)
        if not info then return false, "KEY_NOT_FOUND" end

        local expires = tonumber(info.expires or 0) or 0
        if expires > 0 and expires < now() then
            return false, "KEY_EXPIRED", info
        end

        if info.hwid ~= nil and tostring(info.hwid) ~= "" and tostring(info.hwid) ~= hwid then
            return false, "HWID_MISMATCH", info
        end

        local uses = tonumber(info.uses or 0) or 0
        local maxUses = tonumber(info.max_uses or 0) or 0
        if maxUses > 0 and uses >= maxUses and tostring(info.hwid or "") ~= hwid then
            return false, "MAX_USES", info
        end

        return true, info.tier or "FREE", info
    end

    local old = readFile(FILE_VERIFY)
    local cached = decode(old)
    local hwid = getHWID()
    local cachedKey = readFile(FILE_KEY)

    local function cacheValid()
        if type(cached) ~= "table" then return false end
        if cached.hwid ~= hwid or cached.key ~= cachedKey then return false end
        if now() - tonumber(cached.verified_at or 0) >= CACHE_SECONDS then return false end
        if tonumber(cached.expires_at or 0) > 0 and tonumber(cached.expires_at) < now() then return false end
        return true
    end

    local function make(class, props, parent)
        local obj = Instance.new(class)
        for k, v in pairs(props or {}) do obj[k] = v end
        obj.Parent = parent
        return obj
    end

    local function tween(obj, info, props)
        return TweenService:Create(obj, info, props)
    end

    local gui = make("ScreenGui", {
        Name = "ScriptVaultKeySystem",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 2147483647
    }, (getgenv().gethui and getgenv().gethui()) or CoreGui)

    local scale = make("UIScale", {Scale = 1}, gui)
    local function resize()
        local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800,600)
        scale.Scale = math.clamp(math.min(v.X / 430, v.Y / 530), 0.72, 1)
    end
    resize()

    local backdrop = make("Frame", {
        Size = UDim2.fromScale(1,1),
        BackgroundColor3 = Color3.fromRGB(8,13,24),
        BackgroundTransparency = 0.16,
        BorderSizePixel = 0
    }, gui)

    local card = make("Frame", {
        Size = UDim2.fromOffset(380,460),
        Position = UDim2.fromScale(0.5,0.5),
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BorderSizePixel = 0
    }, backdrop)
    make("UICorner",{CornerRadius=UDim.new(0,18)},card)
    make("UIStroke",{Color=Color3.fromRGB(220,228,240),Thickness=1.2},card)

    local top = make("Frame", {
        Size=UDim2.new(1,0,0,118),
        BackgroundTransparency=1
    },card)

    local logo = make("Frame", {
        Size=UDim2.fromOffset(58,58),
        Position=UDim2.fromOffset(28,22),
        BackgroundColor3=Color3.fromRGB(35,116,255),
        BorderSizePixel=0
    },top)
    make("UICorner",{CornerRadius=UDim.new(0,16)},logo)
    make("TextLabel",{
        Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,
        Text="SV",
        Font=Enum.Font.GothamBold,
        TextSize=20,
        TextColor3=Color3.new(1,1,1)
    },logo)

    make("TextLabel",{
        Size=UDim2.new(1,-105,0,30),
        Position=UDim2.fromOffset(100,25),
        BackgroundTransparency=1,
        Text="ScriptVault",
        Font=Enum.Font.GothamBold,
        TextSize=25,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextColor3=Color3.fromRGB(20,30,48)
    },top)

    make("TextLabel",{
        Size=UDim2.new(1,-105,0,42),
        Position=UDim2.fromOffset(100,54),
        BackgroundTransparency=1,
        Text="Enter your access key to continue.",
        Font=Enum.Font.Gotham,
        TextSize=13,
        TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextColor3=Color3.fromRGB(105,116,135)
    },top)

    local input = make("TextBox",{
        Size=UDim2.new(1,-56,0,54),
        Position=UDim2.fromOffset(28,136),
        BackgroundColor3=Color3.fromRGB(247,249,252),
        BorderSizePixel=0,
        PlaceholderText="SV-XXXX-XXXX-XXXX",
        PlaceholderColor3=Color3.fromRGB(155,165,180),
        Text="",
        ClearTextOnFocus=false,
        Font=Enum.Font.Code,
        TextSize=16,
        TextColor3=Color3.fromRGB(25,35,50),
        TextXAlignment=Enum.TextXAlignment.Center
    },card)
    make("UICorner",{CornerRadius=UDim.new(0,12)},input)
    local inputStroke=make("UIStroke",{Color=Color3.fromRGB(215,222,233),Thickness=1.2},input)

    local verify = make("TextButton",{
        Size=UDim2.new(1,-56,0,50),
        Position=UDim2.fromOffset(28,204),
        BackgroundColor3=Color3.fromRGB(35,116,255),
        BorderSizePixel=0,
        Text="VERIFY KEY",
        Font=Enum.Font.GothamBold,
        TextSize=14,
        TextColor3=Color3.new(1,1,1),
        AutoButtonColor=false
    },card)
    make("UICorner",{CornerRadius=UDim.new(0,12)},verify)

    local status = make("TextLabel",{
        Size=UDim2.new(1,-56,0,48),
        Position=UDim2.fromOffset(28,270),
        BackgroundTransparency=1,
        Text="Ready to verify.",
        Font=Enum.Font.Gotham,
        TextSize=13,
        TextWrapped=true,
        TextColor3=Color3.fromRGB(105,116,135)
    },card)

    local getKey = make("TextButton",{
        Size=UDim2.fromOffset(145,42),
        Position=UDim2.fromOffset(28,340),
        BackgroundColor3=Color3.fromRGB(239,245,255),
        BorderSizePixel=0,
        Text="Get Key",
        Font=Enum.Font.GothamBold,
        TextSize=13,
        TextColor3=Color3.fromRGB(35,116,255)
    },card)
    make("UICorner",{CornerRadius=UDim.new(0,11)},getKey)

    local discord = make("TextButton",{
        Size=UDim2.fromOffset(145,42),
        Position=UDim2.fromOffset(207,340),
        BackgroundColor3=Color3.fromRGB(239,245,255),
        BorderSizePixel=0,
        Text="Discord",
        Font=Enum.Font.GothamBold,
        TextSize=13,
        TextColor3=Color3.fromRGB(35,116,255)
    },card)
    make("UICorner",{CornerRadius=UDim.new(0,11)},discord)

    make("TextLabel",{
        Size=UDim2.new(1,-56,0,28),
        Position=UDim2.fromOffset(28,405),
        BackgroundTransparency=1,
        Text="ScriptVault • v"..VERSION,
        Font=Enum.Font.Gotham,
        TextSize=11,
        TextColor3=Color3.fromRGB(160,169,184)
    },card)

    input.Focused:Connect(function()
        tween(inputStroke,TweenInfo.new(.18),{Color=Color3.fromRGB(35,116,255)}):Play()
    end)
    input.FocusLost:Connect(function()
        tween(inputStroke,TweenInfo.new(.18),{Color=Color3.fromRGB(215,222,233)}):Play()
    end)

    local function copy(url, label)
        local f = getgenv().setclipboard or getgenv().toclipboard
        if type(f) == "function" then
            pcall(f,url)
            status.Text = label.." copied to clipboard."
            status.TextColor3 = Color3.fromRGB(35,116,255)
        else
            status.Text = url
            status.TextColor3 = Color3.fromRGB(105,116,135)
        end
    end

    getKey.Activated:Connect(function() copy(GET_KEY_URL,"Get Key link") end)
    discord.Activated:Connect(function() copy(DISCORD_URL,"Discord link") end)

    local busy=false
    local function finish(info)
        saveJson(FILE_VERIFY,{
            key=input.Text:upper(),
            hwid=hwid,
            verified_at=now(),
            expires_at=tonumber(info.expires or 0) or 0,
            tier=info.tier or "FREE"
        })
        writeFile(FILE_KEY,input.Text:upper())
        status.Text="Verified • "..tostring(info.tier or "FREE")
        status.TextColor3=Color3.fromRGB(24,170,92)
        verify.Text="SUCCESS"
        task.wait(1.5)
        gui:Destroy()
        return true, info
    end

    local function checkKey()
        local keys, err = fetchKeys()
        if not keys then
            status.Text="Unable to reach key server ("..tostring(err)..")."
            status.TextColor3=Color3.fromRGB(220,70,70)
            return false, err
        end

        local key=input.Text:upper()
        local ok, reason, info = verifyKey(key,hwid,keys)
        if not ok then
            local messages={
                KEY_INVALID="Invalid key format.",
                KEY_NOT_FOUND="Key was not found.",
                KEY_EXPIRED="This key has expired.",
                HWID_MISMATCH="This key is bound to another HWID.",
                MAX_USES="This key reached its activation limit."
            }
            status.Text=messages[reason] or "Verification failed."
            status.TextColor3=Color3.fromRGB(220,70,70)
            tween(card,TweenInfo.new(.05,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,3,true),{Position=UDim2.fromScale(.505,.5)}):Play()
            return false, reason
        end
        return finish(info)
    end

    verify.Activated:Connect(function()
        if busy then return end
        busy=true
        verify.Text="VERIFYING..."
        verify.BackgroundColor3=Color3.fromRGB(90,150,255)
        local ok, result = pcall(checkKey)
        if not ok then
            status.Text="Unexpected verification error."
            status.TextColor3=Color3.fromRGB(220,70,70)
        end
        if gui.Parent then
            verify.Text=ok and "VERIFY KEY" or "RETRY"
            verify.BackgroundColor3=Color3.fromRGB(35,116,255)
        end
        busy=false
    end)

    if cachedKey and cacheValid() then
        local keys = fetchKeys()
        if keys then
            local ok, _, info = verifyKey(cachedKey,hwid,keys)
            if ok then
                input.Text=cachedKey
                return finish(info)
            end
        end
    end

    return false, "AWAITING_KEY"
end)()
