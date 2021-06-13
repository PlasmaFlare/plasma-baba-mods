-- Global variables

global_special_cut_mappings = {
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
global_special_pack_mappings = {
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
global_dir_to_name = {
    [0] = "right",
    [1] = "up",
    [2] = "left",
    [3] = "down"
}

-- Local variables
local valid_characters = {}
local special_cut_mappings = {}
local special_pack_mappings = {}

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
    for turning_prop, _ in pairs(turning_word_names) do
        special_pack_mappings["turning"..turning_prop] = "turning_"..turning_prop
    end
    for branching_text, _ in pairs(branching_text_names) do
        special_pack_mappings["omni"..branching_text] = br_prefix..branching_text
        special_pack_mappings["pivot"..branching_text] = pivot_prefix..branching_text
    end
end

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

function get_pack_text(name, dir)
    -- Note: dir is currently not used, but keeping it here just in case I want the cutting to depend on direction
    local t = special_pack_mappings[name]
    if t then return t end

    return name
end