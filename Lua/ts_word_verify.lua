global_special_cut_mappings = {
    fallright =      "fall",
    fallleft =       "fall",
    fallup =         "fall",
    falldown =       "fall",
    lockedright =    "locked",
    lockedleft =     "locked",
    lockedup =       "locked",
    lockeddown =     "locked",
}

local valid_characters = {}

local special_cut_mappings = {}

function cut_work_verify_initialize()
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

    for arrow_prop,_ in pairs(arrow_properties) do
        special_cut_mappings[arrow_prop.."right"] = arrow_prop
        special_cut_mappings[arrow_prop.."left"] = arrow_prop
        special_cut_mappings[arrow_prop.."up"] = arrow_prop
        special_cut_mappings[arrow_prop.."down"] = arrow_prop
    end
end

table.insert(mod_hook_functions["level_start"], 
    function()
        cut_work_verify_initialize()
    end
)

function get_cut_text(name)
    local t = ""
    t = special_cut_mappings[name]
    if t then return t end
    
    t = parse_turning_text(name)
    if t then return t end
    
    if name_is_branching_text(name) or name_is_branching_and(name) then
        return parse_branching_text(name)
    end
    
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