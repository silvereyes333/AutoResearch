local self = AutoResearch
local function GetTraitStringId(traitIndex)
    local traitStringId = _G[zo_strformat("SI_ITEMTRAITTYPE<<1>>", traitIndex)]
    return traitStringId
end
local function SwapDropdownValues(optionsTable, settings, optionIndex, value)
    local oldValue = settings[optionIndex]
    for swapOptionIndex=1,#settings do
        local swapValue = settings[swapOptionIndex]
        if swapValue == value then
            settings[swapOptionIndex] = oldValue
            settings[optionIndex] = value
            return
        end
    end
end
local function CreateTraitOption(optionsTable, optionIndex, researchCategory)
    local traitOption = {
        type = "dropdown",
        width = "half",
        choices = self.traitChoices[researchCategory],
        choicesValues = self.traitChoicesValues[researchCategory],
        name = "|t420%:100%:esoui/art/worldmap/worldmap_map_background.dds|t" 
            .. tostring(optionIndex),
        getFunc = function() return self.settings.traitResearchOrder[researchCategory][optionIndex] end,
        setFunc = function(value)
            SwapDropdownValues(optionsTable, self.settings.traitResearchOrder[researchCategory], optionIndex, value)
        end,
        default = self.defaults.traitResearchOrder[researchCategory][optionIndex]
    }
    
    table.insert(optionsTable, traitOption)
end
local function CreateResearchLineOption(optionsTable, optionIndex, craftSkill)
    local researchLineOption = {
        type = "dropdown",
        width = "half",
        choices = self.researchLineChoices[craftSkill],
        choicesValues = self.researchLineChoicesValues[craftSkill],
        name = "|t420%:100%:esoui/art/worldmap/worldmap_map_background.dds|t" 
            .. tostring(optionIndex),
        getFunc = function() return self.settings.researchLineOrder[craftSkill][optionIndex] end,
        setFunc = function(value)
            SwapDropdownValues(optionsTable, self.settings.researchLineOrder[craftSkill], optionIndex, value)
        end,
        default = self.defaults.researchLineOrder[craftSkill][optionIndex]
    }
    
    table.insert(optionsTable, researchLineOption)
end
function self.SetupOptions()

    -- Populate the dropdown choices
    self.traitChoices = { }
    self.traitChoicesValues = { }
    for researchCategory, config in pairs(self.traitConfig) do
        if config.name then
            self.traitChoices[researchCategory] = { }
            self.traitChoicesValues[researchCategory] = { }
            for _, types in ipairs(config.types) do
                for traitIndex=types.min,types.max do
                    table.insert(self.traitChoicesValues[researchCategory], traitIndex)
                    table.insert(self.traitChoices[researchCategory], GetString("SI_ITEMTRAITTYPE", traitIndex))
                end
            end
        end
    end
    self.researchLineChoices = { }
    self.researchLineChoicesValues = { }
    self.defaults.researchLineOrder = { }
    for craftSkill, _ in pairs(self.craftSkills) do
        local researchLineCount = GetNumSmithingResearchLines(craftSkill)
        self.researchLineChoices[craftSkill] = { }
        self.researchLineChoicesValues[craftSkill] = { }
        for researchLineIndex = 1, researchLineCount do
            local researchLineName = GetSmithingResearchLineInfo(craftSkill, researchLineIndex)
            table.insert(self.researchLineChoicesValues[craftSkill], researchLineIndex)
            table.insert(self.researchLineChoices[craftSkill], researchLineName)
        end
        self.defaults.researchLineOrder[craftSkill] = self.researchLineChoicesValues[craftSkill]
    end
    
    -- Setup saved var
    self.settings = ZO_SavedVars:New("AutoResearch_Data", 1, nil, self.defaults)
    if not self.settings.dataVersion then
        self.settings.dataVersion = 1;
        self.Print(GetString(SI_AUTORESEARCH_NOTICE))
    end

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
        -- Max Quality
        {
            type = "dropdown",
            width = "full",
            choices = qualityChoices,
            choicesValues = qualityChoicesValues,
            name = GetString(SI_AUTORESEARCH_MAX_QUALITY),
            getFunc = function() return self.settings.maxQuality end,
            setFunc = function(value) self.settings.maxQuality = value end,
            default = self.defaults.maxQuality,
        },
    }

    for _, researchCategory in ipairs({ "armor", "weapons", "jewelry" }) do
        local categoryNameStringId = self.traitConfig[researchCategory].name
        if not categoryNameStringId then break end
        table.insert(optionsTable,
            -- Header
            {
                type = "header",
                width = "full",
                name = zo_strformat("<<m:1>>", GetString(categoryNameStringId), 2),
            })
        local maxOrderIndex = #self.defaults.traitResearchOrder[researchCategory]
        local minColumn2Index = math.ceil( maxOrderIndex / 2 ) + 1
        for column1Index=1, minColumn2Index - 1 do
            CreateTraitOption(optionsTable, column1Index, researchCategory)
            local column2Index = column1Index + minColumn2Index - 1
            if column2Index <= maxOrderIndex then
                CreateTraitOption(optionsTable, column2Index, researchCategory)
            end
        end
    end
    
    local traitLinesTitle = zo_strformat("<<m:1>>", GetString(SI_SMITHING_RESEARCH_LINE_HEADER), 2)
    local pairFormat = GetString(SI_INVENTORY_TRAIT_STATUS_TOOLTIP)
    for _, craftSkill in ipairs({ CRAFTING_TYPE_BLACKSMITHING, CRAFTING_TYPE_CLOTHIER, 
                                  CRAFTING_TYPE_WOODWORKING, CRAFTING_TYPE_JEWELRYCRAFTING })
    do
        table.insert(optionsTable,
        -- Header
        {
            type = "header",
            width = "full",
            name = zo_strformat(pairFormat, traitLinesTitle, GetCraftingSkillName(craftSkill)),
        })
        -- Number of research lines
        local researchLineCount = GetNumSmithingResearchLines(craftSkill)
        local minColumn2Index = math.ceil( researchLineCount / 2 ) + 1
        for researchLineIndex = 1, minColumn2Index - 1 do
            CreateResearchLineOption(optionsTable, researchLineIndex, craftSkill)
            local researchLineIndex2 = researchLineIndex + minColumn2Index - 1
            if researchLineIndex2 <= researchLineCount then
                CreateResearchLineOption(optionsTable, researchLineIndex2, craftSkill)
            end
        end
    end

    LAM2:RegisterOptionControls(self.name .. "Options", optionsTable)
end