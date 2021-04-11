register_directional_text_prefix("this")

this_mod_globals = {}

function reset_this_mod_globals()
    this_mod_globals = {
        text_to_cursor = {}, -- mapping from this text unitid to cursor unitid
        text_to_raycast_units = {}, -- mapping from this text unitid to all units that were hit by a raycast
        blocked_tiles = {}, -- all positions where "X is block" is active
        undoed_after_called = false, -- flag for providing a specific hook of when we call code() after an undo
        on_level_start = false,
        deferred_rules_with_this = {["this"] = {}, ["not this"] = {}, ["this block"] = {}, ["not this block"]}, --     
    
        -- These two globals assist in making regular infix conditions with "this" work.
        -- Infix conditions have a list of parameters that determine what objects to compare the testing object
        -- to (Eg "Baba on keke is you" has the param "keke" for condition type "on").
        -- The game doesn't respect the table containing this list of parameters and transfers each
        -- parameter between different tables at will. So we have to imbed some key into the parameter itself.
        -- This key we call it a "parameter id". Currently it is calculated as tostring(unitid). Since
        -- unitids in number form are floats and tonumber(tostring(unitid)) ~= unitid, we have to use a
        -- seperate table to get a mapping from param ids to unitids
        this_param_to_unitid = {}, -- mapping of this text unitids to a "param id"
        registered_this_unitid_as_params = {}, -- record of which text unitids have param ids. This is to ensure that we don't register a unitid twice
    }
end   
reset_this_mod_globals()

table.insert(mod_hook_functions["level_start"], 
    function()
        print("level start")
        -- reset_this_mod()
        for i,unitid in ipairs(codeunits) do
            local unit = mmf.newObject(unitid)
            if is_name_text_this(unit.strings[NAME]) then
                this_mod_globals.text_to_cursor[unitid] = make_cursor(unit)
            end
        end
        this_mod_globals.on_level_start = true
        -- update_raycast_units(true)
        update_all_cursors()
    end
)

table.insert( mod_hook_functions["level_restart"],
    function()
        -- reset_this_mod()
    end
)
table.insert( mod_hook_functions["level_end"],
    function()
        print("level end")
        -- reset_this_mod()
    end
)
table.insert( mod_hook_functions["undoed_after"],
    function()
        print("undoed after after")
        for i,unitid in ipairs(codeunits) do
            local unit = mmf.newObject(unitid)
            set_tt_display_direction(unit)
        end
        this_mod_globals.blocked_tiles = {}
        -- update_raycast_units(true)
        -- update_all_cursors()
        this_mod_globals.undoed_after_called = true
    end
)

table.insert(mod_hook_functions["command_given"],
    function()
        -- this_mod_globals.blocked_tiles = {}
    end
)

table.insert(mod_hook_functions["rule_update"],
    function()
        this_mod_globals.this_param_to_unitid = {}
        this_mod_globals.registered_this_unitid_as_params = {}
        this_mod_globals.deferred_rules_with_this = {["this"] = {}, ["not this"] = {}}
    end
)
table.insert(mod_hook_functions["rule_update_after"],
    function()
        print("rule update after")
        -- update_raycast_units(true)
        if this_mod_globals.on_level_start then
            this_mod_globals.on_level_start = false
            print("level start rule update")
        end
        if this_mod_globals.undoed_after_called then
            this_mod_globals.undoed_after_called = false
            update_all_cursors()
        end
    end
)

table.insert(mod_hook_functions["turn_end"],
    function()
        print("turn end")
        -- update_raycast_units(true)
        update_all_cursors()
    end
)

function is_name_text_this(name, check_not_)
    local check_not = check_not_ or false
    if check_not then
        return string.sub(name, 1, 4) == "not " and string.sub(name, 5, 8) == "this"
    else
        return string.sub(name, 1, 4) == "this"
    end
end

function is_unit_valid_this_property(unitid, verb)
    local unit = mmf.newObject(unitid)
    if unit.strings[UNITTYPE] == "object" then
        return true
    end

    if unit.strings[UNITTYPE] == "text" then
        if verb == "is" then
            if unit.values[TYPE] == 2 then
                return true
            elseif unit.values[TYPE] == 0 and not is_name_text_this(unit.strings[NAME]) then
                return true
            end
        else
            if unit.values[TYPE] == 0 and not is_name_text_this(unit.strings[NAME]) then
                return true
            end
        end
    end

    return false
