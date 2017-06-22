for stringId, value in pairs(AUTORESEARCH_STRINGS) do
    ZO_CreateStringId(stringId, value)
end
AUTORESEARCH_STRINGS = nil
ZO_CreateStringId("SI_AUTORESEARCH_ERROR", 
                  "|cFF0000"..GetString(SI_ITEM_ACTION_RESEARCH)
                  .." "..GetString(SI_PROMPT_TITLE_ERROR).."|r")