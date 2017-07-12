for stringId, value in pairs(AUTORESEARCH_STRINGS) do
    ZO_CreateStringId(stringId, value)
end
AUTORESEARCH_STRINGS = nil

--[[ Dynamically generated strings ]]--

-- Research Error
ZO_CreateStringId("SI_AUTORESEARCH_ERROR", 
                  "|cFF0000"..GetString(SI_ITEM_ACTION_RESEARCH)
                  .." "..GetString(SI_PROMPT_TITLE_ERROR).."|r")

-- Max <<1>>
local maxFormat = string.gsub(GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_MAX_PRICE), 
                              GetString(SI_TRADING_HOUSE_SORT_TYPE_PRICE), 
                              "<<1>>")
-- Max Quality
ZO_CreateStringId("SI_AUTORESEARCH_MAX_QUALITY", 
                   zo_strformat(maxFormat, GetString(SI_MASTER_WRIT_DESCRIPTION_QUALITY)))