end


function reset_this_mod()
    print("reset this mod")
    local count = 0
    for _, cursor_unitid in pairs(this_mod_globals.text_to_cursor) do
        delunit(cursor_unitid)
        MF_remove(cursor_unitid)
        count = count + 1
    end
    reset_this_mod_globals()
end

function make_cursor(unit)
    local x = unit.values[XPOS]
    local y = unit.values[YPOS]
    local dir = unit.values[DIR]

    local unitid2 = MF_create("customsprite")
    local unit2 = mmf.newObject(unitid2)
    
    unit2.values[ONLINE] = 1

    unit2.layer = 1
    unit2.direction = 28
    MF_loadsprite(unitid2,"this_cursor_0",28,true)
    update_this_cursor(unit, unit2)

    return unitid2
end

function update_all_cursors(undo)
    undo = undo or false
    for i,unitid in ipairs(codeunits) do
        local unit = mmf.newObject(unitid)
        if this_mod_globals.text_to_cursor[unitid] then
            local wordunit = mmf.newObject(unitid)
            local cursorunit = mmf.newObject(this_mod_globals.text_to_cursor[unitid])

            update_this_cursor(wordunit, cursorunit)
        elseif is_name_text_this(unit.strings[NAME]) then
            local cursorunit = make_cursor(unit)
            this_mod_globals.text_to_cursor[unitid] = cursorunit
            -- update_this_cursor(unit, cursorunit)
        end
    end
end

function update_this_cursor(wordunit, cursorunit)
    local x = wordunit.values[XPOS]
    local y = wordunit.values[YPOS]
    local dir = wordunit.values[DIR]
    undo = undo or false

    local ray_pos = this_raycast(x, y, dir)
    if ray_pos then
        cursorunit.values[XPOS] = ray_pos[1] * f_tilesize+ Xoffset + (f_tilesize / 2)
        cursorunit.values[YPOS] = ray_pos[2] * f_tilesize + Yoffset + (f_tilesize / 2)
        
        local c1 = nil
        local c2 = nil
        c1,c2 = wordunit.colour[1], wordunit.colour[2]
    
        local blocked = false
        local tileid = ray_pos[1] + ray_pos[2] * roomsizex
    
        local c1 = 0
        local c2 = 0
        if this_mod_globals.blocked_tiles[tileid] then
            -- display different sprite if the tile is blocked
            cursorunit.direction = 29
            MF_loadsprite(cursorunit.fixed,"this_cursor_blocked_0",29,true)
            c1,c2 = getuicolour("blocked")
            
        else
            cursorunit.direction = 28
            MF_loadsprite(cursorunit.fixed,"this_cursor_0",28,true)
            if wordunit.active then
                c1,c2 = getcolour(wordunit.fixed, "active")
            else
                c1,c2 = getcolour(wordunit.fixed)
            end
        end
    
        MF_setcolour(cursorunit.fixed,c1,c2)
    else
        -- Just to hide it
        cursorunit.values[XPOS] = -20
        cursorunit.values[YPOS] = -20
    end
end

