ITEM_MAPPING = {
	[1] = {{"key", "toggle"}},
	[2] = {{"sword", "toggle"}},
	[3] = {{"shield", "toggle"}},
	[4] = {{"hammer", "toggle"}},
	[5] = {{"healthupgrade", "consumable"}}, -- it's a consumable because we get multiple identical pieces of this. If it was a Pokémon that got upgraded from "Regional Dex" to "National Dex", we'd use a progressive here.
    
    -- These are NOT progression items. We could just remove these. You can also comment stuff out in .lua files by putting two -- in the beginning of a line.
	--[6] = {{"confetticannon", "toggle"}},
	--[7] = {{"mathtrap", "toggle"}},
}