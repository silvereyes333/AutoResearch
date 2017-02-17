AutoResearch = {
    name = "AutoResearch",
    title = "Auto Research",
    version = "1.2.1",
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
local itemTraitTypeOrder = {
    ITEM_TRAIT_TYPE_WEAPON_TRAINING,
    ITEM_TRAIT_TYPE_ARMOR_TRAINING,
    ITEM_TRAIT_TYPE_WEAPON_SHARPENED,
    ITEM_TRAIT_TYPE_ARMOR_DIVINES,
    ITEM_TRAIT_TYPE_WEAPON_PRECISE,
    ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE,
    ITEM_TRAIT_TYPE_WEAPON_DECISIVE,
    ITEM_TRAIT_TYPE_ARMOR_INFUSED,
    ITEM_TRAIT_TYPE_WEAPON_CHARGED,
    ITEM_TRAIT_TYPE_ARMOR_STURDY,
    ITEM_TRAIT_TYPE_WEAPON_DEFENDING,
    ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED,
    ITEM_TRAIT_TYPE_WEAPON_INFUSED,
    ITEM_TRAIT_TYPE_ARMOR_REINFORCED,
    ITEM_TRAIT_TYPE_WEAPON_POWERED,
    ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS,
    ITEM_TRAIT_TYPE_WEAPON_NIRNHONED,
    ITEM_TRAIT_TYPE_ARMOR_NIRNHONED,
}
local function DiscoverResearchableTraits(craftSkill, researchLineIndex, returnAll)
    
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
local function GetResearchableItem(inventoryType, craftSkill, researchLineIndex, returnAll)
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
    d("Researching "..tostring(itemLink).." ("..tostring(traitName)..")")
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
-- Stolen from pChat. Thanks Ayantir.
-- Set copied text into text entry, if possible
local function CopyToTextEntry(message)

    -- Max of inputbox is 351 chars
    if string.len(message) < 351 then
        if CHAT_SYSTEM.textEntry:GetText() == "" then
            CHAT_SYSTEM.textEntry:Open(message)
            ZO_ChatWindowTextEntryEditBox:SelectAll()
        end
    end

end
local function EndCraft()
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_CRAFT_COMPLETED)
    self.craftGear = nil
    self.maxCraftCount = nil
    self.traitTypeToIndexMap = nil
end
local function MarkTraitCrafted(patternIndex, itemTraitType)
    self.craftGear[itemTraitType][patternIndex] = nil
    self.maxCraftCount = self.maxCraftCount - 1
    if not next(self.craftGear[itemTraitType]) then
        self.craftGear[itemTraitType] = nil
    end
