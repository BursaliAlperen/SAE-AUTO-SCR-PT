-- ScriptVault Steal an Egg 6.2 runtime lifecycle
local ENV = (type(getgenv) == "function" and getgenv()) or _G
local token = tostring({})
if ENV then ENV.SV_SAE_RUNTIME = token end

local M = {}
function M.isCurrent()
    return not ENV or ENV.SV_SAE_RUNTIME == token
end
function M.env()
    return ENV
end
function M.token()
    return token
end
function M.stopPrevious()
    if ENV then ENV.SV_SAE_RUNTIME = token end
end
return M
