-- Archipelago Handlers
Archipelago:AddClearHandler("clear handler", onClear)
Archipelago:AddItemHandler("item handler", onItem)
Archipelago:AddLocationHandler("location handler", onLocation)
Archipelago:AddSetReplyHandler("notify handler", onNotify)
Archipelago:AddRetrievedHandler("notify launch handler", onNotify)
Archipelago:AddBouncedHandler("map handler", onMap) -- we will never get a map bounce :( Useful for games with lots of submaps

-- Watches for Setting Toggles
ScriptHost:AddWatchForCode("hardmode", "hardmode", toggle_itemgrid)
ScriptHost:AddWatchForCode("hammer_setting", "hammer_setting", toggle_itemgrid)
ScriptHost:AddWatchForCode("hammer_setting2", "hammer_setting", toggle_map)
ScriptHost:AddWatchForCode("extrastartingchest", "extrastartingchest", toggle_itemgrid)
ScriptHost:AddWatchForCode("extrastartingchest2", "extrastartingchest", toggle_map)

-- Watches for Tool Toggle
ScriptHost:AddWatchForCode("hint_tracking", "hint_tracking", toggle_hints)
ScriptHost:AddWatchForCode("splitmap", "splitmap", toggle_splitmap)
