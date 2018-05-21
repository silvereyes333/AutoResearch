-- Bag scan options
AUTORESEARCH_BAG_BACKPACK = 1
AUTORESEARCH_BAG_BANK = 2
AUTORESEARCH_BAG_BOTH = 3

AutoResearch = {
    name = "AutoResearch",
    title = "|c99CCEFAuto Research|r",
    version = "1.9.0",
    author = "|c99CCEFsilvereyes|r",
    
    -- Global details about armor, weapon TraitType value ranges.
    traitConfig = {
        armor = {
            name = SI_ITEMTYPE45,
            types = {
                [1] = {
                    min = 11,
                    max = 18,
                  },
                [2] = {
                    min = 25,
                    max = 25,
                  }
            },
        },
        weapons = {
            name = SI_ITEMTYPE46,
            types = {
                [1] = {
                    min = 1,
                    max = 8,
                  },
                [2] = {
                    min = 26,
                    max = 26,
                  }
            },
        },
        jewelry = {
            name = SI_ITEMTYPE66,
            types = {
                [1] = {
                    min = 21,
                    max = 23,
                  },
                [2] = {
                    min = 28,
                    max = 33,
                  }
            },
        },
    },
    -- Option panel defaults
    defaults = {
        bags = AUTORESEARCH_BAG_BOTH,
        maxQuality = ITEM_QUALITY_ARCANE,
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
            ["jewelry"] = {
                ITEM_TRAIT_TYPE_JEWELRY_ARCANE,
                ITEM_TRAIT_TYPE_JEWELRY_ROBUST,
                ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY,
                ITEM_TRAIT_TYPE_JEWELRY_TRIUNE,
                ITEM_TRAIT_TYPE_JEWELRY_SWIFT,
                ITEM_TRAIT_TYPE_JEWELRY_HEALTHY,
                ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE,
                ITEM_TRAIT_TYPE_JEWELRY_HARMONY,
                ITEM_TRAIT_TYPE_JEWELRY_INFUSED,
            },
        },
    },
    -- Class definition namespace
    classes = {},
    -- Information about supported craft stations
    craftSkills = {
        [CRAFTING_TYPE_BLACKSMITHING]   = { },
        [CRAFTING_TYPE_CLOTHIER]        = { },
        [CRAFTING_TYPE_WOODWORKING]     = { },
        [CRAFTING_TYPE_JEWELRYCRAFTING] = { },
    },
    styledCategories = {
        [ITEM_TRAIT_TYPE_CATEGORY_ARMOR]  = true,
        [ITEM_TRAIT_TYPE_CATEGORY_WEAPON] = true,
    },
    debugMode = false,
}
local self = AutoResearch
local libLazyCraftingName = "LibLazyCrafting"
--[[ Outputs a colorized message to chat with the Auto Research prefix ]]--
function self.Print(input)
    local output = zo_strformat("<<1>>|cFFFFFF: <<2>>|r", self.title, input)
    d(output)
end
function self.Debug(input)
    if not self.debugMode then return end
    self.Print(input)
end

--[[ Stops supressing extraction errors ]]--
local function StopResearching()
    self.researchState = "stopped"
    self.Debug("self.researchState = "..tostring(self.researchState))
end

--[[ Stops UI error thrown on third slot researched due to some extract animation ]]--
local origErrorFrame
local function OnUIError(errorFrame, errorString)
    if errorString and string.find(errorString, "CraftingSmithingExtractSlotAnimation") then
        return
    end
    return origErrorFrame(errorFrame, errorString)
end

local function EndInteraction()
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_CRAFT_COMPLETED)
    self.researchState = nil
    self.Debug("self.researchState = "..tostring(self.researchState))
end

