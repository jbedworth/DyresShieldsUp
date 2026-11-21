local _, DSU = ...

local USAGE = "Use /dsu, /dsu options, /dsu unlock, /dsu lock, /dsu reset, or /dsu debug_shield."
local UNAVAILABLE = "Dyre's Shields Up is unavailable. Check the DSU login message."

-- Each command is one word; "" opens the settings. Handlers live in Core and
-- Options. Diagnostics also run when DSU is unavailable, to help explain why.
local COMMANDS = {
    [""] = {handler = "OpenSettings"},
    options = {handler = "OpenSettings"},
    unlock = {handler = "Unlock"},
    lock = {handler = "Lock"},
    reset = {handler = "ResetPosition"},
    debug_shield = {handler = "ReportShieldDebug", always = true},
}

function DSU.ParseCommand(message)
    if type(message) ~= "string" then
        return nil, USAGE
    end
    local command = message:match("^%s*(.-)%s*$"):lower()
    if command:find("%s") or not COMMANDS[command] then
        return nil, USAGE
    end
    return command
end

function DSU.HandleCommand(message)
    local command, usage = DSU.ParseCommand(message)
    if not command then
        DSU.Report(usage)
        return
    end
    local entry = COMMANDS[command]
    if not DSU.available and not entry.always then
        DSU.Report(UNAVAILABLE)
        return
    end
    DSU[entry.handler]()
end
