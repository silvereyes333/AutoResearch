local addon = AutoResearch

local COLOR_DISABLED = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))
local NONE = COLOR_DISABLED:Colorize(zo_strformat(GetString(SI_QUEST_TYPE_FORMAT), GetString(SI_ITEMTYPE0)))
local LibSavedVars = LibStub("LibSavedVars")

----------------- Settings -----------------------

local function SwapDropdownValues(settings, optionIndex, value)
    if value == 0 then
        settings[optionIndex] = value
        return
    end
    local oldValue = settings[optionIndex]
    for swapOptionIndex=1,#settings do
        local swapValue = settings[swapOptionIndex]
        if swapValue == value then
            settings[swapOptionIndex] = oldValue
            settings[optionIndex] = value
            return
        end
    end
    settings[optionIndex] = value
end
local function CreateTraitOption(optionsTable, optionIndex, researchCategory)
    local self = addon
    local traitOption = {
        type = "dropdown",
        width = "half",
        choices = addon.traitChoices[researchCategory],
        choicesValues = self.traitChoicesValues[researchCategory],
        name = "|t420%:100%:esoui/art/worldmap/worldmap_map_background.dds|t" 
            .. tostring(optionIndex),
        getFunc = function() return self.settings.traitResearchOrder[researchCategory][optionIndex] end,
        setFunc = function(value)
            SwapDropdownValues(self.settings.traitResearchOrder[researchCategory], optionIndex, value)
        end,
        default = self.defaults.traitResearchOrder[researchCategory][optionIndex]
    }
    
    table.insert(optionsTable, traitOption)
end
local function CreateResearchLineOption(optionsTable, optionIndex, craftSkill)
    local self = addon
    local researchLineOption = {
        type = "dropdown",
        width = "half",
        choices = self.researchLineChoices[craftSkill],
        choicesValues = self.researchLineChoicesValues[craftSkill],
        name = "|t420%:100%:art/icons/placeholder/icon_blank.dds|t" 
            .. tostring(optionIndex),
        getFunc = function() return self.settings.researchLineOrder[craftSkill][optionIndex] end,
        setFunc = function(value)
            SwapDropdownValues(self.settings.researchLineOrder[craftSkill], optionIndex, value)
        end,
        default = self.defaults.researchLineOrder[craftSkill][optionIndex],
        disabled = function() return not self.settings.enabled[craftSkill] end
    }
    
    table.insert(optionsTable, researchLineOption)
end
local function GetItemTraitTypeName(traitIndex)
    return GetString("SI_ITEMTRAITTYPE", traitIndex)
end

function addon:OnLegacySavedVarsMigrationStart(legacySavedVars)
    if not legacySavedVars.dataVersion or legacySavedVars.dataVersion > 1 then
        legacySavedVars.dataVersion = 3;
        return
    end
    local oldMaxQuality = legacySavedVars.maxQuality
    if type(oldMaxQuality) ~= "table" then
        local maxQuality = { }
        for craftSkill, _ in pairs(self.craftSkills) do
            maxQuality[craftSkill] = oldMaxQuality
        end
        legacySavedVars.maxQuality = maxQuality
    end
    if legacySavedVars.researchLineOrder then
        legacySavedVars.researchLineOrder[-1] = nil
    end
    legacySavedVars.dataVersion = 3;
end

