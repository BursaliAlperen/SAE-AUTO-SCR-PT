-- ScriptVault Steal an Egg 6.2 UI helpers
local M = {}
function M.safeDestroy(root, name)
    if not root then return end
    local ok, obj = pcall(function() return root:FindFirstChild(name) end)
    if ok and obj then pcall(function() obj:Destroy() end) end
end
function M.setVisible(gui, value)
    if gui then pcall(function() gui.Enabled = value end) end
end
return M
