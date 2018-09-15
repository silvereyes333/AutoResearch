local strings = {
    ["SI_AUTORESEARCH_BAGS"] = "研究のための機器を探すためのバッグ",
}

-- Overwrite English strings
for stringId, value in pairs(strings) do
    AUTORESEARCH_STRINGS[stringId] = value
end