--[[ Ends the auto-research process and starts up Dolgubon's Lazy Writ Crafter, if enabled ]]--
local function TryWritCreator(craftSkill)
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_CRAFT_COMPLETED)
    -- Small delay to prevent last extraction failed message
    self.researchState = "stopping"
    self.Debug("self.researchState = "..tostring(self.researchState))
    zo_callLater(StopResearching, 500)
    
    if WritCreater then 
        if WritCreater.craftCompleteHandler then
            EVENT_MANAGER:RegisterForEvent(WritCreater.name, EVENT_CRAFT_COMPLETED, 
                                           WritCreater.craftCompleteHandler)
            
            self.Debug("Calling WritCreater.craftCheck(1, "..tostring(craftSkill)..")")
            WritCreater.craftCheck(1, craftSkill)
        else
            d("Old version of Dolgubon's Lazy Writ Crafter detected. Please update your addons.")
        end
	end
    local LLC = LibStub("LibLazyCrafting", true)
    if LLC.craftInteract then
        self.Debug("Calling LibLazyCrafting.craftInteract(1, "..tostring(craftSkill)..")")
        LLC.craftInteract(1, craftSkill)
    end
end

--[[ Workaround for the base game bug with the third research slot not starting research. ]]--
local function ResearchItemTimeout(craftSkill)
    self.Debug("ResearchItemTimeout("..tostring(craftSkill)..")")
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, SI_AUTORESEARCH_ERROR)
    TryWritCreator(craftSkill)
end

--[[ Starts research on a specific slot ]]--
local function ResearchItem(craftSkill, bagId, slotIndex)

    -- Print out auto-research message to chat
    local itemLink = GetItemLink(bagId, slotIndex)
    local traitType = GetItemLinkTraitInfo(itemLink)
    local traitName = GetString("SI_ITEMTRAITTYPE", traitType)
    local message = zo_strformat("<<1>> <<2>> (|r<<3>>|cFFFFFF)", 
        GetString(SI_GAMEPAD_SMITHING_CURRENT_RESEARCH_HEADER),
        itemLink, traitName)
    self.Print(message)
    
    -- If research doesn't start in 1.5 seconds, then time out and end auto-research
    local LTO = LibStub("LibTimeout")
    LTO:StartTimeout( 1500, ResearchItemTimeout, craftSkill)
    
    -- Perform the research
    ResearchSmithingTrait( bagId, slotIndex )
end

--[[ Selects the highest priority researchable item from the items cache and starts research.
     If all research slots are full, or if there are no researchable items in the cache, then
     tries running Lazy Writ Crafter ]] --
local function ResearchNext(craftSkill)

    -- Check for full research slots
    if self.queue:AreResearchSlotsFull() then
        self.Debug("Research slots are all full. Try Writ Creator next.")
		TryWritCreator(craftSkill)
        return
    end
    
    -- Start research on the next item from the cache
    local nextItem = self.queue:GetNext()
    if nextItem then
        ResearchItem(craftSkill, nextItem.bagId, nextItem.slotIndex)
        return
    end
    
    -- No researchable items found in the cache.  Start up Lazy Writ Crafter.
    TryWritCreator(craftSkill)
end

--[[ Event handler for when research starts on an item ]]--
local function OnCraftCompleted(eventCode, craftSkill)
    -- Stop waiting for timeout
    local LTO = LibStub("LibTimeout")
    LTO:CancelTimeout(ResearchItemTimeout)
    
    self.Debug("OnCraftCompleted("..tostring(eventCode)..", "..tostring(craftSkill)..")")
    
    -- Start researching the highest priority item from the cache
    ResearchNext(craftSkill)
end

local OnSmithingTraitResearchCanceled

