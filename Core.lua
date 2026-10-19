local addonName, DSU = ...

-- Dyre's Shields Up: the shield display from Mage Tools Forever on its own,
-- for any class (a Priest in the author's group asked for it). Shield.lua is
-- the shared component, byte-identical in every AddOn that ships it; this file
-- adapts it: saved settings, the lock, slash commands, and startup.
local DEFAULT_TITLE = "Dyre's Shields Up"
local READY_MESSAGE = "  Ready. Type /dsu to open the settings."
local SLASH_KEY = "DYRESSHIELDSUP"
local PRIMARY_SLASH = "/dsu"
local BACKUP_SLASH = "/shieldsup"
local MAX_SLASH_ALIASES = 10
local UNLOCK_HINT = "Drag to move · /dsu lock when done"
DSU.available = false

function DSU.Report(message)
    DEFAULT_CHAT_FRAME:AddMessage("DSU: " .. tostring(message))
end

-- Reads TOC fields so the banner follows the packaged version; never gates operations.
local function Metadata(field)
    if type(C_AddOns) ~= "table" or type(C_AddOns.GetAddOnMetadata) ~= "function" then
        return nil
    end
    local value = C_AddOns.GetAddOnMetadata(addonName, field)
    if type(value) == "string" and value:find("%S") then
        return value
    end
end

local function ReportLoaded(available)
    local banner = Metadata("Title") or DEFAULT_TITLE
    local version, author = Metadata("Version"), Metadata("Author")
    if version then
        banner = banner .. " " .. version
    end
    if author then
        banner = banner .. " by " .. author
    end
    DSU.Report(banner)
    if available then
        DSU.Report(READY_MESSAGE)
    end
end

-- Functions other runtime files must define. A mixed install of old and new
-- files otherwise fails silently, because the client hides Lua errors by default.
local REQUIRED_NAMESPACE = {"ParseCommand", "HandleCommand", "InitializeOptions", "OpenSettings"}
local REQUIRED_SHIELD = {"Initialize", "Sanitize", "Refresh", "ApplyBreakSound", "PreviewBreakSound",
    "SanitizeBreakSound", "SoundChoices", "SetupSoundMenu", "ResetPosition", "ReportDebug", "IsOwner",
    "OwnerAddOn"}

local function CheckInstalledFiles()
    local display = DSU.ShieldDisplay
    for _, name in ipairs(REQUIRED_SHIELD) do
        if type(display) ~= "table" or type(display[name]) ~= "function" then
            return false, "AddOn files are from different versions (missing Shield.lua " .. name
                .. "). Reinstall every Dyre's Shields Up file, then restart the client."
        end
    end
    for _, name in ipairs(REQUIRED_NAMESPACE) do
        if type(DSU[name]) ~= "function" then
            return false, "AddOn files are from different versions (missing " .. name
                .. "). Reinstall every Dyre's Shields Up file, then restart the client."
        end
    end
    return true
end

-- Per-character settings in DyresShieldsUpDB, repaired on load so a damaged
-- or older table can never break the AddOn. The shield component owns its
-- defaults, its lock included.
function DSU.SanitizeDB(db)
    db = type(db) == "table" and db or {}
    if DSU.ShieldDisplay then
        db.shield = DSU.ShieldDisplay.Sanitize(db.shield)
    end
    return db
end

-- Another AddOn can register the same slash command; the last one loaded wins.
-- Returns the other command key, or nil when /dsu is ours alone.
local function FindSlashConflict()
    for key in pairs(SlashCmdList) do
        if key ~= SLASH_KEY then
            for index = 1, MAX_SLASH_ALIASES do
                local alias = _G["SLASH_" .. key .. index]
                if type(alias) == "string" and alias:lower() == PRIMARY_SLASH then
                    return key
                end
            end
        end
    end
end

-- With Mage Tools Forever or Warlock Tools Forever also running, only one copy
-- of the display draws (Shield.lua elects it), and DSU's settings then do
-- nothing. Says so, and returns true, when another AddOn shows it.
function DSU.ShownElsewhere()
    if DSU.ShieldDisplay.IsOwner() then
        return false
    end
    DSU.Report("The shield display is shown by " .. tostring(DSU.ShieldDisplay.OwnerAddOn())
        .. "; use its settings for it.")
    return true
end

function DSU.RefreshShield()
    DSU.ShieldDisplay.Refresh()
    DSU.ShieldDisplay.ApplyBreakSound()
end

-- While unlocked, the display shows a sample of every part, outlined, to drag.
function DSU.SetLocked(locked)
    DSU.db.shield.locked = locked
    DSU.RefreshShield()
    if DSU.ShownElsewhere() then
        return
    end
    if locked then
        DSU.Report("Shield display locked.")
    else
        DSU.Report("Shield display unlocked: drag it where you want, then type /dsu lock.")
    end
end

function DSU.Unlock()
    DSU.SetLocked(false)
end

function DSU.Lock()
    DSU.SetLocked(true)
end

-- A plain frame, so it moves back at once, also in combat.
function DSU.ResetPosition()
    DSU.ShieldDisplay.ResetPosition()
    if not DSU.ShownElsewhere() then
        DSU.Report("Shield display moved back to its default place.")
    end
end

function DSU.ReportShieldDebug()
    if type(DSU.ShieldDisplay) ~= "table" or type(DSU.ShieldDisplay.ReportDebug) ~= "function" then
        DSU.Report("debug_shield: Shield.lua is missing.")
        return
    end
    DSU.ShieldDisplay.ReportDebug(DSU.Report)
end

SLASH_DYRESSHIELDSUP1 = PRIMARY_SLASH
SLASH_DYRESSHIELDSUP2 = BACKUP_SLASH
SlashCmdList[SLASH_KEY] = function(message) DSU.HandleCommand(message) end

local function LoadDB()
    DyresShieldsUpDB = DSU.SanitizeDB(DyresShieldsUpDB)
    DSU.db = DyresShieldsUpDB
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, loadedName)
    if event == "ADDON_LOADED" then
        if loadedName == addonName then
            self:UnregisterEvent("ADDON_LOADED")
            LoadDB()
        end
        return
    end
    self:UnregisterEvent("PLAYER_LOGIN")
    local available, message = CheckInstalledFiles()
    if available and not DSU.db then
        LoadDB()
    end
    DSU.available = available
    ReportLoaded(available)
    local conflict = FindSlashConflict()
    if conflict then
        DSU.Report("Another AddOn (" .. conflict .. ") also uses " .. PRIMARY_SLASH
            .. ". Use " .. BACKUP_SLASH .. " instead.")
    end
    if not available then
        DSU.Report(message)
        return
    end
    -- Any class: the display shows every absorb on you, and its icon row
    -- holds your own class's shields and the ones anyone can put on you.
    -- Called here rather than from each file's own PLAYER_LOGIN handler, so
    -- startup never depends on event handler order.
    DSU.ShieldDisplay.Initialize({settings = function() return DSU.db.shield end, report = DSU.Report,
        unlockHint = UNLOCK_HINT})
    DSU.InitializeOptions()
end)
