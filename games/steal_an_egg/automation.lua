-- ScriptVault SAE 6.5 automation
-- Uses live ProximityPrompts and Humanoid:MoveTo.
-- No RemoteEvent/RemoteFunction invocation or server-validation bypass.

local M = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ENV = (type(getgenv) == "function" and getgenv()) or _G

local running, connection = false, nil
local lastAction, lastMove, lastTarget = 0, 0, nil
local stats = {actions=0, eggs=0, hatches=0, training=0, failures=0}

local function char()
    local p = Players.LocalPlayer
    return p and p.Character
end
local function root()
    local c = char()
    return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart)
end
local function hum()
    local c = char()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function text(prompt)
    local p = prompt.Parent
    return string.lower(table.concat({
        tostring(prompt.Name or ""),
        tostring(prompt.ActionText or ""),
        tostring(prompt.ObjectText or ""),
        tostring(p and p.Name or "")
    }, " "))
end
local function kind(prompt)
    local t = text(prompt)
    if t:find("hatch",1,true) or t:find("incub",1,true) or t:find("open egg",1,true) then return "hatch" end
    if t:find("treadmill",1,true) or t:find("train",1,true) or t:find("speed",1,true) then return "training" end
    if t:find("egg",1,true) or t:find("steal",1,true) or t:find("take",1,true) or t:find("grab",1,true) then return "egg" end
end
local function part(prompt)
    local p = prompt.Parent
    if not p then return nil end
    if p:IsA("BasePart") then return p end
    if p:IsA("Attachment") and p.Parent and p.Parent:IsA("BasePart") then return p.Parent end
    return p:FindFirstChildWhichIsA("BasePart", true)
end
local function scan()
    local r = root()
    if not r then return {} end
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local k = kind(obj)
            local bp = part(obj)
            if k and bp then
                list[#list+1] = {prompt=obj, part=bp, kind=k, distance=(bp.Position-r.Position).Magnitude}
            end
        end
    end
    local rank = {hatch=1, egg=2, training=3}
    table.sort(list, function(a,b)
        if rank[a.kind] ~= rank[b.kind] then return rank[a.kind] < rank[b.kind] end
        return a.distance < b.distance
    end)
    return list
end
local function activate(item)
    if type(fireproximityprompt) ~= "function" then return false end
    local ok = pcall(function() fireproximityprompt(item.prompt, 1, true) end)
    if not ok then stats.failures=stats.failures+1; return false end
    stats.actions=stats.actions+1
    if item.kind=="egg" then stats.eggs=stats.eggs+1 end
    if item.kind=="hatch" then stats.hatches=stats.hatches+1 end
    if item.kind=="training" then stats.training=stats.training+1 end
    lastAction=os.clock()
    return true
end
local function moveTo(item)
    local h=hum()
    if not h then return end
    if os.clock()-lastMove < 0.5 and lastTarget==item.part then return end
    lastMove=os.clock(); lastTarget=item.part
    pcall(function() h:MoveTo(item.part.Position) end)
end

function M.start()
    if running then return false,"already running" end
    if type(fireproximityprompt) ~= "function" then return false,"fireproximityprompt unavailable" end
    running=true
    if ENV then ENV.SV_SAE_AUTOMATION_RUNNING=true end
    connection=RunService.Heartbeat:Connect(function()
        if not running or os.clock()-lastAction < 0.8 then return end
        local target=scan()[1]
        if not target then return end
        local r=root()
        if not r then return end
        local activation=math.max(8, tonumber(target.prompt.MaxActivationDistance) or 10)
        if target.distance > activation then moveTo(target) else activate(target) end
    end)
    return true
end

function M.stop()
    running=false
    if connection then pcall(function() connection:Disconnect() end) end
    connection=nil; lastTarget=nil
    if ENV then ENV.SV_SAE_AUTOMATION_RUNNING=false end
end
function M.status()
    return {running=running,supported=type(fireproximityprompt)=="function",actions=stats.actions,eggs=stats.eggs,hatches=stats.hatches,training=stats.training,failures=stats.failures}
end
return M
