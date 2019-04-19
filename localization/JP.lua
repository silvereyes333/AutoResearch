local strings = {
    ["SI_AUTORESEARCH_BAGS"]                   = "研究のための機器を探すためのバッグ",
    ["SI_AUTORESEARCH_STYLES"]                 = GetString(SI_SMITHING_HEADER_STYLE),
    ["SI_AUTORESEARCH_SETS"]                   = GetString(SI_MASTER_WRIT_DESCRIPTION_SET),
    ["SI_AUTORESEARCH_CHAT_MESSAGES"]          = "チャットメッセージ",
    ["SI_AUTORESEARCH_SHORT_PREFIX"]           = "短いプレフィックスを使用",
    ["SI_AUTORESEARCH_SHORT_PREFIX_TOOLTIP"]   = "チャットメッセージの先頭にAutoResearchではなくARを付けます。",
    ["SI_AUTORESEARCH_COLORED_PREFIX"]         = "AutoResearch 1プレフィックスカラーを使用",
    ["SI_AUTORESEARCH_COLORED_PREFIX_TOOLTIP"] = "チャットメッセージのプレフィックスの色として、[チャットメッセージの色]設定ではなく、青いAutoResearch 1の色（|c99CCEFAutoResearch|rまたは|c99CCEFAR|r）を使用します。",
    ["SI_AUTORESEARCH_CHAT_USE_SYSTEM_COLOR"]  = "システムチャットメッセージと同じ色を使用する",
    ["SI_AUTORESEARCH_CHAT_COLOR"]             = "チャットメッセージの色",
}

-- Overwrite English strings
for stringId, value in pairs(strings) do
    AUTORESEARCH_STRINGS[stringId] = value
end