function update_raycast_units(checkblocked_)
    local checkblocked = checkblocked_ or false
    local new_raycast_units = {}
    this_mod_globals.blocked_tiles = {}
    for i,unitid in ipairs(codeunits) do
        local unit = mmf.newObject(unitid)
        if is_name_text_this(unit.strings[NAME]) then
            local x = unit.values[XPOS]
            local y = unit.values[YPOS]
            local dir = unit.values[DIR]
            local ray_unitids = {}

            local blocked = false
            local ray_pos,is_emptyblock = this_raycast(x, y, dir)
            if ray_pos then
                local tileid = ray_pos[1] + ray_pos[2] * roomsizex

                if is_emptyblock then
                    blocked = true
                else
                    for _, ray_unitid in ipairs(unitmap[tileid]) do
                        local ray_unit = mmf.newObject(ray_unitid)
                        local ray_unit_name = ray_unit.strings[NAME] 
                        
                        if ray_unit.strings[UNITTYPE] == "text" then
                            ray_unit_name = "text"
                        end

                        if checkblocked and hasfeature(ray_unit_name, "is", "block",ray_unitid) then
                            blocked = true
                        end
                        table.insert(ray_unitids, ray_unitid)
                    end
                end
            end
            if blocked then
                -- new_raycast_units[unitid] = nil

                local tileid = ray_pos[1] + ray_pos[2] * roomsizex
                this_mod_globals.blocked_tiles[tileid] = true
                updatecode = 1
            else
                if this_mod_globals.blocked_tiles[tileid] then
                    this_mod_globals.blocked_tiles[tileid] = nil
                end
                if updatecode == 0 then
                    -- set updatecode to 1 if any of the raycast units changed
                    local prev_raycast_unitids = this_mod_globals.text_to_raycast_units[unitid] or {}

                    if #ray_unitids ~= #prev_raycast_unitids then
                        updatecode = 1
                    else
                        for _, ray_unitid in ipairs(ray_unitids) do
                            local found_unitid = false
                            for _, prev_unitid in ipairs(prev_raycast_unitids) do
                                if prev_unitid == ray_unitid then
                                    found_unitid = true
                                    break
                                end
                            end

                            if not found_unitid then
                                updatecode = 1
                                break
                            end
                        end
                    end
                end

                if #ray_unitids == 0 then
                    new_raycast_units[unitid] = nil
                else
                    new_raycast_units[unitid] = ray_unitids
                end
            end
        end
    end
    this_mod_globals.text_to_raycast_units = new_raycast_units
end

function get_raycast_units(this_text_unitid, checkblocked)
    local raycast_units = this_mod_globals.text_to_raycast_units[this_text_unitid]
    if raycast_units ~= nil and #raycast_units > 0 then
        if checkblocked then
            local unit = mmf.newObject(raycast_units[1])
            local tileid = unit.values[XPOS] + unit.values[YPOS] * roomsizex
            if this_mod_globals.blocked_tiles[tileid] then
                return nil
            end
        end
        return raycast_units
    end
    return nil
end

function this_raycast(x, y, dir)
    if dir >= 0 and dir <= 3 then 
        local dir_vec = dirs[dir+1]
        local dx = dir_vec[1]
        local dy = dir_vec[2] * -1
        local ox = x + dx
        local oy = y + dy
        while inbounds(ox,oy) do
            local tileid = ox + oy * roomsizex

            if unitmap[tileid] == nil and hasfeature("empty", "is", "block", 2, ox, oy) then
                return {ox, oy},true
            elseif unitmap[tileid] ~= nil and #unitmap[tileid] > 0 then
                return {ox, oy},false
            end

            ox = ox + dx
            oy = oy + dy
        end
    end

    return nil
end

function defer_addoption_with_this(rule, is_not_this)
    local option,conds,ids,tags = rule[1],rule[2],rule[3],rule[4]
    local target,verb,property = option[1],option[2],option[3]

    local prop_is_not = string.sub(property, 1, 4) == "not "
    if prop_is_not then
        property = string.sub(property, 5)
    end

    local 

    if property == "block" then
        table.insert(this_mod_globals.deferred_rules_with_this["this block"], rule)
    elseif is_name_text_this(property) then
        for _, ray_unitid in ipairs(get_raycast_units(ids[3][1])) do
            local u = mmf.newObject(ray_unitid) 
            if u.strings[NAME] == "block" then
                if prop_is_not then
                    table.insert(this_mod_globals.deferred_rules_with_this["not this block"], rule)
                else
                    table.insert(this_mod_globals.deferred_rules_with_this["this block"], rule)
                end
            else
                if prop_is_not then
                    table.insert(this_mod_globals.deferred_rules_with_this["not this"], rule)
                else
                    table.insert(this_mod_globals.deferred_rules_with_this["this"], rule)
                end
            end
        end
    else
        if prop_is_not then
            table.insert(this_mod_globals.deferred_rules_with_this["not this"], rule)
        else
            table.insert(this_mod_globals.deferred_rules_with_this["this"], rule)
        end
    end


    if is_name_text_this(target) or is_name_text_this(property) then
        table.insert(this_mod_globals.deferred_rules_with_this["this"], rule)
    local key = "this"
    if is_not_this then
        key = "not this"
    end
    table.insert(this_mod_globals.deferred_rules_with_this[key], rule)
end

