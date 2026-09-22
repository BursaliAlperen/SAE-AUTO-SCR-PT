-- ScriptVault — Adopt Me profile
-- PlaceId: 920587237 (official Adopt Me! by Uplift Games)
-- This profile intentionally avoids guessing private/internal remotes.
-- It focuses on reliable UI diagnostics, task discovery, ESP, anti-AFK,
-- and a clean game-specific control panel.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local WS = game:GetService("Workspace")
local LP = Players.LocalPlayer

if not LP then return end

local ENV = (type(getgenv) == "function" and getgenv()) or _G
local ID = tostring({})
if ENV then ENV.SV_ADOPT_ME_ID = ID end
local function current()
    return not ENV or ENV.SV_ADOPT_ME_ID == ID
end

local function safe(fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    return ok, a, b, c
end

local old = (gethui and gethui() or nil)
local parent = old
if not parent then
    local cg = game:GetService("CoreGui")
    parent = cg
end
if not parent then
    parent = LP:FindFirstChildOfClass("PlayerGui")
end
if not parent then return end

local oldGui = parent:FindFirstChild("ScriptVault_AdoptMe")
if oldGui then pcall(function() oldGui:Destroy() end) end

local gui = Instance.new("ScreenGui")
gui.Name = "ScriptVault_AdoptMe"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999
gui.Parent = parent

local C = {
    bg = Color3.fromRGB(248,250,252),
    card = Color3.fromRGB(255,255,255),
    text = Color3.fromRGB(15,23,42),
    soft = Color3.fromRGB(71,85,105),
    muted = Color3.fromRGB(100,116,139),
    border = Color3.fromRGB(226,232,240),
    primary = Color3.fromRGB(124,58,237),
    primary2 = Color3.fromRGB(99,102,241),
    pink = Color3.fromRGB(236,72,153),
    green = Color3.fromRGB(16,185,129),
    red = Color3.fromRGB(239,68,68),
    yellow = Color3.fromRGB(245,158,11),
    white = Color3.fromRGB(255,255,255),
}

local function corner(p, r)
    local x=Instance.new("UICorner")
    x.CornerRadius=UDim.new(0,r)
    x.Parent=p
end

local function stroke(p, color, transparency)
    local x=Instance.new("UIStroke")
    x.Color=color or C.border
    x.Transparency=transparency or 0
    x.Thickness=1
    x.Parent=p
end

local function label(parent, text, size, color, font)
    local l=Instance.new("TextLabel")
    l.BackgroundTransparency=1
    l.Text=text
    l.TextColor3=color or C.text
    l.TextSize=size or 14
    l.Font=font or Enum.Font.Gotham
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.Parent=parent
    return l
end

local panel=Instance.new("Frame")
panel.Name="Panel"
panel.Size=UDim2.new(0,620,0,470)
panel.Position=UDim2.new(0.5,-310,0.5,-235)
panel.BackgroundColor3=C.bg
panel.BorderSizePixel=0
panel.Parent=gui
corner(panel,20)
stroke(panel,C.border,0)

local shadow=Instance.new("Frame")
shadow.Size=UDim2.new(1,-10,1,-10)
shadow.Position=UDim2.new(0,8,0,10)
shadow.BackgroundColor3=Color3.fromRGB(15,23,42)
shadow.BackgroundTransparency=.88
shadow.ZIndex=0
shadow.Parent=panel
corner(shadow,20)
panel.ZIndex=2

local header=Instance.new("Frame")
header.Size=UDim2.new(1,0,0,70)
header.BackgroundColor3=C.card
header.BorderSizePixel=0
header.Parent=panel
corner(header,20)

local title=label(header,"SCRIPTVAULT  /  ADOPT ME",18,C.text,Enum.Font.GothamBold)
title.Position=UDim2.new(0,24,0,12)
title.Size=UDim2.new(1,-180,0,25)

local sub=label(header,"Game-specific control center",11,C.muted)
sub.Position=UDim2.new(0,25,0,39)
sub.Size=UDim2.new(1,-180,0,18)

local badge=label(header,"ADOPT ME",11,C.white,Enum.Font.GothamBold)
badge.TextXAlignment=Enum.TextXAlignment.Center
badge.Position=UDim2.new(1,-120,0,18)
badge.Size=UDim2.new(0,90,0,30)
badge.BackgroundColor3=C.primary
corner(badge,10)

local close=Instance.new("TextButton")
close.Text="×"
close.TextSize=22
close.Font=Enum.Font.GothamBold
close.TextColor3=C.soft
close.BackgroundTransparency=1
close.Size=UDim2.new(0,34,0,34)
close.Position=UDim2.new(1,-42,0,2)
close.Parent=header
close.MouseButton1Click:Connect(function()
    if current() then gui.Enabled=false end
end)

local body=Instance.new("ScrollingFrame")
body.Position=UDim2.new(0,18,0,82)
body.Size=UDim2.new(1,-36,1,-100)
body.BackgroundTransparency=1
body.BorderSizePixel=0
body.ScrollBarThickness=4
body.CanvasSize=UDim2.new(0,0,0,0)
body.AutomaticCanvasSize=Enum.AutomaticSize.Y
body.Parent=panel

local layout=Instance.new("UIListLayout")
layout.Padding=UDim.new(0,10)
layout.Parent=body

local pad=Instance.new("UIPadding")
pad.PaddingBottom=UDim.new(0,16)
pad.Parent=body

local function card(text, desc)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,-4,0,74)
    f.BackgroundColor3=C.card
    f.BorderSizePixel=0
    f.Parent=body
    corner(f,14)
    stroke(f,C.border,.25)
    local t=label(f,text,14,C.text,Enum.Font.GothamBold)
    t.Position=UDim2.new(0,16,0,12)
    t.Size=UDim2.new(1,-32,0,22)
    local d=label(f,desc,11,C.muted)
    d.Position=UDim2.new(0,16,0,38)
    d.Size=UDim2.new(1,-32,0,22)
    return f
