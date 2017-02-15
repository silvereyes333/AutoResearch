AutoResearch = {
    name = "AutoResearch",
    title = "Auto Research",
    version = "1.1.0",
    author = "|c99CCEFsilvereyes|r",
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
local function DiscoverResearchableTraits(craftSkill, researchLineIndex)
    
    -- Get the total number of traits in the research line
    local _, _, numTraits = GetSmithingResearchLineInfo(craftSkill, researchLineIndex)
    
    -- Range check
    if numTraits <= 0 then return end
    
    -- Initialize the traits array
    self.researchableTraits[researchLineIndex] = {}
    
    for traitIndex = 1, numTraits do
        local traitType, traitDescription, known = GetSmithingResearchLineTraitInfo(craftSkill, researchLineIndex, traitIndex)

        -- Trait is known
        if not known then  
            local durationSecs = GetSmithingResearchLineTraitTimes(craftSkill, researchLineIndex, traitIndex)
            
            if durationSecs then
                -- No additional research can be done in this line right now.
                self.researchableTraits[researchLineIndex] = nil
                self.currentResearchCount = self.currentResearchCount + 1
                return true
            else
                -- Trait is researchable
                table.insert(self.researchableTraits[researchLineIndex], traitIndex)
            end
            
        end
    end
    
    -- All traits are researched for this line.  Exclude it from any further processing.
    if #self.researchableTraits[researchLineIndex] == 0 then
        self.researchableTraits[researchLineIndex] = nil
    end
end
--[[
local function IsItemLocked(bagId, slotIndex)
    if IsItemPlayerLocked(bagId, slotIndex) then
        return true
    end
    if FCOIS and FCOIS.callItemSelectionHandler 
       and type(FCOIS.callItemSelectionHandler) == "function"
       and FCOIS.callItemSelectionHandler(bagId, slotIndex, false, false, false, true, false, true)
    then
        return true
    end
end]]--
local function GetResearchableItem(inventoryType, craftSkill, researchLineIndex)
    local inventory = PLAYER_INVENTORY.inventories[inventoryType]
    local bagId = inventory.backingBag


    local slotIndex = ZO_GetNextBagSlotIndex(bagId)
    local researchableItems = {}
    local firstTraitIndex = self.researchableTraits[researchLineIndex][1]
    while slotIndex do
        local itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_BRACKETS)
        local quality = GetItemLinkQuality(itemLink)
        local itemStyle = GetItemLinkItemStyle(itemLink)
        local hasSet = GetItemLinkSetInfo(itemLink)
        if quality < ITEM_QUALITY_ARTIFACT and not IsItemPlayerLocked(bagId, slotIndex)
           and cheapStyles[itemStyle] and not hasSet
        then
            for i = 1, #self.researchableTraits[researchLineIndex] do
                local traitIndex = self.researchableTraits[researchLineIndex][i]
                if not researchableItems[traitIndex] 
                   and CanItemBeSmithingTraitResearched(bagId, slotIndex, craftSkill, researchLineIndex, traitIndex) 
                then
                    if i == 1 then
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
    d("Researching "..tostring(itemLink).." ("..tostring(traitName)..")")
    ResearchSmithingTrait(bagId, slotIndex)
end
local function End()
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_SMITHING_TRAIT_RESEARCH_STARTED)
end
local function TryWritCreator(craftSkill)
	End()
	if WritCreater then 
        EVENT_MANAGER:RegisterForEvent(WritCreater.name, EVENT_CRAFT_COMPLETED, 
                                       WritCreater.craftCompleted)
        WritCreater.craftCheck(1, craftSkill)
	end
end
local function ResearchNext(craftSkill)
    if self.currentResearchCount >= self.maxResearchCount then
		TryWritCreator(craftSkill)
        return
    end
    
    local remainingResearchCount = self.maxResearchCount - self.currentResearchCount
    --d("Remaining research count: "..tostring(remainingResearchCount))
    
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
        --d("maxCount: "..tostring(maxCount)..", maxResearchLineIndex: "..tostring(maxResearchLineIndex))
        
        local backpackResearchables = GetResearchableItem(INVENTORY_BACKPACK, craftSkill, 
                                                          maxResearchLineIndex)
        -- A slot specific slot index was returned, so research it
        if type(backpackResearchables) == "number" then
            local slotIndex = backpackResearchables
            ResearchItem(BAG_BACKPACK, slotIndex)
            return
        end
        
        local bankResearchables = GetResearchableItem(INVENTORY_BANK, craftSkill, 
                                                      maxResearchLineIndex)
        -- A slot specific slot index was returned, so research it
        if type(bankResearchables) == "number" then
            local slotIndex = bankResearchables
            ResearchItem(BAG_BANK, slotIndex)
            return
        end
        
        -- The first trait was a bust, so check the cache of backpack and bank researchables
        -- for each of the other traits
        for i = 2, #self.researchableTraits[maxResearchLineIndex] do
            local traitIndex = self.researchableTraits[maxResearchLineIndex][i]
            if backpackResearchables[traitIndex] then
                local slotIndex = backpackResearchables[traitIndex]
                ResearchItem(BAG_BACKPACK, slotIndex)
                return
            elseif bankResearchables[traitIndex] then
                local slotIndex = bankResearchables[traitIndex]
                ResearchItem(BAG_BANK, slotIndex)
                return
            end
        end
        self.researchableTraits[maxResearchLineIndex] = nil
    end
    
    TryWritCreator(craftSkill)
end

local function OnSmithingTraitResearchStarted(eventCode, craftSkill, researchLineIndex, traitIndex)
    -- Increment the number of current research slots in use
    self.currentResearchCount = self.currentResearchCount + 1
    --d("currentResearchCount: "..tostring(self.currentResearchCount))
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
        
    --d("OnCraftingStationInteract("..tostring(eventCode)..", "..tostring(craftSkill)..", "..tostring(sameStation))   
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
end
EVENT_MANAGER:RegisterForEvent(self.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)