function temp()
    -- input this sentences possibilies:
    --       1.this is object
    --       3.object is this
    --       5.this is this
    
    --       2.this is not object
    --       4.object is not this
    --       6.this is not this
    -- not this is X is handled in addoption, being reinterpreted as "All is X" with a "not this" condition

    -- 2 is handled by the engine.
    local this_is_blocks = {}
    local this_is_not_blocks = {}
    local other_this_rules = {}
    local other_not_this_rules = {}

    update_raycast_units(false)
    for i, rules in ipairs(this_mod_globals.deferred_rules_with_this["this"]) do
        local rule = rules[1]
        local ids = rules[3]
        local is_rule_block = false
        local is_rule_not_block = false

        local target = rule[1]
        local verb = rule[2]
        local property = rule[3]
        local is_not = string.sub(property, 1, 4) == "not "
        if is_not then
            property = string.sub(property, 5)
        end
        
        local detected_block_rule = false
        if verb == "is" then
            if property == "block" then
                detected_block_rule = true
                table.insert(this_is_blocks, rules)
            elseif is_name_text_this(property) then
                for _, unitid in ipairs(get_raycast_units(ids[3][1], false)) do
                    local unit = mmf.newObject(unitid)
                    if unit.strings[NAME] == "block" then
                        detected_block_rule = true
                        if is_not then
                            table.insert(this_is_not_blocks, rules)
                        else
                            table.insert(this_is_blocks, rules)
                        end

                        if is_name_text_this(target) then
                            table.insert(this_is_blocks, rules)
                        end
                    end
                end
            end
        end
        if not detected_block_rule then
            if is_not then
                table.insert(other_not_this_rules, rules)
            else
                table.insert(other_this_rules, rules)
            end
        end

        elseif rule[2] == "is" and 
            
        else
            if rule[2] == "is" and is_name_text_this(rule[3]) then
                for _, unitid in ipairs(get_raycast_units(ids[3][1], false)) do
                    local unit = mmf.newObject(unitid)
                    if unit.strings[NAME] == "block" then
                        is_rule_block = true
                        break
                    end
                end
            end
        end
        if is_rule_block then
            table.insert(this_is_blocks, rules)
        elseif is_not_rule_block then
            table.insert(this_is_not_blocks, rules)
        else
            table.insert(other_this_rules, rules)
        end
    end
    process_this_rules(this_is_blocks, this_is_not_blocks)
    update_raycast_units(true)
    process_this_rules(this_mod_globals.deferred_rules_with_this["this"], this_mod_globals.deferred_rules_with_this["not this"])
end

