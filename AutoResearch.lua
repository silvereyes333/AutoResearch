AUTORESEARCH_BAG_BACKPACK = 1
AUTORESEARCH_BAG_BANK = 2
AUTORESEARCH_BAG_BOTH = 3
AutoResearch = {
    name = "AutoResearch",
    title = "|c99CCEFAuto Research|r",
    version = "1.5.1",
    author = "|c99CCEFsilvereyes|r",
    traitConfig = {
        armor = {
            name = SI_ITEMTYPE45,
            min = 11,
            max = 18,
            nirn = 25,
        },
        weapons = {
            name = SI_ITEMTYPE46,
            min = 1,
            max = 8,
            nirn = 26,
        }
    },
    defaults = {
        bags = AUTORESEARCH_BAG_BOTH,
        traitResearchOrder = {
            ["weapons"] = {
                ITEM_TRAIT_TYPE_WEAPON_SHARPENED,
                ITEM_TRAIT_TYPE_WEAPON_PRECISE,
                ITEM_TRAIT_TYPE_WEAPON_INFUSED,
                ITEM_TRAIT_TYPE_WEAPON_DECISIVE,
                ITEM_TRAIT_TYPE_WEAPON_CHARGED,
                ITEM_TRAIT_TYPE_WEAPON_DEFENDING,
                ITEM_TRAIT_TYPE_WEAPON_TRAINING,
                ITEM_TRAIT_TYPE_WEAPON_POWERED,
                ITEM_TRAIT_TYPE_WEAPON_NIRNHONED,
            },
            ["armor"] = {
                ITEM_TRAIT_TYPE_ARMOR_DIVINES,
                ITEM_TRAIT_TYPE_ARMOR_INFUSED,
                ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE,
                ITEM_TRAIT_TYPE_ARMOR_STURDY,
                ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED,
                ITEM_TRAIT_TYPE_ARMOR_REINFORCED,
                ITEM_TRAIT_TYPE_ARMOR_TRAINING,
                ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS,
                ITEM_TRAIT_TYPE_ARMOR_NIRNHONED,
            },
        },
    },
}
local self = AutoResearch
local libLazyCraftingName = "LibLazyCrafting"
local researchableCraftSkills = {
    [CRAFTING_TYPE_BLACKSMITHING] = true,
    [CRAFTING_TYPE_CLOTHIER]      = true,
    [CRAFTING_TYPE_WOODWORKING]   = true,
}
local cheapStyles = {
    [ITEMSTYLE_RACIAL_HIGH_ELF]   = true,
    [ITEMSTYLE_RACIAL_DARK_ELF]   = true,
    [ITEMSTYLE_RACIAL_WOOD_ELF]   = true,
    [ITEMSTYLE_RACIAL_NORD]       = true,
    [ITEMSTYLE_RACIAL_BRETON]     = true,
    [ITEMSTYLE_RACIAL_REDGUARD]   = true,
    [ITEMSTYLE_RACIAL_KHAJIIT]    = true,
    [ITEMSTYLE_RACIAL_ORC]        = true,
    [ITEMSTYLE_RACIAL_ARGONIAN]   = true,
    [ITEMSTYLE_RACIAL_IMPERIAL]   = true,
    [ITEMSTYLE_AREA_ANCIENT_ELF]  = true,
    [ITEMSTYLE_AREA_REACH]        = true,
    [ITEMSTYLE_ENEMY_PRIMITIVE]   = true,
}
function self.Print(input)
    local output = zo_strformat("<<1>>|cFFFFFF: <<2>>|r", self.title, input)
    d(output)
end
local function GetResearchCategory(craftSkill, researchLineIndex)
    local traitType = GetSmithingResearchLineTraitInfo(craftSkill, researchLineIndex, 1)
    for researchCategory, config in pairs(self.traitConfig) do
        if traitType == config.nirn
           or traitType >= config.min and traitType <= config.max
        then
            return researchCategory
        end
    end
