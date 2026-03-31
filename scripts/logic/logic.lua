-- The distinction between utils.lua and logic.lua is arbitrary.
-- I like to distinguish it by saying "utils get used often by many things, logic only for location stuff"

-- A location's access rules can be gated by five things:
  -- A) @-Location Rules which set location based on their access level
  -- B) itemcodes which can either return TRUE or FALSE if they're just normal item codes
  -- C) $functions which can either return TRUE or FALSE
  -- D) ^$functions which can return access levels, like @-Locations
  -- E) Lua Items. We don't fuck with those. They're complicated. It's basically actual coding. Scary.
  
-- "What are access levels"?
-- See the top of utils.lua. We essentially just deal in four: None, Inspect, SequenceBreak, Normal.
-- None is red; Inspect is Blue; SequenceBreak is Yellow; Normal is Green.
    -- Red means "you can't do this"
    -- Blue has different meanings in different packs and like another comment said already, I'd love to poll this.
       -- Generally it means "You can check the item that is here and see what it is but not collect it"
    -- Yellow means "out of logic". You can get it but it requires tricks or is just not in logic because of multiple key usage so the generator wants 4 keys instead of 2 because you could waste 2.
    -- Green means you can get it.
    
-- Always watch out that $ returns true or false and ^$ returns AccessibilityLevel.X, otherwise it will
-- mess up!

function can_destroy_bush()
    --    return has("sword")
    -- has() is a function in utils.lua. This just returns a TRUE or FALSE if you have it
    -- However this is WRONG. Because we call can_destroy_bush with ^$ so it expects a level instead of TRUE/FALSE.
    
    -- We can either do this: 
    --    if has("sword") then
    --       return AccessibilityLevel.Normal
    --   end
    
    -- or this:
    --    if not has("sword") then return AccessibilityLevel.None end
    --    return AccessibilityLevel.Normal
    -- which is called an "early guard" and useful if you have a ton of conditions afterwards but it will always be one specific outcome if one thing is true or false
    
    -- or wrap it with the conversion that Stripes' Pack Builder provided:
    -- return bool_to_accesslvl[has("sword")]
    
    -- or use the function I made to specifically return levels for otherwise true/false statements + an extra layer if "2 makes it possible (yellow) but 3 makes it logical (green)"
    return has_level("sword")
    
    -- now the reason we made this an AccessibilityLevel-Function is "What if NewSoupVi adds a mode where if you press Enter on the Bush 1000 times, it breaks but that's not in logic?"
    -- Then we could do:
    --    if has("sword") then
    --      return AccessibilityLevel.Normal
    --    else
    --      return AccessibilityLevel.SequenceBreak
    --    end
    
    -- If there is further an option to *prevent* that OOL behavior we could go further: 
    --    if has("sword") then
    --      return AccessibilityLevel.Normal
    --    elseif has("setting_ool_prevention_true")
    --      return AccessibilityLevel.None
    --    else
    --      return AccessibilityLevel.Normal
    --    end
    
    -- We can also do fancy math stuff because AccessibilityLevels are just an alias for numbers! 6 is green, 5 is yellow, 0 is gray, don't ask me what blue is or where 1-4 are.
    -- return math.max(has_level("sword"), AccessibilityLevel.SequenceBreak)
    -- this returns whatever is higher: left side is 6 if you have a sword, 0 if not, right side always 5.
end

function hammersetting()
    return has("hammer") or has("hammer_setting_off")
    -- This covers all of our bases. We don't need to check if hammer setting is on & hammer is gotten because hammer can't be gotten when it's off
end

function littleguy()

end

function bigguy()
    -- early guard because if you don't have these, the setting doesn't matter
    if not has("sword") then return AccessibilityLevel.None end
    
    -- So, if you don't have hard mode the logical way to goal is to have Shield. But you can also goal with 2 Health Upgrades and we show this as OOL
    -- If you have Hard Mode, it's Shield + 2 health upgrade OR 5 Health Upgrades.
    -- an "else" here is less "expensive" computing wise than a "elseif has("hardmode_on")"
    
    if has("hardmode_off") then
        if has("shield") then
            return AccessibilityLevel.Normal
        elseif has("healthupgrade", 2) then
            return AccessibilityLevel.SequenceBreak
        end
    else
        if has("shield") and has("healthupgrade", 2) then
            return AccessibilityLevel.Normal
        elseif has("healthupgrade", 5) then
            return AccessibilityLevel.SequenceBreak
        end
    end
    return AccessibilityLevel.None
end