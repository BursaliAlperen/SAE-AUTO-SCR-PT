-- ScriptVault SAE 6.6 automation
-- Robust prompt-driven automation with respawn recovery, target reacquisition,
-- per-prompt cooldowns, stuck detection and bounded error recovery.
-- No RemoteEvent/RemoteFunction invocation or server-validation bypass.

local M = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ENV = (type(getgenv) == "function" and getgenv()) or _G

local running, connection, charConnection = false, nil, nil
local characterRef, humanoidRef, rootRef
local currentTarget
local targetStartedAt, lastProgressAt, lastScanAt = 0, 0, 0
local lastAction = 0
local scanCache = {}
local promptCooldown = {}
local failureStreak, recoveryUntil = 0, 0

local CFG = {
    ACTION_COOLDOWN = 0.8,
    PROMPT_COOLDOWN = 2.0,
    SCAN_INTERVAL = 0.35,
    TARGET_TIMEOUT = 7,
    PROGRESS_TIMEOUT = 2.5,
    RECOVERY_DELAY = 1.5,
    MAX_FAILURE_STREAK = 5,
    REACQUIRE_DISTANCE = 45,
}

local stats = {
    actions=0, eggs=0, hatches=0, training=0,
    failures=0, rescans=0, recoveries=0, respawns=0, noTargets=0
}

local function now() return os.clock() end

local function bindCharacter(c)
    characterRef = c
    humanoidRef = nil
    rootRef = nil
    currentTarget = nil
    targetStartedAt = 0
    lastProgressAt = now()
    recoveryUntil = now() + 1
    stats.respawns = stats.respawns + 1

    pcall(function() humanoidRef = c:WaitForChild("Humanoid", 5) end)
    pcall(function() rootRef = c:WaitForChild("HumanoidRootPart", 5) end)
end

local function refreshCharacter()
    local c = Players.LocalPlayer and Players.LocalPlayer.Character
    if c ~= characterRef then
        if c then bindCharacter(c) end
    end
    if characterRef and characterRef.Parent then
        if not humanoidRef or not humanoidRef.Parent then humanoidRef=characterRef:FindFirstChildOfClass("Humanoid") end
        if not rootRef or not rootRef.Parent then rootRef=characterRef:FindFirstChild("HumanoidRootPart") end
    end
    return characterRef, humanoidRef, rootRef
end

local function text(prompt)
    local p=prompt.Parent
    return string.lower(table.concat({
        tostring(prompt.Name or ""), tostring(prompt.ActionText or ""),
        tostring(prompt.ObjectText or ""), tostring(p and p.Name or "")
    }," "))
end

local function kind(prompt)
    local t=text(prompt)
    if t:find("hatch",1,true) or t:find("incub",1,true) or t:find("open egg",1,true) then return "hatch" end
    if t:find("treadmill",1,true) or t:find("train",1,true) or t:find("speed",1,true) then return "training" end
    if t:find("egg",1,true) or t:find("steal",1,true) or t:find("take",1,true) or t:find("grab",1,true) then return "egg" end
end

local function part(prompt)
    local p=prompt.Parent
    if not p then return nil end
    if p:IsA("BasePart") then return p end
    if p:IsA("Attachment") and p.Parent and p.Parent:IsA("BasePart") then return p.Parent end
    return p:FindFirstChildWhichIsA("BasePart",true)
end

local function validPrompt(p)
    return p and p.Parent and p:IsDescendantOf(Workspace) and p.Enabled
end

