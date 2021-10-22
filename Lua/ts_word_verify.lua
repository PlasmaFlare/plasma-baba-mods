-- Global variables

local global_special_cut_mappings = {
    fallright =      "fall",
    fallleft =       "fall",
    fallup =         "fall",
    falldown =       "fall",
    lockedright =    "locked",
    lockedleft =     "locked",
    lockedup =       "locked",
    lockeddown =     "locked",
    nudgeleft =      "nudge",
    nudgeup =        "nudge",
    nudgeright =     "nudge",
    nudgedown =      "nudge",
}
local global_special_pack_mappings = {
    fallright =      "fall",
    fallleft =       "fall",
    fallup =         "fall",
    falldown =       "fall",
    lockedright =    "locked",
    lockedleft =     "locked",
    lockedup =       "locked",
    lockeddown =     "locked",
    nudgeleft =      "nudge",
    nudgeup =        "nudge",
    nudgeright =     "nudge",
    nudgedown =      "nudge",
}
local global_special_pack_directional_mappings = {
    fall = {
        [0] = "fallright",
        [1] = "fallup",
        [2] = "fallleft",
        [3] = "fall",
    },
    locked = {
        [0] = "lockedright",
        [1] = "lockedup",
        [2] = "lockedleft",
        [3] = "lockeddown",
    },
    nudge = {
        [0] = "nudgeright",
        [1] = "nudgeup",
        [2] = "nudgeleft",
        [3] = "nudgedown",
    },
    beside = {
        [0] = "besideright",
        [2] = "besideleft",
    },
}
local directional_packs_without_normal_variants = {
    fall=true,
    nudge=true,
    locked=true,
    beside=true,
}

-- Local variables
local valid_characters = {}
local special_cut_mappings = {}
local special_pack_mappings = {}
local special_pack_directional_mappings = {}

-- Mod hook inserts
table.insert(mod_hook_functions["level_start"],
    function()
        cut_word_verify_initialize()
        pack_word_verify_initialize()
    end
)

function cut_word_verify_initialize()
    for i, v in pairs(editor_objlist) do
        if v.type == 5 and v.unittype == "text" then
            if string.sub(v.name, 1, 5) == "text_" then
                local character = string.sub(v.name, 6)
                valid_characters[character] = true
            end
        end
    end

    special_cut_mappings = {}
    for k,v in pairs(global_special_cut_mappings) do
        special_cut_mappings[k] = v
    end

    -- Arrow properties
    for arrow_prop,_ in pairs(arrow_properties) do
        special_cut_mappings[arrow_prop.."right"] = arrow_prop
        special_cut_mappings[arrow_prop.."left"] = arrow_prop
        special_cut_mappings[arrow_prop.."up"] = arrow_prop
        special_cut_mappings[arrow_prop.."down"] = arrow_prop
    end
    -- Turning text
    for turning_prop, _ in pairs(turning_word_names) do
        special_cut_mappings["turning_"..turning_prop] = turning_prop
    end
    -- Omni text
    for branching_text, _ in pairs(branching_text_names) do
        special_cut_mappings[br_prefix..branching_text] = branching_text
        special_cut_mappings[pivot_prefix..branching_text] = branching_text
    end
    special_cut_mappings[br_prefix.."and"] = "and"
    special_cut_mappings[pivot_prefix.."and"] = "and"
end

function pack_word_verify_initialize()
    -- Normal pack mappings
    for turning_prop, _ in pairs(turning_word_names) do
        special_pack_mappings["turning"..turning_prop] = "turning_"..turning_prop
    end
    for branching_text, _ in pairs(branching_text_names) do
        special_pack_mappings["omni"..branching_text] = br_prefix..branching_text
        special_pack_mappings["pivot"..branching_text] = pivot_prefix..branching_text
    end

    -- Directional pack mappings
    for k,v in pairs(global_special_pack_directional_mappings) do
        special_pack_directional_mappings[k] = v
    end
    for arrow_prop,_ in pairs(arrow_properties) do
        special_pack_directional_mappings[arrow_prop] = {
            [0] = arrow_prop.."right",
            [1] = arrow_prop.."up",
            [2] = arrow_prop.."left",
            [3] = arrow_prop.."down",
        }
    end
end

--[[
    Given a name of a text that will be cut, return the output text that will be produced. Normally this will be the text name
    itself. But special cases are defined in special_cut_mappings.
 ]]
function get_cut_text(name, dir)
    -- Note: dir is currently not used, but keeping it here just in case I want the cutting to depend on direction

    local t = special_cut_mappings[name]
    if t then return t end

    -- THIS
    if is_name_text_this(name, false) then
        return "this"
    end

    for c in name:gmatch"." do
        if not valid_characters[c] or not unitreference["text_"..c] then
            return nil
        end
    end

    return name
end


--[[
    Given a sequence of letters that will be packed as a single string, return the name of the potential text block the packing might
    produce. Normally this will be the string itself, but special cases are defined in special_pack_mappings and
    special_pack_directional_mappings. Supports special mappings when packed at certain directions.

    Note that the output is not guaranteed to be in the palette.
 ]]
function get_pack_text(name, dir)
    -- Note: dir is currently not used, but keeping it here just in case I want the cutting to depend on direction

    --[[
        Special case priorities:
        1) If there's a normal special mapping for a text name, return that mapping
        2) If there's a directional special mapping:
            - If the normal variant is in the palette, return the normal variant
            - Otherwise return the directional variant
        3) Return the literal text name, regardless of if it is in the palette
     ]]

    if special_pack_mappings[name] then
        return special_pack_mappings[name]
    elseif special_pack_directional_mappings[name] then
        local dir_pack_mapped_text = special_pack_directional_mappings[name][dir]

        -- check that the directional pack mapping is in the palette before returning
        if dir_pack_mapped_text then
            if not directional_packs_without_normal_variants[name] and is_text_in_palette(name) then
                -- If there is a normal variant of the directional variant, Normal variants take precedence over directional variants.
                -- Ex: if "shift" and "shiftup" are in the palette, packing SHIFT upwards will yield "shift"
                return name
            end

            if not is_text_in_palette(dir_pack_mapped_text) then
                dir_pack_mapped_text = nil

                -- This entire loop determines if there is only one directional variant defined in the palette:
                --  - if there is only one defined, return that variant
                --  - otherwise, return the literal name, which resolves to not packing the text
                for testdir = 0,3 do
                    local test_mapped_text = special_pack_directional_mappings[name][testdir]
                    if is_text_in_palette(test_mapped_text) then
                        if dir_pack_mapped_text == nil then
                            dir_pack_mapped_text = test_mapped_text
                        else
                            return name
                        end
                    end
                end
                return dir_pack_mapped_text
            else
                return dir_pack_mapped_text
            end
        end
    end

    return name
end