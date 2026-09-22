-- ScriptVault SAE diagnostics 6.3
-- Runtime-only discovery. It never invokes, hooks, or alters remotes.
local M = {}

local function safe(fn, fallback)
    local ok, value = pcall(fn)
    if ok then return value end
    return fallback
end

local function pathOf(obj)
    return safe(function() return obj:GetFullName() end, obj.Name)
end

function M.scan()
    local report = {
        placeId = safe(function() return game.PlaceId end, -1),
        jobId = safe(function() return game.JobId end, ""),
        remotes = {},
        prompts = {},
        folders = {},
        counts = {},
    }

    local function add(list, value, limit)
        if #list < limit then list[#list + 1] = value end
    end

    local function walk(root)
        if not root then return end
        local ok, descendants = pcall(function() return root:GetDescendants() end)
        if not ok then return end
        for _, obj in ipairs(descendants) do
            local class = safe(function() return obj.ClassName end, "")
            if class == "RemoteEvent" or class == "RemoteFunction" or class == "UnreliableRemoteEvent" then
                add(report.remotes, {
                    class = class,
                    name = safe(function() return obj.Name end, "?"),
                    path = pathOf(obj),
                }, 300)
            elseif class == "ProximityPrompt" then
                add(report.prompts, {
                    name = safe(function() return obj.Name end, "?"),
                    action = safe(function() return obj.ActionText end, ""),
                    object = safe(function() return obj.ObjectText end, ""),
                    path = pathOf(obj),
                }, 200)
            elseif class == "Folder" then
                local name = string.lower(safe(function() return obj.Name end, ""))
                if string.find(name, "egg", 1, true)
                    or string.find(name, "base", 1, true)
                    or string.find(name, "pet", 1, true)
                    or string.find(name, "player", 1, true) then
                    add(report.folders, pathOf(obj), 150)
                end
            end
        end
    end

    walk(safe(function() return game:GetService("ReplicatedStorage") end, nil))
    walk(safe(function() return game:GetService("Workspace") end, nil))

    report.counts.remotes = #report.remotes
    report.counts.prompts = #report.prompts
    report.counts.folders = #report.folders
    return report
end

function M.isTargetPlace(config)
    local id = safe(function() return game.PlaceId end, -1)
    for _, allowed in ipairs((config and config.PRIMARY_PLACE_IDS) or {}) do
        if tonumber(allowed) == tonumber(id) then return true end
    end
    return false
end

function M.publish(report)
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if env then env.SV_SAE_DIAGNOSTICS = report end

    pcall(function()
        print(string.format("[SV-SAE] PlaceId=%s | Remotes=%d | Prompts=%d | RelevantFolders=%d",
            tostring(report.placeId),
            report.counts.remotes,
            report.counts.prompts,
            report.counts.folders
        ))
    end)

    return report
end

return M
