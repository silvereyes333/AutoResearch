--[[ Used to validate that a given slot conforms to the following rules:
        + Is a weapon or armor that has a valid trait and isn't intricate, ornate or otherwise special
        + Is not locked with the in-game or FCO Item Saver lock
        + Is marked for research with FCO Item Saver
        
          -OR-
          
          Is of a cheap style (base racial + primal, barbaric and ancient elf)
          Is white, green or blue quality
          Is not part of an item set
          
    Usage:
        local validator = AutoResearch.classes.Validator:New(bagId, slotIndex)
        local traitType = validator:Validate()
        if traitType then
            -- Valid
        else
            -- Invalid
        end
]]--

local ar   = AutoResearch
local class = ar.classes
class.Validator = ZO_Object:Subclass()

local name = ar.name .. "Validator"
local invalidTraits = {
    [ITEM_TRAIT_TYPE_NONE]              = true,
    [ITEM_TRAIT_TYPE_WEAPON_INTRICATE]  = true,
    [ITEM_TRAIT_TYPE_WEAPON_ORNATE]     = true,
    [ITEM_TRAIT_TYPE_ARMOR_ORNATE]      = true,
    [ITEM_TRAIT_TYPE_ARMOR_INTRICATE]   = true,
    [ITEM_TRAIT_TYPE_JEWELRY_ORNATE]    = true,
    [ITEM_TRAIT_TYPE_JEWELRY_INTRICATE] = true,
}
local craftSkillsByItemSoundCategory = {
    [ITEM_SOUND_CATEGORY_BOW]             = CRAFTING_TYPE_WOODWORKING,
    [ITEM_SOUND_CATEGORY_DAGGER]          = CRAFTING_TYPE_BLACKSMITHING,
    [ITEM_SOUND_CATEGORY_HEAVY_ARMOR]     = CRAFTING_TYPE_BLACKSMITHING,
    [ITEM_SOUND_CATEGORY_LIGHT_ARMOR]     = CRAFTING_TYPE_CLOTHIER,
    [ITEM_SOUND_CATEGORY_MEDIUM_ARMOR]    = CRAFTING_TYPE_CLOTHIER,
    [ITEM_SOUND_CATEGORY_NECKLACE]        = CRAFTING_TYPE_JEWELRYCRAFTING,
    [ITEM_SOUND_CATEGORY_ONE_HAND_AX]     = CRAFTING_TYPE_BLACKSMITHING,
    [ITEM_SOUND_CATEGORY_ONE_HAND_HAMMER] = CRAFTING_TYPE_BLACKSMITHING,
    [ITEM_SOUND_CATEGORY_ONE_HAND_SWORD]  = CRAFTING_TYPE_BLACKSMITHING,
    [ITEM_SOUND_CATEGORY_RING]            = CRAFTING_TYPE_JEWELRYCRAFTING,
    [ITEM_SOUND_CATEGORY_SHIELD]          = CRAFTING_TYPE_WOODWORKING,
    [ITEM_SOUND_CATEGORY_STAFF]           = CRAFTING_TYPE_WOODWORKING,
    [ITEM_SOUND_CATEGORY_TWO_HAND_AX]     = CRAFTING_TYPE_BLACKSMITHING,
    [ITEM_SOUND_CATEGORY_TWO_HAND_HAMMER] = CRAFTING_TYPE_BLACKSMITHING,
    [ITEM_SOUND_CATEGORY_TWO_HAND_SWORD]  = CRAFTING_TYPE_BLACKSMITHING,
}

function class.Validator:New(...)
    local instance = ZO_Object.New(self)
    instance:Initialize(...)
    return instance
end

function class.Validator:Initialize(bagId, slotIndex)
    self.name = name
    self.bagId = bagId
    self.slotIndex = slotIndex
end

--[[ If FCOIS 1.0+ is installed, then returns true for slots that are marked with the research icon. 
     Otherwise, returns nil. ]]--
function class.Validator:IsFcoisResearchMarked()
    if not FCOIS or not FCOIS.IsMarked then
        return
    end
    if FCOIS.IsMarked(self.bagId, self.slotIndex, FCOIS_CON_ICON_RESEARCH) then
        return true
    end
end

--[[ If FCOIS 1.0+ is installed, then returns true for slots that are marked with the lock icon. 
     Otherwise, returns nil. ]]--
function class.Validator:IsFcoisLocked()
    if not FCOIS or not FCOIS.IsMarked then
        return
    end
    if FCOIS.IsMarked(self.bagId, self.slotIndex, FCOIS_CON_ICON_LOCK) then
        return true
    end
end

function class.Validator:GetItemLinkCraftSkill(itemLink)
    local itemSoundCategory = GetItemSoundCategoryFromLink(itemLink)
    return craftSkillsByItemSoundCategory[itemSoundCategory]
end

--[[ If the item slot for this instance is valid, returns the item type.  Otherwise, returns nil. ]]--
function class.Validator:Validate()
    local locked = IsItemPlayerLocked(self.bagId, self.slotIndex)
    if locked then 
        return
    end
    if self:IsFcoisLocked() then
        return
    end
    local itemLink = GetItemLink(self.bagId, self.slotIndex)
    local traitType = GetItemLinkTraitInfo(itemLink)
    if self:IsFcoisResearchMarked() then
        return traitType
    end
    local itemTraitTypeCategory = GetItemTraitTypeCategory(itemTraitType)
    local itemStyle = GetItemLinkItemStyle(itemLink)
    if ar.styledCategories[itemTraitTypeCategory] and itemStyle == ITEMSTYLE_NONE then 
        return
    end
    if invalidTraits[traitType] then
        return
    end
    local quality = GetItemLinkQuality(itemLink)
    local craftSkill = self:GetItemLinkCraftSkill(itemLink)
    if not craftSkill or not ar.craftSkills[craftSkill] then
        return
    end
    if quality > ar.settings.maxQuality[craftSkill] or (ar.styledCategories[itemTraitTypeCategory] and not self.settings.styles[itemStyle]) then
        return
    end
    local hasSet, _, _, _, _, setId = GetItemLinkSetInfo(itemLink)
    if hasSet and (not LibSets or not ar.settings.sets or not ar.settings.setsAllowed or not ar.settings.sets[setId]) then
        return
    end
    return traitType
end