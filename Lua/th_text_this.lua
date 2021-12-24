table.insert(editor_objlist_order, "text_this")
table.insert(editor_objlist_order, "text_block")
table.insert(editor_objlist_order, "text_pass")

editor_objlist["text_this"] = 
{
	name = "text_this",
	sprite_in_root = false,
	unittype = "text",
	tags = {"plasma's mods", "text", "abstract", "text_noun"},
	tiling = 0,
	type = 0,
	layer = 20,
	colour = {0, 1},
    colour_active = {0, 3},
}
editor_objlist["text_block"] = 
{
	name = "text_block",
	sprite_in_root = false,
	unittype = "text",
	tags = {"plasma's mods", "text", "abstract", "text_quality"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {2, 1},
    colour_active = {2, 2},
}
editor_objlist["text_pass"] = 
{
	name = "text_pass",
	sprite_in_root = false,
	unittype = "text",
	tags = {"plasma's mods", "text", "abstract", "text_quality"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {4, 3},
    colour_active = {4, 4},
}

formatobjlist()

register_directional_text_prefix("this")

this_mod_globals = {}
local function reset_this_mod_globals()
    this_mod_globals = {
        active_this_property_text = {}, -- keep track of texts 
        undoed_after_called = false, -- flag for providing a specific hook of when we call code() after an undo
    }
end   
reset_this_mod_globals()

local text_to_cursor = {} -- mapping from this text unitid to cursor unitid
local text_to_raycast_units = {} -- mapping from this text unitid to all units that were hit by a raycast
local text_to_raycast_pos = {}
local blocked_tiles = {} -- all positions where "X is block" is active
local explicit_passed_tiles = {} -- all positions pointed by a "this is pass" rule. Used for cursor display 
local cond_features_with_this_noun = {} -- list of all condition rules with "this" as a noun and "block/pass" as properties. Used to check if updatecode should be set to 1 to recalculate which units are blocked/pass
local deferred_rules_with_this = {}
local on_level_start = false

local function reset_this_mod_locals()
    text_to_cursor = {}
    text_to_raycast_units = {}
    text_to_raycast_pos = {}
    blocked_tiles = {}
    explicit_passed_tiles = {}
    cond_features_with_this_noun = {}
    deferred_rules_with_this = {}
end

local make_cursor, update_all_cursors

table.insert(mod_hook_functions["rule_baserules"],
    function()
        addbaserule("empty", "is", "pass")
    end
)

-- Note: changed from "effect_always" to "always" since effect_always only activates when disable particle effects is off 
table.insert(mod_hook_functions["always"],
    function()
        update_all_cursors()
    end
)

table.insert(mod_hook_functions["level_start"], 
    function()
        for i,unitid in ipairs(codeunits) do
            local unit = mmf.newObject(unitid)
            if is_name_text_this(unit.strings[NAME]) then
                text_to_cursor[unitid] = make_cursor(unit)
            end
        end
        on_level_start = true
    end
)

table.insert( mod_hook_functions["undoed_after"],
    function()
        for i,unitid in ipairs(codeunits) do
            local unit = mmf.newObject(unitid)
            set_tt_display_direction(unit)
        end
        blocked_tiles = {}
        this_mod_globals.undoed_after_called = true
    end
)

table.insert( mod_hook_functions["command_given"],
    function()
        this_mod_globals.update_cursor_zoom = false
    end
)


table.insert(mod_hook_functions["rule_update"],
    function(is_this_a_repeated_update)
        this_mod_globals.active_this_property_text = {}
        deferred_rules_with_this = {}
        cond_features_with_this_noun = {}
    end
)
table.insert(mod_hook_functions["rule_update_after"],
    function()
        if on_level_start then
            on_level_start = false
        end
        if this_mod_globals.undoed_after_called then
            this_mod_globals.undoed_after_called = false
            -- update_all_cursors()
        end
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

-- Really useless function whose only purpose is to gatekeep calling update_raycast_units() in code() before checking updatecode. Also allows
-- the variable "text_to_cursor" to be file scoped
function this_mod_has_this_text()
    for _,_ in pairs(text_to_cursor) do
        return true
    end
    return false
end

-- This is used in {{mod_injections}}
function reset_this_mod()
    local count = 0
    for _, cursor_unitid in pairs(text_to_cursor) do
        delunit(cursor_unitid)
        MF_remove(cursor_unitid)
        count = count + 1
    end
    reset_this_mod_globals()
    reset_this_mod_locals()
end

function on_add_this_text(this_unitid)
    if not text_to_cursor[this_unitid] then
        local wordunit = mmf.newObject(this_unitid)
        local cursorunit = make_cursor(wordunit)
        text_to_cursor[this_unitid] = cursorunit
    end
end

function on_delele_this_text(this_unitid)
    if text_to_cursor[this_unitid] then
        MF_cleanremove(text_to_cursor[this_unitid])
        text_to_cursor[this_unitid] = nil
        text_to_raycast_units[this_unitid] = nil
        text_to_raycast_pos[this_unitid] = nil
    end
end

local function update_this_cursor(wordunit, cursorunit)
    local x = wordunit.values[XPOS]
    local y = wordunit.values[YPOS]

    local tileid = text_to_raycast_pos[wordunit.fixed]
    if tileid then
        local nx = math.floor(tileid % roomsizex)
        local ny = math.floor(tileid / roomsizex)
        local cursor_tilesize = f_tilesize * generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
        cursorunit.values[XPOS] = nx * cursor_tilesize + Xoffset + (cursor_tilesize / 2)
        cursorunit.values[YPOS] = ny * cursor_tilesize + Yoffset + (cursor_tilesize / 2)

        local c1 = 0
        local c2 = 0
        cursorunit.layer = 1
        if blocked_tiles[tileid] then
            -- display different sprite if the tile is blocked
            cursorunit.values[ZLAYER] = 44
            cursorunit.direction = 30
            MF_loadsprite(cursorunit.fixed,"this_cursor_blocked_0",30,true)
            c1,c2 = getuicolour("blocked")
        elseif explicit_passed_tiles[tileid] then
            cursorunit.values[ZLAYER] = 42
            cursorunit.direction = 31
            MF_loadsprite(cursorunit.fixed,"this_cursor_pass_0",31,true)
            c1,c2 = 4, 4
        else
            if ruleids[wordunit.fixed] then
                cursorunit.values[ZLAYER] = 41 -- Note: the game only actually processes Zlayers between 0-30. We don't know what it does with layers outside of this range, but it seems
            else
                cursorunit.values[ZLAYER] = 30
            end
            cursorunit.direction = 28
            MF_loadsprite(cursorunit.fixed,"this_cursor_0",28,true)
            -- MF_loadsprite(cursorunit.fixed,"stable_indicator_0",28,true)
            c1,c2 = wordunit.colour[1],wordunit.colour[2]
        end
    
        MF_setcolour(cursorunit.fixed,c1,c2)
    else
        -- Just to hide it
        cursorunit.values[XPOS] = -20
        cursorunit.values[YPOS] = -20
    end
    cursorunit.scaleX = generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
    cursorunit.scaleY = generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
    
    if (generaldata.values[DISABLEPARTICLES] ~= 0 or generaldata5.values[LEVEL_DISABLEPARTICLES] ~= 0) then
        -- Just to hide it
        cursorunit.values[XPOS] = -20
        cursorunit.values[YPOS] = -20
    end
end

-- local
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

-- local
function update_all_cursors()
    for this_unitid, cursor_unitid in pairs(text_to_cursor) do
        local wordunit = mmf.newObject(this_unitid)
        local cursorunit = mmf.newObject(cursor_unitid)

        update_this_cursor(wordunit, cursorunit)
    end
end

local function this_raycast(x, y, dir, checkemptyblock)
    if dir >= 0 and dir <= 3 then 
        local dir_vec = dirs[dir+1]
        local dx = dir_vec[1]
        local dy = dir_vec[2] * -1
        local ox = x + dx
        local oy = y + dy
        while inbounds(ox,oy) do
            local tileid = ox + oy * roomsizex

            if unitmap[tileid] == nil then
                if checkemptyblock and hasfeature("empty", "is", "block", 2, ox, oy) and not hasfeature("empty", "is", "not block", 2, ox, oy) then
                    return {ox, oy},true, false
                elseif hasfeature("empty", "is", "not pass", 2, ox, oy) then
                    return {ox, oy}, false, true
                end
            elseif unitmap[tileid] ~= nil and #unitmap[tileid] > 0 then
                return {ox, oy},false, false
            end

            ox = ox + dx
            oy = oy + dy
        end
    end

    return nil
end

function update_raycast_units(checkblocked_, checkpass_, affect_updatecode, exclude_this_units, include_this_units, mark_passed_tiles)
    local checkblocked = checkblocked_ or false
    local checkpass = checkpass_ or false
    exclude_this_units = exclude_this_units or {}
    local mark_passed_tiles = mark_passed_tiles or false
    local new_raycast_units = {}
    local all_block = false
    local all_pass = false
    
    if checkblocked then
        all_block = findfeature("all", "is", "block") ~= nil
    end
    if checkpass then
        all_pass = findfeature("all", "is", "pass") ~= nil
    end
    for unitid, _ in pairs(text_to_cursor) do
        if (include_this_units == nil or include_this_units[unitid]) and not exclude_this_units[unitid] then
            local unit = mmf.newObject(unitid)
            local x = unit.values[XPOS]
            local y = unit.values[YPOS]
            local dir = unit.values[DIR]
            local ray_unitids = {}

            local tileid = nil
            local blocked = false
            local select_empty_tile = false
            local tile_pass = true

            while tile_pass do
                tile_pass = false
                local ray_pos,is_emptyblock, select_empty = this_raycast(x, y, dir, checkblocked)
                if ray_pos then
                    tileid = ray_pos[1] + ray_pos[2] * roomsizex

                    if checkblocked and is_emptyblock then
                        blocked = true
                    elseif select_empty then
                        select_empty_tile = true
                        table.insert(ray_unitids, 2)
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
                ray_unitids = {}
            end

            if affect_updatecode and updatecode == 0 then
                -- set updatecode to 1 if any of the raycast units changed
                local prev_raycast_unitids = text_to_raycast_units[unitid] or {}
                local prev_raycast_tileid = text_to_raycast_pos[unitid] or -1

                if #ray_unitids ~= #prev_raycast_unitids then
                    updatecode = 1
                else
                    if #prev_raycast_unitids > 0 and prev_raycast_unitids[1] == 2 then
                        if not select_empty_tile then
                            updatecode = 1
                        elseif prev_raycast_tileid ~= tileid then
                            updatecode = 1
                        end
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
                text_to_raycast_units[unitid] = nil
            else
                text_to_raycast_units[unitid] = ray_unitids
            end

            text_to_raycast_pos[unitid] = tileid
        end
    end
end

function check_cond_rules_with_this_noun()
    for _, data in ipairs(cond_features_with_this_noun) do
        local checkcond = nil
        if data.ray_unitid == 2 then
            local x = math.floor(data.ray_tileid % roomsizex)
            local y = math.floor(data.ray_tileid / roomsizex)
            checkcond = testcond(data.conds, data.ray_unitid, x, y)
        else
            checkcond = testcond(data.conds, data.ray_unitid)
        end
        if checkcond ~= data.last_testcond_result then
            updatecode = 1
            break
        end
    end
end

function get_raycast_units(this_text_unitid, checkblocked)
    if is_this_unit_in_stablerule(this_text_unitid) then
        return get_stable_this_raycast_units(tonumber(this_text_unitid))
    end

    local raycast_units = text_to_raycast_units[this_text_unitid]
    if raycast_units ~= nil and #raycast_units > 0 then
        if checkblocked then
            local tileid = text_to_raycast_pos[this_text_unitid]
            if blocked_tiles[tileid] then
                return {}
            end
        end
        return raycast_units
    end
    return {}
end

function get_raycast_tileid(this_text_unitid)
    if is_this_unit_in_stablerule(this_text_unitid) then
        return get_stable_this_raycast_pos(tonumber(this_text_unitid))
    end
    return text_to_raycast_pos[this_text_unitid]
end

local function is_unit_valid_this_property(unitid, verb)
    if unitid == 2 then return true end
        
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

-- Like get_raycast_units, but factors in this redirection
local function get_raycast_property_units(this_text_unitid, checkblocked, curr_phase, verb)
    if not text_to_raycast_pos[this_text_unitid] then
        return {}, {}
    end
    local this_text_unit = mmf.newObject(this_text_unitid)
    local init_tileid = this_text_unit.values[XPOS] + this_text_unit.values[YPOS] * roomsizex

    local visited_tileids = {}
    visited_tileids[init_tileid] = true
    local out_raycast_units = {}
    local all_redirected_this_units = {}
    local raycast_this_texts = { this_text_unitid } -- This will be treated as a stack, meaning we are doing DFS instead of BFS
    local lit_up_this_texts = {}

    while #raycast_this_texts > 0 do
        local curr_this_unitid = table.remove(raycast_this_texts) -- Pop the stack 
        local curr_raycast_tileid = text_to_raycast_pos[curr_this_unitid]
        
        if checkblocked and blocked_tiles[curr_raycast_tileid] then
            -- do nothing if blocked
        elseif visited_tileids[curr_raycast_tileid] then

        elseif curr_raycast_tileid then
            visited_tileids[curr_raycast_tileid] = true
            lit_up_this_texts[curr_this_unitid] = true

            local raycast_units = text_to_raycast_units[curr_this_unitid]
            if raycast_units then
                for i, ray_unitid in ipairs(raycast_units) do

                    if ray_unitid == 2 then
                        table.insert(out_raycast_units, ray_unitid)
                    else
                        local ray_unit = mmf.newObject(ray_unitid)

                        if is_name_text_this(ray_unit.strings[NAME]) then
                            table.insert(raycast_this_texts, ray_unitid)
                            table.insert(all_redirected_this_units, ray_unitid)
                        elseif is_unit_valid_this_property(ray_unitid, verb) then
                            table.insert(out_raycast_units, ray_unitid)
                        end
                    end
                end
            end
        end
    end

    if #out_raycast_units > 0 then
        for unitid, _ in pairs(lit_up_this_texts) do
            this_mod_globals.active_this_property_text[unitid] = true
        end
    end

    return out_raycast_units, all_redirected_this_units
end

local function process_this_rules(this_rules, filter_property_func, checkblocked, curr_phase)
    local final_options = {}
    local this_noun_cond_options_list = {}
    local processed_this_units = {}
    local all_redirected_this_units = {}

    for i=#this_rules,1,-1 do
        rules = this_rules[i]
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
            if filter_property_func(property) then
                table.insert(property_options, {rule = rule, conds = conds})    
            end
        else
            local this_text_unitid = get_property_unitid_from_rule(rules)
            local raycast_units, redirected_this_units = get_raycast_property_units(this_text_unitid, checkblocked, curr_phase, verb)
            for _, unitid in ipairs(raycast_units) do
                local rulename = ""
                local ray_unit = mmf.newObject(unitid)
                if unitid == 2 then
                    rulename = "empty"
                else
                    rulename = ray_unit.strings[NAME]
                    if is_turning_text(rulename) then
                        rulename = get_turning_text_interpretation(unitid)
                    end
                end

                if filter_property_func(rulename) then
                    if unitid ~= "empty" then
                        if ray_unit.strings[UNITTYPE] == "text" then
                            this_mod_globals.active_this_property_text[unitid] = true
                        end
                    end

                    if prop_isnot then
                        rulename = "not "..rulename
                    end
                    
                    local newrule = {rule[1],rule[2],rulename}
                    local newconds = {}
                    for a,b in ipairs(conds) do
                        table.insert(newconds, b)
                    end
                    table.insert(property_options, {rule = newrule, conds = newconds, newrule = nil, showrule = nil})
                end
            end
            for _, unitid in ipairs(redirected_this_units) do
                table.insert(all_redirected_this_units, unitid)
            end
        end

        -- Process target next
        local target_options = {}
        if not is_name_text_this(target) then
            target_options = property_options
        elseif #property_options > 0 then
            local this_text_unitid = get_target_unitid_from_rule(rules)
            local this_unit_as_param_id = convert_this_unit_to_param_id(this_text_unitid)
            if target_isnot then
                for i,mat in pairs(objectlist) do
                    if (findnoun(i) == false) then
                        for _, option in ipairs(property_options) do
                            local newrule = {i, option.rule[2], option.rule[3]}
                            local newconds = {}
                            table.insert(newconds, {"not this", {this_unit_as_param_id} })
                            for a,b in ipairs(conds) do
                                table.insert(newconds, b)
                            end
                            table.insert(target_options, {rule = newrule, conds = newconds, notrule = true, showrule = false})
                        end
                    end
                end
                
                -- Rule display in pause menu
                if #target_options > 0 and filter_property_func(property) then
                    table.insert(visualfeatures, {rule, conds, ids, tags})
                end
            else
                local ray_tileid = get_raycast_tileid(this_text_unitid)
                for _, ray_unitid in ipairs(get_raycast_units(this_text_unitid, checkblocked)) do
                    local ray_name = ""
                    if ray_unitid == 2 then
                        ray_name = "empty"
                    else
                        local ray_unit = mmf.newObject(ray_unitid)
                        ray_name = ray_unit.strings[NAME]
                        if ray_unit.strings[UNITTYPE] == "text" then
                            ray_name = "text"
                        end
                    end

                    for _, option in ipairs(property_options) do
                        local newrule = {ray_name, option.rule[2], option.rule[3]}
                        local newconds = {}
                        table.insert(newconds, {"this", {this_unit_as_param_id} })
                        for a,b in ipairs(option.conds) do
                            table.insert(newconds, b)
                        end

                        table.insert(target_options, {rule = newrule, conds = newconds, notrule = false, showrule = true})

                        -- Watch sentences in the form "this <infix condition> is pass/block". See cond_features_with_this_noun 
                        -- description for why we do this.
                        if curr_phase == "block" or curr_phase == "pass" or curr_phase == "ray-block" or curr_phase == "ray-pass" and #conds > 0 then
                            table.insert(this_noun_cond_options_list, {
                                this_unitid = this_text_unitid,
                                ray_tileid = ray_tileid,
                                ray_unitid = ray_unitid,
                                conds = conds,
                                last_testcond_result = nil
                            })
                        end
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
                end
            end
            for _, unitid in ipairs(all_redirected_this_units) do
                processed_this_units[unitid] = true
            end

            table.remove(this_rules, i)
        else
            -- @ Note: this is meant to trick postrules to display the active particles even
            -- though we don't actually call addoption
            table.insert(features, {{"this","is","test"}, conds, ids, tags})
        end
    end

    for _, option in ipairs(final_options) do
        addoption(option.rule,option.conds,option.ids,option.showrule,nil,option.tags)
    end

    -- Watch sentences in the form "this <infix condition> is pass/block". See cond_features_with_this_noun 
    -- description for why we do this.
    for _, data in ipairs(this_noun_cond_options_list) do
        local checkcond = nil
        local ray_tileid = get_raycast_tileid(data.this_unitid)
        if data.ray_unitid == 2 then
            local x = math.floor(data.ray_tileid % roomsizex)
            local y = math.floor(data.ray_tileid / roomsizex)
            checkcond = testcond(data.conds, data.ray_unitid, x, y)
        else
            checkcond = testcond(data.conds, data.ray_unitid)
        end
        data.last_testcond_result = checkcond

        table.insert(cond_features_with_this_noun, data)
    end

    return processed_this_units
end

local function block_filter(name)
    return name == "block"
end
local function pass_filter(name)
    return name == "pass"
end
local function other_filter(name)
    return name ~= "block" and name ~= "pass"
end
local function set_blocked_tile(tileid)
    if tileid then
        blocked_tiles[tileid] = true
    end
end
local function set_passed_tile(tileid)
    if tileid then
        explicit_passed_tiles[tileid] = true
    end
end

function do_subrule_this()
    blocked_tiles = {}
    explicit_passed_tiles = {}

    -- Used for preventing certain this texts from updating their raycast units in later phases.
    -- This is used for this texts found in "pass" phase. 
    -- The policy is that "this is block" will apply to all this texts including the "this" in the original rule. While
    -- "this is pass" will apply to all this texts *other* than the "this" in the original rule.
    -- The idea is that "block" will be "active" in enforcing its effect while "pass" will be "passive" in doing the same thing.
    local all_processed_this_units = {}

    if (featureindex["this"] ~= nil) then
        deferred_rules_with_this = featureindex["this"]
        update_raycast_units(true, true, false)
        local processed_block_this_units = process_this_rules(deferred_rules_with_this, block_filter, true, "block")
        for unit, _ in pairs(processed_block_this_units) do
            all_processed_this_units[unit] = true
        end

        update_raycast_units(true, true, false, all_processed_this_units)
        local processed_pass_this_units = process_this_rules(deferred_rules_with_this, pass_filter, true, "pass")
        for unit, _ in pairs(processed_pass_this_units) do
            all_processed_this_units[unit] = true
        end
        
        update_raycast_units(true, true, false, all_processed_this_units)
        local processed_block_this_units2 = process_this_rules(deferred_rules_with_this, block_filter, true, "ray-block")
        
        for unit, _ in pairs(processed_block_this_units2) do
            all_processed_this_units[unit] = true
            processed_block_this_units[unit] = true
        end

        update_raycast_units(true, true, false, all_processed_this_units)
        local processed_pass_this_units2 = process_this_rules(deferred_rules_with_this, pass_filter, true, "ray-pass")
        for unit, _ in pairs(processed_pass_this_units2) do
            all_processed_this_units[unit] = true
            processed_pass_this_units[unit] = true
        end

        update_raycast_units(true, true, false, all_processed_this_units)
        process_this_rules(deferred_rules_with_this, other_filter, true, "other")

        for this_unitid, _ in pairs(processed_block_this_units) do
            local tileid = get_raycast_tileid(this_unitid)
            local x = math.floor(tileid % roomsizex)
            local y = math.floor(tileid / roomsizex)

            for _, ray_unitid in ipairs(get_raycast_units(this_unitid)) do
                local has_block = false
                local has_not_block = false
                if ray_unitid == 2 then
                    has_block = hasfeature("empty", "is", "block", 2, x, y)
                    has_not_block = hasfeature("empty", "is", "not block", 2, x, y)
                else
                    local ray_unit = mmf.newObject(ray_unitid)
                    local ray_unit_name = ray_unit.strings[NAME]
                    if ray_unit.strings[UNITTYPE] == "text" then
                        ray_unit_name = "text"
                    end
                    has_block = hasfeature(ray_unit_name, "is", "block", ray_unitid)
                    has_not_block = hasfeature(ray_unit_name, "is", "not block", ray_unitid)
                end
                
                if has_block and not has_not_block then
                    set_blocked_tile(tileid)
                    break
                end
            end
        end
        for this_unitid, _ in pairs(processed_pass_this_units) do
            local tileid = get_raycast_tileid(this_unitid)
            local x = math.floor(tileid % roomsizex)
            local y = math.floor(tileid / roomsizex)
            for _, ray_unitid in ipairs(get_raycast_units(this_unitid)) do
                local ray_unit_name = ""
                local has_pass = false
                local has_not_pass = false

                if ray_unitid == 2 then
                    ray_unit_name = "empty"
                    has_pass = hasfeature(ray_unit_name, "is", "pass", ray_unitid, x, y)
                    has_not_pass = hasfeature(ray_unit_name, "is", "not pass", ray_unitid, x, y)
                else
                    local ray_unit = mmf.newObject(ray_unitid)
                    ray_unit_name = ray_unit.strings[NAME]
                    if ray_unit.strings[UNITTYPE] == "text" then
                        ray_unit_name = "text"
                    end
                    has_pass = hasfeature(ray_unit_name, "is", "pass",ray_unitid)
                    has_not_pass = hasfeature(ray_unit_name, "is", "not pass",ray_unitid)
                end

                if has_pass and not has_not_pass then
                    set_passed_tile(tileid)
                    break
                end
            end
        end
    end
end