end

local state={antiAfk=false,playerEsp=false,taskScan=true}
local function button(parent,text,x,color)
    local b=Instance.new("TextButton")
    b.Text=text
    b.TextSize=12
    b.Font=Enum.Font.GothamBold
    b.TextColor3=C.white
    b.BackgroundColor3=color or C.primary
    b.BorderSizePixel=0
    b.Size=UDim2.new(0,145,0,34)
    b.Position=x
    b.AutoButtonColor=false
    b.Parent=parent
    corner(b,10)
    return b
end

local info=card("TASK DISCOVERY","Scans visible Adopt Me UI for current pet/player task text without guessing internal remotes.")
local scan=button(info,"SCAN NOW",UDim2.new(1,-161,0,20),C.primary)
local scanResult=label(info,"Ready.",11,C.soft)
scanResult.Position=UDim2.new(0,16,0,54)
scanResult.Size=UDim2.new(1,-180,0,18)

local function scanTasks()
    local found={}
    local seen={}
    local words={"hungry","thirsty","sleepy","bored","dirty","school","sick","camping","hot spring","salon","pizza","task","needs","need"}
    local function visit(root)
        for _,d in ipairs(root:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                local tx=(d.Text or ""):lower()
                if tx~="" then
                    for _,w in ipairs(words) do
                        if tx:find(w,1,true) and not seen[tx] then
                            seen[tx]=true
                            table.insert(found,tx)
                            break
                        end
                    end
                end
            end
        end
    end
    local pg=LP:FindFirstChildOfClass("PlayerGui")
    if pg then visit(pg) end
    if #found==0 then
        scanResult.Text="No visible task text detected."
    else
        local n=math.min(#found,3)
        local out={}
        for i=1,n do out[i]=found[i] end
        scanResult.Text="Detected: "..table.concat(out,"  •  ")
    end
end
scan.MouseButton1Click:Connect(scanTasks)

local espCard=card("PLAYER ESP","Highlights other players with a separate container so it never conflicts with task UI.")
local esp=button(espCard,"PLAYER ESP: OFF",UDim2.new(1,-161,0,20),C.soft)
local espFolder=Instance.new("Folder")
espFolder.Name="SV_AdoptMe_ESP"
espFolder.Parent=WS

local function clearESP()
    for _,x in ipairs(espFolder:GetChildren()) do pcall(function() x:Destroy() end) end
end
local function setESP(on)
    state.playerEsp=on
    esp.Text="PLAYER ESP: "..(on and "ON" or "OFF")
    esp.BackgroundColor3=on and C.green or C.soft
    if not on then clearESP() end
end
esp.MouseButton1Click:Connect(function() setESP(not state.playerEsp) end)

local afk=card("ANTI-AFK","Keeps the session active without changing game remotes.")
local afkBtn=button(afk,"ANTI-AFK: OFF",UDim2.new(1,-161,0,20),C.soft)
afkBtn.MouseButton1Click:Connect(function()
    state.antiAfk=not state.antiAfk
    afkBtn.Text="ANTI-AFK: "..(state.antiAfk and "ON" or "OFF")
    afkBtn.BackgroundColor3=state.antiAfk and C.green or C.soft
end)

local status=card("SESSION","PlaceId: "..tostring(game.PlaceId).."   •   "..LP.DisplayName)
local statusText=label(status,"Profile loaded successfully.",11,C.green)
statusText.Position=UDim2.new(0,16,0,48)
statusText.Size=UDim2.new(1,-32,0,18)

local drag=false
local dragStart, startPos
header.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        drag=true; dragStart=i.Position; startPos=panel.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if not drag or not current() then return end
    if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
        local d=i.Position-dragStart
        panel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
end)

if UIS.TouchEnabled and not UIS.KeyboardEnabled then
    panel.Size=UDim2.new(0,520,0,430)
    panel.Position=UDim2.new(.5,-260,.5,-215)
end

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
        if state.playerEsp then
            local alive={}
            for _,pl in ipairs(Players:GetPlayers()) do
                if pl~=LP and pl.Character then
                    alive[pl.Character]=true
                    local h=espFolder:FindFirstChild("P_"..pl.UserId)
                    if not h then
                        h=Instance.new("Highlight")
                        h.Name="P_"..pl.UserId
                        h.Adornee=pl.Character
                        h.FillColor=C.pink
                        h.FillTransparency=.62
                        h.OutlineColor=C.white
                        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                        h.Parent=espFolder
                    end
                end
            end
            for _,h in ipairs(espFolder:GetChildren()) do
                if not alive[h.Adornee] then pcall(function() h:Destroy() end) end
            end
        end
        task.wait(.8)
    end
    clearESP()
end)

task.spawn(function()
    while current() do
        if state.taskScan then scanTasks() end
        task.wait(5)
    end
end)

scanTasks()
