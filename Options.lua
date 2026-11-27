local addonName, DSU = ...

-- One settings page in Blizzard's vertical layout, with proxy settings that
-- read and write DyresShieldsUpDB.shield directly, under Dyre's Toolkit's
-- "Dyre's AddOns" (its own top-level page only if the toolkit offers none).
local TITLE = "Dyre's Shields Up"
local UNAVAILABLE = "The AddOn settings page is unavailable on this client. Use /dsu unlock, /dsu lock, "
    .. "and /dsu reset."

local REQUIRED_SETTINGS = {
    "RegisterVerticalLayoutCategory", "RegisterProxySetting", "RegisterAddOnCategory", "CreateCheckbox",
    "CreateSlider", "CreateSliderOptions", "CreateDropdown", "CreateControlTextContainer", "OpenToCategory",
}

-- The shield section's key, for Dyre's Toolkit's settings sections (2.17.0):
-- Mage Tools Forever's and Warlock Tools Forever's Shield pages show these
-- same rows and pass each change through to DSU (John, 2026-11-26).
local SECTION_KEY = "shield"
-- The section's one name (John, 2026-11-27: "the same name used consistently
-- everywhere"): its switch here, the title hosts read with
-- SettingsSectionTitle for their sub-page, and their top page's switch.
local SECTION_TITLE = "Shield display"
-- The ring's three sizes, in the widget's order, for a host page.
local SIZE_NAMES = {"scale", "textScale", "iconScale"}
local SIZE_LABELS = {scale = "Display size", textScale = "Text size", iconScale = "Icon size"}
local SIZE_TOOLTIPS = {
    scale = "How big the crescents are.",
    textScale = "How big the absorb number is.",
    iconScale = "How big the icons under the number are.",
}
local RESET_TOOLTIP = "Puts the crescents, the number, and the icons back to their normal size."
-- The toolkit's names for the ring widget's size settings (Widgets.lua
-- VariableName: DYRE_<ADDON>_<KEY>_<NAME>, upper case).
local WIDGET_VARIABLE = "DYRE_DYRESSHIELDSUP_SHIELD_"

local category

local function HasSettingsAPI()
    if type(Settings) ~= "table" or type(Settings.VarType) ~= "table" then
        return false
    end
    for _, name in ipairs(REQUIRED_SETTINGS) do
        if type(Settings[name]) ~= "function" then
            return false
        end
    end
    return true
end

local function Proxy(page, variable, variableType, name, default, getValue, setValue)
    return Settings.RegisterProxySetting(page, variable, variableType, name, default, getValue, setValue)
end

-- A checkbox for one saved shield flag.
local function Flag(page, variable, name, key, default, tooltip)
    local setting = Proxy(page, variable, Settings.VarType.Boolean, name, default,
        function() return DSU.db.shield[key] end,
        function(value)
            DSU.db.shield[key] = value == true
            DSU.RefreshShield()
        end)
    return Settings.CreateCheckbox(page, setting, tooltip)
end

local function SliderOptions(minValue, maxValue, step)
    local options = Settings.CreateSliderOptions(minValue, maxValue, step)
    if type(MinimalSliderWithSteppersMixin) == "table" and type(options.SetLabelFormatter) == "function" then
        -- The value shows the % sign, so the label has none (as the toolkit's sliders).
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
            function(value) return string.format("%d%%", value) end)
    end
    return options
end

