local _, SUF = ...

local USAGE = "Use /suf, /suf options, /suf unlock, /suf lock, /suf reset, or /suf debug_shield."
local UNAVAILABLE = "Shields Up Forever is unavailable. Check the SUF login message."

-- Each command is one word; "" opens the settings. Handlers live in Core and
-- Options. Diagnostics also run when SUF is unavailable, to help explain why.
local COMMANDS = {
    [""] = {handler = "OpenSettings"},
    options = {handler = "OpenSettings"},
    unlock = {handler = "Unlock"},
    lock = {handler = "Lock"},
    reset = {handler = "ResetPosition"},
    debug_shield = {handler = "ReportShieldDebug", always = true},
}

function SUF.ParseCommand(message)
    if type(message) ~= "string" then
        return nil, USAGE
    end
    local command = message:match("^%s*(.-)%s*$"):lower()
    if command:find("%s") or not COMMANDS[command] then
        return nil, USAGE
    end
    return command
end

function SUF.HandleCommand(message)
    local command, usage = SUF.ParseCommand(message)
    if not command then
        SUF.Report(usage)
        return
    end
    local entry = COMMANDS[command]
    if not SUF.available and not entry.always then
        SUF.Report(UNAVAILABLE)
        return
    end
    SUF[entry.handler]()
end
