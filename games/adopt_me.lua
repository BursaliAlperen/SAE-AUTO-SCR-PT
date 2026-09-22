-- ScriptVault — Adopt Me! dedicated profile
-- PlaceId: 920587237
-- Architecture:
--   1) Deep inventory discovery/classification
--   2) Baby + pet selectors
--   3) Real remote discovery / learn-next-action / replay
--   4) Visible task assistant
--   5) Player ESP + Anti-AFK
--   6) Mobile-friendly UI
--
-- IMPORTANT:
-- This profile does not hard-code imaginary Adopt Me remote names.
-- For actions that require server RPCs, it learns the actual RemoteEvent/
-- RemoteFunction and argument shape from a real user action, then replays
-- that learned action. This makes updates less brittle than fake names.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local WS = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local LP = Players.LocalPlayer
if not LP then return end

local ENV = (type(getgenv) == "function" and getgenv()) or _G
local ID = tostring({})
if ENV then ENV.SV_ADOPT_ME_ID = ID end
local function current()
    return not ENV or ENV.SV_ADOPT_ME_ID == ID
end

local function safe(fn, ...)
    local ok, a, b, c, d = pcall(fn, ...)
    return ok, a, b, c, d
end

-- ═══════════════════════════════════════════════════════════════════════
-- GUI PARENT
-- ═══════════════════════════════════════════════════════════════════════
local parent
pcall(function()
    if type(gethui) == "function" then parent = gethui() end
end)
if not parent then parent = game:GetService("CoreGui") end
if not parent then parent = LP:FindFirstChildOfClass("PlayerGui") end
if not parent then return end

local old = parent:FindFirstChild("ScriptVault_AdoptMe")
if old then pcall(function() old:Destroy() end) end

local gui = Instance.new("ScreenGui")
gui.Name = "ScriptVault_AdoptMe"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999
gui.Parent = parent

local C = {
    bg = Color3.fromRGB(247,249,252),
    white = Color3.fromRGB(255,255,255),
    card = Color3.fromRGB(255,255,255),
    text = Color3.fromRGB(15,23,42),
    soft = Color3.fromRGB(71,85,105),
    muted = Color3.fromRGB(100,116,139),
    border = Color3.fromRGB(226,232,240),
    primary = Color3.fromRGB(124,58,237),
    primary2 = Color3.fromRGB(99,102,241),
    cyan = Color3.fromRGB(14,165,233),
    pink = Color3.fromRGB(236,72,153),
    green = Color3.fromRGB(16,185,129),
    red = Color3.fromRGB(239,68,68),
    yellow = Color3.fromRGB(245,158,11),
}

local function corner(p, r)
    local x = Instance.new("UICorner")
    x.CornerRadius = UDim.new(0, r)
    x.Parent = p
end

local function line(p, color, transparency, thickness)
    local x = Instance.new("UIStroke")
    x.Color = color or C.border
    x.Transparency = transparency or 0
    x.Thickness = thickness or 1
    x.Parent = p
end

local function txt(p, value, size, color, bold)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = value or ""
    l.TextSize = size or 14
    l.TextColor3 = color or C.text
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = p
    return l
end

local function button(p, value, color, w, h)
    local b = Instance.new("TextButton")
    b.Text = value or ""
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = C.white
    b.BackgroundColor3 = color or C.primary
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Size = UDim2.new(0, w or 125, 0, h or 34)
    b.Parent = p
    corner(b, 10)
    return b
end

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 700, 0, 520)
panel.Position = UDim2.new(0.5, -350, 0.5, -260)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel = 0
panel.Parent = gui
corner(panel, 20)
line(panel, C.border, 0)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 72)
header.BackgroundColor3 = C.white
header.BorderSizePixel = 0
header.Parent = panel
corner(header, 20)

local title = txt(header, "SCRIPTVAULT  /  ADOPT ME", 18, C.text, true)
title.Position = UDim2.new(0, 20, 0, 11)
title.Size = UDim2.new(1, -180, 0, 25)
local sub = txt(header, "Inventory intelligence • Baby • Pet • Remote learning • Tasks", 11, C.muted, false)
sub.Position = UDim2.new(0, 21, 0, 39)
sub.Size = UDim2.new(1, -220, 0, 18)

local badge = txt(header, "ADOPT ME", 10, C.white, true)
badge.TextXAlignment = Enum.TextXAlignment.Center
badge.Position = UDim2.new(1, -155, 0, 16)
badge.Size = UDim2.new(0, 88, 0, 30)
badge.BackgroundColor3 = C.primary
corner(badge, 10)

local close = button(header, "×", C.red, 34, 34)
close.TextSize = 20
close.Position = UDim2.new(1, -49, 0, 12)
close.Activated:Connect(function()
    gui.Enabled = false
end)