--[[ Runs whenever a research station is first opened ]]--
local function Start(eventCode, craftSkill, sameStation)
    self.Debug("Start("..tostring(eventCode)..","..tostring(craftSkill)..","..tostring(sameStation)..")")
    if self.researchState then
        self.Debug("Exiting Start()...")
        return
    end

    -- Filter out any non-researchable craft skill lines
    local craftSkillInfo = self.craftSkills[craftSkill]
    if not craftSkillInfo then
        TryWritCreator(craftSkill)
        return
    end
    
    
    -- Instantiate link parser
    if not craftSkillInfo.linkParser then
        craftSkillInfo.linkParser = self.classes.LinkParser:New(craftSkill)
    end
    
    -- Initialize the items cache to detect whether all research slots are full
    self.queue = self.classes.ResearchQueue:New(craftSkill)
    
    -- Workaround for ZOS bug that allowed a research timer on a known trait
    if self.queue.invalidResearchTrait then
        
        self.Debug("Invalid research trait found. Canceling...")
        EVENT_MANAGER:RegisterForEvent(self.name, EVENT_SMITHING_TRAIT_RESEARCH_CANCELED, 
                                       OnSmithingTraitResearchCanceled)
        CancelSmithingTraitResearch(craftSkill,
                                    self.queue.invalidResearchTrait.researchLineIndex,
                                    self.queue.invalidResearchTrait.traitIndex)
        return
    end
    if self.queue:AreResearchSlotsFull() then
        self.Debug("All research slots are full")
        TryWritCreator(craftSkill)
        return
    end
    
    self.researchState = "started"
    self.Debug("self.researchState = "..tostring(self.researchState))
    
    -- Select which bags will be scanned for researchable items based on user configuration
    local bagIds
    if self.settings.bags == AUTORESEARCH_BAG_BOTH then
        bagIds = { BAG_BACKPACK, BAG_BANK, BAG_SUBSCRIBER_BANK }
    elseif self.settings.bags == AUTORESEARCH_BAG_BACKPACK then
        bagIds = { BAG_BACKPACK }
    else
        bagIds = { BAG_BANK, BAG_SUBSCRIBER_BANK }
    end
    
    -- Scan the bags for researchable items
    self.queue:Fill(bagIds)
    
    -- Cover Lazy Writ Crafter's ears and hum for a little bit
    if WritCreater then
        EVENT_MANAGER:UnregisterForEvent(WritCreater.name, EVENT_CRAFT_COMPLETED)
    end
    
    -- Listen for for the research started event
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CRAFT_COMPLETED, 
                                   OnCraftCompleted)
    
    -- Start researching the highest priority item from the cache
    ResearchNext(craftSkill)
end

-- Update 15+ only; if a known trait that has an active research counter was found and canceled,
-- then restart the research process.
OnSmithingTraitResearchCanceled = function(craftSkill, researchLineIndex, traitIndex)
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_SMITHING_TRAIT_RESEARCH_CANCELED)
    if not self.queue or not self.queue.invalidResearchTrait then
        return
    end
    if self.queue 
       and self.queue.invalidResearchTrait
       and self.queue.invalidResearchTrait.researchLineIndex == researchLineIndex
       and self.queue.invalidResearchTrait.traitIndex == traitIndex
    then
        self.Debug("Research successfully canceled. Starting over...")
        Start(nil, craftSkill)
    end
end

--[[ Whenever self.researchState is set, suppresses extraction errors ]]--
local function OnAlertNoSuppression(category, soundId, message)
    -- When auto-researching on the default craft station tab (extraction), extraction errors get
    -- raised by the game client.  Suppress them below.
    -- TODO: perhaps switch to the research tab automatically before starting auto research.
    if not self.researchState or self.researchState == "stopped" or category ~= UI_ALERT_CATEGORY_ALERT then
        return
    end
    if message == SI_SMITHING_EXTRACTION_FAILED
    then
        return true
    end
end

--[[ Runs once upon login or /reloadui for every addon that is loaded ]]--
local function OnAddonLoaded(event, name)

    -- Only run when this addon is loaded
    if name ~= self.name then return end
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
    
    -- Procrastinate our writ laziness until after done researching
    if WritCreater then
        EVENT_MANAGER:UnregisterForEvent(WritCreater.name, EVENT_CRAFTING_STATION_INTERACT)
    end
    local LLC = LibStub("LibLazyCrafting", true)
    if LLC then
        EVENT_MANAGER:UnregisterForEvent("LibLazyCrafting", EVENT_CRAFTING_STATION_INTERACT)
    end
    
    -- Wire up event handlers
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CRAFTING_STATION_INTERACT, Start)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_END_CRAFTING_STATION_INTERACT, EndInteraction)
    
    -- Wire up extraction error suppressions
    ZO_PreHook("ZO_AlertNoSuppression", OnAlertNoSuppression)
    origErrorFrame = ZO_ERROR_FRAME.OnUIError
    ZO_ERROR_FRAME.OnUIError = OnUIError
    
    -- Set up settings menu.  See Settings.lua.
    self.SetupOptions()
end

-- Wire up addon loaded event
EVENT_MANAGER:RegisterForEvent(self.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)