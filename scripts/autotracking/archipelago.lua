require("scripts/autotracking/item_mapping")
require("scripts/autotracking/location_mapping")
require("scripts/autotracking/option_mapping")
--require("scripts/autotracking/flag_mapping")
--require("scripts/autotracking/map_mapping")

CUR_INDEX = -1
SLOT_DATA = nil
SAVED_HINTS = {}

if Highlight then
    HIGHLIGHT_LEVEL= {
        [0] = Highlight.Unspecified,
        [1] = Highlight.Priority,
        [2] = Highlight.NoPriority,
        [3] = Highlight.Priority,
        [4] = Highlight.Avoid,
        [5] = Highlight.Priority,
        [6] = Highlight.NoPriority
    }
end

HIGHLIGHT_PRIORITY =  {
    [3] = 1,
    [2] = 2,
    [-1] = 3,
    [1] = 4,
    [0] = 5
}

function onClear(slot_data)
    print(dump_table(slot_data))
    CUR_INDEX = -1
    PLAYER_ID = Archipelago.PlayerNumber or -1
    TEAM_NUMBER = Archipelago.TeamNumber or 0
    SLOT_DATA = slot_data
    GAME = Archipelago:GetPlayerGame(PLAYER_ID)
    
    -- we check for correct game, version, and non manual
    if GAME == "APQuest" then
        Tracker:AddLayouts("layouts/tracker.json")
    else
        Tracker:AddLayouts("layouts/errors/error_game.json")
        return
    end
    
    -------------------------------------------------
    -- RESET AREA
    resetLocations()
    resetItems()
    -------------------------------------------------

    for k, v in pairs(slot_data) do
        if SLOT_CODES[k] then
            -- right now this only implements setting Stages and it's dirt simple. It's usually not this simple.
            -- If you name your option codes *exactly* like the slot_data keys, you can even save on code here!
            -- but often apworld devs name keys badly. So we like to make them pretty! Because we need to stare at them. A lot.
            Tracker:FindObjectForCode(SLOT_CODES[k].code).CurrentStage = (SLOT_CODES[k].mapping and SLOT_CODES[k].mapping[v] or v)
        end
    end
    
    if Archipelago.PlayerNumber > -1 then 
        local suffix = TEAM_NUMBER .. "_" .. PLAYER_ID
        -- we only need the below once somebody actually adds data storage entries for us to read.
        --local function makeID(s) return "pokemon_platinum_" .. s .. suffix end
        
        IDs = {
            -- Example:
            -- EVENT      = makeID("tracked_events_"),

            GOAL       = "_read_client_status_" .. suffix,
            HINT       = "_read_hints_" .. suffix,
        }
        
        for _, id in pairs(IDs) do
            Archipelago:SetNotify({id})
            Archipelago:Get({id})
        end
    end
end

function resetLocations()
    for _, location_array in pairs(LOCATION_MAPPING) do
        for _, location in pairs(location_array) do
            if location then
                local location_obj = Tracker:FindObjectForCode(location)
                if location_obj then
                    if location:sub(1, 1) == "@" then
                        location_obj.AvailableChestCount = location_obj.ChestCount
                    else
                        location_obj.Active = false
                    end
                end
            end
        end
    end
end

function resetItems()
    for _, item_array in pairs(ITEM_MAPPING) do
        for _, item_pair in pairs(item_array) do
            item_code = item_pair[1]
            item_type = item_pair[2]
            -- print("on clear", item_code, item_type)
            local item_obj = Tracker:FindObjectForCode(item_code)
            if item_obj then
                if item_obj.Type == "toggle" then
                    item_obj.Active = false
                elseif item_obj.Type == "progressive" then
                    item_obj.CurrentStage = 0
                elseif item_obj.Type == "consumable" then
                    if item_obj.MinCount then
                        item_obj.AcquiredCount = item_obj.MinCount
                    else
                        item_obj.AcquiredCount = 0
                    end
                elseif item_obj.Type == "progressive_toggle" then
                    item_obj.CurrentStage = 0
                    item_obj.Active = false
                end
            end
        end
    end
end