-- The shield display draws in one AddOn only (Shield.lua's election); in the
-- others its settings do nothing, so they are greyed out (author-approved) with
-- a note naming the AddOn that draws it. Checked each time the page shows.
local function ShieldOwnerNote(display)
    if display.IsOwner() then
        return ""
    end
    return " " .. display.ShownByText(display.OwnerAddOn())
end

-- Whether a row can be changed: DSU draws the ring, and every switch above
-- the row is on (John, 2026-11-27: "when the top-level is off, the settings
-- that are controlling a disabled feature should be disabled too"). The whole
-- chain is checked, also on a host's sub-page where "Shield display" itself
-- is on the host's top page.
local function Allowed(display, switches)
    if not display.IsOwner() then
        return false
    end
    for _, key in ipairs(switches or {}) do
        if not DSU.db.shield[key] then
            return false
        end
    end
    return true
end

-- Blizzard checks a row's modify predicates again only when its direct
-- parent's setting changes (Blizzard_SettingControls.lua 297-302), so each
-- greyed row also watches its switches' variables (Toolkit 2.17.0's
-- WatchSettings, the initializer's own AddEvaluateStateCVar): it greys the
-- moment a switch is clicked, not only when the page draws again.
local function Watch(initializer, variables)
    local toolkit = DSU.toolkit or DSU.Toolkit()
    if variables and toolkit and type(toolkit.WatchSettings) == "function" then
        toolkit.WatchSettings(initializer, variables)
    end
    return initializer
end

local function GreyUnlessOwner(initializer, display, switches, watch)
    if type(initializer) == "table" and type(initializer.AddModifyPredicate) == "function" then
        initializer:AddModifyPredicate(function() return Allowed(display, switches) end)
    end
    return Watch(initializer, watch)
end

-- The switches above each kind of row.
local UNDER_DISPLAY = {"enabled"}
local UNDER_SOUND = {"enabled", "breakSound"}

-- The gold default mark, as on the toolkit's own sliders (2.2.0).
local function AddDefaultTick(slider, display)
    local toolkit = DSU.toolkit or DSU.Toolkit()
    if toolkit and type(toolkit.AddDefaultTick) == "function" then
        toolkit.AddDefaultTick(slider,
            {min = display.SCALE_MIN, max = display.SCALE_MAX, default = display.DEFAULT_SCALE})
    end
end

-- One size of the ring, through its widget when it is built (the widget
-- clamps, saves, and applies), else straight into the saved settings: a host
-- page can draw before DSU's own PLAYER_LOGIN builds the ring.
local function GetSize(name)
    local widget = DSU.shieldWidget
    if widget then
        return widget:GetSetting(name)
    end
    return DSU.db.shield[name]
end

local function SetSize(name, value)
    local widget = DSU.shieldWidget
    if widget then
        widget:SetSetting(name, value)
    else
        DSU.db.shield[name] = DSU.ShieldDisplay.SanitizeScale(value)
    end
    DSU.RefreshShield()
end

-- The three size sliders and "Reset size" on a host page drawn before DSU's
-- PLAYER_LOGIN has made the ring a widget, or with a toolkit whose
-- AddWidgetSettings cannot rename its variables (sections version 1). The
-- variables are the widget's own names through ctx.variable, as the
-- toolkit's would be, on the same saved sizes.
local function AddHostSizes(page, layout, ctx, display, note, watch)
    local variables = {}
    for _, name in ipairs(SIZE_NAMES) do
        local variable = ctx.variable(WIDGET_VARIABLE .. name:upper())
        variables[#variables + 1] = variable
        local setting = Proxy(page, variable, Settings.VarType.Number, SIZE_LABELS[name], display.DEFAULT_SCALE,
            function() return GetSize(name) end,
            function(value) SetSize(name, value) end)
        local slider = GreyUnlessOwner(Settings.CreateSlider(page, setting,
            SliderOptions(display.SCALE_MIN, display.SCALE_MAX, display.SCALE_STEP), SIZE_TOOLTIPS[name] .. note),
            display, UNDER_DISPLAY, watch)
        AddDefaultTick(slider, display)
    end
    if type(CreateSettingsButtonInitializer) == "function" and type(layout) == "table"
            and type(layout.AddInitializer) == "function" then
        local reset = GreyUnlessOwner(CreateSettingsButtonInitializer(TITLE, "Reset size", function()
            for _, name in ipairs(SIZE_NAMES) do
                SetSize(name, display.DEFAULT_SCALE)
            end
            for _, variable in ipairs(variables) do
                Settings.NotifyUpdate(variable)
            end
        end, RESET_TOOLTIP, true), display, UNDER_DISPLAY, watch)
        -- A greyed button row keeps a gold label on Forever while checkbox
        -- and slider rows grey theirs; the toolkit greys it too (2.17.0).
        local toolkit = DSU.toolkit or DSU.Toolkit()
        if toolkit and type(toolkit.GreyButtonLabel) == "function" then
            toolkit.GreyButtonLabel(reset)
        end
        layout:AddInitializer(reset)
    end
end

-- Every shield-display setting, for DSU's own page and for a host's page
-- (ctx: Dyre's Toolkit's settings section context). Every variable is named
-- through ctx.variable. Settings are read only in get, set, and predicates,
-- since a host can build its page before DSU's PLAYER_LOGIN. The display is
-- the same for every class, so ctx.class and ctx.filter change nothing.
-- ctx.part (sections version 3; John, 2026-11-27: "the top-level disable for
-- each section should be on the top-level MTF panel"): "master" is "Shield
-- display" alone, for a host's top page; "rest" is every other row, for the
-- host's Shield page; "all" (or none, before version 3) is both.
local function BuildShieldSection(page, layout, ctx)
    if not HasSettingsAPI() or type(DSU.db) ~= "table" or (DSU.loginDone and not DSU.available) then
        return false
    end
    local part = (ctx.part == "master" or ctx.part == "rest") and ctx.part or "all"
    local display = DSU.ShieldDisplay
    local V = ctx.variable
    local note = ShieldOwnerNote(display)
    -- The switches' variables on this host (on a host's Shield page,
    -- "Shield display" is on its top page, under the same prefix).
    local watchDisplay = {V("DSU_SHIELD_ENABLED")}
    local watchSound = {V("DSU_SHIELD_ENABLED"), V("DSU_SHIELD_BREAK_SOUND")}
    if part ~= "rest" then
        GreyUnlessOwner(Flag(page, V("DSU_SHIELD_ENABLED"), SECTION_TITLE, "enabled", true,
            "A crescent beside your character that shows how much of your shield is left: full when it "
                .. "lands, empty when it breaks." .. note), display)
        if part == "master" then
            return true
        end
    end
    GreyUnlessOwner(Flag(page, V("DSU_SHIELD_NUMBER"), "Show the absorb amount", "number", true,
        "Show your remaining absorb as a number under the crescent." .. note), display, UNDER_DISPLAY, watchDisplay)
    local soundSwitch = GreyUnlessOwner(Flag(page, V("DSU_SHIELD_BREAK_SOUND"), "Sound when a shield ends",
        "breakSound", false, "Play a sound when one of your shields ends or breaks, also in combat." .. note),
        display, UNDER_DISPLAY, watchDisplay)
    -- Which sound, under its switch (author-approved: a default you can change).
    local sound = Proxy(page, V("DSU_SHIELD_BREAK_SOUND_CHOICE"), Settings.VarType.String, "Sound",
        display.DEFAULT_BREAK_SOUND,
        function() return DSU.db.shield.breakSoundKey end,
        function(value)
            DSU.db.shield.breakSoundKey = display.SanitizeBreakSound(value)
            DSU.RefreshShield()
            display.PreviewBreakSound()
        end)
    -- The sounds come from Dyre's Sounds; without it the list is empty.
    local dropdown = Settings.CreateDropdown(page, sound, display.SoundChoices,
        "The sound to play when a shield ends. If the list is empty, install "
            .. "Dyre's Sounds." .. note)
    display.SetupSoundMenu(dropdown)
    GreyUnlessOwner(dropdown, display, UNDER_SOUND, watchSound)
    -- Its switch is always on the same page; the predicate above also checks
    -- "Shield display", which can be on another page.
    if type(dropdown.SetParentInitializer) == "function" then
        dropdown:SetParentInitializer(soundSwitch, function() return DSU.db.shield.breakSound end)
    end
    local toolkit = DSU.toolkit or DSU.Toolkit()
    local renames = toolkit and type(toolkit.SETTINGS_SECTIONS_VERSION) == "number"
        and toolkit.SETTINGS_SECTIONS_VERSION >= 2
    if DSU.shieldWidget and (ctx.own or renames) then
        -- The ring is a widget: the toolkit's size sliders (from the center,
        -- with their default marks) and "Reset size"; on a host page with
        -- the host's prefix (opts.variable, sections version 2).
        toolkit.AddWidgetSettings(page, layout, DSU.shieldWidget, {
            labels = {scale = SIZE_LABELS.scale},
            tooltips = SIZE_TOOLTIPS,
            resetTooltip = RESET_TOOLTIP,
            variable = not ctx.own and ctx.variable or nil,
            -- Sections version 3; an older toolkit ignores it.
            modify = function() return Allowed(display, UNDER_DISPLAY) end,
            watch = watchDisplay,
        })
    elseif not ctx.own then
        AddHostSizes(page, layout, ctx, display, note, watchDisplay)
    else
        -- Another AddOn draws the ring, so this only keeps the saved size.
        local scale = Proxy(page, V("DSU_SHIELD_SCALE"), Settings.VarType.Number, SIZE_LABELS.scale,
            display.DEFAULT_SCALE,
            function() return DSU.db.shield.scale end,
            function(value)
                DSU.db.shield.scale = display.SanitizeScale(value)
                DSU.RefreshShield()
            end)
        local slider = GreyUnlessOwner(Settings.CreateSlider(page, scale,
            SliderOptions(display.SCALE_MIN, display.SCALE_MAX, display.SCALE_STEP),
            SIZE_TOOLTIPS.scale .. note), display, UNDER_DISPLAY, watchDisplay)
        AddDefaultTick(slider, display)
    end
    return true
end

-- The toolkit with settings sections (2.17.0), else nil: with an older
-- toolkit, DSU's page stays as it was and MTF and WTF keep their link to it.
local function SectionToolkit()
    local toolkit = DSU.Toolkit()
    if toolkit and type(toolkit.SETTINGS_SECTIONS_VERSION) == "number" and toolkit.SETTINGS_SECTIONS_VERSION >= 1
            and type(toolkit.RegisterSettingsSection) == "function"
            and type(toolkit.OwnSettingsContext) == "function" then
        return toolkit
    end
end

-- From Core at ADDON_LOADED, after the saved settings are repaired: a host
-- builds its page at its own PLAYER_LOGIN, which can come before DSU's.
function DSU.RegisterSettingsSection()
    local toolkit = SectionToolkit()
    if not toolkit then
        return false
    end
    return toolkit.RegisterSettingsSection({addon = addonName, key = SECTION_KEY, title = SECTION_TITLE,
        build = BuildShieldSection}) == true
end

function DSU.InitializeOptions()
    if not HasSettingsAPI() then
        return
    end
    local display = DSU.ShieldDisplay
    local nested, layout = DSU.toolkit.RegisterSettingsCategory(TITLE)
    category = nested or Settings.RegisterVerticalLayoutCategory(TITLE)
    -- The same builder as on a host page, with the variables as named.
    local toolkit = SectionToolkit()
    local ctx = toolkit and toolkit.OwnSettingsContext(addonName, SECTION_KEY)
        or {own = true, owner = addonName, host = addonName, key = SECTION_KEY,
            variable = function(name) return name end}
    BuildShieldSection(category, layout, ctx)
    -- Proc cues moved to Dyre's Buff Reminders (1.5.0): a link to its page.
    DSU.AddProcsMovedRow(category, layout)
    -- A page under the toolkit's home is registered with it, and the toolkit's
    -- "Unlock frames" switch there unlocks every Dyre's AddOn (author-approved:
    -- no unlock switch of DSU's own then).
    if nested then
        return
    end
    local unlocked = Proxy(category, "DSU_UNLOCKED", Settings.VarType.Boolean, "Unlock to move it", false,
        function() return not DSU.db.shield.locked end,
        function(value) DSU.SetLocked(value ~= true) end)
    GreyUnlessOwner(Settings.CreateCheckbox(category, unlocked,
        "Show the whole display so you can drag it; untick to lock it." .. ShieldOwnerNote(display)), display)
    Settings.RegisterAddOnCategory(category)
end

function DSU.OpenSettings()
    if not category then
        DSU.Report(UNAVAILABLE)
        return
    end
    DSU.ShownElsewhere()
    -- The toolkit's opener says so in combat instead.
    DSU.toolkit.OpenSettings(category)
end