local tabs = Instance.new("Frame")
tabs.Position = UDim2.new(0, 14, 0, 82)
tabs.Size = UDim2.new(1, -28, 0, 38)
tabs.BackgroundTransparency = 1
tabs.Parent = panel

local content = Instance.new("Frame")
content.Position = UDim2.new(0, 14, 0, 128)
content.Size = UDim2.new(1, -28, 1, -142)
content.BackgroundTransparency = 1
content.Parent = panel

local pages = {}
local tabButtons = {}
local function makePage(name)
    local p = Instance.new("ScrollingFrame")
    p.Name = name
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 4
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.CanvasSize = UDim2.new(0,0,0,0)
    p.Visible = false
    p.Parent = content
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 9)
    l.Parent = p
    local pad = Instance.new("UIPadding")
    pad.PaddingBottom = UDim.new(0, 14)
    pad.Parent = p
    pages[name] = p
    return p
end

local function makeTab(name, caption, order)
    local b = button(tabs, caption, C.white, 116, 34)
    b.Position = UDim2.new(0, (order-1)*120, 0, 2)
    line(b, C.border, .3)
    tabButtons[name] = b
    b.Activated:Connect(function()
        for n,p in pairs(pages) do
            p.Visible = (n == name)
        end
        for n,bb in pairs(tabButtons) do
            bb.BackgroundColor3 = (n == name) and C.primary or C.white
            bb.TextColor3 = (n == name) and C.white or C.soft
        end
    end)
    return b
end

local dash = makePage("dashboard")
local inv = makePage("inventory")
local remote = makePage("remote")
local player = makePage("player")

makeTab("dashboard","DASHBOARD",1)
makeTab("inventory","INVENTORY",2)
makeTab("remote","REMOTE LAB",3)
makeTab("player","PLAYER",4)

local state = {
    autoBaby = false,
    autoPet = false,
    autoTasks = false,
    antiAfk = false,
    playerEsp = false,
    selectedPet = nil,
    inventory = {},
    invFilter = "Pets",
    search = "",
    learned = {
        baby = nil,
        pet = nil,
    },
}

-- ═══════════════════════════════════════════════════════════════════════
-- COMMON CARD
-- ═══════════════════════════════════════════════════════════════════════
local function card(page, titleText, descText, height)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -4, 0, height or 88)
    f.BackgroundColor3 = C.card
    f.BorderSizePixel = 0
    f.Parent = page
    corner(f, 14)
    line(f, C.border, .35)

    local t = txt(f, titleText, 14, C.text, true)
    t.Position = UDim2.new(0, 16, 0, 10)
    t.Size = UDim2.new(1, -32, 0, 20)

    local d = txt(f, descText or "", 10, C.muted, false)
    d.Position = UDim2.new(0, 16, 0, 34)
    d.Size = UDim2.new(1, -32, 0, 18)
    d.TextWrapped = true
    return f
end

-- ═══════════════════════════════════════════════════════════════════════
-- REMOTE ENGINE
-- ═══════════════════════════════════════════════════════════════════════
local RemoteEngine = {
    hookInstalled = false,
    hookMethod = nil,
    oldNamecall = nil,
    learning = nil,
    recent = {},
    candidates = {},
}

local function instancePath(obj)
    if not obj or not obj.GetFullName then return "" end
    local ok, value = pcall(function() return obj:GetFullName() end)
    return ok and value or ""
end

local function getByFullName(path)
    if type(path) ~= "string" or path == "" then return nil end
    local parts = string.split(path, ".")
    if parts[1] ~= "game" then return nil end
    local node = game
    for i = 2, #parts do
        if not node then return nil end
        node = node:FindFirstChild(parts[i])
    end
    return node
end

local function cloneArg(value, depth)
    depth = depth or 0
    if depth > 5 then return value end
    if typeof(value) == "Instance" then return value end
    if type(value) ~= "table" then return value end
    local out = {}
    for k,v in pairs(value) do
        out[cloneArg(k, depth+1)] = cloneArg(v, depth+1)
    end
    return out
end

