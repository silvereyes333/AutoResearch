local strings = {
    ["SI_AUTORESEARCH_NOTICE"] = "Du kannst die Reihenfolge auswählen, in der Eigenschaften erforscht werden sollen. Öffne Einstellungen > Erweiterungen > Auto Research zum Konfigurieren",
    ["SI_AUTORESEARCH_BAGS"]   = "Taschen für die Suche nach Ausrüstung für die Forschung",
}

-- Overwrite English strings
for stringId, value in pairs(strings) do
    AUTORESEARCH_STRINGS[stringId] = value
end