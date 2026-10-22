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
-- Dyre's Toolkit's runtime files, without the minimap (it needs the embedded
-- libraries); tests/toolkit holds a copy, checked against ../DyresToolkit.
local TOOLKIT_FILES = {"Core.lua", "Layout.lua", "Widgets.lua", "Settings.lua"}
local WIDGET_SCALE = "DYRE_DYRESSHIELDSUP_SHIELD_SCALE"
local PAGE = "Shields Up"
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
        local function newCategory(name, parent)
            local category = {name = name, initializers = {}, parent = parent, buttons = {}}
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
            -- Returns the page and its layout, as the client does.
            RegisterVerticalLayoutSubcategory = function(parent, name)
                local page = newCategory(name, parent)
                local layout = {}
                function layout:AddInitializer(button) page.buttons[#page.buttons + 1] = button end
                return page, layout
            end,
            NotifyUpdate = function() end,
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
                function object:SetLabelFormatter(label, formatter) self.label, self.formatter = label, formatter end
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
        function object:GetScale() return self.scale or 1 end
        function object:GetEffectiveScale()
            local parentScale = 1
            if self.parent and self.parent.GetEffectiveScale then parentScale = self.parent:GetEffectiveScale() end
            return (self.scale or 1) * parentScale
        end
        function object:SetSize(width, height) self.width, self.height = width, height end
        function object:GetWidth() return self.width or 0 end
        function object:GetHeight() return self.height or 0 end
        function object:GetNumPoints() return #self.points end
        -- As in client, in the frame's own units; nothing while unplaced.
        function object:GetCenter()
            if self ~= env.UIParent and #self.points == 0 then return end
            local x, y = state.absCenter(self)
            local scale = self:GetEffectiveScale()
            return x / scale, y / scale
        end
        function object:IsProtected() return false end
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
    env.UIParent.width, env.UIParent.height = 1000, 800
    env.IsShiftKeyDown = function() return state.shift == true end
    env.IsControlKeyDown = function() return state.ctrl == true end
    env.CreateSettingsButtonInitializer = function(name, buttonText, onClick, tooltip)
        return {button = true, name = name, buttonText = buttonText, onClick = onClick, tooltip = tooltip}
    end
    local SPOTS = {CENTER = {0.5, 0.5}, BOTTOMLEFT = {0, 0}, TOP = {0.5, 1}, TOPLEFT = {0, 1}, LEFT = {0, 0.5},
        BOTTOMRIGHT = {1, 0}, RIGHT = {1, 0.5}, BOTTOM = {0.5, 0}}
    -- Screen position of a frame's center, from its last point.
    function state.absCenter(frame)
        if frame == env.UIParent or frame == nil then return 500, 400 end
        local point = frame.points[#frame.points]
        local relative = point[2] or env.UIParent
        local relativeScale = relative == env.UIParent and 1 or relative:GetEffectiveScale()
        local rx, ry = state.absCenter(relative)
        local spot = SPOTS[point[3]] or SPOTS.CENTER
        local width = (relative.width or 0) * relativeScale
        local height = (relative.height or 0) * relativeScale
        local scale = frame:GetEffectiveScale()
        return rx + (spot[1] - 0.5) * width + (point[4] or 0) * scale,
            ry + (spot[2] - 0.5) * height + (point[5] or 0) * scale
    end
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
    -- Dyre's Toolkit, its real files: DSU requires contract 2. options.noToolkit
    -- leaves it out; options.oldToolkit offers contract 1 only.
    if not options.noToolkit then
        state.toolkitNS = {InitializeMinimap = function() end}
        -- Toolkit 2.2.1 snaps to the grid by default; these tests drop frames without it.
        env.DyresToolkitDB = env.DyresToolkitDB or {snapToGrid = false}
        for _, path in ipairs(TOOLKIT_FILES) do
            local chunk = assert(loadfile("tests/toolkit/" .. path))
            setfenv(chunk, env)
            chunk("DyresToolkit", state.toolkitNS)
        end
        state.toolkit = env.DyresToolkit
        if options.oldToolkit then
            local require = env.DyresToolkit.RequireContract
            env.DyresToolkit.RequireContract = function(n)
                if n >= 2 then return nil end
                return require(n)
            end
        end
    end
    -- Other AddOns shipping Shield.lua, loaded in folder order: {addon, version,
    -- before, runs, layout}; each gets its own namespace. A copy whose AddOn runs
    -- (MTF on a Mage) initializes it at login, before or after DSU as given;
    -- layout "v9" passes the toolkit's RegisterMovable, BeginDrag, and EndDrag,
    -- as MTF 1.1.0 and WTF 1.1.0 do.
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
                local layout
                if spec.layout == "v9" then
                    local toolkit = env.DyresToolkit
                    layout = {register = toolkit.RegisterMovable, beginDrag = toolkit.BeginDrag,
                        endDrag = toolkit.EndDrag}
                end
                namespace.ShieldDisplay.Initialize({settings = function() return namespace.settings end,
                    report = function(message) namespace.said[#namespace.said + 1] = message end,
                    layout = layout})
            end)
            namespace.settings = namespace.ShieldDisplay.Sanitize(spec.settings or {})
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
    state.emit("ADDON_LOADED", "DyresToolkit")
    state.emit("ADDON_LOADED", ADDON)
    state.emit("PLAYER_LOGIN")

    function state.slash(text) env.SlashCmdList.DYRESSHIELDSUP(text) end
    function state.cast(spellID)
        state.emit("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-" .. spellID, spellID)
    end
    function state.ring() return state.suf.ShieldDisplay.frame end
    -- A frame's center on screen.
    function state.center(frame)
        local x, y = frame:GetCenter()
        local scale = frame:GetEffectiveScale()
        return x * scale, y * scale
    end
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
    equal(state.messages[1], "DSU: Dyre's Shields Up 1.2.0 by Dyre")
    equal(state.messages[2], "DSU:   Ready. Type /dsu to open the settings.")
    equal(#state.messages, 2, "nothing else at login")
    equal(state.toc.Category, "Buffs & Debuffs")
end)
test("the TOC requires the toolkit and nests under it in the AddOn list", function()
    local state = fixture()
    equal(state.toc.Dependencies, "DyresToolkit", "the toolkit places and sizes the ring")
    equal(state.toc.OptionalDeps, "DyresSounds")
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
    equal(state.opened, "id:" .. PAGE)
    state.opened = nil
    state.slash("  OPTIONS ")
    equal(state.opened, "id:" .. PAGE)
    equal(state.categories[PAGE].parent, state.categories["Dyre's AddOns"], "under Dyre's AddOns")
    equal(state.registered, state.categories["Dyre's AddOns"], "no top-level page of its own")
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
    equal(ring.iconButtons.blessingofprotection.display.icon ~= nil, true, "an icon in the icon row")
    equal(ring.icons.parent, ring.iconHolder, "the icons are the icon row's size")
    equal(#ring.crescents.slots, 1, "the timed crescent is a slot of its own")
    local bubble = ring.crescents.slots[1]
    equal(bubble.key, "blessingofprotection")
    equal(bubble.button.display.barOptions.direction, 1, "a bubble drains with time")
    contains(bubble.button.display.bar.statusBarTexture, "ShieldArcInnermost")
    equal(bubble.button.display.icon, nil, "no icon there")
    equal(ring.crescents.parent, ring, "the crescents' size")
end)
test("each class's row holds its own shields first, then the shared ones", function()
    local rows = {WARRIOR = {"powerwordshield", "blessingofprotection"},
        WARLOCK = {"shadowward", "sacrifice", "powerwordshield", "blessingofprotection"},
        PALADIN = {"divineshield", "divineprotection", "powerwordshield", "blessingofprotection"},
        MAGE = {"icebarrier", "manashield", "fireward", "frostward", "powerwordshield", "blessingofprotection"}}
    -- An icon's place left to right.
    local function spotX(ring, key)
        return ring.iconButtons[key].points[1][4]
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
    local bubble
    for _, slot in ipairs(ring.crescents.slots) do
        if slot.key == "blessingofprotection" then bubble = slot.button.display.bar end
    end
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
    equal(ring.bar.parent, ring.gated)
    equal(ring.background.parent, ring.gated)
    equal(ring.gated.parent, ring.visible, "the opacity still follows the absorb")
    -- The number, at its own size, has a gate of its own.
    equal(ring.textGate.value, state.absorb)
    equal(ring.textGate.minValue, 74)
    equal(ring.textGate.maxValue, 75)
    equal(ring.textGate.alpha, 0)
    equal(ring.textGated.clips, true)
    equal(ring.textGated.points[2][2], ring.textGate:GetStatusBarTexture())
    equal(ring.text.parent, ring.textGated)
    equal(ring.textHolder.parent, ring.visible, "the number fades with the absorb too")
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
    state.settings[WIDGET_SCALE]:SetValue(83)
    equal(state.suf.db.shield.scale, 85)
    equal(ring.scale, 0.85)
    state.settings.DSU_SHIELD_BREAK_SOUND:SetValue(true)
    equal(state.auraSoundCount, 13, "every rank of Power Word: Shield and Blessing of Protection")
    equal(state.auraSounds[1].trigger, 2, "on removal")
    equal(state.auraSounds[1].info.soundFileName,
        "Interface\\AddOns\\DyresSounds\\Sounds\\FadingSlowDisappear.mp3",
        "Dyre's Sounds' file: DSU ships no sounds")
    equal(table.concat(state.soundsPlayed, ","), "fadingslow", "turning it on plays it once")
    state.settings[WIDGET_SCALE]:SetValue(90)
    equal(#state.soundsPlayed, 1, "other settings do not play it")
    state.settings.DSU_SHIELD_ENABLED:SetValue(false)
    equal(ring.shown, false)
    local left = 0
    for _ in pairs(state.auraSounds) do left = left + 1 end
    equal(left, 0, "no sounds while the display is off")
end)
test("the break sound is chosen in a dropdown under its switch; choosing one plays it", function()
    local state = fixture()
    local page = state.categories[PAGE]
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
    state.settings[WIDGET_SCALE]:SetValue(90)
    local count = 0
    for _, message in ipairs(state.messages) do
        if message:find("Install Dyre's Sounds", 1, true) then count = count + 1 end
    end
    equal(count, 1, "once per session")
end)
test("/dsu unlock shows the sample and outline to drag; /dsu lock locks every Dyre's AddOn", function()
    local state = fixture()
    local ring = state.ring()
    equal(ring.mouse, false, "locked: clicks pass through")
    state.clear()
    state.slash("unlock")
    equal(state.toolkit.IsLocked(), false, "/dsu unlock is the toolkit's lock")
    equal(state.suf.db.shield.locked, false)
    equal(ring.shown, true)
    equal(ring.mouse, true)
    equal(ring.text.text, "drag me")
    equal(ring.sample.shown, true)
    equal(ring.dyre.mover.shown, true, "the toolkit's gold outline")
    contains(ring.dyre.mover.hint.text, "Dyre's Shields Up")
    equal(ring.mover, nil, "no outline of the display's own")
    for _, message in ipairs(state.messages) do
        equal(message:find("^DSU:"), nil, "only the toolkit's line: " .. message)
    end
    ring.scripts.OnDragStart(ring)
    equal(ring.moving, true)
    ring:ClearAllPoints()
    ring:SetPoint("CENTER", state.env.UIParent, "CENTER", 200, 100)
    ring.scripts.OnDragStop(ring)
    local position = state.suf.db.shield.position
    equal(position.point, "CENTER")
    equal(position.relativePoint, "BOTTOMLEFT", "saved by the toolkit, from UIParent's corner")
    equal(position.x, 700)
    equal(position.y, 500)
    state.slash("lock")
    equal(state.toolkit.IsLocked(), true)
    equal(state.suf.db.shield.locked, true)
    equal(ring.shown, false)
    equal(ring.mouse, false)
    equal(ring.dyre.mover.shown, false)
    state.slash("reset")
    equal(state.suf.db.shield.position, nil)
    equal(ring.points[1][1], "CENTER")
    equal(ring.points[1][4], 20, "the display's default place")
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
    contains(text, "owner=DyresShieldsUp copies=DyresShieldsUp v11 (running)")
    contains(text, "minimumAbsorb=75")
    contains(text, "the absorb total shows above your character")
    equal(text:find("failed", 1, true), nil, "every debug step ran")
end)

-- Dyre's Toolkit ------------------------------------------------------------------

test("the ring is a toolkit widget, and the saved place and size carry over", function()
    local state = fixture({db = {shield = {position = {point = "CENTER", relativePoint = "CENTER", x = 100, y = 50},
        scale = 120}}})
    local ring = state.ring()
    local widgets = state.toolkit.Widgets("DyresShieldsUp")
    equal(#widgets, 1)
    equal(widgets[1], ring, "the display's own frame")
    equal(ring.dyre.store, state.suf.db.shield, "its store is DSU's shield settings")
    equal(ring.scale, 1.2)
    equal(ring.width, 160)
    local point = ring.points[#ring.points]
    equal(point[1], "CENTER")
    equal(point[3], "CENTER")
    equal(point[4], 100)
    equal(point[5], 50)
    equal(state.settings[WIDGET_SCALE]:GetValue(), 120, "the toolkit's size slider")
    equal(state.settings.DSU_SHIELD_SCALE, nil, "no slider of DSU's own")
    local members = state.toolkit.AddOns()
    equal(#members, 1)
    equal(members[1].title, "Dyre's Shields Up")
end)
test("a size change keeps the ring's center and saves its place", function()
    local state = fixture({db = {shield = {position = {point = "CENTER", relativePoint = "CENTER", x = 100, y = 50}}}})
    local ring = state.ring()
    local x, y = state.center(ring)
    state.settings[WIDGET_SCALE]:SetValue(150)
    equal(ring.scale, 1.5)
    local afterX, afterY = state.center(ring)
    equal(math.abs(afterX - x) < 0.01 and math.abs(afterY - y) < 0.01, true, "the center stays put")
    equal(state.suf.db.shield.position.relativePoint, "BOTTOMLEFT", "the new place is saved")
    equal(state.suf.db.shield.scale, 150)
    local page = state.categories[PAGE]
    equal(page.buttons[1].buttonText, "Reset size")
    page.buttons[1].onClick()
    equal(state.suf.db.shield.scale, 100)
    afterX, afterY = state.center(ring)
    equal(math.abs(afterX - x) < 0.01 and math.abs(afterY - y) < 0.01, true, "and back, from the center")
end)
test("the crescents grow; the number and the icons keep their own sizes", function()
    local state = fixture({class = "MAGE"})
    local ring = state.ring()
    local textScale, iconScale = ring.text:GetEffectiveScale(), ring.iconButtons.icebarrier:GetEffectiveScale()
    equal(textScale, 1)
    equal(iconScale, 1)
    state.settings[WIDGET_SCALE]:SetValue(150)
    equal(ring:GetEffectiveScale(), 1.5, "the crescents grow")
    equal(math.abs(ring.text:GetEffectiveScale() - 1) < 1e-9, true, "the number stays its size")
    equal(math.abs(ring.iconButtons.icebarrier:GetEffectiveScale() - 1) < 1e-9, true, "the icons stay their size")
    local timed
    for _, slot in ipairs(ring.crescents.slots) do
        if slot.key == "manashield" then timed = slot.button end
    end
    equal(timed:GetEffectiveScale(), 1.5, "Mana Shield's crescent grows with the outer one")
    state.settings.DYRE_DYRESSHIELDSUP_SHIELD_TEXTSCALE:SetValue(130)
    equal(math.abs(ring.text:GetEffectiveScale() - 1.3) < 1e-9, true, "the number has its own size")
    state.settings.DYRE_DYRESSHIELDSUP_SHIELD_ICONSCALE:SetValue(70)
    equal(math.abs(ring.iconButtons.icebarrier:GetEffectiveScale() - 0.7) < 1e-9, true, "and so do the icons")
    equal(state.suf.db.shield.textScale, 130, "saved with DSU's settings")
    equal(state.suf.db.shield.iconScale, 70)
    -- The number follows the crescent's foot, with no offsets in its own units.
    local anchor = ring.textHolder.points[1]
    equal(anchor[2], ring.foot)
    equal(anchor[4], nil)
    -- The sample's icons are the icon row's size.
    equal(ring.sampleIcons.parent, ring.iconHolder)
    -- Reset size: all three back to 100%.
    state.categories[PAGE].buttons[1].onClick()
    equal(state.suf.db.shield.scale, 100)
    equal(state.suf.db.shield.textScale, 100)
    equal(state.suf.db.shield.iconScale, 100)
    equal(math.abs(ring.text:GetEffectiveScale() - 1) < 1e-9, true)
end)
test("the size sliders: crescents, then the number, then the icons", function()
    local state = fixture()
    local order = {}
    for _, initializer in ipairs(state.categories[PAGE].initializers) do
        if initializer.setting.variable:find("^DYRE_") then order[#order + 1] = initializer.setting.name end
    end
    equal(table.concat(order, ", "), "Display size, Text size, Icon size", "no (%): the values show it")
    -- While another AddOn draws the ring, DSU's own greyed slider shows the % too.
    local elsewhere = fixture({class = "MAGE",
        shieldCopies = {{addon = "MageToolsForever", before = true, runs = true}}})
    local own = elsewhere.settings.DSU_SHIELD_SCALE
    equal(own.name, "Display size")
    for _, initializer in ipairs(elsewhere.categories[PAGE].initializers) do
        if initializer.setting == own then equal(initializer.options.formatter(85), "85%") end
    end
    equal(fixture({db = {shield = {textScale = 999, iconScale = "big"}}}).suf.db.shield.textScale, 150,
        "repaired on load")
end)
test("a v9-style host keeps the number and icons at 100% while its crescents grow", function()
    local state = fixture({class = "MAGE",
        shieldCopies = {{addon = "MageToolsForever", before = true, runs = true, layout = "v9"}}})
    local copy = state.copies.MageToolsForever
    local ring = copy.ShieldDisplay.frame
    copy.settings.scale = 140
    copy.ShieldDisplay.Refresh()
    equal(math.abs(ring:GetEffectiveScale() - 1.4) < 1e-9, true)
    equal(math.abs(ring.text:GetEffectiveScale() - 1) < 1e-9, true)
    equal(math.abs(ring.iconButtons.icebarrier:GetEffectiveScale() - 1) < 1e-9, true)
end)
test("no widget opacity: the ring's inner frame still fades with the secret absorb", function()
    local state = fixture()
    local ring = state.ring()
    equal(state.settings.DYRE_DYRESSHIELDSUP_SHIELD_OPACITY, nil, "no opacity slider")
    state.cast(POWER_WORD_SHIELD)
    equal(ring.visible.alpha, state.absorb, "the secret absorb, passed on unread")
    equal(ring.alpha, nil, "the widget itself is never faded")
end)
test("the icon row's engine slots are set up only when the engine makes them", function()
    local state = fixture()
    local ring = state.ring()
    local before = {}
    for _, slot in ipairs(ring.icons.slots) do before[slot.key] = slot.button.points[1] end
    state.settings[WIDGET_SCALE]:SetValue(150)
    state.slash("unlock")
    state.slash("lock")
    for _, slot in ipairs(ring.icons.slots) do
        equal(slot.button.points[1], before[slot.key], slot.key .. " untouched")
    end
end)
test("/dsu opens DSU's page through the toolkit, never in combat", function()
    local state = fixture()
    state.combat = true
    state.slash("options")
    equal(state.opened, nil)
    state.combat = false
    state.toolkit.AddOns()[1].openSettings()
    equal(state.opened, "id:" .. PAGE, "the toolkit's menu opens it too")
end)
test("without Dyre's Toolkit 2.0 DSU stays off and says once what to install", function()
    for _, options in ipairs({{noToolkit = true}, {oldToolkit = true}}) do
        local state = fixture(options)
        equal(state.suf.available, false)
        equal(state.ring(), nil, "no ring")
        local count = 0
        for _, message in ipairs(state.messages) do
            if message:find("needs Dyre's Toolkit 2.0", 1, true) then count = count + 1 end
        end
        equal(count, 1)
        contains(state.last(), "CurseForge")
        equal(state.last():find("github", 1, true), nil, "CurseForge only")
        state.slash("unlock")
        contains(state.last(), "unavailable")
    end
end)
test("the toolkit copy the tests load matches ../DyresToolkit when it is there", function()
    for _, path in ipairs(TOOLKIT_FILES) do
        local own = io.open("../DyresToolkit/" .. path, "rb")
        if own then
            local copy = assert(io.open("tests/toolkit/" .. path, "rb"))
            equal(copy:read("*a") == own:read("*a"), true, "tests/toolkit/" .. path .. " is stale: copy it again")
            copy:close()
            own:close()
        end
    end
end)

-- Settings from Mage Tools Forever and Warlock Tools Forever -------------------------

local function mtfShield()
    return {enabled = false, locked = false, number = false, breakSound = true, breakSoundKey = "magical",
        scale = 130, textScale = 120, iconScale = 80,
        position = {point = "CENTER", relativePoint = "BOTTOMLEFT", x = 300, y = 200}}
end
local function copied(state, fragment)
    local count = 0
    for _, message in ipairs(state.messages) do
        if message:find("Copied your shield settings", 1, true) then
            count = count + 1
            contains(message, fragment)
        end
    end
    return count
end

test("a Mage's first DSU login copies MTF's shield settings once", function()
    local source = {shield = mtfShield(), locked = false}
    local state = fixture({class = "MAGE", globals = {MageToolsForeverDB = source}})
    local shield = state.suf.db.shield
    equal(shield.enabled, false)
    equal(shield.number, false)
    equal(shield.breakSound, true)
    equal(shield.breakSoundKey, "magical")
    equal(shield.scale, 130)
    equal(shield.textScale, 120)
    equal(shield.iconScale, 80)
    equal(shield.position.x, 300)
    equal(shield.locked, true, "the lock is the toolkit's, not copied")
    equal(state.suf.db.migratedFrom, "MageToolsForever")
    equal(copied(state, "from Mage Tools Forever."), 1, "said once")
    equal(state.ring().scale, 1.3, "the widget uses the copied size")
    local point = state.ring().points[#state.ring().points]
    equal(point[3], "BOTTOMLEFT")
    equal(point[4], 300, "and the copied place")
    -- The source is read, never written.
    equal(source.shield.locked, false)
    equal(source.shield.scale, 130)
    shield.position.x = 1
    equal(source.shield.position.x, 300, "a new table, not MTF's")
    -- The next login: DSU has its own settings now.
    local again = fixture({class = "MAGE", globals = {MageToolsForeverDB = {shield = mtfShield()}},
        db = state.suf.db})
    equal(copied(again, ""), 0, "never twice")
end)
test("a Warlock's first DSU login copies WTF's shield settings", function()
    local state = fixture({class = "WARLOCK", globals = {WarlockToolsForeverDB = {shield = mtfShield()}}})
    equal(state.suf.db.shield.scale, 130)
    equal(state.suf.db.migratedFrom, "WarlockToolsForever")
    equal(copied(state, "from Warlock Tools Forever."), 1)
end)
test("settings DSU already has win, and nothing is copied", function()
    local state = fixture({class = "MAGE", globals = {MageToolsForeverDB = {shield = mtfShield()}},
        db = {shield = {scale = 70}}})
    equal(state.suf.db.shield.scale, 70)
    equal(state.suf.db.migratedFrom, nil)
    equal(copied(state, ""), 0)
end)
test("only the player's class's AddOn counts", function()
    -- Both AddOns make a default shield table on every class.
    local state = fixture({class = "WARLOCK", globals = {MageToolsForeverDB = {shield = mtfShield()}}})
    equal(state.suf.db.shield.scale, 100, "a Mage AddOn's table on a Warlock is ignored")
    equal(copied(state, ""), 0)
    local priest = fixture({globals = {MageToolsForeverDB = {shield = mtfShield()},
        WarlockToolsForeverDB = {shield = mtfShield()}}})
    equal(priest.suf.db.shield.scale, 100, "no source for a Priest")
    equal(copied(priest, ""), 0)
end)
test("damaged copied settings are repaired", function()
    local state = fixture({class = "MAGE", globals = {MageToolsForeverDB = {shield = {enabled = "yes",
        scale = 999, textScale = "big", breakSoundKey = 7, position = {point = "LEFT", x = "far"}}}}})
    local shield = state.suf.db.shield
    equal(shield.enabled, true)
    equal(shield.scale, 150)
    equal(shield.textScale, 100)
    equal(shield.breakSoundKey, "fadingslow")
    equal(shield.position, nil, "a broken place is dropped")
    equal(state.suf.db.migratedFrom, "MageToolsForever")
    for _, broken in ipairs({"text", 5, {shield = "nope"}}) do
        local other = fixture({class = "MAGE", globals = {MageToolsForeverDB = broken}})
        equal(other.suf.db.shield.scale, 100, "no usable source: DSU's defaults")
        equal(copied(other, ""), 0)
    end
end)
test("with no source, a new character starts at DSU's defaults", function()
    local state = fixture({class = "MAGE"})
    equal(state.suf.db.shield.scale, 100)
    equal(state.suf.db.migratedFrom, nil)
    equal(copied(state, ""), 0)
    equal(fixture({db = {migratedFrom = 5}}).suf.db.migratedFrom, nil, "repaired on load")
end)

-- Hosts of the shared display without widgets (MTF and WTF 1.1.0) ----------------

test("a v9-style host keeps its toolkit drag and save, and a size change keeps the center", function()
    local state = fixture({class = "MAGE",
        shieldCopies = {{addon = "MageToolsForever", before = true, runs = true, layout = "v9"}}})
    local copy = state.copies.MageToolsForever
    equal(copy.ShieldDisplay.IsOwner(), true, "the first registered wins a tie")
    local ring = copy.ShieldDisplay.frame
    equal(ring.dyre, nil, "not a widget")
    equal(#state.toolkit.Widgets("DyresShieldsUp"), 0, "DSU adopts nothing it does not draw")
    copy.settings.position = {point = "CENTER", relativePoint = "CENTER", x = 100, y = 50}
    copy.ShieldDisplay.ResetPosition()
    copy.settings.position = {point = "CENTER", relativePoint = "CENTER", x = 100, y = 50}
    ring:ClearAllPoints()
    ring:SetPoint("CENTER", state.env.UIParent, "CENTER", 100, 50)
    local x, y = state.center(ring)
    copy.settings.scale = 150
    copy.ShieldDisplay.Refresh()
    equal(ring.scale, 1.5)
    local afterX, afterY = state.center(ring)
    equal(math.abs(afterX - x) < 0.01 and math.abs(afterY - y) < 0.01, true, "grows from its center")
    equal(copy.settings.position.relativePoint, "BOTTOMLEFT", "the display saves the new place")
    copy.ShieldDisplay.Refresh()
    equal(copy.settings.position.relativePoint, "BOTTOMLEFT", "an unchanged size moves nothing")
    -- The next toolkit drag saves through the host's save.
    state.toolkit.Unlock()
    copy.settings.locked = false
    copy.ShieldDisplay.Refresh()
    ring.scripts.OnDragStart(ring)
    equal(ring.moving, true, "registered with the toolkit")
    ring:ClearAllPoints()
    ring:SetPoint("CENTER", state.env.UIParent, "CENTER", -100, 0)
    ring.scripts.OnDragStop(ring)
    equal(ring.moving, false)
    local position = copy.settings.position
    equal(position.relativePoint, "BOTTOMLEFT")
    equal(math.abs(position.x * 1.5 - 350) < 0.01, true, "saved where it was dropped, in its own units")
end)
test("a host with no layout drags freely, and a size change keeps the center", function()
    local state = fixture({class = "MAGE",
        shieldCopies = {{addon = "MageToolsForever", before = true, runs = true}}})
    local copy = state.copies.MageToolsForever
    local ring = copy.ShieldDisplay.frame
    equal(ring.points[1][1], "CENTER", "placed at its default")
    local x, y = state.center(ring)
    copy.settings.scale = 70
    copy.ShieldDisplay.Refresh()
    local afterX, afterY = state.center(ring)
    equal(math.abs(afterX - x) < 0.01 and math.abs(afterY - y) < 0.01, true, "shrinks to its center")
    copy.settings.locked = false
    copy.ShieldDisplay.Refresh()
    equal(ring.mouse, true)
    equal(ring.mover.shown, true, "its own outline")
    ring.scripts.OnDragStart(ring)
    ring:ClearAllPoints()
    ring:SetPoint("LEFT", state.env.UIParent, "LEFT", 10, 0)
    ring.scripts.OnDragStop(ring)
    equal(copy.settings.position.point, "LEFT", "saved as dropped")
    copy.ShieldDisplay.ResetPosition()
    equal(copy.settings.position, nil)
end)
test("a saved place in a scaled ring lands where it was at login", function()
    local state = fixture({class = "MAGE", shieldCopies = {{addon = "MageToolsForever", before = true, runs = true,
        settings = {scale = 150, position = {point = "CENTER", relativePoint = "BOTTOMLEFT", x = 200, y = 100}}}}})
    local ring = state.copies.MageToolsForever.ShieldDisplay.frame
    local x, y = state.center(ring)
    equal(x, 300)
    equal(y, 150, "the saved offsets are in the ring's own scaled units")
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
    local page = state.categories[PAGE]
    for _, initializer in ipairs(page.initializers) do
        equal(initializer.modifyPredicates[1](), false, initializer.setting.variable .. " is greyed out")
        contains(initializer.tooltip, "Mage Tools Forever draws the shield display, so use its settings for it.")
    end
    local alone = fixture()
    for _, initializer in ipairs(alone.categories[PAGE].initializers) do
        local predicate = initializer.modifyPredicates[1]
        equal(predicate == nil or predicate(), true, "not greyed while DSU draws the ring")
        equal(initializer.tooltip:find("draws the shield display", 1, true), nil)
    end
end)
test("a newer copy elsewhere takes over; DSU takes over from an older one", function()
    local newer = fixture({shieldCopies = {{addon = "MageToolsForever", before = true, runs = true,
        version = 12}}})
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
