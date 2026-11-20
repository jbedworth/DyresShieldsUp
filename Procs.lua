local addonName, DSU = ...

-- Proc overlays (John, 2026-11-18: "DSU is the right home for our 'spell
-- activation overlays'; we already do this for the shields, which is an
-- activation overlay, across various classes"; "build the catalog one set of
-- classes at a time, starting with a simple set of mage, warlock, paladin, and
-- warrior overlays, in DSU"). DSU holds every class's proc data and art and is
-- the one caller of Dyre's Toolkit's proc engine (Toolkit 2.11.0 Procs.lua,
-- RegisterProcs): the engine draws an arc each side of the caster while a
-- proc's buff is up and plays a sound when it appears, in combat too. DSU
-- keeps the settings (db.procs) and the buff IDs read in client (db.procIDs).
-- The Mage and Warlock entries moved here from Mage Tools Forever and Warlock
-- Tools Forever (their unreleased proc code), with the same keys, which Dyre's
-- Buff Reminders' Proc Chimes match on (the engine claims Owners
-- "proc:<key>", so DBR steps aside).
--
-- SpellActivationOverlay (John: "We'll plan to coexist"): with that AddOn
-- loaded, DSU registers no procs, unless the player turns on "Show Dyre's
-- proc overlays with SpellActivationOverlay" (off by default). Registering
-- claims Owners "proc:<key>", which also silences DBR's Proc Chimes, so not
-- registering leaves SAO's overlays and DBR's chimes as they are. Decided at
-- PLAYER_LOGIN, when every AddOn of the login has loaded
-- (SpellActivationOverlay loads after DSU, by folder name). DSU never reads
-- SAO's own code or data.

