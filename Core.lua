local addonName, DSU = ...

-- Dyre's Shields Up: the shield display from Mage Tools Forever on its own,
-- for any class (a Priest in the author's group asked for it). Shield.lua is
-- the shared component, byte-identical in every AddOn that ships it; this file
-- adapts it: saved settings, the lock, slash commands, and startup. The ring
-- is a Dyre's Toolkit widget (contract 2, author: "all the widget layout,
-- snapping, modifier key move rules, etc., centralized in Dyre's Tools"): the
-- toolkit places, drags, snaps, sizes from the center, outlines, and saves
-- it; DSU never moves or scales it. Without contract 2 DSU stays off.
local DEFAULT_TITLE = "Dyre's Shields Up"
local READY_MESSAGE = "  Ready. Type /dsu to open the settings."
local SLASH_KEY = "DYRESSHIELDSUP"
local PRIMARY_SLASH = "/dsu"
local BACKUP_SLASH = "/shieldsup"
local MAX_SLASH_ALIASES = 10
local TOOLKIT_CONTRACT = 2
local TOOLKIT_FUNCTIONS = {"RegisterAddOn", "RegisterSettingsCategory", "IsLocked", "SetLocked", "OpenSettings",
    "CreateWidget", "AddWidgetSettings"}
local TOOLKIT_MISSING = "Dyre's Shields Up needs Dyre's Toolkit 2.0 or later: install or update it from "
    .. "CurseForge. DSU stays off until then."
local WIDGET_KEY = "shield"
-- Mage Tools Forever and Warlock Tools Forever drew this display before DSU
-- drew it for everyone (author-approved, 1.2.0): a character's first DSU login
-- copies its class's AddOn's shield settings once, so no layout resets. By
-- class, since both AddOns make a default shield table on every class.
local SETTINGS_SOURCES = {
    MAGE = {addon = "MageToolsForever", title = "Mage Tools Forever", saved = "MageToolsForeverDB"},
    WARLOCK = {addon = "WarlockToolsForever", title = "Warlock Tools Forever", saved = "WarlockToolsForeverDB"},
}
-- The same keys in all three (the shared display's Sanitize); not locked,
-- which is the toolkit's lock.
local COPIED_KEYS = {"enabled", "number", "breakSound", "breakSoundKey", "scale", "textScale", "iconScale",
    "position"}
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
    if type(db.migratedFrom) ~= "string" then
        db.migratedFrom = nil
    end
    return db
end

-- Once per character, only when DSU had no saved settings here: the class's
-- AddOn's shield settings, read (never written) and repaired. Saved variables
-- of every enabled AddOn are loaded by PLAYER_LOGIN.
function DSU.CopyShieldSettings()
    if not DSU.newCharacter or DSU.db.migratedFrom or type(UnitClass) ~= "function" then
        return
    end
    local _, class = UnitClass("player")
    local source = SETTINGS_SOURCES[class]
    local saved = source and rawget(_G, source.saved)
    local shield = type(saved) == "table" and saved.shield
    if type(shield) ~= "table" then
        return
    end
    local copy = {}
    for _, key in ipairs(COPIED_KEYS) do
        copy[key] = shield[key]
    end
    -- Sanitize builds new tables, the position too, so the source stays as it is.
    DSU.db.shield = DSU.ShieldDisplay.Sanitize(copy)
    DSU.db.migratedFrom = source.addon
    DSU.Report("Copied your shield settings from " .. source.title .. ".")
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

-- Dyre's Toolkit with the contract and functions DSU uses, else nil.
function DSU.Toolkit()
    local toolkit = rawget(_G, "DyresToolkit")
    if type(toolkit) ~= "table" or type(toolkit.RequireContract) ~= "function" then
        return nil
    end
    toolkit = toolkit.RequireContract(TOOLKIT_CONTRACT)
    if type(toolkit) ~= "table" then
        return nil
    end
    for _, name in ipairs(TOOLKIT_FUNCTIONS) do
        if type(toolkit[name]) ~= "function" then
            return nil
        end
    end
    return toolkit
end

-- One layout mode for every Dyre's AddOn: the toolkit says one line for all,
-- draws the outline, and calls the widget's onUnlock, which shows the sample.
function DSU.SetLocked(locked)
    DSU.toolkit.SetLocked(locked)
    DSU.ShownElsewhere()
end

-- The display hands its built ring over (Shield.lua's layout.adopt), and the
-- ring becomes a widget whose store is DSU's shield settings: the saved place
-- and size (keys position and scale) carry over as they are. No widget
-- opacity: the ring's inner frame fades with the secret absorb.
local function PartSize(label)
    local display = DSU.ShieldDisplay
    return {min = display.SCALE_MIN, max = display.SCALE_MAX, step = display.SCALE_STEP,
        default = display.DEFAULT_SCALE, label = label, percent = label ~= nil or nil}
end

local function AdoptRing(frame)
    local display = DSU.ShieldDisplay
    DSU.shieldWidget = DSU.toolkit.CreateWidget({
        addon = addonName,
        key = WIDGET_KEY,
        title = Metadata("Title") or DEFAULT_TITLE,
        frame = frame,
        store = DSU.db.shield,
        width = display.SIZE,
        height = display.SIZE,
        point = display.DEFAULT_PLACE,
        -- The crescents' size, then the number's and the icon row's, which
        -- the display keeps apart from it (author-approved).
        sizes = {scale = PartSize(), textScale = PartSize("Text size"), iconScale = PartSize("Icon size")},
        sizeOrder = {"scale", "textScale", "iconScale"},
        onLayout = function() DSU.ShieldDisplay.Refresh() end,
        onUnlock = function(_, unlocked)
            DSU.db.shield.locked = not unlocked
            DSU.RefreshShield()
        end,
    })
end

local function ResetRing()
    DSU.shieldWidget:ResetPosition()
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
    -- No saved settings: DSU has never run on this character.
    DSU.newCharacter = DyresShieldsUpDB == nil
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
    -- Before the display reads its settings; also when DSU then stays off, so
    -- the copy is there once the toolkit is.
    DSU.CopyShieldSettings()
    local toolkit = DSU.Toolkit()
    if not toolkit then
        DSU.available = false
        DSU.Report(TOOLKIT_MISSING)
        return
    end
    DSU.toolkit = toolkit
    -- The toolkit's frames start locked at login; DSU's follow.
    DSU.db.shield.locked = toolkit.IsLocked()
    -- Any class: the display shows every absorb on you, and its icon row
    -- holds your own class's shields and the ones anyone can put on you.
    -- Called here rather than from each file's own PLAYER_LOGIN handler, so
    -- startup never depends on event handler order.
    DSU.ShieldDisplay.Initialize({settings = function() return DSU.db.shield end, report = DSU.Report,
        layout = {adopt = AdoptRing, resetPosition = ResetRing}})
    DSU.InitializeOptions()
    toolkit.RegisterAddOn({addon = addonName, title = Metadata("Title") or DEFAULT_TITLE,
        openSettings = DSU.OpenSettings})
end)
