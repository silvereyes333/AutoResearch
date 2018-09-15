local strings = {
    ["SI_AUTORESEARCH_BAGS"] = "Сумки для поиска оборудования для исследования",
}

-- Overwrite English strings
for stringId, value in pairs(strings) do
    AUTORESEARCH_STRINGS[stringId] = value
end