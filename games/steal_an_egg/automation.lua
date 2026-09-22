-- ScriptVault SAE 6.4 automation
-- Prompt-driven automation only. It uses objects/prompts that exist in the live client.
-- It does not invoke RemoteEvents/RemoteFunctions or bypass server validation.
local M = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ENV = (type(getgenv) == "function" and getgenv()) or _G
local running = false
local connection
local lastAction = 0

local function rootPart()
    local p = Players.LocalPlayer
    local c = p and p.Character
    return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart)
end

local function promptText(prompt)
    local a = string.lower(tostring(prompt.ActionText or ""))
    local o = string.lower(tostring(prompt.ObjectText or ""))
    local n = string.lower(tostring(prompt.Parent and prompt.Parent.Name or ""))
    return a .. " " .. o .. " " .. n
end

local function isEggPrompt(prompt)
    local t = promptText(prompt)
    return string.find(t, "egg", 1, true)
        or string.find(t, "steal", 1, true)
        or string.find(t, "take", 1, true)
        or string.find(t, "grab", 1, true)
end

local function isHatchPrompt(prompt)
    local t = promptText(prompt)
    return string.find(t, "hatch", 1, true)
        or string.find(t, "place egg", 1, true)
        or string.find(t, "incub", 1, true)
end

local function fire(prompt)
    if type(fireproximityprompt) ~= "function" then
        return false, "fireproximityprompt unavailable"
    end
    local ok, err = pcall(function()
        fireproximityprompt(prompt, 1, true)
    end)
    return ok, err
end

local function nearestPrompt(test)
    local hrp = rootPart()
    if not hrp then return nil end

    local best, bestDistance
    local descendants = Workspace:GetDescendants()
    for _, obj in ipairs(descendants) do
        if obj:IsA("ProximityPrompt") and obj.Enabled and test(obj) then
            local parent = obj.Parent
            local part = parent and (parent:IsA("BasePart") and parent or parent:FindFirstChildWhichIsA("BasePart", true))
            if part then
                local d = (part.Position - hrp.Position).Magnitude
                if d <= math.max(obj.MaxActivationDistance or 10, 10) + 2 then
                    if not bestDistance or d < bestDistance then
                        best, bestDistance = obj, d
                    end
                end
            end
        end
    end
    return best, bestDistance
end

function M.start()
    if running then return false, "already running" end
    running = true
    if ENV then ENV.SV_SAE_AUTOMATION_RUNNING = true end

    connection = RunService.Heartbeat:Connect(function()
        if not running then return end
        if os.clock() - lastAction < 0.8 then return end

        -- Hatch/place locally available eggs first.
        local hatch = nearestPrompt(isHatchPrompt)
        if hatch then
            local ok = fire(hatch)
            if ok then lastAction = os.clock() end
            return
        end

        -- Then pick up a nearby egg. No teleporting and no remote invocation.
        local egg = nearestPrompt(isEggPrompt)
        if egg then
            local ok = fire(egg)
            if ok then lastAction = os.clock() end
        end
    end)

    return true
end

function M.stop()
    running = false
    if connection then
        pcall(function() connection:Disconnect() end)
        connection = nil
    end
    if ENV then ENV.SV_SAE_AUTOMATION_RUNNING = false end
end

function M.status()
    return {
        running = running,
        fireProximityPrompt = type(fireproximityprompt) == "function",
    }
end

return M
