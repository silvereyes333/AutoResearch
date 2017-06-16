local strings = {
    ["SI_AUTORESEARCH_NOTICE"] = "つの設定パネルで、特性を調査する順序をカスタマイズできます。",
    ["SI_AUTORESEARCH_BAGS"]   = "研究のための機器を探すためのバッグ",
}

-- Overwrite English strings
for stringId, value in pairs(strings) do
    AUTORESEARCH_STRINGS[stringId] = value
end