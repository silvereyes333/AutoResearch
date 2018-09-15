local strings = {
    ["SI_AUTORESEARCH_BAGS"] = "Sacs pour rechercher de l'équipement à la recherche",
}

-- Overwrite English strings
for stringId, value in pairs(strings) do
    AUTORESEARCH_STRINGS[stringId] = value
end