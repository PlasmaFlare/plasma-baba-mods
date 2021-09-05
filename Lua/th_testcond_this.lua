function get_this_parms_in_conds(conds, ids)
    local id_index = 4 -- start at 4 since 1-3 ids is target, verb, property
    local conds_with_this_as_param = {} -- cond object -> {index -> unitid}

    if #conds > 0 then
        -- skip through all extraids (aka ands and nots and filler texts)
        while id_index <= #ids do
            local unit = mmf.newObject(ids[id_index][1])
            local type = unit.values[TYPE]

            if type ~= 4 and type ~= 6 and type ~= 11 then
                break
            end
            id_index = id_index + 1
        end

        for _, cond in ipairs(conds) do
            local condtype = cond[1]
            local params = cond[2]
            
            if condtype == "this" or condtype == "not this" or condtype == "stable" then
                -- skip params if the condtype is "this", since the params are actually unitids
            else
                id_index = id_index + 1 -- consume the condition
                for i, param in ipairs(params) do
                    if string.sub(param, 1, 4) == "not " then
                        param = string.sub(param, 5)
                    end
                    if is_name_text_this(param) or is_name_text_this(param, true) then
                        local this_unitid = ids[id_index][1]
                        if not conds_with_this_as_param[cond] then
                            conds_with_this_as_param[cond] = {}
                        end
                        conds_with_this_as_param[cond][i] = this_unitid
                    end
                    id_index = id_index + 1
                end
            end
        end    
    end

    return conds_with_this_as_param
end

function parse_this_param_and_get_raycast_units(this_param)
    local this_param_name = ""
    if string.sub(this_param, 1, 4) == "not " then 
        this_param_name = "not "
        this_param = string.sub(this_param, 5, #this_param)
    end
    if not is_name_text_this(string.sub(this_param, 1, 4)) then 
        return false, nil, nil, 0, nil
    end
    local end_index = string.find(this_param, " ", 5)
    if not end_index then
        end_index = #this_param
    end
    local this_param_name = this_param_name..string.sub(this_param, 1, end_index-1) 
    local param_id = string.sub(this_param, end_index + 1)

    local this_unitid = parse_this_unit_from_param_id(param_id)
    if not this_unitid then
        return false, nil, nil, 0, nil
    end
    
    local raycast_units = get_raycast_units(this_unitid, true)            
    local tileid = get_raycast_tileid(this_unitid)
    local out = {}
    local count = 0
    for _, ray_unitid in ipairs(raycast_units) do
        out[ray_unitid] = true
        count = count + 1
    end

    return this_param_name, out, tileid, count, this_unitid
end


--@TODO: might delete or refactor this later when we make THIS mod use values[ID] to represent the specific THIS text instead of unitids
function make_this_param(param_name, param_id)
    return param_name.." "..param_id
end

--[[ 
    Return a string representing the THIS text that can be used in parameters for rule conditions. Throws an error if the provided unitid isn't a THIS text
 ]]
function convert_this_unit_to_param_id(this_unitid)
    local this_unit = mmf.newObject(this_unitid)
    if not this_unit or not is_name_text_this(this_unit.strings[NAME]) then
        error("Provided unit id that points to invalid THIS text. Stack trace: "..debug.traceback())
    end
    return tostring(this_unit.values[ID])
end

--[[ 
    Return the unitid of a THIS text from the output of convert_this_unit_to_param_id(). Returns nil if this_param_id isn't a number. 
    If this_param_id is a stable_this_id, it returns the stable_this_id directly.
 ]]
function parse_this_unit_from_param_id(this_param_id)
    local this_unitid = tonumber(this_param_id)
    if not this_unitid then
        return nil
    end

    if not is_this_unit_in_stablerule(this_unitid) then
        this_unitid = MF_getfixed(this_unitid)
    end

    return this_unitid
end