-- Mage (from Mage Tools Forever). Missile Barrage (Forever): talents 400588
-- (TalentsForeverBook's Data.lua) and 1326083; buff 400589 (a fact from
-- MageProcs 1.13.0, datamined from build 1.60.1.70338; no code or art from
-- it); 1326083 is a talent here, since its passive aura would keep the arcs
-- up; 44401 is a spare candidate. Fingers of Frost (Forever): talent 400647,
-- 2 ranks, rank 2 gives 2 charges (TalentsForeverBook); buff 400670 (a fact
-- from MageProcs: 2 stacks, 15 s); 44544 the old expansion's buff, a spare.
-- stacks = 2: the right arc shows only while both charges are up (Toolkit
-- Procs.lua, "Stacks"). Its sound is a Dyre's Frosty sound (Dyre's Sounds
-- 1.7.0); with an older Dyre's Sounds the engine's default plays. Frost is
-- not checked in client (no Frost Mage to test with; Frost checks never hold
-- a release).
-- Warlock (from Warlock Tools Forever). Nightfall: talent 18094 (Forever's,
-- and Classic Era's rank 1); 18095 is Classic Era's rank 2 (from memory, not
-- checked in client). Shadow Trance 17941 is the buff ID Dyre's Buff Reminders
-- uses; Nightfall keeps "impspell", its sound in WTF 1.2 and DBR. Decimation:
-- talent 440870 (new on Forever); no source gives its buff ID, so it shows
-- only after the engine has read the ID once out of combat.
-- No ID is confirmed in client: the engine uses a candidate only when the
-- client names it the buff, and learns the real ID out of combat.
DSU.MISSILE_BARRAGE_MACRO = "/stopcasting\n/use Arcane Missiles"
-- One art for every proc for now (per-family art comes later): white
-- lightning the Toolkit tints with each proc's color, made by
-- scripts/make_arcane_arcs.py to the Toolkit's geometry (its Procs.lua, "Art").
DSU.PROC_ART = {
    right = "Interface\\AddOns\\" .. addonName .. "\\Textures\\ArcaneArc",
    left = "Interface\\AddOns\\" .. addonName .. "\\Textures\\ArcaneArcLeft",
    tint = true,
}
DSU.PROCS = {
    {key = "missilebarrage", label = "Missile Barrage", buff = "Missile Barrage", class = "MAGE",
        talents = {400588, 1326083}, ids = {400589, 44401}, color = {0.62, 0.8, 1}, sound = "alertselect",
        tooltip = "\n\nA macro that catches it, also during a cast:\n" .. DSU.MISSILE_BARRAGE_MACRO},
    {key = "fingersoffrost", label = "Fingers of Frost", buff = "Fingers of Frost", class = "MAGE",
        talents = {400647}, ids = {400670, 44544}, color = {0.7, 0.95, 1}, sound = "frostyicespell1",
        stacks = 2,
        tooltip = "\n\nWith two charges up, both arcs show; when you use one, the right arc goes."},
    {key = "nightfall", label = "Nightfall", buff = "Shadow Trance", class = "WARLOCK",
        talents = {18094, 18095}, ids = {17941}, color = {0.35, 0.95, 0.35}, sound = "impspell",
        tooltip = "Shadow Trance: your next Shadow Bolt is instant."},
    {key = "decimation", label = "Decimation", buff = "Decimation", class = "WARLOCK",
        talents = {440870}, ids = {}, color = {1, 0.45, 0.1}, sound = "powerup",
        tooltip = "Soul Fire casts faster and costs no Soul Shard for 10 seconds."},
    -- Clearcasting (John, 2026-11-20: "Go for A", Druid and Shaman; Mage left
    -- out, the game gives it a cue). Keys as Dyre's Buff Reminders'
    -- PROC_SOUNDS, so its Clearcasting chime steps aside. soundOn = false: the
    -- sound starts off, as DBR's (John: "off, the game already plays a sound
    -- for it"). Druid: Omen of Clarity 16864, a trained passive at 20 on
    -- Forever (TalentsForeverBook Data.lua, "a passive now"; a talent on
    -- Classic Era); Clearcasting 16870, DBR's ID. Shaman: Elemental Focus
    -- talent 16164 (TalentsForeverBook: "classic = same"); Clearcasting 16246,
    -- DBR's ID. Not confirmed in client.
    {key = "druidclearcasting", label = "Clearcasting (Omen of Clarity)", buff = "Clearcasting", class = "DRUID",
        talents = {16864}, ids = {16870}, color = {0.85, 0.95, 1}, sound = "magical", soundOn = false,
        tooltip = "Your next damage or healing spell or offensive ability costs nothing."},
    {key = "shamanclearcasting", label = "Clearcasting (Elemental Focus)", buff = "Clearcasting",
        class = "SHAMAN", talents = {16164}, ids = {16246}, color = {0.3, 0.6, 1}, sound = "magical",
        soundOn = false, tooltip = "Your next damage spell costs no mana."},
    -- Warrior (John, 2026-11-19: "Overpower/Revenge for Warrior would be super
    -- helpful"): not buffs but abilities the game makes usable for a few
    -- seconds (after a dodge; after a block, dodge, or parry). The Toolkit's
    -- usable procs (2.11.0) show the arcs while C_Spell.IsSpellUsable says so,
    -- by name so every rank counts, dimmed while the window is open but rage is
    -- short; no sound (Dyre's Buff Reminders plays these two, and its reactive
    -- sounds never step aside) and no Owners claim. Rank 1 IDs, Classic's, as
    -- DBR's PROC_SOUNDS uses (same keys). A Toolkit without usable procs drops
    -- these entries (they have no buff), so a Warrior then gets no arcs and no
    -- error. Forever Arms: hits on a target with your Rend can open Overpower
    -- (TalentsForeverBook Data.lua).
    {key = "overpower", label = "Overpower", class = "WARRIOR", usable = 7384, color = {1, 0.35, 0.2},
        tooltip = "The arcs show while Overpower is usable (after your target dodges), dimmed while you lack "
            .. "the rage."},
    {key = "revenge", label = "Revenge", class = "WARRIOR", usable = 6572, color = {1, 0.8, 0.25},
        tooltip = "The arcs show while Revenge is usable (after you block, dodge, or parry), dimmed while you "
            .. "lack the rage."},
}

-- SpellActivationOverlay's folder name, the AddOn DSU steps aside for.
DSU.SAO_ADDON = "SpellActivationOverlay"
local PROCS_MISSING = "Proc overlays need Dyre's Toolkit 2.11 or later: update it from CurseForge."
local STEP_ASIDE = "SpellActivationOverlay is loaded, so Dyre's proc overlays stay off. To show both, turn "
    .. "on \"Show Dyre's proc overlays with SpellActivationOverlay\" in /dsu (it applies after a /reload)."

-- Whether the loaded Dyre's Toolkit has the proc engine (2.11.0).
function DSU.ProcEngineAvailable()
    local toolkit = rawget(_G, "DyresToolkit")
    return type(toolkit) == "table" and type(toolkit.RegisterProcs) == "function"
        and type(toolkit.SanitizeProcs) == "function" and type(toolkit.SanitizeProcIDs) == "function"
end

-- Whether the player's class has a proc in the catalog.
local function ClassHasProcs()
    local _, class = UnitClass("player")
    for _, proc in ipairs(DSU.PROCS) do
        if proc.class == class then
            return true
        end
    end
    return false
end

-- Whether SpellActivationOverlay is loaded now.
function DSU.SpellActivationOverlayLoaded()
    return type(C_AddOns) == "table" and type(C_AddOns.IsAddOnLoaded) == "function"
        and C_AddOns.IsAddOnLoaded(DSU.SAO_ADDON) == true
end

-- Whether DSU steps aside for SpellActivationOverlay: it is loaded, and the
-- player has not asked for both. Then DSU registers nothing, so it claims no
-- Owners kind: SAO draws the overlays, and DBR's Proc Chimes keep their sounds.
function DSU.ProcsStepAside()
    return DSU.SpellActivationOverlayLoaded() and DSU.db.procsWithSAO ~= true
end

-- Repairs DSU's proc settings and learned buff IDs, from DSU.SanitizeDB.
-- With a Toolkit older than 2.11.0 they stay as saved, so a Toolkit update
-- finds them again.
function DSU.SanitizeProcSettings(db)
    local toolkit = rawget(_G, "DyresToolkit")
    if type(toolkit) == "table" and type(toolkit.SanitizeProcs) == "function"
            and type(toolkit.SanitizeProcIDs) == "function" then
        db.procs = toolkit.SanitizeProcs(db.procs, DSU.PROCS)
        db.procIDs = toolkit.SanitizeProcIDs(db.procIDs, DSU.PROCS)
    else
        db.procs = type(db.procs) == "table" and db.procs or nil
        db.procIDs = type(db.procIDs) == "table" and db.procIDs or nil
    end
    db.procsWithSAO = db.procsWithSAO == true
end

-- Once, at PLAYER_LOGIN, after the settings load: hands the catalog to the
-- Toolkit's engine. A class without procs, a step aside, or an older Toolkit
-- gets no handle (and the shields work as before); the last two say so once.
function DSU.InitializeProcs()
    DSU.procs = nil
    if not ClassHasProcs() then
        return
    end
    if DSU.ProcsStepAside() then
        DSU.procsSteppedAside = true
        DSU.Report(STEP_ASIDE)
        return
    end
    if not DSU.ProcEngineAvailable() then
        DSU.Report(PROCS_MISSING)
        return
    end
    DSU.procs = rawget(_G, "DyresToolkit").RegisterProcs({
        addon = addonName,
        art = DSU.PROC_ART,
        procs = DSU.PROCS,
        store = function() return DSU.db.procs end,
        learned = function() return DSU.db.procIDs end,
    })
end

-- After a profile copy or import (the widgets are reapplied first).
function DSU.ApplyProcs()
    if DSU.procs then
        DSU.procs.Apply()
    end
end

-- /dsu reset: the proc arcs back to their default place. True when there are some.
function DSU.ResetProcPosition()
    return DSU.procs ~= nil and DSU.procs.ResetPosition() == true
end

-- /dsu debug_procs: one line per proc (talent, buff IDs, arcs, sound).
function DSU.ReportProcsDebug()
    if DSU.procs then
        DSU.procs.Report(DSU.Report)
    elseif not ClassHasProcs() then
        DSU.Report("No proc overlays for your class yet.")
    elseif DSU.procsSteppedAside then
        DSU.Report(STEP_ASIDE)
    else
        DSU.Report(DSU.ProcEngineAvailable() and "No proc overlays on this character." or PROCS_MISSING)
    end
end
