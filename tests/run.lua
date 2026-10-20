-- Run from the repository root: lua tests/run.lua
-- These mocks test AddOn logic, not Forever compatibility, protected actions,
-- secret-value behavior, layout, or taint.
-- Every test gets its own globals, clock, event frames, and namespace.
if _VERSION ~= "Lua 5.1" then
    io.stderr:write("This suite requires Lua 5.1; found " .. tostring(_VERSION) .. "\n")
    os.exit(1)
end

local tests = {}
local function test(name, body)
    tests[#tests + 1] = {name = name, body = body}
end
local function equal(actual, expected, context)
    if actual ~= expected then
        error((context or "value") .. ": expected " .. tostring(expected)
            .. ", got " .. tostring(actual), 2)
    end
end
local function contains(actual, fragment, context)
    if type(actual) ~= "string" or not actual:find(fragment, 1, true) then
        error((context or "text") .. ": expected text containing " .. fragment
            .. ", got " .. tostring(actual), 2)
    end
end

local ADDON = "DyresShieldsUp"
local RUNTIME_FILES = {"Commands.lua", "Core.lua", "Shield.lua", "Options.lua"}
local SPELLS = {
    [11426] = "Ice Barrier", [13031] = "Ice Barrier", [1463] = "Mana Shield", [543] = "Fire Ward",
    [6143] = "Frost Ward", [17] = "Power Word: Shield", [592] = "Power Word: Shield", [6229] = "Shadow Ward",
    [7812] = "Sacrifice", [642] = "Divine Shield", [498] = "Divine Protection",
    [1022] = "Blessing of Protection", [585] = "Smite"}
local POWER_WORD_SHIELD, ICE_BARRIER, SMITE = 17, 11426, 585

-- A secret stands in for the client's opaque combat values; tests mark them with
-- issecretvalue, and any comparison or concatenation with one raises an error.
local function secret()
    return setmetatable({}, {
        __eq = function() error("compared a secret value") end,
        __lt = function() error("compared a secret value") end,
        __le = function() error("compared a secret value") end,
        __concat = function() error("concatenated a secret value") end,
        __tostring = function() error("printed a secret value") end,
        __index = function() error("indexed a secret value") end,
    })
end

local function fixture(options)
    options = options or {}
    local state = {frames = {}, messages = {}, now = 100, combat = false, secrets = {}, settings = {},
        categories = {}, opened = nil, buffs = {}}
    local env = setmetatable({}, {__index = _G})
    env._G = env
    env.SlashCmdList = options.slashCmdList or {}
    for key, value in pairs(options.globals or {}) do env[key] = value end
    env.DEFAULT_CHAT_FRAME = {AddMessage = function(_, message)
        state.messages[#state.messages + 1] = message
    end}
    state.toc = {}
    for text in io.lines(ADDON .. ".toc") do
        local key, value = text:match("^##%s*([^:]+):%s*(.-)%s*$")
        if key then state.toc[key] = value end
    end
    env.C_AddOns = {GetAddOnMetadata = function(name, field)
        if name ~= ADDON then
            -- Another AddOn's title, for the note naming the AddOn that draws the ring.
            local titles = {MageToolsForever = "Mage Tools Forever", WarlockToolsForever = "Warlock Tools Forever"}
            return field == "Title" and titles[name] or nil
        end
        return state.toc[field] or ""
    end}
    env.UnitClass = function(unit)
        equal(unit, "player")
        local class = options.class or "PRIEST"
        return class:sub(1, 1) .. class:sub(2):lower(), class
    end
    env.GetTime = function() return state.now end
    env.InCombatLockdown = function() return state.combat end
    env.issecretvalue = function(value) return state.secrets[value] == true end
    env.C_Spell = {
        GetSpellName = function(id) if SPELLS[id] then return SPELLS[id] end end,
        GetSpellTexture = function(id) return 2000 + id end,
    }
    state.timers = {}
    env.C_Timer = {After = function(seconds, callback)
        state.timers[#state.timers + 1] = {at = state.now + seconds, callback = callback}
    end}
    function state.runTimers()
        local due = {}
        for index = #state.timers, 1, -1 do
            if state.timers[index].at <= state.now then
                due[#due + 1] = table.remove(state.timers, index)
            end
        end
        for _, timer in ipairs(due) do timer.callback() end
    end
    env.C_XMLUtil = {GetTemplateInfo = function(name)
        if name == "CustomAuraContainerTemplate" and not options.noAuraContainer then return {} end
    end}
    env.C_AddOns.IsAddOnLoaded = function(name) return state.loadedAddOns and state.loadedAddOns[name] end
    env.C_AddOns.LoadAddOn = function(name)
        state.loadedAddOns = state.loadedAddOns or {}
        state.loadedAddOns[name] = true
    end
    env.Enum = {StatusBarTimerDirection = {ElapsedTime = 0, RemainingTime = 1},
        AddOnRestrictionType = {Combat = 0, Encounter = 1, Chat = 5},
        UnitAuraSoundTrigger = {Added = 0, ApplicationsIncreased = 1, Removed = 2}}
    env.C_RestrictedActions = {IsAddOnRestrictionActive = function(kind)
        return kind == 1 and state.encounter == true
    end}
    -- Absorbs: always secret, as the client's UnitGetTotalAbsorbs is.
    state.absorb = secret()
    state.secrets[state.absorb] = true
    state.maxHealth = 1500
    env.UnitGetTotalAbsorbs = function(unit) equal(unit, "player") return state.absorb end
    env.UnitHealthMax = function(unit) equal(unit, "player") return state.maxHealth end
    env.AbbreviateNumbers = function(value) return {abbreviated = value} end
    env.PlaySoundFile = function(file, channel) state.played = {file = file, channel = channel} end
    -- Dyre's Sounds, faked with a few sounds of each kind (the library has its
    -- own suite); options.noSounds leaves it out.
    if not options.noSounds then
        local catalog = {
            fadingslow = {label = "Dyre's Picks: Fading slow disappear", file = "FadingSlowDisappear.mp3"},
            magical = {label = "Dyre's Picks: Magical disappear", file = "MagicalDisappear.mp3"},
            impspell = {label = "Imp: Spell chirp", id = 639156},
            talent = {label = "Interface: Talent ready"},
        }
        local order = {"fadingslow", "magical", "impspell", "talent"}
        local aliases = {effectmagical = "magical", pickmagical = "magical"}
        local library = {}
        function library.RequireContract(minimum)
            if minimum <= 1 then return library end
        end
        function library.Resolve(key)
            key = aliases[key] or key
            return catalog[key] and key or nil
        end
        function library.AuraSound(key)
            local sound = catalog[library.Resolve(key) or ""]
            if sound and sound.file then
                return {soundFileName = "Interface\\AddOns\\DyresSounds\\Sounds\\" .. sound.file}
            elseif sound and sound.id then
                return {soundFileID = sound.id}
            end
        end
        function library.Play(key)
            state.soundsPlayed = state.soundsPlayed or {}
            state.soundsPlayed[#state.soundsPlayed + 1] = key
        end
        function library.Choices(filter)
            return function()
                local list = {}
                for _, key in ipairs(order) do
                    if filter ~= "aura" or library.AuraSound(key) then
                        list[#list + 1] = {value = key, label = catalog[key].label}
                    end
                end
                return list
            end
        end
        function library.SetupMenu(initializer, filter) initializer.soundMenu = filter or "all" end
        env.DyresSounds = library
    end
    env.C_UnitAuras = {
        -- As in client, aura sound changes are refused during an encounter.
        AddAuraSound = function(trigger, info)
            if state.encounter then error("AddAuraSound during an encounter") end
            state.auraSoundCount = (state.auraSoundCount or 0) + 1
            state.auraSounds = state.auraSounds or {}
            state.auraSounds[state.auraSoundCount] = {trigger = trigger, info = info}
            return state.auraSoundCount
        end,
        RemoveAuraSound = function(id)
            if state.encounter then error("RemoveAuraSound during an encounter") end
            state.auraSounds[id] = nil
        end,
        -- As in client, AddOn code cannot read auras in combat.
        GetAuraDataBySpellName = function(unit, name, filter)
            equal(unit, "player")
            equal(filter, "HELPFUL")
            if state.combat then error("Auras cannot be accessed when secret while tainted") end
            return state.buffs[name]
        end,
    }

    -- Settings: proxy settings with getters and setters, as the client builds them.
    if not options.noSettings then
        local function newCategory(name)
            local category = {name = name, initializers = {}}
            function category:GetID() return "id:" .. name end
            state.categories[name] = category
            return category
        end
        state.newCategory = newCategory
        local function initializer(category, setting, extra, tooltip)
            local object = {setting = setting, options = extra, tooltip = tooltip}
            function object:SetParentInitializer(parent, predicate)
                self.parentInitializer, self.predicate = parent, predicate
            end
            object.modifyPredicates = {}
            function object:AddModifyPredicate(predicate)
                self.modifyPredicates[#self.modifyPredicates + 1] = predicate
            end
            category.initializers[#category.initializers + 1] = object
            return object
        end
        env.MinimalSliderWithSteppersMixin = {Label = {Right = "right"}}
        env.Settings = {
            VarType = {Boolean = "boolean", Number = "number", String = "string"},
            RegisterVerticalLayoutCategory = function(name) return newCategory(name) end,
            RegisterProxySetting = function(category, variable, variableType, name, default, getValue, setValue)
                equal(state.settings[variable], nil, "setting variables are unique")
                local setting = {category = category, variable = variable, type = variableType, name = name,
                    default = default}
                function setting:GetValue() return getValue() end
                function setting:SetValue(value) setValue(value) end
                state.settings[variable] = setting
                return setting
            end,
            RegisterAddOnCategory = function(category) state.registered = category end,
            CreateCheckbox = function(category, setting, tooltip)
                return initializer(category, setting, nil, tooltip)
            end,
            CreateSlider = function(category, setting, sliderOptions, tooltip)
                return initializer(category, setting, sliderOptions, tooltip)
            end,
            CreateSliderOptions = function(minValue, maxValue, step)
                local object = {minValue = minValue, maxValue = maxValue, step = step}
                function object:SetLabelFormatter(label) self.label = label end
                return object
            end,
            CreateControlTextContainer = function()
                local container = {data = {}}
                function container:Add(value, label) self.data[#self.data + 1] = {value = value, label = label} end
                function container:GetData() return self.data end
                return container
            end,
            CreateDropdown = function(category, setting, choices, tooltip)
                local object = initializer(category, setting, nil, tooltip)
                object.choices = choices
                return object
            end,
            OpenToCategory = function(id) state.opened = id end,
        }
    end

    -- Dyre's Toolkit, faked (it has its own suite); options.toolkit adds it.
    -- Frames start locked; SetLocked calls each AddOn's setLocked and says one
    -- line for all.
    if options.toolkit then
        local toolkit = {locked = true, members = {}, movables = {}, drags = {}, pages = {}}
        function toolkit.RequireContract(required)
            if required == 1 then return toolkit end
        end
        function toolkit.RegisterAddOn(info) toolkit.members[#toolkit.members + 1] = info return true end
        function toolkit.IsLocked() return toolkit.locked end
        function toolkit.SetLocked(locked)
            toolkit.locked = locked == true
            for _, info in ipairs(toolkit.members) do info.setLocked(toolkit.locked) end
            state.messages[#state.messages + 1] = "Dyre: Frames " .. (toolkit.locked and "locked." or "unlocked.")
        end
        function toolkit.RegisterMovable(frame, save) toolkit.movables[frame] = save return true end
        function toolkit.BeginDrag(frame) toolkit.drags[#toolkit.drags + 1] = "begin" frame:StartMoving() end
        function toolkit.EndDrag(frame)
            toolkit.drags[#toolkit.drags + 1] = "end"
            frame:StopMovingOrSizing()
            toolkit.movables[frame]({point = "CENTER", relativePoint = "BOTTOMLEFT", x = 400, y = 300})
        end
        function toolkit.RegisterSettingsCategory(name)
            if not state.newCategory then return nil end
            local page = state.newCategory(name)
            page.parent = "Dyre's AddOns"
            toolkit.pages[#toolkit.pages + 1] = page
            return page, {}
        end
        function toolkit.OpenSettings(category)
            if state.combat then return false end
            state.opened = category:GetID()
            return true
        end
        if options.toolkit == "newer" then
            function toolkit.RequireContract() return nil end
        end
        env.DyresToolkit = toolkit
        state.toolkit = toolkit
    end

    local function widget(kind, name, parent, template)
        local object = {kind = kind, name = name, parent = parent, template = template, events = {},
            unitEvents = {}, scripts = {}, points = {}, shown = true, text = "", children = {}}
        if parent and parent.children then parent.children[#parent.children + 1] = object end
        function object:SetBackdropBorderColor(...) self.backdropBorder = {...} end
        function object:SetBackdrop(backdrop) self.backdrop = backdrop end
        function object:SetStatusBarColor(...) self.barColor = {...} end
        function object:SetMinMaxValues(minValue, maxValue) self.minValue, self.maxValue = minValue, maxValue end
        function object:SetStatusBarTexture(texture) self.statusBarTexture = texture end
        function object:SetValue(value) self.value = value end
        function object:GetStatusBarTexture()
            self.fill = self.fill or widget("Texture", nil, self)
            return self.fill
        end
        function object:SetClipsChildren(value) self.clips = value end
        function object:EnableMouse(value) self.mouse = value == true end
        function object:SetAlpha(value) self.alpha = value end
        function object:GetAlpha() return self.alpha or 1 end
        function object:SetScale(value) self.scale = value end
        function object:SetSize(width, height) self.width, self.height = width, height end
        function object:SetShown(value)
            if value then self:Show() else self:Hide() end
        end
        function object:RegisterEvent(event)
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                error("COMBAT_LOG_EVENT_UNFILTERED is restricted")
            end
            self.events[event] = true
        end
        function object:RegisterUnitEvent(event, unit) self.unitEvents[event] = unit end
        function object:UnregisterEvent(event) self.events[event] = nil end
        function object:UnregisterAllEvents() self.events, self.unitEvents = {}, {} end
        function object:SetScript(script, callback) self.scripts[script] = callback end
        function object:Show() self.shown = true end
        function object:Hide() self.shown = false end
        function object:IsShown() return self.shown end
        function object:SetPoint(...) self.points[#self.points + 1] = {...} end
        function object:ClearAllPoints() self.points = {} end
        function object:GetPoint()
            -- As in client, a frame with no points returns nothing.
            local point = self.points[#self.points]
            if not point then return end
            return point[1], point[2], point[3], point[4], point[5]
        end
        function object:StartMoving() self.moving = true end
        function object:StopMovingOrSizing() self.moving = false end
        function object:SetText(text) self.text = text end
        function object:SetTexture(texture) self.texture = texture end
        function object:CreateTexture() return widget("Texture", nil, self) end
        function object:CreateFontString() return widget("FontString", nil, self) end
        function object:AddAuraSlot(key, filter, slotOptions)
            self.slots = self.slots or {}
            local button = widget("Button", nil, self)
            button.display = {}
            function button:SetIcon(region) self.display.icon = region end
            function button:SetDurationCooldown(region) self.display.cooldown = region end
            function button:SetDurationBar(region, barOptions)
                self.display.bar, self.display.barOptions = region, barOptions
            end
            function button:SetMouseClickEnabled(value) self.clicks = value end
            slotOptions.initializeFrame(button)
            self.slots[#self.slots + 1] = {key = key, filter = filter, button = button,
                ids = slotOptions.candidateFilters.includeSpellIDs}
            return button
        end
        function object:SetUnit(unit) self.unit = unit end
        function object:UpdateAllAuras() self.updates = (self.updates or 0) + 1 end
        -- Unknown methods (layout, colors, and so on) do nothing here.
        return setmetatable(object, {__index = function(_, key)
            if type(key) == "string" and key:match("^%u") then return function() end end
        end})
    end
    env.CreateFrame = function(kind, name, parent, template)
        local frame = widget(kind, name, parent, template)
        if name then env[name] = frame end
        if kind == "AuraContainer" then
            equal(template, "CustomAuraContainerTemplate")
            equal(state.loadedAddOns and state.loadedAddOns.Blizzard_AuraContainer, true, "container AddOn loaded")
        end
        state.frames[#state.frames + 1] = frame
        return frame
    end
    env.UIParent = widget("Frame", "UIParent")
    function state.emit(event, ...)
        for _, frame in ipairs(state.frames) do
            local unit = frame.unitEvents[event]
            local first = ...
            if frame.events[event] or (unit and unit == first) then
                frame.scripts.OnEvent(frame, event, ...)
            end
        end
    end

    for _, name in ipairs(options.remove or {}) do env[name] = nil end
    -- Other AddOns shipping Shield.lua, loaded in folder order: {addon, version,
    -- before, runs}; each gets its own namespace. A copy whose AddOn runs (MTF
    -- on a Mage) initializes it at login, before or after DSU as given.
    state.copies = {}
    local function loadShieldCopy(spec)
        local source = assert(io.open("Shield.lua")):read("*a")
        if spec.version then
            source = source:gsub("local VERSION = %d+", "local VERSION = " .. spec.version)
        end
        local chunk = assert(loadstring(source, "=" .. spec.addon .. "/Shield.lua"))
        setfenv(chunk, env)
        local namespace = {}
        chunk(spec.addon, namespace)
        state.copies[spec.addon] = namespace
        if spec.runs then
            local login = env.CreateFrame("Frame")
            login:RegisterEvent("PLAYER_LOGIN")
            login:SetScript("OnEvent", function()
                namespace.said = {}
                namespace.ShieldDisplay.Initialize({settings = function() return namespace.settings end,
                    report = function(message) namespace.said[#namespace.said + 1] = message end})
            end)
            namespace.settings = namespace.ShieldDisplay.Sanitize({})
        end
    end
    for _, spec in ipairs(options.shieldCopies or {}) do
        if spec.before then loadShieldCopy(spec) end
    end
    state.suf = {}
    for _, path in ipairs(options.files or RUNTIME_FILES) do
        local chunk, message = loadfile(path)
        if not chunk then error(message) end
        setfenv(chunk, env)
        chunk(ADDON, state.suf)
    end
    for _, spec in ipairs(options.shieldCopies or {}) do
        if not spec.before then loadShieldCopy(spec) end
    end
    env.DyresShieldsUpDB = options.db
    state.env = env
    state.emit("ADDON_LOADED", ADDON)
    state.emit("PLAYER_LOGIN")

    function state.slash(text) env.SlashCmdList.DYRESSHIELDSUP(text) end
    function state.cast(spellID)
        state.emit("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-" .. spellID, spellID)
    end
    function state.ring() return state.suf.ShieldDisplay.frame end
    function state.last() return state.messages[#state.messages] end
    function state.clear() state.messages = {} end
    function state.said(fragment)
        for _, message in ipairs(state.messages) do
            if message:find(fragment, 1, true) then return true end
        end
        return false
    end
    return state
end

-- Startup and commands ----------------------------------------------------------

test("texture paths follow the AddOn's folder", function()
    local source = assert(io.open("Shield.lua")):read("*a")
    contains(source, 'local ARC_TEXTURE = "Interface\\\\AddOns\\\\" .. addonName .. "\\\\Textures\\\\ShieldArc"')
    local state = fixture()
    state.cast(POWER_WORD_SHIELD)
    equal(state.ring().bar.statusBarTexture, "Interface\\AddOns\\DyresShieldsUp\\Textures\\ShieldArc")
end)
test("login prints the banner from the TOC and the ready hint", function()
    local state = fixture()
    equal(state.messages[1], "DSU: Dyre's Shields Up 0.3.2-beta by Dyre")
    equal(state.messages[2], "DSU:   Ready. Type /dsu to open the settings.")
    equal(state.messages[3], "DSU: Install Dyre's Toolkit from CurseForge for one layout mode and settings "
        .. "home for all Dyre's AddOns.", "without the toolkit, said once")
    equal(#state.messages, 3, "nothing else at login")
    equal(state.messages[3]:find("github", 1, true), nil, "CurseForge only, for now")
    equal(state.toc.Category, "Buffs & Debuffs")
    local withToolkit = fixture({toolkit = true})
    equal(#withToolkit.messages, 2, "with the toolkit, no install line")
end)
test("the TOC lists the toolkit as optional and nests under it in the AddOn list", function()
    local state = fixture()
    equal(state.toc.OptionalDeps, "DyresSounds, DyresToolkit", "never ## Dependencies")
    equal(state.toc.Dependencies, nil)
    equal(state.toc.Group, "DyresToolkit")
end)
test("every class runs it", function()
    for _, class in ipairs({"PRIEST", "WARRIOR", "MAGE", "WARLOCK", "PALADIN", "ROGUE", "DRUID", "HUNTER",
        "SHAMAN"}) do
        local state = fixture({class = class})
        equal(state.suf.available, true, class)
        equal(state.ring() ~= nil, true, class .. " draws the ring")
    end
end)
test("commands are one word; extra words and unknown commands show usage", function()
    local state = fixture()
    for _, text in ipairs({"what", "unlock now", "debug"}) do
        state.slash(text)
        contains(state.last(), "Use /dsu, /dsu options")
    end
end)
test("/dsu and /dsu options open the settings page", function()
    local state = fixture()
    state.slash("")
    equal(state.opened, "id:Dyre's Shields Up")
    state.opened = nil
    state.slash("  OPTIONS ")
    equal(state.opened, "id:Dyre's Shields Up")
    equal(state.registered, state.categories["Dyre's Shields Up"])
end)
test("/shieldsup is a backup slash command", function()
    local state = fixture()
    equal(state.env.SLASH_DYRESSHIELDSUP1, "/dsu")
    equal(state.env.SLASH_DYRESSHIELDSUP2, "/shieldsup")
end)
test("another AddOn registering /dsu is reported once at login", function()
    local state = fixture({slashCmdList = {OTHER = function() end}, globals = {SLASH_OTHER1 = "/DSU"}})
    contains(state.messages[3], "Another AddOn (OTHER) also uses /dsu. Use /shieldsup instead.")
end)
test("a mixed install of old and new files is reported at login", function()
    local state = fixture({files = {"Commands.lua", "Core.lua", "Options.lua"}})
    equal(state.suf.available, false)
    contains(state.last(), "missing Shield.lua")
    state.slash("unlock")
    contains(state.last(), "Dyre's Shields Up is unavailable")
    state.slash("debug_shield")
    contains(state.last(), "Shield.lua is missing")
    local noOptions = fixture({files = {"Commands.lua", "Core.lua", "Shield.lua"}})
    contains(noOptions.last(), "missing InitializeOptions")
    equal(noOptions.ring(), nil, "the display stays off")
end)
test("saved settings get defaults and are repaired on load", function()
    local fresh = fixture()
    local shield = fresh.suf.db.shield
    equal(shield.enabled, true)
    equal(shield.locked, true)
    equal(shield.number, true)
    equal(shield.breakSound, false)
    equal(shield.scale, 100)
    equal(shield.position, nil)
    local damaged = fixture({db = {shield = {enabled = "yes", scale = 999, number = false,
        position = {point = "LEFT", relativePoint = 3, x = 1, y = 2}}}})
    shield = damaged.suf.db.shield
    equal(shield.enabled, true)
    equal(shield.scale, 150)
    equal(shield.number, false)
    equal(shield.position, nil, "a broken position is dropped")
    equal(fixture({db = "broken"}).suf.db.shield.scale, 100)
    equal(fixture({db = {shield = {scale = 72}}}).suf.db.shield.scale, 70, "sizes step by 5")
end)
test("without the Settings API DSU runs and /dsu explains", function()
    local state = fixture({noSettings = true})
    equal(state.suf.available, true)
    state.slash("")
    contains(state.last(), "settings page is unavailable")
end)

-- The display ----------------------------------------------------------------------

test("a Priest's own Power Word: Shield shows the live absorb in its color", function()
    local state = fixture()
    local ring = state.ring()
    equal(ring.shown, false)
    equal(ring.mouse, false, "never blocks world clicks")
    state.cast(SMITE)
    equal(ring.shown, false, "other spells do nothing")
    state.cast(POWER_WORD_SHIELD)
    equal(ring.shown, true)
    equal(ring.bar.value, state.absorb, "the secret absorb, passed on unread")
    equal(ring.bar.maxValue, state.absorb, "measured against the shield's size as it landed")
    equal(ring.text.text.abbreviated, state.absorb)
    equal(ring.visible.alpha, state.absorb, "the ring's opacity is the absorb, so it drops at zero")
    equal(ring.bar.barColor[3], 0.85, "Power Word: Shield white")
    state.now = state.now + 31
    state.runTimers()
    equal(ring.shown, false, "hidden when the shield ends")
end)
test("a Priest's icon row holds Power Word: Shield and Blessing of Protection", function()
    local state = fixture()
    local ring = state.ring()
    equal(#ring.icons.slots, 2, "no class has its own shields on a Priest")
    equal(ring.icons.slots[1].key, "powerwordshield")
    equal(ring.icons.slots[1].ids[592], true, "a set of every rank")
    equal(ring.icons.slots[2].key, "blessingofprotection")
    equal(ring.iconButtons.blessingofprotection.display.barOptions.direction, 1, "a bubble drains with time")
    contains(ring.iconButtons.blessingofprotection.display.bar.statusBarTexture, "ShieldArcInnermost")
end)
test("each class's row holds its own shields first, then the shared ones", function()
    local rows = {WARRIOR = {"powerwordshield", "blessingofprotection"},
        WARLOCK = {"shadowward", "sacrifice", "powerwordshield", "blessingofprotection"},
        PALADIN = {"divineshield", "divineprotection", "powerwordshield", "blessingofprotection"},
        MAGE = {"icebarrier", "manashield", "fireward", "frostward", "powerwordshield", "blessingofprotection"}}
    -- An icon's place left to right; a timed shield's icon sits on its own holder.
    local function spotX(ring, key)
        local button = ring.iconButtons[key]
        if button.display.bar then
            for _, child in ipairs(button.children) do
                if child.kind == "Frame" then button = child end
            end
        end
        return button.points[1][4]
    end
    for class, keys in pairs(rows) do
        local ring = fixture({class = class}).ring()
        equal(#ring.icons.slots, #keys, class)
        for index = 2, #keys do
            equal(spotX(ring, keys[index]) - spotX(ring, keys[index - 1]), 21, class .. " spot " .. index)
        end
    end
end)
test("a shield another player puts on you shows, also after a reload", function()
    local state = fixture({class = "WARRIOR"})
    state.emit("UNIT_ABSORB_AMOUNT_CHANGED", "player")
    equal(state.ring().shown, true, "an absorb it cannot name, in the neutral color")
    equal(state.ring().bar.barColor[2], 0.85)
    local reloaded = fixture({class = "WARRIOR"})
    reloaded.buffs["Power Word: Shield"] = {name = "Power Word: Shield", expirationTime = reloaded.now + 25}
    reloaded.emit("PLAYER_ENTERING_WORLD")
    equal(reloaded.ring().shown, true)
    equal(reloaded.ring().bar.barColor[3], 0.85, "Power Word: Shield white")
end)
test("every crescent is centered on the ring, also the outer one inside the taller clip", function()
    local ring = fixture({class = "PALADIN"}).ring()
    local bubble = ring.iconButtons.blessingofprotection.display.bar
    for name, region in pairs({background = ring.background, bar = ring.bar, bubble = bubble}) do
        local top, bottom = region.points[1], region.points[2]
        equal(top[2], ring, name .. " anchored to the ring, not its parent")
        equal(bottom[2], ring, name .. " anchored to the ring, not its parent")
        equal(top[5], -bottom[5], name .. " is as far from the top as from the bottom")
    end
    equal(ring.bar.points[2][5], 160 * (1 - 118 / 128) / 2)
    equal(bubble.points[2][5], 160 * (1 - 70 / 128) / 2)
end)
test("a tiny absorb stays hidden: a gate bar ending at the minimum clips the ring", function()
    local state = fixture({class = "PALADIN"})
    state.emit("UNIT_ABSORB_AMOUNT_CHANGED", "player")
    local ring = state.ring()
    equal(ring.shown, true)
    equal(ring.gate.value, state.absorb, "the secret absorb, passed on unread")
    equal(ring.gate.minValue, 74, "one point wide, so the fill is empty or full")
    equal(ring.gate.maxValue, 75, "5% of 1500 health beats 25 points")
    equal(ring.gate.alpha, 0, "the gate itself is never seen")
    equal(ring.gated.clips, true)
    local corner = ring.gated.points[2]
    equal(corner[2], ring.gate:GetStatusBarTexture(), "the clipping frame ends where the gate's fill ends")
    equal(corner[5], -40, "and reaches below the frame for the number")
    equal(ring.bar.parent, ring.gated)
    equal(ring.background.parent, ring.gated)
    equal(ring.gated.parent, ring.visible, "the opacity still follows the absorb")
end)
test("the minimum is 25 points when health is low or secret", function()
    local state = fixture({class = "PALADIN"})
    state.maxHealth = 200
    state.emit("UNIT_MAXHEALTH", "player")
    equal(state.ring().gate.maxValue, 25, "5% of 200 is below 25 points")
    state.maxHealth = secret()
    state.secrets[state.maxHealth] = true
    state.cast(POWER_WORD_SHIELD)
    equal(state.ring().gate.minValue, 24, "secret health is never read")
    equal(state.ring().gate.maxValue, 25)
end)
test("unlocked, the gate is open so the sample shows", function()
    local state = fixture()
    state.slash("unlock")
    local gate = state.ring().gate
    equal(gate.minValue, 0)
    equal(gate.maxValue, 1)
    equal(gate.value, 1)
end)
test("in combat buffs are not read, and the display stays up", function()
    local state = fixture()
    state.cast(POWER_WORD_SHIELD)
    state.combat = true
    state.emit("PLAYER_REGEN_DISABLED")
    state.emit("UNIT_AURA", "player")
    equal(state.ring().shown, true)
    state.combat = false
    state.emit("PLAYER_REGEN_ENABLED")
    equal(state.ring().shown, false, "out of combat the broken shield is seen")
end)
test("the settings page changes the display", function()
    local state = fixture()
    local ring = state.ring()
    state.settings.DSU_SHIELD_NUMBER:SetValue(false)
    state.cast(POWER_WORD_SHIELD)
    equal(ring.text.text, "")
    state.settings.DSU_SHIELD_SCALE:SetValue(83)
    equal(state.suf.db.shield.scale, 85)
    equal(ring.scale, 0.85)
    state.settings.DSU_SHIELD_BREAK_SOUND:SetValue(true)
    equal(state.auraSoundCount, 13, "every rank of Power Word: Shield and Blessing of Protection")
    equal(state.auraSounds[1].trigger, 2, "on removal")
    equal(state.auraSounds[1].info.soundFileName,
        "Interface\\AddOns\\DyresSounds\\Sounds\\FadingSlowDisappear.mp3",
        "Dyre's Sounds' file: DSU ships no sounds")
    equal(table.concat(state.soundsPlayed, ","), "fadingslow", "turning it on plays it once")
    state.settings.DSU_SHIELD_SCALE:SetValue(90)
    equal(#state.soundsPlayed, 1, "other settings do not play it")
    state.settings.DSU_SHIELD_ENABLED:SetValue(false)
    equal(ring.shown, false)
    local left = 0
    for _ in pairs(state.auraSounds) do left = left + 1 end
    equal(left, 0, "no sounds while the display is off")
end)
test("the break sound is chosen in a dropdown under its switch; choosing one plays it", function()
    local state = fixture()
    local page = state.categories["Dyre's Shields Up"]
    local dropdown
    for _, initializer in ipairs(page.initializers) do
        if initializer.setting.variable == "DSU_SHIELD_BREAK_SOUND_CHOICE" then dropdown = initializer end
    end
    equal(dropdown.parentInitializer.setting.variable, "DSU_SHIELD_BREAK_SOUND", "under the sound switch")
    local labels = {}
    for _, choice in ipairs(dropdown.choices()) do labels[#labels + 1] = choice.label end
    equal(table.concat(labels, ", "), "Dyre's Picks: Fading slow disappear, Dyre's Picks: Magical disappear, "
        .. "Imp: Spell chirp", "Dyre's Sounds' aura sounds only: a sound kit cannot be an aura sound")
    equal(dropdown.soundMenu, "aura", "with Dyre's Sounds' nested menu")
    equal(state.suf.db.shield.breakSoundKey, "fadingslow", "the default")
    state.settings.DSU_SHIELD_BREAK_SOUND:SetValue(true)
    state.settings.DSU_SHIELD_BREAK_SOUND_CHOICE:SetValue("magical")
    equal(state.suf.db.shield.breakSoundKey, "magical")
    equal(state.soundsPlayed[#state.soundsPlayed], "magical", "previewed")
    local live
    for _, sound in pairs(state.auraSounds) do live = sound end
    equal(live.info.soundFileName, "Interface\\AddOns\\DyresSounds\\Sounds\\MagicalDisappear.mp3",
        "registered again with the new sound")
    state.settings.DSU_SHIELD_BREAK_SOUND_CHOICE:SetValue("impspell")
    for _, sound in pairs(state.auraSounds) do live = sound end
    equal(live.info.soundFileID, 639156, "a game sound by file ID")
    equal(live.info.soundFileName, nil)
    for _, key in ipairs({"nonsense", "talent"}) do
        state.settings.DSU_SHIELD_BREAK_SOUND_CHOICE:SetValue(key)
        equal(state.suf.db.shield.breakSoundKey, "fadingslow", key .. " falls back to the default")
    end
    equal(fixture({db = {shield = {breakSoundKey = 7}}}).suf.db.shield.breakSoundKey, "fadingslow", "repaired on load")
    equal(fixture({db = {shield = {breakSoundKey = "effectmagical"}}}).suf.db.shield.breakSoundKey, "magical",
        "a v6 key is mapped by Dyre's Sounds")
end)
test("without Dyre's Sounds the display works, keeps the choice, and says once what to install", function()
    local state = fixture({noSounds = true, db = {shield = {breakSoundKey = "magical"}}})
    equal(state.suf.db.shield.breakSoundKey, "magical", "a missing library never resets a choice")
    state.cast(POWER_WORD_SHIELD)
    equal(state.ring().shown, true)
    state.clear()
    state.settings.DSU_SHIELD_BREAK_SOUND:SetValue(true)
    equal(state.auraSoundCount, nil, "no sound to register")
    contains(state.last(), "Install Dyre's Sounds")
    contains(state.last(), "Get it from CurseForge.")
    equal(state.last():find("github", 1, true), nil, "CurseForge only, for now")
    state.settings.DSU_SHIELD_SCALE:SetValue(90)
    local count = 0
    for _, message in ipairs(state.messages) do
        if message:find("Install Dyre's Sounds", 1, true) then count = count + 1 end
    end
    equal(count, 1, "once per session")
end)
test("/dsu unlock shows a sample to drag; /dsu lock and the page's switch lock it", function()
    local state = fixture()
    local ring = state.ring()
    state.slash("unlock")
    equal(state.suf.db.shield.locked, false)
    equal(state.settings.DSU_UNLOCKED:GetValue(), true, "the page's switch follows")
    equal(ring.shown, true)
    equal(ring.mouse, true)
    equal(ring.text.text, "drag me")
    equal(ring.sample.shown, true)
    equal(ring.mover.shown, true)
    contains(ring.mover.hint.text, "/dsu lock when done")
    contains(state.last(), "drag it where you want")
    ring.scripts.OnDragStart(ring)
    equal(ring.moving, true)
    ring:SetPoint("LEFT", state.env.UIParent, "LEFT", 10, 0)
    ring.scripts.OnDragStop(ring)
    equal(state.suf.db.shield.position.point, "LEFT")
    state.settings.DSU_UNLOCKED:SetValue(false)
    equal(state.suf.db.shield.locked, true)
    equal(ring.shown, false)
    equal(ring.mouse, false)
    state.slash("reset")
    equal(state.suf.db.shield.position, nil)
    equal(ring.points[1][1], "CENTER")
    contains(state.last(), "default place")
end)
test("without the absorb API the display stays off with one message", function()
    local state = fixture({remove = {"UnitGetTotalAbsorbs"}})
    equal(state.ring(), nil)
    equal(state.said("The shield display stays off"), true)
end)
test("/dsu debug_shield runs every step", function()
    local state = fixture()
    state.clear()
    state.slash("debug_shield")
    local text = table.concat(state.messages, "|")
    contains(text, "owner=DyresShieldsUp copies=DyresShieldsUp v9 (running)")
    contains(text, "minimumAbsorb=75")
    contains(text, "the absorb total shows above your character")
    equal(text:find("failed", 1, true), nil, "every debug step ran")
end)

-- Dyre's Toolkit ------------------------------------------------------------------

test("with Dyre's Toolkit, DSU joins it: one lock, quiet, and its page under Dyre's AddOns", function()
    local state = fixture({toolkit = true, db = {shield = {locked = false}}})
    local toolkit = state.toolkit
    equal(#toolkit.members, 1)
    equal(toolkit.members[1].addon, "DyresShieldsUp")
    equal(toolkit.members[1].title, "Dyre's Shields Up")
    equal(state.suf.db.shield.locked, true, "frames start locked at login, as the toolkit's do")
    local page = state.categories["Dyre's Shields Up"]
    equal(page.parent, "Dyre's AddOns", "the page is the toolkit's")
    equal(state.registered, nil, "no top-level page of its own")
    local ring = state.ring()
    state.clear()
    state.slash("unlock")
    equal(toolkit.locked, false, "/dsu unlock unlocks every Dyre's AddOn")
    equal(state.suf.db.shield.locked, false)
    equal(ring.shown, true)
    equal(ring.sample.shown, true)
    equal(ring.mover.shown, true)
    equal(#state.messages, 1, "only the toolkit's line")
    equal(state.last(), "Dyre: Frames unlocked.")
    toolkit.SetLocked(true)
    equal(state.suf.db.shield.locked, true, "the toolkit's lock locks DSU too")
    equal(ring.shown, false)
    state.slash("unlock")
    state.slash("lock")
    equal(toolkit.locked, true, "/dsu lock locks every Dyre's AddOn")
    equal(state.suf.db.shield.locked, true)
    equal(state.settings.DSU_UNLOCKED, nil, "no unlock switch of its own: the toolkit's page has one")
    for _, initializer in ipairs(page.initializers) do
        equal(initializer.tooltip:find("Unlock to move", 1, true), nil, initializer.setting.variable)
    end
    local variables = {}
    for _, initializer in ipairs(page.initializers) do variables[#variables + 1] = initializer.setting.variable end
    equal(table.concat(variables, ","), "DSU_SHIELD_ENABLED,DSU_SHIELD_NUMBER,DSU_SHIELD_BREAK_SOUND,"
        .. "DSU_SHIELD_BREAK_SOUND_CHOICE,DSU_SHIELD_SCALE", "the rest of the page stays")
    state.slash("reset")
    contains(state.last(), "default place", "/dsu reset stays")
end)
test("with Dyre's Toolkit, the ring drags and snaps through it and saves its place", function()
    local state = fixture({toolkit = true})
    local ring = state.ring()
    local toolkit = state.toolkit
    equal(type(toolkit.movables[ring]), "function", "the ring is registered as movable")
    ring.scripts.OnDragStart(ring)
    equal(#toolkit.drags, 0, "locked: no drag")
    state.slash("unlock")
    ring.scripts.OnDragStart(ring)
    equal(ring.moving, true)
    ring.scripts.OnDragStop(ring)
    equal(table.concat(toolkit.drags, ","), "begin,end")
    equal(state.suf.db.shield.position.relativePoint, "BOTTOMLEFT", "saved as the toolkit placed it")
    equal(state.suf.db.shield.position.x, 400)
    state.slash("reset")
    equal(state.suf.db.shield.position, nil)
end)
test("with Dyre's Toolkit, /dsu opens DSU's page through it, never in combat", function()
    local state = fixture({toolkit = true})
    state.slash("")
    equal(state.opened, "id:Dyre's Shields Up")
    state.opened = nil
    state.combat = true
    state.slash("options")
    equal(state.opened, nil)
    state.combat = false
    state.toolkit.members[1].openSettings()
    equal(state.opened, "id:Dyre's Shields Up", "the toolkit's menu opens it too")
end)
test("a toolkit with only a newer contract, or no settings, leaves DSU as it is today", function()
    local newer = fixture({toolkit = "newer"})
    equal(newer.said("Install Dyre's Toolkit"), true)
    equal(#newer.toolkit.members, 0)
    equal(newer.registered, newer.categories["Dyre's Shields Up"], "its own top-level page")
    equal(newer.settings.DSU_UNLOCKED ~= nil, true, "with its own unlock switch, the only way to unlock there")
    newer.slash("unlock")
    equal(newer.toolkit.locked, true, "the toolkit's lock is not touched")
    contains(newer.last(), "drag it where you want")
    local ring = newer.ring()
    ring.scripts.OnDragStart(ring)
    equal(#newer.toolkit.drags, 0, "dragged freely")
    equal(ring.moving, true)
    local noPage = fixture({toolkit = true, noSettings = true})
    equal(noPage.suf.available, true)
    noPage.slash("")
    contains(noPage.last(), "settings page is unavailable")
end)

-- Other AddOns shipping the display -------------------------------------------------

test("with Mage Tools Forever on a Priest, DSU draws the ring", function()
    local state = fixture({shieldCopies = {{addon = "MageToolsForever", before = true}}})
    equal(state.suf.ShieldDisplay.IsOwner(), true, "MTF stays off on a Priest, so its copy takes no part")
    equal(state.ring() ~= nil, true)
end)
test("with Mage Tools Forever running too, only one ring shows, and DSU says where", function()
    local state = fixture({class = "MAGE",
        shieldCopies = {{addon = "MageToolsForever", before = true, runs = true}}})
    equal(state.suf.ShieldDisplay.IsOwner(), false, "the first registered wins a tie")
    equal(state.ring(), nil, "DSU draws nothing")
    equal(state.copies.MageToolsForever.ShieldDisplay.frame ~= nil, true)
    equal(state.said("The shield display is shown by MageToolsForever; use its settings for it."), true)
    state.clear()
    state.slash("unlock")
    contains(state.last(), "shown by MageToolsForever")
    state.slash("options")
    contains(state.last(), "shown by MageToolsForever")
    local page = state.categories["Dyre's Shields Up"]
    for _, initializer in ipairs(page.initializers) do
        equal(initializer.modifyPredicates[1](), false, initializer.setting.variable .. " is greyed out")
        contains(initializer.tooltip, "Mage Tools Forever draws the shield display, so use its settings for it.")
    end
    local alone = fixture()
    for _, initializer in ipairs(alone.categories["Dyre's Shields Up"].initializers) do
        equal(initializer.modifyPredicates[1](), true, "not greyed while DSU draws the ring")
        equal(initializer.tooltip:find("draws the shield display", 1, true), nil)
    end
end)
test("a newer copy elsewhere takes over; DSU takes over from an older one", function()
    local newer = fixture({shieldCopies = {{addon = "MageToolsForever", before = true, runs = true,
        version = 10}}})
    equal(newer.suf.ShieldDisplay.IsOwner(), false)
    local older = fixture({shieldCopies = {{addon = "WarlockToolsForever", runs = true, version = 2}}})
    equal(older.suf.ShieldDisplay.IsOwner(), true)
    equal(older.ring() ~= nil, true)
    contains(older.copies.WarlockToolsForever.said[1], "shown by DyresShieldsUp")
end)

local failed = 0
for index, entry in ipairs(tests) do
    local ok, message = xpcall(entry.body, debug.traceback)
    if ok then
        io.write("ok ", index, " - ", entry.name, "\n")
    else
        failed = failed + 1
        io.write("not ok ", index, " - ", entry.name, "\n", tostring(message), "\n")
    end
end
io.write(string.format("\n%d tests: %d passed, %d failed\n", #tests, #tests - failed, failed))
io.write("Mock results do not establish in-client compatibility.\n")
os.exit(failed == 0 and 0 or 1)