function do_subrule_this()
    print("do subrule this")
    update_raycast_units(true)
    local this_is_blocks = {}
    local checkthese = {}

    if (this_mod_globals.deferred_rules_with_this["this"] ~= nil) then
        for i, rules in ipairs(this_mod_globals.deferred_rules_with_this["this"]) do
            local rule = rules[1]
            if is_name_text_this(rule[1]) and rule[2] == "is" and rule[3] == "block" then
                table.insert(this_is_blocks, rules) -- prioritize "this is block"
            else
                table.insert(checkthese, rules)
            end
        end
    end
    for i, rules in ipairs(this_is_blocks) do
        local rule = rules[1]
        local conds = rules[2]
        local ids = rules[3]

        local this_text_unitid = ids[1][1]
        local raycast_units = get_raycast_units(this_text_unitid, false)
        if raycast_units ~= nil then
            for _, ray_unitid in ipairs(raycast_units) do
                local ray_unit = mmf.newObject(ray_unitid)
                local ray_name = ray_unit.strings[NAME]
                if ray_unit.strings[UNITTYPE] == "text" then
                    ray_name = "text"
                end
                
                local newrule = {ray_name,rule[2],rule[3]}
                local newconds = {}
                table.insert(newconds, {"this", {this_text_unitid}})
                for a,b in ipairs(conds) do
                    table.insert(newconds, b)
                end
                -- local tileid = ray_unit.values[XPOS] + ray_unit.values[YPOS] * roomsizex
                -- this_mod_globals.blocked_tiles[tileid] = true
                addoption(newrule,newconds,ids,true,nil,tags)
            end
        end
    end

    update_raycast_units(true)
    local final_options = {}
    local this_is_not_this_options = {}
    if this_mod_globals.deferred_rules_with_this["this"] ~= nil then
        for i, rules in ipairs(this_mod_globals.deferred_rules_with_this["this"]) do
            local rule = rules[1]
            local conds = rules[2]
            local ids = rules[3]
            local tags = rules[4]

            if not (is_name_text_this(rule[1]) and rule[2] == "is" and rule[3] == "block") then
                local property_options = {}
                local target_options = {}
                local newrule = {rule[1], rule[2], rule[3]}
                local newconds = {}
                local add_option = false
                for a,b in ipairs(conds) do
                    table.insert(newconds, b)
                end

                local target_name = rule[3]

                if is_name_text_this(target_name) then
                    local this_text_unitid = ids[3][1]
                    local raycast_units = get_raycast_units(this_text_unitid, true)
                    local unit = mmf.newObject(this_text_unitid)
                    if raycast_units ~= nil then
                        for _, ray_unitid in ipairs(raycast_units) do
                            local ray_unit = mmf.newObject(ray_unitid)
                            
                            if is_unit_valid_this_property(ray_unitid, rule[2]) then
                                local rulename = ray_unit.strings[NAME]
                                local newrule = {rule[1],rule[2],rulename}
                                local newconds = {}
                                for a,b in ipairs(conds) do
                                    table.insert(newconds, b)
                                end
                                table.insert(property_options, {rule = newrule, conds = newconds})
                            end
                        end
                    end
                else
                    table.insert(property_options, {rule = rule, conds = conds})
                end

                local has_not_this_at_end = is_name_text_this(rule[3], true)
                target_name = rule[1]
                if (is_name_text_this(rule[1])) then
                    local this_text_unitid = ids[1][1]
                    local raycast_units = get_raycast_units(this_text_unitid, true)
                    if raycast_units ~= nil then
                        for _, ray_unitid in ipairs(raycast_units) do
                            local ray_unit = mmf.newObject(ray_unitid)
                            local ray_name = ray_unit.strings[NAME]
                            if ray_unit.strings[UNITTYPE] == "text" then
                                ray_name = "text"
                            end
                            -- if isnot then
                            --     ray_name = "not "..ray_name
                            -- end
                            for _, option in ipairs(property_options) do
                                local newrule = {ray_name,option.rule[2],option.rule[3]}
                                local newconds = {}
                                for a,b in ipairs(option.conds) do
                                    table.insert(newconds, b)
                                end
                                table.insert(newconds, {"this", {this_text_unitid}})

                                if has_not_this_at_end then
                                    table.insert(this_is_not_this_options, {rule = newrule, conds = newconds, ids = ids, tags = tags})
                                else 
                                    table.insert(target_options, {rule = newrule, conds = newconds})
                                end
                            end
                        end
                    end
                end

                if #target_options == 0 and #this_is_not_this_options == 0 then
                    target_options = property_options
                end

                for _, option in ipairs(target_options) do
                    table.insert(final_options, {rule = option.rule, conds=option.conds, ids=ids, tags=tags})
                end
            end
        end
    end

    if this_mod_globals.deferred_rules_with_this["not this"] ~= nil then
        for i, rules in ipairs(this_mod_globals.deferred_rules_with_this["not this"]) do
            local rule = rules[1]
            local conds = rules[2]
            local ids = rules[3]
            local tags = rules[4]
            if not is_name_text_this(rule[1]) then
                table.insert(this_is_not_this_options, {rule = rule, conds = conds, ids = ids, tags = tags})
            end
        end
    end

    for _, option in ipairs(this_is_not_this_options) do
        local this_text_unitid = option.ids[3][1]
        local raycast_units = get_raycast_units(this_text_unitid, true)
        if raycast_units ~= nil then
            for _, ray_unitid in ipairs(raycast_units) do
                local ray_unit = mmf.newObject(ray_unitid)
                local add_rule = false

                if ray_unit.strings[UNITTYPE] == "text" then
                    if option.rule[2] == "is" and ray_unit.values[TYPE] == 2 then
                        add_rule = true
                    elseif ray_unit.values[TYPE] == 0 and not is_name_text_this(ray_unit.strings[NAME]) then
                        add_rule = true
                    end
                else
                    add_rule = true
                end
                
                
                if add_rule then
                    local rulename = "not "..ray_unit.strings[NAME]
                    local newrule = {option.rule[1],option.rule[2],rulename}
                    table.insert(final_options, {rule = newrule, conds = option.conds, ids = option.ids, tags = option.tags})
                end
            end
        end
    end

    for _,option in ipairs(final_options) do
        addoption(option.rule,option.conds,option.ids,true,nil,option.tags)
    end
end