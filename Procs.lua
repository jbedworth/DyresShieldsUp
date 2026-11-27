local _, DSU = ...

-- Proc cues moved to Dyre's Buff Reminders in 1.5.0 (John, 2026-11-20: DBR is
-- "a better fit for all buffs/procs ... This lets DSU focus on managing just
-- absorption shield rendering"). DSU 1.4.x drew the proc arcs and played
-- their sounds through Dyre's Toolkit's proc engine; DBR 1.13.0 now holds the
-- catalog, the art, and the SpellActivationOverlay step-aside. DSU keeps only
-- the shield display, plus this file: a settings row that links to DBR's page
-- and one chat line per character that had a proc on.
--
-- The 1.4.x proc data in DyresShieldsUpDB stays as it was, never repaired or
-- removed: DBR 1.13.0 reads it once to import the player's choices. Keys:
-- procs (arc and sound switches, sounds, the arcs' place and size), procIDs
-- (buff IDs read in client), procsWithSAO.
DSU.LEGACY_PROC_KEYS = {"procs", "procIDs", "procsWithSAO"}
DSU.PROCS_ADDON = "DyresBuffReminders"
DSU.PROCS_MOVED = "Proc arcs and sounds moved to Dyre's Buff Reminders."
local PROCS_ROW = "Proc cues moved to Dyre's Buff Reminders"
local PROCS_BUTTON = "Open Buff Reminders"
local PROCS_TOOLTIP = "Proc arcs and sounds moved to Dyre's Buff Reminders, with your choices."
local PROCS_MISSING = "Proc arcs and sounds moved to Dyre's Buff Reminders: install it from CurseForge "
    .. "to keep them."

-- The 1.4.x catalog's keys by class (DSU 1.4.x Procs.lua), to tell whether
-- this character had a proc of its own class on. 1.4.x saved a switch for
-- every key on every character, so other classes' keys say nothing.
local LEGACY_CLASS_PROCS = {
    MAGE = {"missilebarrage", "fingersoffrost"},
    WARLOCK = {"nightfall", "decimation"},
    DRUID = {"druidclearcasting"},
    SHAMAN = {"shamanclearcasting"},
    WARRIOR = {"overpower", "revenge"},
}

-- Whether DSU 1.4.x left a proc of this character's class switched on: its
-- arcs or its sound.
function DSU.HadProcsOn(db)
    local saved = type(db) == "table" and db.procs
    if type(saved) ~= "table" or type(UnitClass) ~= "function" then
        return false
    end
    local _, class = UnitClass("player")
    local arc = type(saved.arc) == "table" and saved.arc or {}
    local sound = type(saved.sound) == "table" and saved.sound or {}
    for _, key in ipairs(LEGACY_CLASS_PROCS[class] or {}) do
        if arc[key] == true or sound[key] == true then
            return true
        end
    end
    return false
end

-- Once per character, at login: one chat line when DSU 1.4.x had a proc on
-- here. Marked as said either way, so it never comes back.
function DSU.NoteProcsMoved()
    if DSU.db.procsMovedNoted then
        return
    end
    if DSU.HadProcsOn(DSU.db) then
        DSU.Report(DSU.PROCS_MOVED)
    end
    DSU.db.procsMovedNoted = true
end

-- The settings row: Dyre's Toolkit's link to DBR's page (Toolkit 2.3.0),
-- greyed with the note while DBR is missing. An older Toolkit gets no row;
-- the chat line still says where the procs went.
function DSU.AddProcsMovedRow(category, layout)
    local toolkit = DSU.toolkit
    if type(toolkit) ~= "table" or type(toolkit.AddSettingsLink) ~= "function" then
        return nil
    end
    return toolkit.AddSettingsLink(category, layout, {addon = DSU.PROCS_ADDON, name = PROCS_ROW,
        button = PROCS_BUTTON, tooltip = PROCS_TOOLTIP, missing = PROCS_MISSING})
end