end
local function DiscoverResearchableTraits(craftSkill, researchLineIndex, returnAll)
    
    -- Get the total number of traits in the research line
    local _, _, numTraits = GetSmithingResearchLineInfo(craftSkill, researchLineIndex)
    
    -- Range check
    if numTraits <= 0 then return true end
    
    local researchCategory = GetResearchCategory(craftSkill, researchLineIndex)
    if not researchCategory then return true end
    
    -- Initialize the traits array
    self.researchableTraits[researchLineIndex] = {}
    
    for traitOrder = 1, numTraits do
        local traitType = self.settings.traitResearchOrder[researchCategory][traitOrder]
        local traitIndex
        if traitType == self.traitConfig[researchCategory].nirn then
            traitIndex = numTraits
        else
            traitIndex = traitType + 1 - self.traitConfig[researchCategory].min
        end
        local _, _, known = GetSmithingResearchLineTraitInfo(craftSkill, researchLineIndex, traitIndex)
        
        -- Trait is known
        if not known then  
            local durationSecs = GetSmithingResearchLineTraitTimes(craftSkill, researchLineIndex, traitIndex)
            
            if not durationSecs then
                -- Trait is researchable
                table.insert(self.researchableTraits[researchLineIndex], traitIndex)
                
            elseif not returnAll then
                -- No additional research can be done in this line right now.
                self.currentResearchCount = self.currentResearchCount + 1
                self.researchableTraits[researchLineIndex] = nil
                return true
            end
            
        end
    end
    
    -- All traits are researched for this line.  Exclude it from any further processing.
    if #self.researchableTraits[researchLineIndex] == 0 then
        self.researchableTraits[researchLineIndex] = nil
    end
end

local function IsFcoisResearchMarked(bagId, slotIndex)
    if not FCOIS or not FCOIS.IsMarked then
        return
    end
    if FCOIS.IsMarked(bagId, slotIndex, FCOIS_CON_ICON_RESEARCH) then
        return true
    end
end
local function IsFcoisLocked(bagId, slotIndex)
    if not FCOIS or not FCOIS.IsMarked then
        return
    end
    if FCOIS.IsMarked(bagId, slotIndex, FCOIS_CON_ICON_LOCK) then
        return true
    end
end
local function IsResearchable(bagId, slotIndex)
    local _, _, _, _, locked, _, itemStyle, quality = GetItemInfo(bagId, slotIndex)
    if locked or itemStyle == ITEMSTYLE_NONE then 
        return
    end
    if IsFcoisLocked(bagId, slotIndex) then
        return
    end
    if IsFcoisResearchMarked(bagId, slotIndex) then
        return true
    end
    local itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_BRACKETS)
    local hasSet = GetItemLinkSetInfo(itemLink)
    if quality < ITEM_QUALITY_ARTIFACT 
       and cheapStyles[itemStyle] 
       and not hasSet
    then
        return true
    end
end
local function GetResearchableItem(bagId, craftSkill, researchLineIndex, returnAll)
    local slotIndex = ZO_GetNextBagSlotIndex(bagId)
    local researchableItems = {}
    while slotIndex do
        if IsResearchable(bagId, slotIndex) then
            for i = 1, #self.researchableTraits[researchLineIndex] do
                local traitIndex = self.researchableTraits[researchLineIndex][i]
                if not researchableItems[traitIndex] 
                   and CanItemBeSmithingTraitResearched(bagId, slotIndex, craftSkill, researchLineIndex, traitIndex) 
                then
                    if i == 1 and not returnAll then
                        return slotIndex
                    end
                    researchableItems[traitIndex] = slotIndex
                    break
                end
            end
        end
        slotIndex = ZO_GetNextBagSlotIndex(bagId, slotIndex)
    end
    return researchableItems
end
local function ResearchItem(bagId, slotIndex)
    local itemLink = GetItemLink(bagId, slotIndex)
    local traitType = GetItemLinkTraitInfo(itemLink)
    local traitName = GetString("SI_ITEMTRAITTYPE", traitType)
    self.Print("Researching "..tostring(itemLink).." ("..tostring(traitName)..")")
    self.researching = true
    ResearchSmithingTrait(bagId, slotIndex)
end
local function StopResearching()
    self.researching = nil
end
local function End()
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_SMITHING_TRAIT_RESEARCH_STARTED)
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_CRAFT_COMPLETED)
    -- Small delay to prevent last extraction failed message
    zo_callLater(StopResearching, 500)
end
local function TryWritCreator(craftSkill)
	End()
	if WritCreater then 
        if WritCreater.craftCompleteHandler then
            EVENT_MANAGER:RegisterForEvent(WritCreater.name, EVENT_CRAFT_COMPLETED, 
                                           WritCreater.craftCompleteHandler)
            WritCreater.craftCheck(1, craftSkill)
        else
            d("Old version of Dolgubon's Lazy Writ Crafter detected. Please update your addons.")
        end
	end
end
local function ResearchNextFromBag(craftSkill, maxResearchLineIndex, bagId, researchables)
    local bagResearchables = GetResearchableItem(bagId, craftSkill, maxResearchLineIndex)
    -- A slot specific slot index was returned, so research it
    if type(bagResearchables) == "number" then
        local slotIndex = bagResearchables
        ResearchItem(bagId, slotIndex)
        return true
    end
    researchables[bagId] = bagResearchables
