local _, SUF = ...

-- One settings page in Blizzard's vertical layout, with proxy settings that
-- read and write ShieldsUpForeverDB.shield directly.
local TITLE = "Shields Up Forever"
local UNAVAILABLE = "The AddOn settings page is unavailable on this client. Use /suf unlock, /suf lock, "
    .. "and /suf reset."

local REQUIRED_SETTINGS = {
    "RegisterVerticalLayoutCategory", "RegisterProxySetting", "RegisterAddOnCategory", "CreateCheckbox",
    "CreateSlider", "CreateSliderOptions", "OpenToCategory",
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
        function() return SUF.db.shield[key] end,
        function(value)
            SUF.db.shield[key] = value == true
            SUF.RefreshShield()
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

function SUF.InitializeOptions()
    if not HasSettingsAPI() then
        return
    end
    local display = SUF.ShieldDisplay
    category = Settings.RegisterVerticalLayoutCategory(TITLE)
    Flag("SUF_SHIELD_ENABLED", "Shield display", "enabled", true,
        "A crescent beside your character that fills with your remaining shield, full when it lands. "
            .. "If Mage Tools Forever or Warlock Tools Forever shows it instead, use that AddOn's settings.")
    Flag("SUF_SHIELD_NUMBER", "Show the absorb amount", "number", true,
        "Show your remaining absorb as a number under the crescent.")
    Flag("SUF_SHIELD_BREAK_SOUND", "Sound when a shield ends", "breakSound", false,
        "Play a sound when a shield in the icon row ends or breaks, also in combat.")
    local scale = Proxy("SUF_SHIELD_SCALE", Settings.VarType.Number, "Display size (%)", display.DEFAULT_SCALE,
        function() return SUF.db.shield.scale end,
        function(value)
            SUF.db.shield.scale = display.SanitizeScale(value)
            SUF.RefreshShield()
        end)
    Settings.CreateSlider(category, scale, SliderOptions(display.SCALE_MIN, display.SCALE_MAX, display.SCALE_STEP),
        "How big the shield display is, in percent.")
    local unlocked = Proxy("SUF_UNLOCKED", Settings.VarType.Boolean, "Unlock to move it", false,
        function() return not SUF.db.shield.locked end,
        function(value) SUF.SetLocked(value ~= true) end)
    Settings.CreateCheckbox(category, unlocked,
        "Show a sample of the whole display, outlined, so you can drag it; untick to lock it again. "
            .. "/suf unlock and /suf lock do the same, and /suf reset moves it back to its default place.")
    Settings.RegisterAddOnCategory(category)
end

function SUF.OpenSettings()
    if not category then
        SUF.Report(UNAVAILABLE)
        return
    end
    SUF.ShownElsewhere()
    Settings.OpenToCategory(category:GetID())
end
