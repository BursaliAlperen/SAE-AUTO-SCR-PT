-- ScriptVault — Generic profile
-- Safe fallback for places without a dedicated game module.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local LP = Players.LocalPlayer
if not LP then return end

local ENV = (type(getgenv) == "function" and getgenv()) or _G
local ID = tostring({})
if ENV then ENV.SV_GENERIC_ID = ID end
local function current()
    return not ENV or ENV.SV_GENERIC_ID == ID
end

local parent
pcall(function() if type(gethui) == "function" then parent = gethui() end end)
if not parent then parent = game:GetService("CoreGui") end
if not parent then parent = LP:FindFirstChildOfClass("PlayerGui") end
if not parent then return end

local old = parent:FindFirstChild("ScriptVault_Generic")
if old then pcall(function() old:Destroy() end) end

local gui = Instance.new("ScreenGui")
gui.Name = "ScriptVault_Generic"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999
gui.Parent = parent

local C = {
    bg=Color3.fromRGB(248,250,252), white=Color3.fromRGB(255,255,255),
    text=Color3.fromRGB(15,23,42), muted=Color3.fromRGB(100,116,139),
    border=Color3.fromRGB(226,232,240), primary=Color3.fromRGB(99,102,241),
    green=Color3.fromRGB(16,185,129), red=Color3.fromRGB(239,68,68),
}

local function corner(p,r)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=p
end
local function stroke(p,c,t)
    local s=Instance.new("UIStroke"); s.Color=c or C.border; s.Transparency=t or 0; s.Thickness=1; s.Parent=p
end
local function text(p,txt,size,color,bold)
    local l=Instance.new("TextLabel")
    l.BackgroundTransparency=1; l.Text=txt or ""; l.TextSize=size or 14
    l.TextColor3=color or C.text; l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=p; return l
end

local panel=Instance.new("Frame")
panel.Size=UDim2.new(0,580,0,410); panel.Position=UDim2.new(.5,-290,.5,-205)
panel.BackgroundColor3=C.bg; panel.BorderSizePixel=0; panel.Parent=gui; corner(panel,18); stroke(panel)
local header=Instance.new("Frame"); header.Size=UDim2.new(1,0,0,70); header.BackgroundColor3=C.white
header.BorderSizePixel=0; header.Parent=panel; corner(header,18)
local title=text(header,"SCRIPTVAULT  /  GENERIC",18,C.text,true); title.Position=UDim2.new(0,20,0,12); title.Size=UDim2.new(1,-90,0,24)
local sub=text(header,"Fallback profile • unknown game",11,C.muted,false); sub.Position=UDim2.new(0,21,0,39); sub.Size=UDim2.new(1,-120,0,18)

local close=Instance.new("TextButton")
close.Text="×"; close.Font=Enum.Font.GothamBold; close.TextSize=22; close.TextColor3=C.muted
close.BackgroundTransparency=1; close.Size=UDim2.new(0,36,0,36); close.Position=UDim2.new(1,-42,0,8); close.Parent=header
close.Activated:Connect(function() gui.Enabled=false end)

local body=Instance.new("ScrollingFrame")
body.Position=UDim2.new(0,16,0,82); body.Size=UDim2.new(1,-32,1,-96)
body.BackgroundTransparency=1; body.BorderSizePixel=0; body.ScrollBarThickness=3
body.AutomaticCanvasSize=Enum.AutomaticSize.Y; body.Parent=panel
local list=Instance.new("UIListLayout"); list.Padding=UDim.new(0,10); list.Parent=body
local pad=Instance.new("UIPadding"); pad.PaddingBottom=UDim.new(0,12); pad.Parent=body

local info=Instance.new("Frame"); info.Size=UDim2.new(1,-4,0,110); info.BackgroundColor3=C.white
info.BorderSizePixel=0; info.Parent=body; corner(info,14); stroke(info,C.border,.25)
local a=text(info,"Session",14,C.text,true); a.Position=UDim2.new(0,16,0,12); a.Size=UDim2.new(1,-32,0,20)
local b=text(info,"PlaceId: "..tostring(game.PlaceId),11,C.muted); b.Position=UDim2.new(0,16,0,40); b.Size=UDim2.new(1,-32,0,18)
local c=text(info,"Player: "..LP.DisplayName.."  •  UserId: "..tostring(LP.UserId),11,C.muted); c.Position=UDim2.new(0,16,0,60); c.Size=UDim2.new(1,-32,0,18)
local d=text(info,"Profile: generic.lua",11,C.green,true); d.Position=UDim2.new(0,16,0,82); d.Size=UDim2.new(1,-32,0,18)

local services=Instance.new("Frame"); services.Size=UDim2.new(1,-4,0,98); services.BackgroundColor3=C.white
services.BorderSizePixel=0; services.Parent=body; corner(services,14); stroke(services,C.border,.25)
local st=text(services,"Runtime checks",14,C.text,true); st.Position=UDim2.new(0,16,0,12); st.Size=UDim2.new(1,-32,0,20)
local status=text(services,"Services: scanning...",11,C.muted); status.Position=UDim2.new(0,16,0,42); status.Size=UDim2.new(1,-32,0,18)
local fps=text(services,"FPS: ?   Ping: ?",11,C.muted); fps.Position=UDim2.new(0,16,0,64); fps.Size=UDim2.new(1,-32,0,18)

local drag,dragStart,startPos=false,nil,nil
header.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        drag=true; dragStart=i.Position; startPos=panel.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if not drag or not current() then return end
    if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
        local delta=i.Position-dragStart
        panel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
end)

local function update()
    local names={"Players","UserInputService","TweenService","ReplicatedStorage","Workspace","RunService"}
    local okCount=0
    for _,name in ipairs(names) do
        if pcall(function() return game:GetService(name) end) then okCount+=1 end
    end
    status.Text="Services: "..tostring(okCount).."/"..tostring(#names).." available"
end

task.spawn(function()
    local frames=0; local t0=os.clock()
    while current() do
        frames+=1
        if os.clock()-t0>=1 then
            local f=math.floor(frames/(os.clock()-t0))
            local ping="?"; pcall(function() ping=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            fps.Text="FPS: "..tostring(f).."   Ping: "..tostring(ping)
            frames=0; t0=os.clock()
        end
        task.wait()
    end
end)

update()
