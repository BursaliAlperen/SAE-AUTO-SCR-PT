-- ScriptVault Steal an Egg 6.2 safety / pacing module
local M = {}
local last = {}
function M.allow(key, interval)
    local now = os.clock()
    local gap = interval or 0.35
    if now - (last[key] or 0) < gap then return false end
    last[key] = now
    return true
end
function M.reset()
    table.clear(last)
end
function M.safeCall(fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    return ok, a, b, c
end
return M