end
local function CraftNext()

    if self.maxCraftCount < 1 then
        EndCraft()
        return
    end
    
    -- check inventory for available slot
    local slotIndex = FindFirstEmptySlotInBag(BAG_BACKPACK)
    if not slotIndex then
        ZO_AlertEvent(EVENT_INVENTORY_IS_FULL, 1, 0)
        EndCraft()
        return
    end
    
    -- Look up the next trait and pattern
    local itemTraitType
    for i=1, #itemTraitTypeOrder do
        if self.craftGear[itemTraitTypeOrder[i]] then
            itemTraitType = itemTraitTypeOrder[i]
            break
        end
    end
    if not itemTraitType then
        EndCraft()
        return
    end
    
    local patternIndex = next(self.craftGear[itemTraitType])
    
    -- Check inventory for sufficient materials
    local materialIndex = 1 -- always use the cheap stuff
    local materialCount = GetCurrentSmithingMaterialItemCount(patternIndex, materialIndex)
    local materialRequired = GetSmithingPatternNextMaterialQuantity(patternIndex, 
                                                                    materialIndex, 1, 1)
    local materialLink = GetSmithingPatternMaterialItemLink(patternIndex, materialIndex)
    if materialCount < materialRequired then
        d("You do not have the " .. tostring(materialRequired) .. "x " .. materialLink 
          .. " required to continue crafting.")
        EndCraft()
        return
    end
    
    -- find style stone with the biggest stack
    local maxStyleItemStackSize = 0
    local selectedStyleItemIndex
    local selectedItemStyle
    local maxStyleItemIndex = GetNumSmithingStyleItems()
    for styleItemIndex = 1, maxStyleItemIndex do
        local _, _, _, _, itemStyle = GetSmithingStyleItemInfo(styleItemIndex)
        local styleItemStackSize = GetCurrentSmithingStyleItemCount(styleItemIndex)
        if IsSmithingStyleKnown(styleItemIndex, patternIndex)
           and cheapStyles[itemStyle]
           and styleItemStackSize > maxStyleItemStackSize
        then
            selectedStyleItemIndex = styleItemIndex
            maxStyleItemStackSize = styleItemStackSize  
            selectedItemStyle = itemStyle       
        end
    end
    
    -- No cheap style materials found for any known styles
    if not selectedStyleItemIndex then
        d("You do not have any inexpensive style stones for known motifs.")
        EndCraft()
        return
    end
    
    -- Check inventory for trait stone
    local traitItemIndex = self.traitTypeToIndexMap[itemTraitType]
    local traitName = GetString("SI_ITEMTRAITTYPE", GetSmithingTraitItemInfo(traitItemIndex))
    local traitItemLink = GetSmithingTraitItemLink(traitItemIndex)
    local itemLink = GetSmithingPatternResultLink(patternIndex, materialIndex, materialRequired, 
                                                  selectedStyleItemIndex, traitItemIndex)
    itemLink = itemLink .. " ("..traitName..")"
    --d("trait item index: "..tostring(traitItemIndex))
    local traitStoneCount = GetCurrentSmithingTraitItemCount(traitItemIndex)
    if traitStoneCount == 0 then
        d("You do not have any "..tostring(traitItemLink).." so you cannot craft "..itemLink)
        MarkTraitCrafted(patternIndex, itemTraitType)
        CraftNext()
        return
    end
    
    local styleItemLink = GetSmithingStyleItemLink(selectedStyleItemIndex)
    --local itemStyleName = zo_strformat("<<1>>", GetString("SI_ITEMSTYLE", selectedItemStyle))
    d("Crafting " .. itemLink .. " using " .. tostring(materialRequired) .. "x " .. materialLink
      .. ", 1x " .. styleItemLink .. " and 1x " .. traitItemLink .. "...")
    -- Craft the item, at last
    MarkTraitCrafted(patternIndex, itemTraitType)
    --CraftNext()
    CraftSmithingItem(patternIndex, materialIndex, materialRequired, 
                      selectedStyleItemIndex, traitItemIndex)
end
local function ResearchCraft(encoded)
    if not encoded then
        d("Expected encoded research trait list. Please run /researchexport on the toon you want to craft for, and then copy/paste the resulting command here.")
        return
    end
    
    local craftSkill = GetCraftingInteractionType()
    if not researchableCraftSkills[craftSkill] then
        d("You cannot craft researchable gear here. Please go to an equipment crafting station and try again.")
        return
    end
    
    local isLine = true
    local isCraftSkill = true
    local isFreeSlots = false
    self.craftGear = {}
    local substitutions = { ["Robe"] = "Robe & Jerkin", ["Jerkin"] = "Robe & Jerkin"}
    
    self.traitTypeToIndexMap = {}
    for traitItemIndex = 1, GetNumSmithingTraitItems() do
        local itemTraitType = GetSmithingTraitItemInfo(traitItemIndex)
        if itemTraitType then
            self.traitTypeToIndexMap[itemTraitType] = traitItemIndex
        end
    end
    local nameToPatternMap = {}
    for patternIndex = 1, GetNumSmithingPatterns() do
        local name = GetSmithingPatternInfo(patternIndex)
        if substitutions[name] then
            name = substitutions[name]
        end
        nameToPatternMap[name] = patternIndex
    end
    local patternIndex
    local researchLineIndex
    for part in string.gmatch(encoded, '([^:]+)') do
        if isCraftSkill then
            isCraftSkill = false
            if tonumber(part) ~= craftSkill then
                d("You cannot craft that type of gear here. Please visit the appropriate craft station.")
                return
            end
            isFreeSlots = true
        elseif isFreeSlots then
            self.maxCraftCount = tonumber(part)
            isFreeSlots = false
        elseif isLine then
            researchLineIndex = tonumber(part)
            local researchLineName = GetSmithingResearchLineInfo(craftSkill, researchLineIndex)
            patternIndex = nameToPatternMap[researchLineName]
        else
            for splitPart in string.gmatch(part, '([^,]+)') do
                local researchTraitIndex = tonumber(splitPart)
                local itemTraitType, _, known = GetSmithingResearchLineTraitInfo(craftSkill, researchLineIndex, researchTraitIndex)
        
                -- Trait is known
                if known then  
                    if not self.craftGear[itemTraitType] then
                        self.craftGear[itemTraitType] = {}
                    end
                    self.craftGear[itemTraitType][patternIndex] = true
                end
            end
        end
        isLine = not isLine
    end
    
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CRAFT_COMPLETED, CraftNext)
    CraftNext()
