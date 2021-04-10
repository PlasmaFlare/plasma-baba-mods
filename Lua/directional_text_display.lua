local directional_text_names = {}
local directional_text_prefixes = {}

function register_directional_text(name)
    directional_text_names[name] = true
end
function register_directional_text_prefix(name)
    table.insert(directional_text_prefixes, name)
end

function set_tt_display_direction(unit, dir)
    dir = dir or nil
    local is_tt = directional_text_names[unit.strings[NAME]]
    if not is_tt then
        for i, prefix in pairs(directional_text_prefixes) do
            if string.sub(unit.strings[NAME], 1, #prefix) == prefix then
                is_tt = true
                break
            end
        end
    end
    if is_tt then
        if dir == nil then
            unit.direction = (unit.values[DIR] * 8) % 32
        else
            unit.direction = (dir * 8) % 32
        end
    end
end

table.insert( mod_hook_functions["level_start"],
    function()
        for i,unitid in ipairs(codeunits) do
            local unit = mmf.newObject(unitid)
            set_tt_display_direction(unit)
        end
    end
)

table.insert( mod_hook_functions["turn_end"], 
    function()
        for i,unitid in ipairs(codeunits) do
            local unit = mmf.newObject(unitid)
            set_tt_display_direction(unit)
        end
    end
)