local function scan()
    local r=refreshCharacter()
    if not r then return {} end
    local list={}
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local k=kind(obj)
            local bp=part(obj)
            if k and bp then
                local ok,dist=pcall(function() return (bp.Position-rootRef.Position).Magnitude end)
                if ok then list[#list+1]={prompt=obj,part=bp,kind=k,distance=dist} end
            end
        end
    end
    local rank={hatch=1,egg=2,training=3}
    table.sort(list,function(a,b)
        if rank[a.kind]~=rank[b.kind] then return rank[a.kind]<rank[b.kind] end
        return a.distance<b.distance
    end)
    stats.rescans=stats.rescans+1
    scanCache=list
    lastScanAt=now()
    return list
end

local function chooseTarget()
    if now()-lastScanAt >= CFG.SCAN_INTERVAL or #scanCache==0 then scan() end
    for _,item in ipairs(scanCache) do
        if validPrompt(item.prompt) and item.part.Parent then
            if item.distance <= CFG.REACQUIRE_DISTANCE or item.kind=="hatch" then return item end
        end
    end
    return nil
end

local function cooldownKey(prompt)
    return prompt
end

local function canActivate(prompt)
    local t=promptCooldown[cooldownKey(prompt)] or 0
    return now()-t >= CFG.PROMPT_COOLDOWN
end

local function activate(item)
    if not validPrompt(item.prompt) or not canActivate(item.prompt) then return false,"cooldown" end
    if type(fireproximityprompt)~="function" then return false,"fireproximityprompt unavailable" end

    promptCooldown[item.prompt]=now()
    local ok=pcall(function()
        fireproximityprompt(item.prompt,1,true)
    end)
    if not ok then
        stats.failures=stats.failures+1
        failureStreak=failureStreak+1
        return false,"activation failed"
    end

    stats.actions=stats.actions+1
    if item.kind=="egg" then stats.eggs=stats.eggs+1 end
    if item.kind=="hatch" then stats.hatches=stats.hatches+1 end
    if item.kind=="training" then stats.training=stats.training+1 end
    lastAction=now()
    failureStreak=0
    currentTarget=nil
    return true
end

local function moveTo(item)
    refreshCharacter()
    if not humanoidRef or not rootRef or not item.part or not item.part.Parent then return false end

    local distance=(item.part.Position-rootRef.Position).Magnitude
    if distance <= math.max(8,tonumber(item.prompt.MaxActivationDistance) or 10) then
        return true
    end

    if currentTarget~=item then
        currentTarget=item
        targetStartedAt=now()
        lastProgressAt=now()
    end

    pcall(function() humanoidRef:MoveTo(item.part.Position) end)
    return true
end

local function recover(reason)
    stats.recoveries=stats.recoveries+1
    recoveryUntil=now()+CFG.RECOVERY_DELAY
    currentTarget=nil
    scanCache={}
    lastScanAt=0
    failureStreak=0

    if humanoidRef and humanoidRef.Parent then
        pcall(function() humanoidRef:MoveTo(rootRef and rootRef.Position or Vector3.zero) end)
    end

    if ENV then ENV.SV_SAE_AUTOMATION_LAST_RECOVERY=tostring(reason) end
end

local function tickAutomation()
    if not running or now()<recoveryUntil then return end
    refreshCharacter()
    if not characterRef or not humanoidRef or not rootRef then
        recoveryUntil=now()+0.5
        return
    end
    if humanoidRef.Health<=0 then
        recoveryUntil=now()+1
        return
    end
    if now()-lastAction<CFG.ACTION_COOLDOWN then return end

    if failureStreak>=CFG.MAX_FAILURE_STREAK then
        recover("failure-streak")
        return
    end

    local target=chooseTarget()
    if not target then
        stats.noTargets=stats.noTargets+1
        return
    end

    if currentTarget and (now()-targetStartedAt)>CFG.TARGET_TIMEOUT then
        recover("target-timeout")
        return
    end

    local distance=(target.part.Position-rootRef.Position).Magnitude
    target.distance=distance

    local activationDistance=math.max(8,tonumber(target.prompt.MaxActivationDistance) or 10)
    if distance>activationDistance then
        if currentTarget==target and distance<((currentTarget.lastDistance or distance)+1) then
            currentTarget.lastDistance=distance
            lastProgressAt=now()
        elseif currentTarget==target and now()-lastProgressAt>CFG.PROGRESS_TIMEOUT then
            recover("movement-stuck")
            return
        else
            currentTarget=target
            currentTarget.lastDistance=distance
            lastProgressAt=now()
        end
        moveTo(target)
        return
    end

    local ok,reason=activate(target)
    if not ok and reason~="cooldown" then
        if failureStreak>=3 then recover(reason) end
    end
end

function M.start()
    if running then return false,"already running" end
    if type(fireproximityprompt)~="function" then return false,"fireproximityprompt unavailable" end

    running=true
    refreshCharacter()
    if charConnection then pcall(function() charConnection:Disconnect() end) end
    charConnection=Players.LocalPlayer.CharacterAdded:Connect(function(c)
        task.defer(function() bindCharacter(c) end)
    end)

    if ENV then ENV.SV_SAE_AUTOMATION_RUNNING=true end

    connection=RunService.Heartbeat:Connect(function()
        local ok,err=pcall(tickAutomation)
        if not ok then
            stats.failures=stats.failures+1
            failureStreak=failureStreak+1
            if failureStreak>=CFG.MAX_FAILURE_STREAK then recover(err) end
        end
    end)
    return true
end

function M.stop()
    running=false
    if connection then pcall(function() connection:Disconnect() end) end
    if charConnection then pcall(function() charConnection:Disconnect() end) end
    connection=nil; charConnection=nil
    currentTarget=nil; scanCache={}
    if ENV then ENV.SV_SAE_AUTOMATION_RUNNING=false end
end

function M.status()
    return {
        running=running,
        supported=type(fireproximityprompt)=="function",
        target=currentTarget and tostring(currentTarget.kind) or nil,
        failures=stats.failures,
        failureStreak=failureStreak,
        recoveries=stats.recoveries,
        respawns=stats.respawns,
        rescans=stats.rescans,
        noTargets=stats.noTargets,
        actions=stats.actions,
        eggs=stats.eggs,
        hatches=stats.hatches,
        training=stats.training
    }
end

return M
