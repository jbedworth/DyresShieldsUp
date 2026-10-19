local _, DSU = ...

-- One settings page in Blizzard's vertical layout, with proxy settings that
-- read and write DyresShieldsUpDB.shield directly.
local TITLE = "Dyre's Shields Up"
local UNAVAILABLE = "The AddOn settings page is unavailable on this client. Use /dsu unlock, /dsu lock, "
    .. "and /dsu reset."

local REQUIRED_SETTINGS = {
    "RegisterVerticalLayoutCategory", "RegisterProxySetting", "RegisterAddOnCategory", "CreateCheckbox",
    "CreateSlider", "CreateSliderOptions", "CreateDropdown", "CreateControlTextContainer", "OpenToCategory",
}

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

local function Proxy(variable, variableType, name, default, getValue, setValue)
    return Settings.RegisterProxySetting(category, variable, variableType, name, default, getValue, setValue)
end

-- A checkbox for one saved shield flag.
local function Flag(variable, name, key, default, tooltip)
    local setting = Proxy(variable, Settings.VarType.Boolean, name, default,
        function() return DSU.db.shield[key] end,
        function(value)
            DSU.db.shield[key] = value == true
            DSU.RefreshShield()
        end)
    return Settings.CreateCheckbox(category, setting, tooltip)
end

local function SliderOptions(minValue, maxValue, step)
    local options = Settings.CreateSliderOptions(minValue, maxValue, step)
    if type(MinimalSliderWithSteppersMixin) == "table" and type(options.SetLabelFormatter) == "function" then
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    end
    return options
end

function DSU.InitializeOptions()
    if not HasSettingsAPI() then
        return
    end
    local display = DSU.ShieldDisplay
    category = Settings.RegisterVerticalLayoutCategory(TITLE)
    Flag("DSU_SHIELD_ENABLED", "Shield display", "enabled", true,
        "A crescent beside your character that fills with your remaining shield, full when it lands. "
            .. "If Mage Tools Forever or Warlock Tools Forever shows it instead, use that AddOn's settings.")
    Flag("DSU_SHIELD_NUMBER", "Show the absorb amount", "number", true,
        "Show your remaining absorb as a number under the crescent.")
    local soundSwitch = Flag("DSU_SHIELD_BREAK_SOUND", "Sound when a shield ends", "breakSound", false,
        "Play a sound when a shield in the icon row ends or breaks, also in combat.")
    -- Which sound, under its switch (author-approved: a default you can change).
    local sound = Proxy("DSU_SHIELD_BREAK_SOUND_CHOICE", Settings.VarType.String, "Sound",
        display.DEFAULT_BREAK_SOUND,
        function() return DSU.db.shield.breakSoundKey end,
        function(value)
            DSU.db.shield.breakSoundKey = display.SanitizeBreakSound(value)
            DSU.RefreshShield()
            display.PreviewBreakSound()
        end)
    -- The sounds come from Dyre's Sounds; without it the list is empty.
    local dropdown = Settings.CreateDropdown(category, sound, display.SoundChoices,
        "The sound when a shield ends. Choosing one plays it once. The sounds come from Dyre's Sounds.")
    display.SetupSoundMenu(dropdown)
    if type(dropdown.SetParentInitializer) == "function" then
        dropdown:SetParentInitializer(soundSwitch, function() return DSU.db.shield.breakSound end)
    end
    local scale = Proxy("DSU_SHIELD_SCALE", Settings.VarType.Number, "Display size (%)", display.DEFAULT_SCALE,
        function() return DSU.db.shield.scale end,
        function(value)
            DSU.db.shield.scale = display.SanitizeScale(value)
            DSU.RefreshShield()
        end)
    Settings.CreateSlider(category, scale, SliderOptions(display.SCALE_MIN, display.SCALE_MAX, display.SCALE_STEP),
        "How big the shield display is, in percent.")
    local unlocked = Proxy("DSU_UNLOCKED", Settings.VarType.Boolean, "Unlock to move it", false,
        function() return not DSU.db.shield.locked end,
        function(value) DSU.SetLocked(value ~= true) end)
    Settings.CreateCheckbox(category, unlocked,
        "Show a sample of the whole display, outlined, so you can drag it; untick to lock it again. "
            .. "/dsu unlock and /dsu lock do the same, and /dsu reset moves it back to its default place.")
    Settings.RegisterAddOnCategory(category)
end

function DSU.OpenSettings()
    if not category then
        DSU.Report(UNAVAILABLE)
        return
    end
    DSU.ShownElsewhere()
    Settings.OpenToCategory(category:GetID())
end