end
local function ResearchExport(skill)
    
    local craftSkill
    if skill == "smith" or skill == "bs" or skill == "blacksmithing" or skill == "metal" then
        craftSkill = CRAFTING_TYPE_BLACKSMITHING
    elseif skill == "cloth" or skill == "clothier" then
        craftSkill = CRAFTING_TYPE_CLOTHIER
    elseif skill == "ww" or skill == "woodworking" then
        craftSkill = CRAFTING_TYPE_WOODWORKING
    else
        d("Unrecognized skill line. Expected blacksmithing (bs, metal, smith), clothier (cloth) or woodworking (ww).")
        return
    end
    
    local freeSlots = GetNumBagFreeSlots(BAG_BACKPACK) - 20
    if freeSlots < 0 then 
        d("You do not have enough free slots in your inventory.")
        return
    end
    local encoded = "/researchcraft "..tostring(craftSkill)..":"..tostring(freeSlots)..":"
    
    -- Subtotals how many traits are researched for each research line in this craft skill
    self.researchableTraits = {}
    
    -- Total number of research lines for this craft skill
    local researchLineCount = GetNumSmithingResearchLines(craftSkill)
    
    -- Loop through each research line (e.g. axe, mace, etc.)
    local firstLine = true
    for researchLineIndex = 1, researchLineCount do
        -- Calculate subtotals for the research line
        DiscoverResearchableTraits(craftSkill, researchLineIndex, true)
        if self.researchableTraits[researchLineIndex] then
            local backpackResearchables = GetResearchableItem(INVENTORY_BACKPACK, craftSkill, 
                                                              researchLineIndex, true)
            local bankResearchables     = GetResearchableItem(INVENTORY_BANK, craftSkill, 
                                                              researchLineIndex, true)
            local firstTrait = true
            for i = 1, #self.researchableTraits[researchLineIndex] do
                local traitIndex = self.researchableTraits[researchLineIndex][i]
                local traitType = GetSmithingResearchLineTraitInfo(craftSkill, researchLineIndex, 
                                                                   traitIndex)
                if not backpackResearchables[traitIndex] and not bankResearchables[traitIndex] 
                   and traitType ~= ITEM_TRAIT_TYPE_ARMOR_NIRNHONED
                   and traitType ~= ITEM_TRAIT_TYPE_WEAPON_NIRNHONED
                then
                    if firstTrait then
                        if firstLine then
                            firstLine = false
                        else
                            encoded = encoded .. ":"
                        end
                        encoded = encoded .. tostring(researchLineIndex) .. ":"
                        firstTrait = false
                    else
                        encoded = encoded .. ","
                    end
                    encoded = encoded .. tostring(traitIndex)
                end
            end
        end
    end 
    CopyToTextEntry(encoded)
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
    SLASH_COMMANDS["/rexport"] = ResearchExport
    SLASH_COMMANDS["/researchexport"] = ResearchExport
    SLASH_COMMANDS["/rcraft"] = ResearchCraft
    SLASH_COMMANDS["/researchcraft"] = ResearchCraft
end
EVENT_MANAGER:RegisterForEvent(self.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)