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
local invalidTraits = {
    [ITEM_TRAIT_TYPE_NONE]             = true,
    [ITEM_TRAIT_TYPE_WEAPON_INTRICATE] = true,
    [ITEM_TRAIT_TYPE_WEAPON_ORNATE]    = true,
    [ITEM_TRAIT_TYPE_ARMOR_ORNATE]     = true,
    [ITEM_TRAIT_TYPE_ARMOR_INTRICATE]  = true,
    [ITEM_TRAIT_TYPE_JEWELRY_HEALTHY]  = true,
    [ITEM_TRAIT_TYPE_JEWELRY_ARCANE]   = true,
    [ITEM_TRAIT_TYPE_JEWELRY_ROBUST]   = true,
    [ITEM_TRAIT_TYPE_JEWELRY_ORNATE]   = true,
}
if ITEM_TRAIT_TYPE_SPECIAL_STAT then
    invalidTraits[ITEM_TRAIT_TYPE_SPECIAL_STAT] = true
end

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
    local itemStyle = GetItemLinkItemStyle(itemLink)
    if itemStyle == ITEMSTYLE_NONE then 
        return
    end
    if invalidTraits[traitType] then
        return
    end
    local quality = GetItemLinkQuality(itemLink)
    if quality > ar.settings.maxQuality or not cheapStyles[itemStyle] then
        return
    end
    local hasSet = GetItemLinkSetInfo(itemLink)
    if hasSet then
        return
    end
    return traitType
end