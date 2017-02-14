AutoResearch = {
    name = "AutoResearch",
    title = "Auto Research",
    version = "1.0.0",
    author = "|c99CCEFsilvereyes|r",
}

local function OnCraftingStationInteract(eventCode, craftSkill, sameStation)
    local self = AutoResearch
    d("Crafting station code "..tostring(craftSkill).." entered")
    local currentResearchCount = 0
    local researchLines = {}
    for researchLineIndex = 1, GetNumSmithingResearchLines(craftSkill) do
        local _, _, numTraits = GetSmithingResearchLineInfo(craftSkill, researchLineIndex)
        researchLines[researchLineIndex] = 0
        if numTraits > 0 then
            for traitIndex = 1, numTraits do
                local traitType, traitDescription, known = GetSmithingResearchLineTraitInfo(craftSkill, researchLineIndex, traitIndex)
        
                if known then  
                    researchLines[researchLineIndex] = researchLines[researchLineIndex] + 1
                else      
                    local durationSecs = GetSmithingResearchLineTraitTimes(craftSkill, researchLineIndex, traitIndex)
                    if durationSecs then
                        currentResearchCount = currentResearchCount + 1
                    end
                end
            end
            d("index: "..tostring(researchLineIndex)..", traits: "..tostring(researchLines[researchLineIndex]))
            local researchingTraitIndex = ZO_SharedSmithingResearch:FindResearchingTraitIndex(craftSkill, researchLineIndex, numTraits)
            if researchingTraitIndex then
                currentResearchCount = currentResearchCount + 1
            end
        end
    end
    d("Current research count: "..tostring(currentResearchCount))
    local maxResearchCount = GetMaxSimultaneousSmithingResearch(craftSkill)
    d("Max research count: "..tostring(maxResearchCount))
    if currentResearchCount >= maxResearchCount then
        return
    end
    local remainingResearchCount = maxResearchCount - currentResearchCount
    d("Remaining research count: "..tostring(remainingResearchCount))
end
local function OnAddonLoaded(event, name)
    local self = AutoResearch
    if name ~= self.name then return end
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
    
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CRAFTING_STATION_INTERACT, OnCraftingStationInteract)
end
EVENT_MANAGER:RegisterForEvent(AutoResearch.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)