function addon:SetupOptions()

    -- Populate the dropdown choices
    self.traitChoices = { }
    self.traitChoicesValues = { }
    self.defaults.traitResearchOrder = { }
    for researchCategory, config in pairs(self.traitConfig) do
        if config.name then
            self.traitChoicesValues[researchCategory] = { 0 }
            self.traitChoices[researchCategory] = { NONE }
            self.defaults.traitResearchOrder[researchCategory] = { }
            for _, types in ipairs(config.types) do
                for traitIndex=types.min,types.max do
                    table.insert(self.traitChoicesValues[researchCategory], traitIndex)
                    table.insert(self.traitChoices[researchCategory], GetItemTraitTypeName(traitIndex))
                    table.insert(self.defaults.traitResearchOrder[researchCategory], traitIndex)
                end
            end
        end
    end
    self.researchLineChoices = { }
    self.researchLineChoicesValues = { }
    self.defaults.researchLineOrder = { }
    self.defaults.enabled = { }
    for craftSkill, _ in pairs(self.craftSkills) do
        local researchLineCount = GetNumSmithingResearchLines(craftSkill)
        self.researchLineChoicesValues[craftSkill] = { 0 }
        self.researchLineChoices[craftSkill] = { NONE }
        self.defaults.researchLineOrder[craftSkill] = { }
        for researchLineIndex = 1, researchLineCount do
        local researchLineName = GetSmithingResearchLineInfo(craftSkill, researchLineIndex)
            table.insert(self.researchLineChoicesValues[craftSkill], researchLineIndex)
            table.insert(self.researchLineChoices[craftSkill], researchLineName)
            table.insert(self.defaults.researchLineOrder[craftSkill], researchLineIndex)
        end
        self.defaults.enabled[craftSkill] = true
    end    
    
    -- Setup saved vars
    self.settings = LibSavedVars:New(self.name .. "_Account", self.name .. "_Character", self.defaults, false)
    local legacySettings = ZO_SavedVars:New(self.name .. "_Data", 1)
    self.settings:Migrate(legacySettings, self.OnLegacySavedVarsMigrationStart, self)

    -- Setup options panel
    local LAM2 = LibStub("LibAddonMenu-2.0")

    local panelData = {
        type = "panel",
        name = self.title,
        displayName = self.title,
        author = self.author,
        version = self.version,
        slashCommand = "/autoresearch",
        registerForRefresh = true,
        registerForDefaults = true,
    }
    LAM2:RegisterAddonPanel(self.name .. "Options", panelData)
    
    local qualityChoices = {}
    local qualityChoicesValues = {}
    for quality = ITEM_QUALITY_MIN_VALUE, ITEM_QUALITY_MAX_VALUE do
        local qualityColor = GetItemQualityColor(quality)
        local qualityString = qualityColor:Colorize(GetString("SI_ITEMQUALITY", quality))
        table.insert(qualityChoicesValues, quality)
        table.insert(qualityChoices, qualityString)
    end

    local optionsTable = { 
        -- Account-wide settings
        self.settings:GetLibAddonMenuAccountCheckbox(),
        
        -- Bags to search for equipment to research
        {
            type = "dropdown",
            width = "full",
            choices = { 
                GetString(SI_GAMEPAD_INVENTORY_CATEGORY_HEADER),
                GetString(SI_GAMEPAD_BANK_CATEGORY_HEADER),
                zo_strformat("<<1>><<2>><<3>>", 
                             GetString(SI_GAMEPAD_INVENTORY_CATEGORY_HEADER),
                             GetString(SI_LIST_AND_SEPARATOR),
                             GetString(SI_GAMEPAD_BANK_CATEGORY_HEADER)),
            },
            choicesValues = { 
                AUTORESEARCH_BAG_BACKPACK,
                AUTORESEARCH_BAG_BANK,
                AUTORESEARCH_BAG_BOTH,
            },
            name = GetString(SI_AUTORESEARCH_BAGS),
            getFunc = function() return self.settings.bags end,
            setFunc = function(value) self.settings.bags = value end,
            default = self.defaults.bags,
        },
    }
    
    local traitLinesTitle = zo_strformat("<<m:1>>", GetString(SI_SMITHING_RESEARCH_LINE_HEADER), 2)
    local pairFormat = GetString(SI_INVENTORY_TRAIT_STATUS_TOOLTIP)
    for _, craftSkill in ipairs({ CRAFTING_TYPE_BLACKSMITHING, CRAFTING_TYPE_CLOTHIER, 
                                  CRAFTING_TYPE_WOODWORKING, CRAFTING_TYPE_JEWELRYCRAFTING })
    do
        local controls = { 
            {
                type = "divider",
                width = "full",
            },
            {
                type = "checkbox",
                name = "|t420%:100%:art/icons/placeholder/icon_blank.dds|t"
                       .. GetString(SI_ADDON_MANAGER_ENABLED),
                getFunc = function() return self.settings.enabled[craftSkill] end,
                setFunc = function(value) self.settings.enabled[craftSkill] = value end,
                width = "full",
                default = self.defaults.enabled[craftSkill],
            },
            -- Max Quality
            {
                type = "dropdown",
                width = "full",
                choices = qualityChoices,
                choicesValues = qualityChoicesValues,
                name = "|t420%:100%:art/icons/placeholder/icon_blank.dds|t"
                       .. GetString(SI_AUTORESEARCH_MAX_QUALITY),
                getFunc = function() return self.settings.maxQuality[craftSkill] end,
                setFunc = function(value) self.settings.maxQuality[craftSkill] = value end,
                default = self.defaults.maxQuality[craftSkill],
                disabled = function() return not self.settings.enabled[craftSkill] end
            },
            {
                type = "divider",
                width = "full",
            },
        }
        -- Number of research lines
        local researchLineCount = GetNumSmithingResearchLines(craftSkill)
        local minColumn2Index = math.ceil( researchLineCount / 2 ) + 1
        for researchLineIndex = 1, minColumn2Index - 1 do
            CreateResearchLineOption(controls, researchLineIndex, craftSkill)
            local researchLineIndex2 = researchLineIndex + minColumn2Index - 1
            if researchLineIndex2 <= researchLineCount then
                CreateResearchLineOption(controls, researchLineIndex2, craftSkill)
            end
        end
        table.insert(optionsTable,
            -- Submenu
            {
                type = "submenu",
                name = zo_strformat(pairFormat, traitLinesTitle, GetCraftingSkillName(craftSkill)),
                controls = controls,
            })
    end

    for _, researchCategory in ipairs({ "armor", "weapons", "jewelry" }) do
        local categoryNameStringId = self.traitConfig[researchCategory].name
        if not categoryNameStringId then break end
        local controls = { }
        local maxOrderIndex = #self.defaults.traitResearchOrder[researchCategory]
        local minColumn2Index = math.ceil( maxOrderIndex / 2 ) + 1
        for column1Index=1, minColumn2Index - 1 do
            CreateTraitOption(controls, column1Index, researchCategory)
            local column2Index = column1Index + minColumn2Index - 1
            if column2Index <= maxOrderIndex then
                CreateTraitOption(controls, column2Index, researchCategory)
            end
        end
        table.insert(optionsTable,
            -- Submenu
            {
                type = "submenu",
                name = zo_strformat("<<m:1>>", GetString(categoryNameStringId), 2),
                controls = controls,
            })
    end

    LAM2:RegisterOptionControls(self.name .. "Options", optionsTable)
end