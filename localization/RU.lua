local strings = {
    ["SI_AUTORESEARCH_NOTICE"] = "На панели настроек вы можете настроить порядок, в котором исследуются признаки.",
    ["SI_AUTORESEARCH_BAGS"]   = "Сумки для поиска оборудования для исследования",
}

-- Overwrite English strings
for stringId, value in pairs(strings) do
    AUTORESEARCH_STRINGS[stringId] = value
end