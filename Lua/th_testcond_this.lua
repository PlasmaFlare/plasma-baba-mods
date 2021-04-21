function get_this_parms_in_conds(conds, ids)
    local id_index = 4 -- start at 4 since 1-3 ids is target, verb, property
    local conds_with_this_as_param = {} -- cond object -> {index -> unitid}

    if #conds > 0 then
        -- skip through all extraids (aka ands and nots)
        while id_index <= #ids do
            local unit = mmf.newObject(ids[id_index][1])
            local type = unit.values[TYPE]

            if type ~= 4 and type ~= 6 then
                break
            end
            id_index = id_index + 1
        end

        for _, cond in ipairs(conds) do
            local condtype = cond[1]
            local params = cond[2]
            
            if condtype == "this" or condtype == "not this" then
                -- skip params if the condtype is "this", since the params are actually unitids
            else
                id_index = id_index + 1 -- consume the condition
                for i, param in ipairs(params) do
                    if string.sub(param, 1, 4) == "not " then
                        param = string.sub(param, 5)
                    end
                    if is_name_text_this(param) or param == "not this" then
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
    if not is_name_text_this(string.sub(this_param, 1, 4)) then 
        return false, nil, nil, 0
    else
        local end_index = string.find(this_param, " ", 5)
        if not end_index then
            end_index = #this_param
        end
        local this_param_name = string.sub(this_param, 1, end_index) 
        local param_id = string.sub(this_param, end_index + 1)
        local this_unitid = get_this_unit_from_param_id(param_id)
        if not this_unitid then
            return false, nil, nil, 0
        end

        local out = {}
        local count = 0
        for _, ray_unitid in ipairs(get_raycast_units(this_unitid, true)) do
            out[ray_unitid] = true
            count = count +1
        end
        return this_param_name, out, this_mod_globals.text_to_raycast_pos[this_unitid], count
    end
end

function get_this_unit_from_param_id(param_id)
    return this_mod_globals.this_param_to_unitid[param_id]
end 

function is_this_param_id_registered(unitid)
    return this_mod_globals.registered_this_unitid_as_params[unitid] ~= nil
end

function register_this_param_id(unitid)
    local param_id = tostring(unitid)
    this_mod_globals.this_param_to_unitid[param_id] = unitid
    this_mod_globals.registered_this_unitid_as_params[unitid] = true
    return param_id 
end