function onItem(index, item_id, item_name, player_number)
    if index <= CUR_INDEX then
        return
    end
    local is_local = player_number == Archipelago.PlayerNumber
    CUR_INDEX = index;
    local item = ITEM_MAPPING[item_id]
    if not item or not item[1] then
        --print(string.format("onItem: could not find item mapping for id %s", item_id))
        return
    end
    for _, item_pair in pairs(item) do
        item_code = item_pair[1]
        item_type = item_pair[2]
        local item_obj = Tracker:FindObjectForCode(item_code)
        if item_obj then
            if item_obj.Type == "toggle" then
                -- print("toggle")
                item_obj.Active = true
            elseif item_obj.Type == "progressive" then
                -- print("progressive")
                if item_obj.Active == true then
                    item_obj.CurrentStage = item_obj.CurrentStage + 1
                else
                    item_obj.Active = true
                end
            elseif item_obj.Type == "consumable" then
                -- print("consumable")
                item_obj.AcquiredCount = item_obj.AcquiredCount + item_obj.Increment * (tonumber(item_pair[3]) or 1)
            elseif item_obj.Type == "progressive_toggle" then
                -- print("progressive_toggle")
                if item_obj.Active then
                    item_obj.CurrentStage = item_obj.CurrentStage + 1
                else
                    item_obj.Active = true
                end
            end
        else
            print(string.format("onItem: could not find object for code %s", item_code[1]))
        end
    end
end

-- This is a debug to be used so you can check if there's locations that exist in either
-- the pack or the game (fullsanity seed) that don't in the tracker
------ tables to track usage
----local missing_mappings = {}   -- location_ids passed to function but not in LOCATION_MAPPING
----local called_mappings  = {}   -- mappings that were actually used
----
----function onLocation(location_id, location_name)
----    local location_array = LOCATION_MAPPING[location_id]
----
----    -- mark this id as called
----    called_mappings[location_id] = true
----
----    -- no mapping exists
----    if not location_array then
----        missing_mappings[location_id] = true
----        return
----    end
----
----    for _, location in pairs(location_array) do
----        -- (code)
----    end
----end
----
------ call this when processing is finished
----function printLocationReport()
----    print("=== Missing LOCATION_MAPPING ===")
----    for id, _ in pairs(missing_mappings) do
----        print(id)
----    end
----
----    print("=== LOCATION_MAPPING never called ===")
----    for id, _ in pairs(LOCATION_MAPPING) do
----        if not called_mappings[id] then
----            print(id)
----        end
----    end
----end

---- we use this for hint tracking
CLEARED_LOCATIONS = {}
--called when a location gets cleared
function onLocation(location_id, location_name)
    local location_array = LOCATION_MAPPING[location_id]
    if not location_array or not location_array[1] then
        print(string.format("onLocation: could not find location mapping for id %s", location_id))
        return
    end

    for _, location in pairs(location_array) do
        local location_obj = Tracker:FindObjectForCode(location)
        -- print(location, location_obj)
        if location_obj then
            if location:sub(1, 1) == "@" then
                location_obj.AvailableChestCount = location_obj.AvailableChestCount - 1
                local current_total = CLEARED_LOCATIONS[location_id] or 0
                CLEARED_LOCATIONS[location_id] = current_total + 1
            else
                location_obj.Active = true
            end
        else
            print(string.format("onLocation: could not find location_object for code %s", location))
        end
    end
end

function onNotify(key, value, old_value)
    if value ~= nil and value ~= 0 and old_value ~= value then
        if key == IDs.HINT then
            SAVED_HINTS = value
            updateHints()
        elseif key == IDs.GOAL then
            updateGoal(value)
        end
    end
end

function updateGoal(value)
    local goal = Tracker:FindObjectForCode("victory")
    -- this means that if value equals 30 (30 means goaled), it is set to true, otherwise to false!)
    goal.Active = (value == 30)
end

function toggleHints()
    if has("hint_tracking_off") then
        resetHints()
    elseif has("hint_tracking_on") then
        resetHints()
        updateHints()
    elseif has("hint_tracking_on_plus") then
        updateHints()
    end
end

