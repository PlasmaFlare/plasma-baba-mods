register_directional_text_prefix("this")

this_mod_globals = {}

function reset_this_mod_globals()
    this_mod_globals = {
        text_to_cursor = {}, -- mapping from this text unitid to cursor unitid
        text_to_raycast_units = {}, -- mapping from this text unitid to all units that were hit by a raycast
        text_to_raycast_pos = {},
        blocked_tiles = {}, -- all positions where "X is block" is active
        undoed_after_called = false, -- flag for providing a specific hook of when we call code() after an undo
        active_this_property_text = {}, -- keep track of texts 
        on_level_start = false,
        deferred_rules_with_this = {}, --     
        on_already_run = false,
    
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

table.insert( mod_hook_functions["undoed_after"],
    function()
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


table.insert(mod_hook_functions["rule_update"],
    function(is_this_a_repeated_update)
        this_mod_globals.on_already_run = is_this_a_repeated_update
        if not is_this_a_repeated_update then
            this_mod_globals.this_param_to_unitid = {}
            this_mod_globals.registered_this_unitid_as_params = {}
        end
        this_mod_globals.active_this_property_text = {}
        this_mod_globals.deferred_rules_with_this = {}
    end
)
table.insert(mod_hook_functions["rule_update_after"],
    function()
        if this_mod_globals.on_level_start then
            this_mod_globals.on_level_start = false
        end
        if this_mod_globals.undoed_after_called then
            this_mod_globals.undoed_after_called = false
            update_all_cursors()
        end
    end
)

table.insert(mod_hook_functions["turn_end"],
    function()
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
    local count = 0
    for _, cursor_unitid in pairs(this_mod_globals.text_to_cursor) do
        delunit(cursor_unitid)
        MF_remove(cursor_unitid)
        count = count + 1
    end
    reset_this_mod_globals()
end

function make_cursor(unit)
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
        end
    end
end

function update_this_cursor(wordunit, cursorunit)
    local x = wordunit.values[XPOS]
    local y = wordunit.values[YPOS]
    local dir = wordunit.values[DIR]
    undo = undo or false

    local tileid = this_mod_globals.text_to_raycast_pos[wordunit.fixed]
    if tileid then
        local x = math.floor(tileid % roomsizex)
        local y = math.floor(tileid / roomsizex)
        cursorunit.values[XPOS] = x * f_tilesize+ Xoffset + (f_tilesize / 2)
        cursorunit.values[YPOS] = y * f_tilesize + Yoffset + (f_tilesize / 2)
        
        local c1 = nil
        local c2 = nil
        c1,c2 = wordunit.colour[1], wordunit.colour[2]
    
        local c1 = 0
        local c2 = 0
        if this_mod_globals.blocked_tiles[tileid] then
            -- display different sprite if the tile is blocked
            cursorunit.values[ZLAYER] = 40
            cursorunit.direction = 29
            MF_loadsprite(cursorunit.fixed,"this_cursor_blocked_0",29,true)
            c1,c2 = getuicolour("blocked")
            
        else
            cursorunit.values[ZLAYER] = 39
            cursorunit.direction = 28
            MF_loadsprite(cursorunit.fixed,"this_cursor_0",28,true)
            c1,c2 = wordunit.colour[1],wordunit.colour[2]
        end
    
        MF_setcolour(cursorunit.fixed,c1,c2)
    else
        -- Just to hide it
        cursorunit.values[XPOS] = -20
        cursorunit.values[YPOS] = -20
    end
end

function update_raycast_units(checkblocked_, checkpass_, processed_this_units_)
    local checkblocked = checkblocked_ or false
    local checkpass = checkpass_ or false
    local processed_this_units = processed_this_units_ or {}
    local new_raycast_units = {}
    local all_block = false
    local all_pass = false
    
    if checkblocked then
        all_block = findfeature("all", "is", "block") ~= nil
    end
    if checkpass then
        all_pass = findfeature("all", "is", "pass") ~= nil
    end
    for i,unitid in ipairs(codeunits) do
        local unit = mmf.newObject(unitid)
        if is_name_text_this(unit.strings[NAME]) and not processed_this_units[unitid] then
            local x = unit.values[XPOS]
            local y = unit.values[YPOS]
            local dir = unit.values[DIR]
            local ray_unitids = {}

            local tileid = nil
            local blocked = false
            local tile_pass = true

            while tile_pass do
                tile_pass = false
                local ray_pos,is_emptyblock = this_raycast(x, y, dir, checkblocked)
                if ray_pos then
                    tileid = ray_pos[1] + ray_pos[2] * roomsizex

                    if is_emptyblock then
                        blocked = true
                    else
                        local total_pass = 0
                        for _, ray_unitid in ipairs(unitmap[tileid]) do
                            local ray_unit = mmf.newObject(ray_unitid)
                            local ray_unit_name = ray_unit.strings[NAME] 
                            
                            if ray_unit.strings[UNITTYPE] == "text" then
                                ray_unit_name = "text"
                            end

                            if checkblocked then
                                if all_block and ray_unit_name ~= "text" and ray_unit_name ~= "empty" then
                                    blocked = true
                                elseif hasfeature(ray_unit_name, "is", "block",ray_unitid) and not hasfeature(ray_unit_name, "is", "not block",ray_unitid) then
                                    blocked = true
                                end
                            end

                            local add_to_rayunits = not blocked
                            if checkpass and not blocked then
                                if all_pass and ray_unit_name ~= "text" and ray_unit_name ~= "empty" then
                                    total_pass = total_pass + 1
                                    add_to_rayunits = false
                                else
                                    local has_pass = hasfeature(ray_unit_name, "is", "pass",ray_unitid)
                                    local has_not_pass = hasfeature(ray_unit_name, "is", "not pass",ray_unitid) 
                                    if has_pass and not has_not_pass then
                                        total_pass = total_pass + 1
                                        add_to_rayunits = false
                                    end
                                end
                            end

                            if add_to_rayunits then
                                table.insert(ray_unitids, ray_unitid)
                            end

                        end

                        if checkpass and total_pass >= #unitmap[tileid] then
                            tile_pass = true
                            tileid = nil
                            ray_unitids = {}
                            x = ray_pos[1]
                            y = ray_pos[2]
                        end
                    end
                end
            end

            if blocked and tileid then
                set_blocked_tile(tileid)
                updatecode = 1
            elseif checkpass then
                updatecode = 1
            elseif tileid and tileid ~= this_mod_globals.text_to_raycast_pos[unitid] then
                updatecode = 1
            else
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
            end
            if #ray_unitids == 0 then
                new_raycast_units[unitid] = nil
            else
                new_raycast_units[unitid] = ray_unitids
            end

            this_mod_globals.text_to_raycast_pos[unitid] = tileid
        end
    end
    this_mod_globals.text_to_raycast_units = new_raycast_units
end

function set_blocked_tile(tileid)
    if tileid then
        this_mod_globals.blocked_tiles[tileid] = true
    end
end

function get_raycast_units(this_text_unitid, checkblocked)
    local raycast_units = this_mod_globals.text_to_raycast_units[this_text_unitid]
    if raycast_units ~= nil and #raycast_units > 0 then
        if checkblocked then
            local unit = mmf.newObject(raycast_units[1])
            local tileid = unit.values[XPOS] + unit.values[YPOS] * roomsizex
            if this_mod_globals.blocked_tiles[tileid] then
                return {}
            end
        end
        return raycast_units
    end
    return {}
end

function get_raycast_tileid(this_text_unitid)
    return this_mod_globals.text_to_raycast_pos[this_text_unitid]
end

function this_raycast(x, y, dir, checkemptyblock_)
    local checkemptyblock = checkemptyblock_ or false
    if dir >= 0 and dir <= 3 then 
        local dir_vec = dirs[dir+1]
        local dx = dir_vec[1]
        local dy = dir_vec[2] * -1
        local ox = x + dx
        local oy = y + dy
        while inbounds(ox,oy) do
            local tileid = ox + oy * roomsizex

            if checkemptyblock and unitmap[tileid] == nil and hasfeature("empty", "is", "block", 2, ox, oy) then
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

function defer_addoption_with_this(rule)
    table.insert(this_mod_globals.deferred_rules_with_this, rule)
end

function process_this_rules(this_rules, filter_property_func, processed_this_units, checkblocked, is_block_phase)
    local final_options = {}

    for i, rules in ipairs(this_rules) do
        local rule, conds, ids, tags = rules[1], rules[2], rules[3], rules[4]
        local target, verb, property = rule[1], rule[2], rule[3]

        local target_isnot = string.sub(target, 1, 4) == "not "
        if target_isnot then
            target = string.sub(target, 5)
        end
        local prop_isnot = string.sub(property, 1, 4) == "not "
        if prop_isnot then
            property = string.sub(property, 5)
        end

        -- Process properties first
        local property_options = {}
        if not is_name_text_this(property) then
            if filter_property_func(ids[3][1]) then
                table.insert(property_options, {rule = rule, conds = conds})    
            end
        else
            local this_text_unitid = ids[3][1]
            for _, unitid in ipairs(get_raycast_units(this_text_unitid, checkblocked)) do
                if filter_property_func(unitid) and is_unit_valid_this_property(unitid, verb) then
                    local ray_unit = mmf.newObject(unitid)
                    local rulename = ray_unit.strings[NAME]
                    if is_turning_text(rulename) then
                        rulename = get_turning_text_interpretation(this_text_unitid)
                    end

                    if prop_isnot then
                        rulename = "not "..rulename
                    end

                    if ray_unit.strings[UNITTYPE] == "text" then
                        this_mod_globals.active_this_property_text[unitid] = true
                    end
                    
                    local newrule = {rule[1],rule[2],rulename}
                    local newconds = {}
                    for a,b in ipairs(conds) do
                        table.insert(newconds, b)
                    end
                    table.insert(property_options, {rule = newrule, conds = newconds, newrule = nil, showrule = nil})
                end
            end
        end

        -- Process target next
        local target_options = {}
        if not is_name_text_this(target) then
            target_options = property_options
        elseif #property_options > 0 then
            local this_text_unitid = ids[1][1]
            if target_isnot then
                for i,mat in pairs(objectlist) do
                    if (findnoun(i) == false) then
                        for _, option in ipairs(property_options) do
                            local newrule = {i, option.rule[2], option.rule[3]}
                            local newconds = {}
                            table.insert(newconds, {"not this", {this_text_unitid}})
                            for a,b in ipairs(conds) do
                                table.insert(newconds, b)
                            end
                            table.insert(target_options, {rule = newrule, conds = newconds, notrule = true, showrule = false})
                        end
                    end
                end
                
                -- Rule display in pause menu
                if #target_options > 0 and filter_property_func(ids[3][1]) then
                    table.insert(visualfeatures, {rule, conds, ids, tags})
                end
            else
                for _, ray_unitid in ipairs(get_raycast_units(this_text_unitid, checkblocked)) do
                    local ray_unit = mmf.newObject(ray_unitid)
                    local ray_name = ray_unit.strings[NAME]
                    if ray_unit.strings[UNITTYPE] == "text" then
                        ray_name = "text"
                    end

                    for _, option in ipairs(property_options) do
                        local newrule = {ray_name, option.rule[2], option.rule[3]}
                        local newconds = {}
                        table.insert(newconds, {"this", {this_text_unitid}})
                        for a,b in ipairs(conds) do
                            table.insert(newconds, b)
                        end

                        table.insert(target_options, {rule = newrule, conds = newconds, notrule = false, showrule = true})
                    end
                end
            end
        end

        if #target_options > 0 then
            for _, option in ipairs(target_options) do
                table.insert(final_options, {rule = option.rule, conds=option.conds, ids=ids, tags=tags, notrule = option.notrule, showrule = option.showrule})
            end

            -- For all "this" text in each option, mark it as processed so that future update_raycast_units() calls don't change the raycast units for each "this" text
            for i, id in ipairs(ids) do
                local unit = mmf.newObject(id[1])
                if is_name_text_this(unit.strings[NAME]) then
                    processed_this_units[id[1]] = true
                    -- if is_block_phase then
                    --    set_blocked_tile(get_raycast_tileid(id[1]))
                    -- end
                end
            end

        else
            -- @ Note: this is meant to trick postrules to display the active particles even
            -- though we don't actually call addoption
            table.insert(features, {{"this","is","test"}, conds, ids, tags})
        end
    end

    for _, option in ipairs(final_options) do
        addoption(option.rule,option.conds,option.ids,option.showrule,nil,option.tags)
    end
end

function do_subrule_this()
    function block_filter(unitid)
        local unit = mmf.newObject(unitid)
        return unit.strings[NAME] == "block"
    end
    function pass_filter(unitid)
        local unit = mmf.newObject(unitid)
        return unit.strings[NAME] == "pass"
    end
    function other_filter(unitid)
        local unit = mmf.newObject(unitid)
        return unit.strings[NAME] ~= "block" and unit.strings[NAME] ~= "pass"
    end
    this_mod_globals.blocked_tiles = {}
    local processed_this_units = {}
    update_raycast_units(false, false, processed_this_units)
    process_this_rules(this_mod_globals.deferred_rules_with_this, block_filter, processed_this_units, false, true)
    update_raycast_units(true, false, processed_this_units)
    process_this_rules(this_mod_globals.deferred_rules_with_this, pass_filter, processed_this_units, true, false)
    
    -- update_raycast_units(true, true, processed_this_units)
    -- process_this_rules(this_mod_globals.deferred_rules_with_this, block_filter, processed_this_units, true, true)
    -- update_raycast_units(true, true, processed_this_units)
    -- process_this_rules(this_mod_globals.deferred_rules_with_this, pass_filter, processed_this_units, true, false)

    update_raycast_units(true, true, processed_this_units)
    process_this_rules(this_mod_globals.deferred_rules_with_this, other_filter, processed_this_units, true, false)
end