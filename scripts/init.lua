local variant = Tracker.ActiveVariantUID

-- Items
Tracker:AddItems("items/items.json")
Tracker:AddItems("items/events.json")
Tracker:AddItems("items/settings.json")
Tracker:AddItems("items/tools.json")

-- Logic
ScriptHost:LoadScript("scripts/logic/utils.lua")
ScriptHost:LoadScript("scripts/logic/logic.lua")

-- Maps
Tracker:AddMaps("maps/maps.json")
Tracker:AddMaps("maps/main.json") -- this map image will change depending on setting. We initially load either the YAML-default.

-- Locations
Tracker:AddLocations("locations/access.json") -- all our location-based access logic goes in here
Tracker:AddLocations("locations/overworld.json") -- the overworld map goes in here
Tracker:AddLocations("locations/submaps.json") -- this entirely contains refs to the overworld map for submaps.

-- Layout
Tracker:AddLayouts("layouts/settings_popup.json")
Tracker:AddLayouts("layouts/tools.json")
Tracker:AddLayouts("layouts/items/items.json")
Tracker:AddLayouts("layouts/tabs_single.json") -- we initially load the simple one. Watches & Toggle can change it by hotswapping it.
Tracker:AddLayouts("layouts/tracker.json")
Tracker:AddLayouts("layouts/broadcast.json") -- who even uses this.

-- AutoTracking for Poptracker
ScriptHost:LoadScript("scripts/autotracking/archipelago.lua")
ScriptHost:LoadScript("scripts/toggles.lua") -- to be clean, we put all our toggles here that Watches activate
ScriptHost:LoadScript("scripts/watches.lua") -- to be clean, we put all our WatchForCodes here