local function summarizeArg(value, depth)
    depth = depth or 0
    if typeof(value) == "Instance" then
        return "<"..value.ClassName.."> "..instancePath(value)
    end
    if type(value) == "table" then
        if depth >= 2 then return "{...}" end
        local parts = {}
        local n = 0
        for k,v in pairs(value) do
            n = n + 1
            if n > 8 then break end
            parts[#parts+1] = tostring(k).."="..summarizeArg(v, depth+1)
        end
        return "{"..table.concat(parts,", ").."}"
    end
    return tostring(value)
end

local function scoreRemote(name, kind)
    local s = string.lower(name or "")
    local score = 0
    local positive
    if kind == "baby" then
        positive = {"baby","role","family","character","avatar","adult","parent"}
    elseif kind == "pet" then
        positive = {"pet","equip","companion","inventory","item","activate","select","use"}
    elseif kind == "task" then
        positive = {"task","needs","feed","sleep","shower","dirty","school","camp","pizza"}
    else
        positive = {"remote","event","function"}
    end
    for _,w in ipairs(positive) do
        if s:find(w,1,true) then score = score + 2 end
    end
    local negative = {"heartbeat","update","tick","analytics","telemetry","ping","replicate"}
    for _,w in ipairs(negative) do
        if s:find(w,1,true) then score = score - 1 end
    end
    return score
end

local function installRemoteHook()
    if RemoteEngine.hookInstalled then return true end
    if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then
        return false, "executor lacks hookmetamethod/getnamecallmethod"
    end

    local ok, oldHook = pcall(function()
        return hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if current()
                and RemoteEngine.learning
                and (method == "FireServer" or method == "InvokeServer")
                and (typeof(self) == "Instance")
                and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then

                local learn = RemoteEngine.learning
                local args = {...}
                local name = self.Name
                local score = scoreRemote(name, learn.kind)

                if learn.kind == "baby" and score >= 2 or learn.kind == "pet" and score >= 2 then
                    local capture = {
                        remotePath = instancePath(self),
                        remoteName = name,
                        method = method,
                        args = {},
                        score = score,
                        time = os.clock(),
                    }
                    for i,v in ipairs(args) do capture.args[i] = cloneArg(v) end

                    local bindingIndex
                    if learn.kind == "pet" and state.selectedPet then
                        for i,v in ipairs(args) do
                            local sv = tostring(v)
                            if sv == tostring(state.selectedPet.id) or sv:lower() == tostring(state.selectedPet.name):lower() then
                                bindingIndex = i
                                break
                            end
                        end
                    end
                    capture.bindingIndex = bindingIndex
                    state.learned[learn.kind] = capture
                    RemoteEngine.learning = nil
                    remoteStatus.Text = "Learned "..learn.kind.." remote: "..name
                    refreshRemoteCards()
                end
            end

            return oldHook(self, ...)
        end))
    end)

    if not ok then
        return false, tostring(oldHook)
    end

    RemoteEngine.oldNamecall = oldHook
    RemoteEngine.hookInstalled = true
    return true
end

local function invokeLearned(kind, pet)
    local data = state.learned[kind]
    if not data then return false, "Nothing learned for "..kind end

    local remoteObj = getByFullName(data.remotePath)
    if not remoteObj then return false, "Learned remote no longer exists" end

    local args = {}
    for i,v in ipairs(data.args or {}) do args[i] = cloneArg(v) end

    if kind == "pet" and pet and data.bindingIndex then
        local idx = data.bindingIndex
        local oldValue = args[idx]
        if typeof(oldValue) == "string" then
            args[idx] = tostring(pet.id or pet.name)
        elseif type(oldValue) == "number" then
            args[idx] = tonumber(pet.id) or oldValue
        end
    end

    local ok, result = pcall(function()
        if remoteObj:IsA("RemoteEvent") then
            remoteObj:FireServer(table.unpack(args))
            return true
        elseif remoteObj:IsA("RemoteFunction") then
            return remoteObj:InvokeServer(table.unpack(args))
        end
    end)
    return ok, result
end

local function beginLearn(kind)
    local ok, reason = installRemoteHook()
    if not ok then
        remoteStatus.Text = "Remote learner unavailable: "..tostring(reason)
        return
    end
    RemoteEngine.learning = {kind=kind, started=os.clock()}
    remoteStatus.Text = "Learning "..kind.."... now perform the real in-game "..kind.." action once."
end

-- ═══════════════════════════════════════════════════════════════════════
-- DEEP INVENTORY ENGINE
-- ═══════════════════════════════════════════════════════════════════════
local function normalize(s)
    return string.lower(tostring(s or "")):gsub("[%s%p_]+","")
end

local function classify(pathText, itemName)
    local p = string.lower((pathText or "").." "..(itemName or ""))
    if p:find("pet",1,true) or p:find("companion",1,true) then return "Pets" end
    if p:find("egg",1,true) or p:find("hatch",1,true) then return "Eggs" end
    if p:find("vehicle",1,true) or p:find("car",1,true) then return "Vehicles" end
    if p:find("toy",1,true) or p:find("stroller",1,true) or p:find("food",1,true)
        or p:find("potion",1,true) or p:find("gift",1,true) then
        return "Items"
    end
    return "Other"
end

local function valueOf(inst, names)
    for _,name in ipairs(names) do
        local c = inst:FindFirstChild(name)
        if c and c:IsA("ValueBase") then
            local ok,v = pcall(function() return c.Value end)
            if ok then return v end
        end
        local ok,a = pcall(function() return inst:GetAttribute(name) end)
        if ok and a ~= nil then return a end
    end
