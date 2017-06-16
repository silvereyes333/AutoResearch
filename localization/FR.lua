local strings = {
    ["SI_AUTORESEARCH_NOTICE"] = "Vous pouvez maintenant personnaliser l'ordre des traits à rechercher. Allez en Paramètres > Extensions > Auto Research pour cela.",
    ["SI_AUTORESEARCH_BAGS"]   = "Sacs pour rechercher de l'équipement à la recherche",
}

-- Overwrite English strings
for stringId, value in pairs(strings) do
    AUTORESEARCH_STRINGS[stringId] = value
end