end
local function ResearchNext(craftSkill)
    if self.currentResearchCount >= self.maxResearchCount then
		TryWritCreator(craftSkill)
        return
    end
    
    local remainingResearchCount = self.maxResearchCount - self.currentResearchCount
    
    while next(self.researchableTraits) ~= nil do
        local maxCount = 0
        local maxResearchLineIndex
        for researchLineIndex, traits in pairs(self.researchableTraits) do
            local count = #traits
            if count > maxCount then
                maxCount = count
                maxResearchLineIndex = researchLineIndex
            end
        end
        
        local researchables = {}
        
        -- Try to research an item out of the backpack, if so configured
        if (self.settings.bags == AUTORESEARCH_BAG_BACKPACK or self.settings.bags == AUTORESEARCH_BAG_BOTH) 
           and ResearchNextFromBag(craftSkill, maxResearchLineIndex, BAG_BACKPACK, researchables)
        then
            return
            
        -- Try to research an item from the player bank, if so configured
        elseif (self.settings.bags == AUTORESEARCH_BAG_BANK or self.settings.bags == AUTORESEARCH_BAG_BOTH) then
            if ResearchNextFromBag(craftSkill, maxResearchLineIndex, BAG_BANK, researchables) then
                return
            elseif ResearchNextFromBag(craftSkill, maxResearchLineIndex, BAG_SUBSCRIBER_BANK, researchables) then
                return
            end
        end
        
        -- The first trait was a bust, so check the cache of researchables
        -- for each of the other traits
        for i = 2, #self.researchableTraits[maxResearchLineIndex] do
            local traitIndex = self.researchableTraits[maxResearchLineIndex][i]
            for bagId, bagResearchables in pairs(researchables) do
                if bagResearchables[traitIndex] then
                    local slotIndex = bagResearchables[traitIndex]
                    ResearchItem(bagId, slotIndex)
                    return
                end
            end
        end
        self.researchableTraits[maxResearchLineIndex] = nil
    end
    
    TryWritCreator(craftSkill)
end

local function OnSmithingTraitResearchStarted(eventCode, craftSkill, researchLineIndex, traitIndex)
    -- Increment the number of current research slots in use
    self.currentResearchCount = self.currentResearchCount + 1
    -- No more research can be done in the current line, so remove its list of researchable traits
    self.researchableTraits[researchLineIndex] = nil
    -- Try to research the next slot
    ResearchNext(craftSkill)
end
local function Start(eventCode, craftSkill, sameStation) 
    -- Filter out any non-researchable craft skill lines
    if not researchableCraftSkills[craftSkill] then
        TryWritCreator(craftSkill)
        return
    end
    
    -- The number of research slots used for the current craft skill
    self.currentResearchCount = 0
    self.currentCraftSkill = craftSkill
    
    -- Max number of research slots based on passives
    self.maxResearchCount = GetMaxSimultaneousSmithingResearch(craftSkill)
    
    -- Subtotals how many traits are researched for each research line in this craft skill
    self.researchableTraits = {}
    
    -- Total number of research lines for this craft skill
    local researchLineCount = GetNumSmithingResearchLines(craftSkill)
    
    -- Loop through each research line (e.g. axe, mace, etc.)
    for researchLineIndex = 1, researchLineCount do
        -- Calculate subtotals for the research line
        if DiscoverResearchableTraits(craftSkill, researchLineIndex) then
            -- A true response means the research line already has a trait being researched
            if self.currentResearchCount >= self.maxResearchCount then
                TryWritCreator(craftSkill)
                return
            end
        end
    end
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_SMITHING_TRAIT_RESEARCH_STARTED, 
                                   OnSmithingTraitResearchStarted)
    ResearchNext(craftSkill)
end

local function OnAlertNoSuppression(category, soundId, message)
    if not self.researching or category ~= UI_ALERT_CATEGORY_ALERT then
        return
    end
    if message == SI_SMITHING_BLACKSMITH_EXTRACTION_FAILED 
       or message == SI_SMITHING_CLOTHIER_EXTRACTION_FAILED
       or message == SI_SMITHING_WOODWORKING_EXTRACTION_FAILED
    then
        return true
    end
end
local function OnAddonLoaded(event, name)
    if name ~= self.name then return end
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
    
    -- Defer our writ laziness until after done researching
    if WritCreater then
        EVENT_MANAGER:UnregisterForEvent(WritCreater.name, EVENT_CRAFTING_STATION_INTERACT)
        EVENT_MANAGER:UnregisterForEvent(WritCreater.name, EVENT_CRAFT_COMPLETED)
    end
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CRAFTING_STATION_INTERACT, Start)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_END_CRAFTING_STATION_INTERACT, End)
    
    ZO_PreHook("ZO_AlertNoSuppression", OnAlertNoSuppression)
    
    self.SetupOptions()
end
EVENT_MANAGER:RegisterForEvent(self.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)