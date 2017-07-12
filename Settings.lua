local self = AutoResearch
local function GetTraitStringId(traitIndex)
    local traitStringId = _G[zo_strformat("SI_ITEMTRAITTYPE<<1>>", traitIndex)]
    return traitStringId
end
local function SwapTraitOrders(optionsTable, researchCategory, optionIndex, value)
    local researchOrderSettings = self.settings.traitResearchOrder[researchCategory]
    local oldValue = researchOrderSettings[optionIndex]
    for swapOptionIndex=1,#researchOrderSettings do
        local swapValue = researchOrderSettings[swapOptionIndex]
        if swapValue == value then
            researchOrderSettings[swapOptionIndex] = oldValue
            researchOrderSettings[optionIndex] = value
            return
        end
    end
end
local function CreateTraitOption(optionsTable, optionIndex, researchCategory)
    local traitOption = {
        type = "dropdown",
        width = "half",
        choices = self.choices[researchCategory],
        choicesValues = self.choicesValues[researchCategory],
        name = "|t420%:100%:esoui/art/worldmap/worldmap_map_background.dds|t" 
            .. tostring(optionIndex),
        getFunc = function() return self.settings.traitResearchOrder[researchCategory][optionIndex] end,
        setFunc = function(value)
            SwapTraitOrders(optionsTable, researchCategory, optionIndex, value)
        end,
        default = self.defaults.traitResearchOrder[researchCategory][optionIndex]
    }
    
    table.insert(optionsTable, traitOption)
end
function self.SetupOptions()
    -- Setup saved var
    self.settings = ZO_SavedVars:New("AutoResearch_Data", 1, nil, self.defaults)
    if not self.settings.dataVersion then
        self.settings.dataVersion = 1;
        self.Print(GetString(SI_AUTORESEARCH_NOTICE))
    end

    -- Populate the dropdown choices
    self.choices = { }
    self.choicesValues = { }
    for researchCategory, config in pairs(self.traitConfig) do
        self.choices[researchCategory] = {}
        self.choicesValues[researchCategory] = {}
        for traitIndex=config.min,config.max do
            table.insert(self.choicesValues[researchCategory], traitIndex)
            table.insert(self.choices[researchCategory], GetString("SI_ITEMTRAITTYPE", traitIndex))
        end
        table.insert(self.choicesValues[researchCategory], config.nirn)
        table.insert(self.choices[researchCategory], GetString("SI_ITEMTRAITTYPE", config.nirn))
    end

    -- Setup options panel
    local LAM2 = LibStub("LibAddonMenu-2.0")
    if not LAM2 then return end

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

    for _, researchCategory in ipairs( { "armor", "weapons" } ) do
        table.insert(optionsTable,
            -- Header
            {
                type = "header",
                width = "full",
                name = GetString(self.traitConfig[researchCategory].name),
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

    LAM2:RegisterOptionControls(self.name .. "Options", optionsTable)
end