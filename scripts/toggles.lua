function toggle_itemgrid()
    local suffix = ""
    
    if has("hardmode_on") then
        suffix = suffix.."_hard"
    end
    
    if has("hammer_setting_on") then
        suffix = suffix.."_hammer"
    end
    
    Tracker:AddLayouts("layouts/items/items"..suffix..".json")
end

function toggle_splitmap()
    if has("splitmap_off") then
        Tracker:AddLayouts("layouts/tabs_single.json")
    elseif has("splitmap_on") then
        Tracker:AddLayouts("layouts/tabs_split.json")
    elseif has("splitmap_reverse") then
        Tracker:AddLayouts("layouts/tabs_reverse.json")
    end
end


function toggle_map()
    local suffix = ""
    
    if has("hammer_setting_on") then
        suffix = suffix .. "_hammer"
    end
    
    if has("extrastartingchest_on") then
        suffix = suffix .. "_extra"
    end
    
    Tracker:AddMaps("maps/main"..suffix..".json")
end