end

local function addInventoryEntry(out, seen, obj, pathText, forcedKind)
    if not obj then return end
    local name = obj.Name
    if not name or name == "" then return end

    local id = valueOf(obj, {"Id","ID","ItemId","itemId","UUID","Uid","UID","PetId","petId","AssetId","assetId"})
    local count = valueOf(obj, {"Count","count","Amount","amount","Quantity","quantity","Stack","stack"})
    local display = valueOf(obj, {"DisplayName","displayName","Name","name"})
    display = tostring(display or name)

    local key = tostring(id or "").."|"..display.."|"..(pathText or "")
    if seen[key] then return end

    local useful = id ~= nil
    if obj:IsA("StringValue") or obj:IsA("IntValue") or obj:IsA("NumberValue") then useful = true end
    if obj:IsA("TextButton") or obj:IsA("ImageButton") then useful = true end
    if obj:FindFirstChild("Id") or obj:FindFirstChild("ID") then useful = true end
    if not useful then return end

    seen[key] = true
    local entry = {
        name = display,
        id = id or display,
        count = tonumber(count) or 1,
        kind = forcedKind or classify(pathText, display),
        path = pathText or instancePath(obj),
        object = obj,
    }
    table.insert(out, entry)
end

local function inventoryRoots()
    local roots = {LP}

    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if pg then table.insert(roots, pg) end
    local backpack = LP:FindFirstChildOfClass("Backpack")
    if backpack then table.insert(roots, backpack) end

    local hints = {"inventory","backpack","profile","data","saved","pets","items","collection","playerdata"}
    local scanContainers = {LP, pg, RS}
    for _,root in ipairs(scanContainers) do
        if root then
            local descendants = root:GetDescendants()
            local limit = math.min(#descendants, 1800)
            for i=1,limit do
                local d = descendants[i]
                local n = string.lower(d.Name)
                for _,h in ipairs(hints) do
                    if n == h or n:find(h,1,true) and #d:GetDescendants() < 400 then
                        roots[#roots+1] = d
                        break
                    end
                end
            end
        end
    end

    local unique, out = {}, {}
    for _,r in ipairs(roots) do
        if r and not unique[r] then unique[r]=true; out[#out+1]=r end
    end
    return out
end

local function scanInventory()
    local result, seen = {}, {}
    for _,root in ipairs(inventoryRoots()) do
        local ok, descendants = pcall(function() return root:GetDescendants() end)
        if ok then
            local limit = math.min(#descendants, 2200)
            for i=1,limit do
                local d = descendants[i]
                if current() then
                    local path = instancePath(d)
                    if d:IsA("Folder") or d:IsA("Configuration") or d:IsA("StringValue")
                        or d:IsA("IntValue") or d:IsA("NumberValue") or d:IsA("TextButton")
                        or d:IsA("ImageButton") then
                        addInventoryEntry(result, seen, d, path)
                    end
                end
            end
        end
    end

    -- UI text fallback: pick visible inventory-like buttons even if no id object exists.
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if pg then
        for _,d in ipairs(pg:GetDescendants()) do
            if (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Visible then
                local n = d.Name
                local t = d:IsA("TextButton") and d.Text or ""
                local blob = string.lower(n.." "..t)
                if blob:find("pet",1,true) or blob:find("egg",1,true) or blob:find("vehicle",1,true) then
                    addInventoryEntry(result, seen, d, instancePath(d))
                end
            end
        end
    end

    table.sort(result, function(a,b)
        local ak = (a.kind or "")..":"..(a.name or "")
        local bk = (b.kind or "")..":"..(b.name or "")
        return ak < bk
    end)
    state.inventory = result
    return result
end

-- ═══════════════════════════════════════════════════════════════════════
-- DASHBOARD
-- ═══════════════════════════════════════════════════════════════════════
local roleCard = card(dash, "BABY CONTROL",
    "Uses a real learned role action. Click LEARN BABY once, select Baby in Adopt Me, then Auto Baby can replay it.", 118)

local babyStatus = txt(roleCard, "Baby action: not learned", 11, C.muted, false)
babyStatus.Position = UDim2.new(0, 16, 0, 58)
babyStatus.Size = UDim2.new(0.56, 0, 0, 18)

local learnBaby = button(roleCard, "LEARN BABY", C.primary, 125, 34)
learnBaby.Position = UDim2.new(1, -275, 0, 54)
learnBaby.Activated:Connect(function() beginLearn("baby") end)

local autoBaby = button(roleCard, "AUTO BABY: OFF", C.soft, 135, 34)
autoBaby.Position = UDim2.new(1, -140, 0, 54)
autoBaby.Activated:Connect(function()
    state.autoBaby = not state.autoBaby
    autoBaby.Text = "AUTO BABY: "..(state.autoBaby and "ON" or "OFF")
    autoBaby.BackgroundColor3 = state.autoBaby and C.green or C.soft
end)

local petCard = card(dash, "PET CONTROL",
    "Select any pet discovered from your live inventory model, then learn the real equip/select remote once.", 148)
local petStatus = txt(petCard, "Pet: none selected", 11, C.soft, false)
petStatus.Position = UDim2.new(0,16,0,58); petStatus.Size = UDim2.new(1,-32,0,18)
local petHelp = txt(petCard, "Open INVENTORY to choose a pet.", 10, C.muted, false)
petHelp.Position = UDim2.new(0,16,0,78); petHelp.Size = UDim2.new(1,-32,0,18)

local learnPet = button(petCard, "LEARN PET ACTION", C.primary2, 150, 34)
learnPet.Position = UDim2.new(0,16,0,103)
learnPet.Activated:Connect(function() beginLearn("pet") end)

local autoPet = button(petCard, "AUTO PET: OFF", C.soft, 132, 34)
autoPet.Position = UDim2.new(0,174,0,103)
autoPet.Activated:Connect(function()
    state.autoPet = not state.autoPet
    autoPet.Text = "AUTO PET: "..(state.autoPet and "ON" or "OFF")
    autoPet.BackgroundColor3 = state.autoPet and C.green or C.soft
end)

local scanNow = button(petCard, "SCAN INVENTORY", C.cyan, 145, 34)
scanNow.Position = UDim2.new(1,-161,0,103)
scanNow.Activated:Connect(function()
    scanInventory()
    inventoryStatus.Text = "Inventory scan: "..tostring(#state.inventory).." entries"
    refreshInventory()
end)

local taskCard = card(dash, "AUTO TASK ASSISTANT",
    "Finds visible task/need buttons (Hungry, Thirsty, Sleepy, Dirty, School, Camping, etc.) and can press safe visible UI actions.", 112)
local taskStatus = txt(taskCard, "Task scan ready.", 11, C.muted, false)
taskStatus.Position = UDim2.new(0,16,0,58); taskStatus.Size = UDim2.new(0.6,0,0,18)
local autoTasks = button(taskCard, "AUTO TASKS: OFF", C.soft, 140, 34)
autoTasks.Position = UDim2.new(1,-150,0,52)
autoTasks.Activated:Connect(function()
    state.autoTasks = not state.autoTasks
    autoTasks.Text = "AUTO TASKS: "..(state.autoTasks and "ON" or "OFF")
    autoTasks.BackgroundColor3 = state.autoTasks and C.green or C.soft
end)

local session = card(dash, "SESSION",
    "PlaceId: "..tostring(game.PlaceId).."  •  Player: "..LP.DisplayName.."  •  Inventory entries are discovered live.", 92)
local sessionStatus = txt(session, "Ready.", 11, C.green, true)
sessionStatus.Position = UDim2.new(0,16,0,58); sessionStatus.Size = UDim2.new(1,-32,0,18)

-- ═══════════════════════════════════════════════════════════════════════
-- INVENTORY PAGE
-- ═══════════════════════════════════════════════════════════════════════
local inventoryBox = card(inv, "LIVE INVENTORY",
    "A→Z catalog built from the live client-visible inventory/data/UI. No hard-coded pet roster.", 130)
local inventoryStatus = txt(inventoryBox, "Inventory scan: waiting...", 11, C.muted, false)
inventoryStatus.Position = UDim2.new(0,16,0,58); inventoryStatus.Size = UDim2.new(1,-32,0,18)

local searchBox = Instance.new("TextBox")
searchBox.PlaceholderText = "Search pet/item/egg..."
searchBox.Text = ""
searchBox.TextSize = 12
searchBox.Font = Enum.Font.Gotham
searchBox.TextColor3 = C.text
searchBox.PlaceholderColor3 = C.muted
searchBox.BackgroundColor3 = C.bg
searchBox.Position = UDim2.new(0,16,0,83)
searchBox.Size = UDim2.new(1,-180,0,34)
searchBox.BorderSizePixel = 0
searchBox.Parent = inventoryBox
corner(searchBox, 10)
line(searchBox, C.border, .25)

local rescan = button(inventoryBox, "RESCAN", C.primary, 125, 34)
rescan.Position = UDim2.new(1,-141,0,83)
rescan.Activated:Connect(function()
    scanInventory()
    inventoryStatus.Text = "Inventory scan: "..tostring(#state.inventory).." entries"
    refreshInventory()
end)

local filters = Instance.new("Frame")
filters.Size = UDim2.new(1,-4,0,42)
filters.BackgroundTransparency = 1
filters.Parent = inv
local filterNames = {"Pets","Eggs","Vehicles","Items","Other"}
for i,name in ipairs(filterNames) do
    local b = button(filters,name, name=="Pets" and C.primary or C.white, 98, 32)
    b.Position = UDim2.new(0,(i-1)*103,0,4)
    b.TextColor3 = name=="Pets" and C.white or C.soft
    line(b,C.border,.3)
    b.Activated:Connect(function()
        state.invFilter=name
        for _,child in ipairs(filters:GetChildren()) do
            if child:IsA("TextButton") then
                local active=(child.Text==name)
                child.BackgroundColor3=active and C.primary or C.white
                child.TextColor3=active and C.white or C.soft
            end
        end
        refreshInventory()
    end)
end

local invList = Instance.new("Frame")
invList.Size = UDim2.new(1,-4,0,500)
invList.BackgroundTransparency = 1
invList.Parent = inv
local invLayout = Instance.new("UIListLayout")
invLayout.Padding = UDim.new(0,6)
invLayout.Parent = invList

local function clearChildrenExceptLayout(node)
    for _,d in ipairs(node:GetChildren()) do
        if not d:IsA("UIListLayout") then pcall(function() d:Destroy() end) end
    end
end

function refreshInventory()
    if not invList.Parent then return end
    clearChildrenExceptLayout(invList)

    local q = string.lower(searchBox.Text or "")
    local shown = 0
    for _,entry in ipairs(state.inventory) do
        if entry.kind == state.invFilter then
            local blob = string.lower((entry.name or "").." "..tostring(entry.id or ""))
            if q == "" or blob:find(q,1,true) then
                shown = shown + 1
                if shown <= 80 then
                    local row = Instance.new("TextButton")
                    row.Size = UDim2.new(1,0,0,44)
                    row.BackgroundColor3 = C.white
                    row.BorderSizePixel = 0
                    row.Text = ""
                    row.AutoButtonColor = false
                    row.Parent = invList
                    corner(row,10)
                    line(row,C.border,.45)

                    local n = txt(row, tostring(entry.name), 12, C.text, true)
                    n.Position=UDim2.new(0,12,0,5); n.Size=UDim2.new(.62,0,0,17)
                    local meta = txt(row, tostring(entry.kind).." • x"..tostring(entry.count).." • "..tostring(entry.id), 9, C.muted, false)
                    meta.Position=UDim2.new(0,12,0,23); meta.Size=UDim2.new(1,-135,0,16)

                    local pick = txt(row, (state.selectedPet == entry) and "SELECTED" or "SELECT", 10,
                        (state.selectedPet == entry) and C.green or C.primary, true)
                    pick.TextXAlignment=Enum.TextXAlignment.Center
                    pick.Position=UDim2.new(1,-100,0,8); pick.Size=UDim2.new(0,88,0,28)

                    row.Activated:Connect(function()
                        if entry.kind == "Pets" then
                            state.selectedPet = entry
                            petStatus.Text = "Pet: "..tostring(entry.name).."  •  id="..tostring(entry.id)
                            petHelp.Text = "Selected pet will be substituted into a learned pet remote when a bindable argument is detected."
                            refreshInventory()
                        end
                    end)
                end
            end
        end
    end
    inventoryStatus.Text = "Inventory scan: "..tostring(#state.inventory).." entries • showing "..tostring(shown).." "..state.invFilter
end

searchBox:GetPropertyChangedSignal("Text"):Connect(refreshInventory)

-- ═══════════════════════════════════════════════════════════════════════
-- REMOTE PAGE
-- ═══════════════════════════════════════════════════════════════════════
local remoteCard = card(remote, "REAL REMOTE LEARNING",
    "Remote names are discovered at runtime. Learn actions from actual in-game interactions instead of guessing private API names.", 148)
remoteStatus = txt(remoteCard, "Hook: not initialized.", 11, C.muted, false)
remoteStatus.Position=UDim2.new(0,16,0,58); remoteStatus.Size=UDim2.new(1,-32,0,18)

local hookBtn = button(remoteCard, "CHECK HOOK", C.cyan, 120, 34)
hookBtn.Position=UDim2.new(0,16,0,95)
hookBtn.Activated:Connect(function()
    local ok, reason = installRemoteHook()
    if ok then
        remoteStatus.Text = "Hook installed. Remote learning is ready."
    else
        remoteStatus.Text = "Hook unavailable: "..tostring(reason)
    end
    refreshRemoteCards()
end)

local babyInfo = txt(remoteCard, "Baby bind: ".."not learned", 10, C.soft, false)
babyInfo.Position=UDim2.new(0,150,0,100); babyInfo.Size=UDim2.new(.32,0,0,18)
local petInfo = txt(remoteCard, "Pet bind: not learned", 10, C.soft, false)
petInfo.Position=UDim2.new(.5,0,0,100); petInfo.Size=UDim2.new(.46,0,0,18)

local remotesList = Instance.new("Frame")
remotesList.Size=UDim2.new(1,-4,0,620)
remotesList.BackgroundTransparency=1
remotesList.Parent=remote
local remotesLayout=Instance.new("UIListLayout"); remotesLayout.Padding=UDim.new(0,5); remotesLayout.Parent=remotesList

function refreshRemoteCards()
    babyInfo.Text = "Baby bind: "..(state.learned.baby and state.learned.baby.remoteName or "not learned")
    petInfo.Text = "Pet bind: "..(state.learned.pet and state.learned.pet.remoteName or "not learned")
    clearChildrenExceptLayout(remotesList)

    local found={}
    local containers={RS,WS}
    local seen={}
    for _,root in ipairs(containers) do
        local ok, ds=pcall(function() return root:GetDescendants() end)
        if ok then
            local lim=math.min(#ds,3500)
            for i=1,lim do
                local d=ds[i]
                if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                    local score=scoreRemote(d.Name,"pet")+scoreRemote(d.Name,"baby")+scoreRemote(d.Name,"task")
                    if score>=2 and not seen[d] then
                        seen[d]=true
                        found[#found+1]={obj=d,score=score}
                    end
                end
            end
        end
    end

    table.sort(found,function(a,b)
        if a.score==b.score then return a.obj:GetFullName()<b.obj:GetFullName() end
        return a.score>b.score
    end)

    for i=1,math.min(#found,35) do
        local item=found[i]
        local row=Instance.new("TextLabel")
        row.Size=UDim2.new(1,0,0,34)
        row.BackgroundColor3=C.white
        row.BorderSizePixel=0
        row.Text="["..item.obj.ClassName.."] "..item.obj:GetFullName().."  • score "..tostring(item.score)
        row.TextSize=9
        row.Font=Enum.Font.Gotham
        row.TextColor3=C.soft
        row.TextXAlignment=Enum.TextXAlignment.Left
        row.Parent=remotesList
        corner(row,8); line(row,C.border,.55)
    end

    if #found==0 then
        local empty=txt(remotesList,"No relevant RemoteEvent/RemoteFunction found in the current client view.",10,C.muted,false)
        empty.Size=UDim2.new(1,0,0,28)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- PLAYER PAGE
-- ═══════════════════════════════════════════════════════════════════════
local afkCard = card(player, "ANTI-AFK", "Keeps the session active without touching game-specific remotes.", 92)
local afkBtn = button(afkCard, "ANTI-AFK: OFF", C.soft, 145, 34)
afkBtn.Position=UDim2.new(1,-161,0,45)
afkBtn.Activated:Connect(function()
    state.antiAfk=not state.antiAfk
    afkBtn.Text="ANTI-AFK: "..(state.antiAfk and "ON" or "OFF")
    afkBtn.BackgroundColor3=state.antiAfk and C.green or C.soft
end)

local espCard = card(player, "PLAYER ESP", "Separated highlight folder; does not share objects with inventory/remote UI.", 92)
local espBtn = button(espCard, "PLAYER ESP: OFF", C.soft, 145, 34)
espBtn.Position=UDim2.new(1,-161,0,45)
local espFolder=Instance.new("Folder")
espFolder.Name="SV_AdoptMe_ESP"
espFolder.Parent=WS

local function clearEsp()
    for _,d in ipairs(espFolder:GetChildren()) do pcall(function() d:Destroy() end) end
end
local function updateEsp()
    if not state.playerEsp then clearEsp(); return end
    local live={}
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LP and plr.Character then
            live[plr.Character]=true
            local h=espFolder:FindFirstChild("P_"..plr.UserId)
            if not h then
                h=Instance.new("Highlight")
                h.Name="P_"..plr.UserId
                h.Adornee=plr.Character
                h.FillColor=C.pink
                h.FillTransparency=.6
                h.OutlineColor=C.white
                h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent=espFolder
            end
        end
    end
    for _,h in ipairs(espFolder:GetChildren()) do
        if not live[h.Adornee] then pcall(function() h:Destroy() end) end
    end
end
espBtn.Activated:Connect(function()
    state.playerEsp=not state.playerEsp
    espBtn.Text="PLAYER ESP: "..(state.playerEsp and "ON" or "OFF")
    espBtn.BackgroundColor3=state.playerEsp and C.green or C.soft
    updateEsp()
end)

local statsCard = card(player, "RUNTIME", "Live diagnostics for FPS, ping, inventory count and learned remote state.", 112)
local runtimeText = txt(statsCard, "FPS ? • Ping ? • Inventory 0", 11, C.soft, false)
runtimeText.Position=UDim2.new(0,16,0,56); runtimeText.Size=UDim2.new(1,-32,0,18)
local learnedText = txt(statsCard, "Baby remote: —   Pet remote: —", 10, C.muted, false)
learnedText.Position=UDim2.new(0,16,0,78); learnedText.Size=UDim2.new(1,-32,0,18)

-- ═══════════════════════════════════════════════════════════════════════
-- TASK + UI ACTION ENGINE
-- ═══════════════════════════════════════════════════════════════════════
local taskWords={"hungry","thirsty","sleepy","bored","dirty","school","sick","camping","hot spring","salon","pizza","task","need","needs","family","baby"}
local lastTask=os.clock()

local function runVisibleTaskPass()
    local pg=LP:FindFirstChildOfClass("PlayerGui")
    if not pg then return 0 end
    local hit=0
    local used={}
    for _,d in ipairs(pg:GetDescendants()) do
        if current() and (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Visible then
            local textValue=d:IsA("TextButton") and d.Text or d.Name
            local low=string.lower(tostring(textValue))
            for _,w in ipairs(taskWords) do
                if low:find(w,1,true) and not used[d] then
                    used[d]=true
                    local ok=pcall(function() d:Activate() end)
                    if ok then hit=hit+1 end
                    break
                end
            end
        end
    end
    return hit
end

-- ═══════════════════════════════════════════════════════════════════════
-- REMOTE / AUTO LOOPS
-- ═══════════════════════════════════════════════════════════════════════
LP.Idled:Connect(function()
    if not current() or not state.antiAfk then return end
    pcall(function()
        local vu=game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new(0,0))
    end)
end)

task.spawn(function()
    while current() do
        if state.autoBaby and state.learned.baby then
            invokeLearned("baby")
        end
        if state.autoPet and state.selectedPet and state.learned.pet then
            invokeLearned("pet",state.selectedPet)
        end
        if state.autoTasks and os.clock()-lastTask>=4 then
            local n=runVisibleTaskPass()
            taskStatus.Text="Task pass: "..tostring(n).." visible action(s) triggered."
            lastTask=os.clock()
        end
        updateEsp()
        task.wait(7)
    end
    clearEsp()
end)

task.spawn(function()
    local frames=0
    local t0=os.clock()
    while current() do
        frames=frames+1
        if os.clock()-t0>=1 then
            local fps=math.floor(frames/(os.clock()-t0))
            local ping="?"
            pcall(function() ping=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            runtimeText.Text="FPS "..tostring(fps).." • Ping "..tostring(ping).."ms • Inventory "..tostring(#state.inventory)
            learnedText.Text="Baby remote: "..(state.learned.baby and state.learned.baby.remoteName or "—")
                .."   Pet remote: "..(state.learned.pet and state.learned.pet.remoteName or "—")
            frames=0
            t0=os.clock()
        end
        task.wait()
    end
end)

task.spawn(function()
    while current() do
        if RemoteEngine.learning and os.clock()-RemoteEngine.learning.started>30 then
            remoteStatus.Text="Learn timeout. Press LEARN/perform the real action again."
            RemoteEngine.learning=nil
        end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- DRAG + MOBILE
-- ═══════════════════════════════════════════════════════════════════════
local dragging=false
local dragStart,startPos
header.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=i.Position; startPos=panel.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if not dragging or not current() then return end
    if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
        local d=i.Position-dragStart
        panel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)

if UIS.TouchEnabled and not UIS.KeyboardEnabled then
    panel.Size=UDim2.new(0,610,0,500)
    panel.Position=UDim2.new(.5,-305,.5,-250)
end

-- ═══════════════════════════════════════════════════════════════════════
-- BOOT
-- ═══════════════════════════════════════════════════════════════════════
dash.Visible=true
tabButtons["dashboard"].BackgroundColor3=C.primary
tabButtons["dashboard"].TextColor3=C.white

local okInv = pcall(function()
    scanInventory()
    inventoryStatus.Text="Inventory scan: "..tostring(#state.inventory).." entries"
end)
if not okInv then inventoryStatus.Text="Inventory scanner failed; UI fallback still available." end

pcall(function()
    local ok = installRemoteHook()
    remoteStatus.Text = ok and "Hook ready. Use LEARN BABY / LEARN PET to capture real actions."
        or "Hook not auto-installed; use CHECK HOOK for capability status."
end)

pcall(refreshInventory)
pcall(refreshRemoteCards)

task.spawn(function()
    while current() do
        if state.autoBaby and not state.learned.baby then
            babyStatus.Text="Auto Baby ON but no learned real remote yet."
        elseif state.learned.baby then
            babyStatus.Text="Baby action learned: "..tostring(state.learned.baby.remoteName)
        end
        if state.selectedPet then
            petStatus.Text="Pet: "..tostring(state.selectedPet.name).."  •  id="..tostring(state.selectedPet.id)
        end
        task.wait(2)
    end
end)