function resetHints()
    CLEARED_HINTS = {}
    for _, hint in ipairs(SAVED_HINTS) do
        if hint.finding_player == PLAYER_ID then
            local mapped = LOCATION_MAPPING[hint.location]
            local locations = (type(mapped) == "table") and mapped or { mapped }
    
            for _, location in ipairs(locations) do
                -- Only sections (items don't support Highlight)
                if location:sub(1, 1) == "@" then
                    local obj = Tracker:FindObjectForCode(location)
                    local final_value = obj.ChestCount
                    local cleared = CLEARED_LOCATIONS[location] or 0
                    final_value = final_value - cleared
                    obj.AvailableChestCount = final_value
                    obj.Highlight = 0
                end
            end
        end
    end
end


-- don't copy this quite yet, it's broken.
-- i need to fix in my other trackers first x_x
CLEARED_HINTS = {}
function updateHints()
    if not Highlight then return end
    if has("hint_tracking_off") then return end

    CLEARED_HINTS = {}

    local tracking_plus = has("hint_tracking_on_plus")
    for _, hint in ipairs(SAVED_HINTS) do
        if hint.finding_player == PLAYER_ID then
            local mapped = LOCATION_MAPPING[hint.location]
            local incoming_val = HIGHLIGHT_LEVEL[hint.item_flags]

            local locations = (type(mapped) == "table") and mapped or { mapped }

            if hint.found == false then
                for _, location in ipairs(locations) do
                    if location:sub(1, 1) == "@" then
                        local obj = Tracker:FindObjectForCode(location)
    
                        if tracking_plus then
                            if incoming_val == 3 then
                                obj.Highlight = incoming_val
                            else
                                local current_total = CLEARED_HINTS[location] or 0
                                CLEARED_HINTS[location] = current_total + 1
                            end
                        else
                            local current_val = obj.Highlight
                            if current_val == nil or HIGHLIGHT_PRIORITY[incoming_val] < HIGHLIGHT_PRIORITY[current_val] then
                                obj.Highlight = incoming_val
                            end
                        end
                    end
                end
            end

            ::continue_hint::
        end
    end

    if tracking_plus then
        for location, count in pairs(CLEARED_HINTS) do
            local obj = Tracker:FindObjectForCode(location)
            local cleared = CLEARED_LOCATIONS[location] or 0
            obj.AvailableChestCount = obj.ChestCount - count - cleared
            if obj.AvailableChestCount == 0 then
                obj.Highlight = 0
            end
        end
    end
end

-- yeah all this could be crazy stuff like map IDs and where you are on the map
-- would be neat if this 16x16 grid game had that.
-- we could even display a diamond at the exact player position!
-- surely that won't cause 10.000 bounces an hour, right? :)
function onMap(mapBounce)
    print("Bounced")
    if has("automap_on") and mapBounce.data ~= nil then
        local mapID = mapBounce.data.mapNumber
        
        if MAP_XZYSPLIT_MAPPING[mapID] ~= nil then
            local matrixX = mapBounce.data.matrixX
            local matrixZ = mapBounce.data.matrixZ
            local playerY = mapBounce.data.playerY
            local tabs = MAP_XZYSPLIT_MAPPING[mapID] and MAP_XZYSPLIT_MAPPING[mapID][matrixX] and MAP_XZYSPLIT_MAPPING[mapID][matrixX][matrixZ] and MAP_XZYSPLIT_MAPPING[mapID][matrixX][matrixZ][playerY]
            if tabs then
                for i, tab in ipairs(tabs) do
                    Tracker:UiHint("ActivateTab", tab)
                end
            end
        elseif MAP_SPLIT_MAPPING[mapID] ~= nil then
            local matrixX = mapBounce.data.matrixX
            local matrixZ = mapBounce.data.matrixZ
            local tabs = MAP_SPLIT_MAPPING[mapID] and MAP_SPLIT_MAPPING[mapID][matrixX] and MAP_SPLIT_MAPPING[mapID][matrixX][matrixZ]
            if tabs then
                for i, tab in ipairs(tabs) do
                    Tracker:UiHint("ActivateTab", tab)
                end
            end
        elseif MAP_MAPPING[mapID] ~= nil then    
            local tabs = MAP_MAPPING[mapID]
            if tabs then
                for _, tab in ipairs(tabs) do
                    Tracker:UiHint("ActivateTab", tab)
                end
            end
        else
            print("No Mapping found for:")
            print(dump_table(mapBounce))
        end
    end
end
