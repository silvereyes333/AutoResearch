local strings = {
    ["SI_AUTORESEARCH_BAGS"] = "Taschen für die Suche nach Ausrüstung für die Forschung",
}

-- Overwrite English strings
for stringId, value in pairs(strings) do
    AUTORESEARCH_STRINGS[stringId] = value
end