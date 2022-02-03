table.insert(editor_objlist_order, "text_this")
table.insert(editor_objlist_order, "text_block")
table.insert(editor_objlist_order, "text_relay")
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
editor_objlist["text_relay"] = 
{
	name = "text_relay",
	sprite_in_root = false,
	unittype = "text",
	tags = {"plasma's mods", "text", "abstract", "text_quality"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {5, 2},
    colour_active = {5, 4},
}

formatobjlist()

register_directional_text_prefix("this")
register_directional_text_prefix("these")

this_mod_globals = {}
local function reset_this_mod_globals()
    this_mod_globals = {
        active_this_property_text = {}, -- keep track of texts 
        undoed_after_called = false, -- flag for providing a specific hook of when we call code() after an undo
    }
end   
reset_this_mod_globals()

local utils = plasma_utils

local blocked_tiles = {} -- all positions where "X is block" is active
local explicit_passed_tiles = {} -- all positions pointed by a "this is pass" rule. Used for cursor display 
local explicit_relayed_tiles = {} -- all positions pointed by a "this is relay" rule. Used for cursor display 
local cond_features_with_this_noun = {} -- list of all condition rules with "this" as a noun and "block/pass" as properties. Used to check if updatecode should be set to 1 to recalculate which units are blocked/pass
local deferred_rules_with_this = {} -- gather all features with THIS in the sentence into here instead of directly submitting into featureindex. Then when do_subrule_this() is called, process all features
local on_level_start = false
local NO_POSITION = -1
local THIS_LOGGING = false

--[[ 
    local raycast_data = {
        <unit id of THIS text> = {
            -- list of all objects that were hit by the raycast
            raycast_unitids = [<object>, <object>],

            -- Mapping of raycast positions to the objects that are in those objects. Note that these
            -- object lists aren't currently used since we don't need position specific logic. But maybe later
            -- if we come up with another word that needs that data.
            raycast_positions = { 
                <tileid> = [<object>, <object>], 
                <tileid> = [<object>, <object>], 
                ...
            },


            -- List of all extra spawned from relay or other raycast splitting
            cursors = {
                <tileid> = <unitid of cursor>,
                ...
            },
        }
    }
 ]]
local raycast_data = {}

--[[ 
    local relay_indicators = {
        <tileid + dir> = <unitid of indicator>,
        <tileid + dir> = <unitid of indicator>,
        ...
    }    
]]
local relay_indicators = {}

local POINTER_NOUNS = {
    this = true,
    these = true
}

local function reset_this_mod_locals()
    blocked_tiles = {}
    explicit_passed_tiles = {}
    explicit_relayed_tiles = {}
    cond_features_with_this_noun = {}
    raycast_data = {}
    relay_indicators = {}
end

local make_cursor, update_all_cursors, make_relay_indicator

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
        cond_features_with_this_noun = {}
        deferred_rules_with_this = {}
    end
)
table.insert(mod_hook_functions["rule_update_after"],
    function()
        if on_level_start then
            on_level_start = false
        end
        if this_mod_globals.undoed_after_called then
            this_mod_globals.undoed_after_called = false
        end
    end
)

-- This actually returns the pointer name if valid. It should be named "get_pointer_noun_from_name()" But can't rename it because the BASED mod uses "is_name_text_this"
function is_name_text_this(name, check_not_)
    local check_not = check_not_ or false

    local isnot = false
    if string.sub(name, 1, 4) == "not " then
        isnot = true
        name = string.sub(name, 5)
    end

    if check_not and not isnot then
        return false
    end

    for noun, _ in pairs(POINTER_NOUNS) do
        if string.sub(name, 1, #noun) == noun then
            return noun
        end
    end
    return nil
end

-- Determine the raycast velocity vectors, given a name of a pointer noun
local function get_raycast_vectors(name, dir)
    local cast_vecs = {}
    local pointer_noun = is_name_text_this(name)

    if pointer_noun then
        local dir_vec = {dirs[dir+1][1], dirs[dir+1][2] * -1}

        if pointer_noun == "this" then
            table.insert(cast_vecs, dir_vec)
        elseif pointer_noun == "these" then
            if (math.abs(dir_vec[1]) > math.abs(dir_vec[2])) then
                table.insert(cast_vecs, {dir_vec[1], dir_vec[2] + 1} )
                table.insert(cast_vecs, {dir_vec[1], dir_vec[2] - 1} )
            else
                table.insert(cast_vecs, {dir_vec[1] + 1, dir_vec[2]} )
                table.insert(cast_vecs, {dir_vec[1] - 1, dir_vec[2]} )
            end
        end
    end

    return cast_vecs
end

-- Really useless function whose only purpose is to gatekeep calling update_raycast_units() in code() before checking updatecode.
function this_mod_has_this_text()
    for _,_ in pairs(raycast_data) do
        return true
    end
    return false
end

-- This is used in {{mod_injections}}
function reset_this_mod()
    for this_unitid, v in pairs(raycast_data) do
        for _, cursor in pairs(v.cursors) do
            delunit(cursor)
            MF_cleanremove(cursor)
        end
    end
    for tileid, relay_indicator_unitid in pairs(relay_indicators) do
        delunit(relay_indicator_unitid)
        MF_cleanremove(relay_indicator_unitid)
    end
    reset_this_mod_globals()
    reset_this_mod_locals()
end

function on_add_this_text(this_unitid)
    if not raycast_data[this_unitid] then
        local unit = mmf.newObject(this_unitid)
        raycast_data[this_unitid] = {
            raycast_unitids = {},
            raycast_positions = {},
            cursors = {},
        }
    end
end

function on_delele_this_text(this_unitid)
    if raycast_data[this_unitid] then
        for _, cursor in ipairs(raycast_data[this_unitid].cursors) do
            delunit(cursor)
            MF_cleanremove(cursor)
        end
        raycast_data[this_unitid] = nil
    end
end

function defer_addoption_with_this(rule)
    table.insert(deferred_rules_with_this, rule)
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
local function set_relay_tile(tileid)
    if tileid then
        explicit_relayed_tiles[tileid] = true
    end
end

-- local
function update_all_cursors()
    for this_unitid, v in pairs(raycast_data) do
        for tileid, cursor_unitid in pairs(v.cursors) do
            local wordunit = mmf.newObject(this_unitid)
            local cursorunit = mmf.newObject(cursor_unitid)

            local x = wordunit.values[XPOS]
            local y = wordunit.values[YPOS]

            if tileid ~= NO_POSITION then
                local nx = math.floor(tileid % roomsizex)
                local ny = math.floor(tileid / roomsizex)
                local cursor_tilesize = f_tilesize * generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
                cursorunit.values[XPOS] = nx * cursor_tilesize + Xoffset + (cursor_tilesize / 2)
                cursorunit.values[YPOS] = ny * cursor_tilesize + Yoffset + (cursor_tilesize / 2)

                local c1 = 0
                local c2 = 0
                cursorunit.layer = 2
                if blocked_tiles[tileid] then
                    cursorunit.values[ZLAYER] = 30
                    cursorunit.direction = 30
                    MF_loadsprite(cursorunit.fixed,"this_cursor_blocked_0",30,true)
                    c1,c2 = getuicolour("blocked")
                elseif explicit_relayed_tiles[tileid] then
                    cursorunit.values[ZLAYER] = 29
                    cursorunit.direction = 29
                    MF_loadsprite(cursorunit.fixed,"this_cursor_relay_0",29,true)
                    c1,c2 = 5, 4
                elseif explicit_passed_tiles[tileid] then
                    cursorunit.values[ZLAYER] = 28
                    cursorunit.direction = 31
                    MF_loadsprite(cursorunit.fixed,"this_cursor_pass_0",31,true)
                    c1,c2 = 4, 4
                else
                    if ruleids[wordunit.fixed] then
                        cursorunit.values[ZLAYER] = 27 -- Note: the game only actually processes Zlayers between 0-30. We don't know what it does with layers outside of this range, but it seems
                    else
                        cursorunit.values[ZLAYER] = 26
                    end
                    cursorunit.direction = 28
                    MF_loadsprite(cursorunit.fixed,"this_cursor_0",28,true)
                    -- MF_loadsprite(cursorunit.fixed,"stable_indicator_0",28,true)
                    c1,c2 = wordunit.colour[1],wordunit.colour[2]
                end
            
                MF_setcolour(cursorunit.fixed,c1,c2)
                cursorunit.visible = true
            else
                -- Just to hide it
                cursorunit.visible = false
            end
            cursorunit.scaleX = generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
            cursorunit.scaleY = generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
            
            if (generaldata.values[DISABLEPARTICLES] ~= 0 or generaldata5.values[LEVEL_DISABLEPARTICLES] ~= 0) then
                -- Just to hide it
                cursorunit.visible = false
            else
                cursorunit.visible = true
            end
        end
    end

    for indicator_key, indicator_id in pairs(relay_indicators) do
        local relay_indicator = mmf.newObject(indicator_id)
        
        local dir = relay_indicator.values[DIR]
        local tileid = indicator_key - (dir * roomsizex * roomsizey)
        local x = math.floor(tileid % roomsizex)
        local y = math.floor(tileid / roomsizex)
        
        local cursor_tilesize = f_tilesize * generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
        relay_indicator.values[XPOS] = x * cursor_tilesize + Xoffset + (cursor_tilesize / 2)
        relay_indicator.values[YPOS] = y * cursor_tilesize + Yoffset + (cursor_tilesize / 2)
        
        if (generaldata.values[DISABLEPARTICLES] ~= 0 or generaldata5.values[LEVEL_DISABLEPARTICLES] ~= 0) then
            -- Just to hide it
            relay_indicator.visible = false
        else
            relay_indicator.visible = true
        end

        relay_indicator.scaleX = generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
        relay_indicator.scaleY = generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
    end
end

-- local
function make_cursor()
    local unitid2 = MF_create("customsprite")
    local unit2 = mmf.newObject(unitid2)
    
    unit2.values[ONLINE] = 1
    
    unit2.layer = 2
    unit2.direction = 28
    MF_loadsprite(unitid2,"this_cursor_0",28,true)
    
    return unitid2
end

-- local
function make_relay_indicator(x, y, dir)
    local unitid = MF_create("customsprite")
    local unit = mmf.newObject(unitid)
    
    unit.values[ONLINE] = 1
    
    unit.layer = 2
    unit.direction = 27
    MF_loadsprite(unitid,"relay_indicator_0",27,true)

    unit.values[DIR] = dir
    if dir == 0 then
        unit.angle = 0
    elseif dir == 1 then
        unit.angle = 90
    elseif dir == 2 then
        unit.angle = 180
    elseif dir == 3 then
        unit.angle = 270
    end

    local cursor_tilesize = f_tilesize * generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
    unit.values[XPOS] = x * cursor_tilesize + Xoffset + (cursor_tilesize / 2)
    unit.values[YPOS] = y * cursor_tilesize + Yoffset + (cursor_tilesize / 2)
    unit.scaleX = generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
    unit.scaleY = generaldata2.values[ZOOM] * spritedata.values[TILEMULT]

    MF_setcolour(unitid,5,4)
    
    return unitid
end

local function this_raycast(x, y, vector, checkemptyblock)
    -- return values: ray_pos, is_emptyblock, select_empty, emptyrelay_dir
    local ox = x + vector[1]
    local oy = y + vector[2]
    while inbounds(ox,oy,1) do
        local tileid = ox + oy * roomsizex

        if unitmap[tileid] == nil then
            local empty_dir = emptydir(ox, oy)
            --@TODO: should empty have a random direction? It would lead to dumb tesla coil levels
            -- if empty_dir == 4 then
            --     empty_dir = fixedrandom(0,3)
            -- end

            if checkemptyblock and hasfeature("empty", "is", "block", 2, ox, oy) and not hasfeature("empty", "is", "not block", 2, ox, oy) then
                return {ox, oy}, true, false, nil
            elseif hasfeature("empty", "is", "relay", 2, ox, oy) and not hasfeature("empty", "is", "not relay", 2, ox, oy) and empty_dir ~= 4 then
                return {ox, oy}, false, false, empty_dir
            elseif hasfeature("empty", "is", "not pass", 2, ox, oy) then
                return {ox, oy}, false, true, nil
            end
        elseif unitmap[tileid] ~= nil and #unitmap[tileid] > 0 then
            return {ox, oy}, false, false, nil
        end

        ox = ox + vector[1]
        oy = oy + vector[2]
    end

    return nil
end

function update_raycast_units(checkblocked_, checkpass_, affect_updatecode, exclude_this_units, keep_relay_indicators)
    local checkblocked = checkblocked_ or false
    local checkpass = checkpass_ or false
    exclude_this_units = exclude_this_units or {}
    local new_raycast_units = {}
    local all_block = false
    local all_pass = false
    
    local found_relay_indicators = {}
    local new_relay_indicators = {}
    
    if checkblocked then
        all_block = findfeature("all", "is", "block") ~= nil
    end
    if checkpass then
        all_pass = findfeature("all", "is", "pass") ~= nil
    end
    for unitid, curr_raycast_data in pairs(raycast_data) do
        if not exclude_this_units[unitid] then
            -- curr_raycast_data.raycast_unitids = nil -- @TODO: should this be uncommented?
            curr_raycast_data.raycast_positions = {}

            local unit = mmf.newObject(unitid)
            local x = unit.values[XPOS]
            local y = unit.values[YPOS]
            local dir = unit.values[DIR]

            local cast_vecs = get_raycast_vectors(unit.strings[NAME], dir)
            
            local found_raycast_pos_count = 0
            local all_rayunits = {}
            for i, vector in ipairs(cast_vecs) do
                local ray_unitids_found_in_curr_cast = {}
                local visited_tileids = {}
                local pending_raycast_stack = {
                    {
                        x = x,
                        y = y,
                        vector = vector,
                    }
                }

                while #pending_raycast_stack > 0 do
                    local raycast_data = table.remove(pending_raycast_stack)
                    local ray_pos,is_emptyblock, select_empty, emptyrelay_dir = this_raycast(raycast_data.x,raycast_data.y, raycast_data.vector, checkblocked)
                    
                    if ray_pos then
                        local ray_unitids = {}
                        local relay_dirs = {}
                        local blocked = false
                        local is_stopping_point = true
                        local tileid = ray_pos[1] + ray_pos[2] * roomsizex

                        if not visited_tileids[tileid] then
                            visited_tileids[tileid] = true
    
                            if checkblocked and is_emptyblock then
                                blocked = true
                            elseif emptyrelay_dir then
                                local indicator_key = tileid + emptyrelay_dir * roomsizex * roomsizey
                                found_relay_indicators[indicator_key] = true
                                if relay_indicators[indicator_key] == nil and new_relay_indicators[indicator_key] == nil then
                                    new_relay_indicators[indicator_key] = make_relay_indicator(ray_pos[1], ray_pos[2], emptyrelay_dir)
                                end

                                is_stopping_point = false
                                table.insert(pending_raycast_stack, {
                                    x = ray_pos[1],
                                    y = ray_pos[2],
                                    vector = ndirs[emptyrelay_dir+1],
                                })
                            elseif select_empty then
                                local object = utils.make_object(2, ray_pos[1], ray_pos[2])
                                table.insert(ray_unitids, object)
                            else
                                local total_pass_unit_count = 0
                                local found_relay = false
                                for _, ray_unitid in ipairs(unitmap[tileid]) do
                                    local ray_unit = mmf.newObject(ray_unitid)
                                    local ray_unit_name = getname(ray_unit) -- If the unit is a text block, we want the name to be "text"
    
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
                                            total_pass_unit_count = total_pass_unit_count + 1
                                            add_to_rayunits = false
                                        else
                                            local has_pass = hasfeature(ray_unit_name, "is", "pass",ray_unitid)
                                            local has_not_pass = hasfeature(ray_unit_name, "is", "not pass",ray_unitid) 
                                            if has_pass and not has_not_pass then
                                                total_pass_unit_count = total_pass_unit_count + 1
                                                add_to_rayunits = false
                                            end
                                        end
                                    end
    
                                    if add_to_rayunits then
                                        local object = utils.make_object(ray_unitid, ray_pos[1], ray_pos[2])
                                        table.insert(ray_unitids, object)
                                    end
    
                                    -- relay logic
                                    if not blocked then
                                        if hasfeature(ray_unit_name, "is", "relay", ray_unitid) then
                                            found_relay = true
                                            relay_dirs[ray_unit.values[DIR]] = true
                                            
                                            local indicator_key = tileid + ray_unit.values[DIR] * roomsizex * roomsizey
                                            found_relay_indicators[indicator_key] = true
                                            if relay_indicators[indicator_key] == nil and new_relay_indicators[indicator_key] == nil then
                                                new_relay_indicators[indicator_key] = make_relay_indicator(ray_pos[1], ray_pos[2], ray_unit.values[DIR])
                                            end
                                        end
                                    end
                                end

    
                                if found_relay and not blocked then
                                    is_stopping_point = false
                                    for dir, _ in pairs(relay_dirs) do
                                        table.insert(pending_raycast_stack, {
                                            x = ray_pos[1],
                                            y = ray_pos[2],
                                            vector = ndirs[dir+1],
                                        })
                                    end
                                elseif checkpass and total_pass_unit_count >= #unitmap[tileid] and not blocked then
                                    is_stopping_point = false
                                    table.insert(pending_raycast_stack, {
                                        x = ray_pos[1],
                                        y = ray_pos[2],
                                        vector = raycast_data.vector,
                                    })
                                else
                                    -- Found stopping point. Keep is_stopping_point = true
                                end
                            end
                            
                            if blocked then
                                if THIS_LOGGING then
                                    print("setting blocked in update raycast", ray_pos[1], ray_pos[2])
                                end
                                set_blocked_tile(tileid)
                            end
    
                            if is_stopping_point then
                                if curr_raycast_data.raycast_positions[tileid] == nil then
                                    curr_raycast_data.raycast_positions[tileid] = ray_unitids
                                    found_raycast_pos_count = found_raycast_pos_count + 1
                                end
                            else
                                -- Note: maybe in the future there's a case where we insert back into pending_raycast_stack but we still
                                -- want to insert units into the final set of raycast units?
                                ray_unitids = {}
                            end
    
                            for _, ray_unitid in ipairs(ray_unitids) do
                                table.insert(ray_unitids_found_in_curr_cast, ray_unitid)
                            end
                        end
                    end
                end

                for _, ray_unitid in ipairs(ray_unitids_found_in_curr_cast) do
                    table.insert(all_rayunits, ray_unitid)
                end
            end

            -- Add/Update/Remove cursors based on how many raycast positions we found
            local new_positions = {}
            for tileid, _ in pairs(curr_raycast_data.raycast_positions) do
                if not curr_raycast_data.cursors[tileid] then
                    table.insert(new_positions, tileid)
                end
            end

            local tileids_to_delete = {}
            for tileid, cursor_unitid in pairs(curr_raycast_data.cursors) do
                if not curr_raycast_data.raycast_positions[tileid] then
                    table.insert(tileids_to_delete, tileid)
                    if #new_positions > 0 then
                        local new_tileid = table.remove(new_positions)
                        curr_raycast_data.cursors[new_tileid] = cursor_unitid
                    else
                        delunit(cursor_unitid)
                        MF_cleanremove(cursor_unitid)
                    end
                end
            end
            for _, tileid in ipairs(tileids_to_delete) do
                curr_raycast_data.cursors[tileid] = nil
            end
            if #new_positions > 0 then
                for _, tileid in ipairs(new_positions) do
                    local cursor_unitid = make_cursor()
                    curr_raycast_data.cursors[tileid] = cursor_unitid
                end
            end

            if affect_updatecode and updatecode == 0 then
                -- set updatecode to 1 if any of the raycast units changed
                local prev_raycast_unitids = curr_raycast_data.raycast_unitids or {}

                if #all_rayunits ~= #prev_raycast_unitids then
                    updatecode = 1
                else
                    for _, ray_object in ipairs(all_rayunits) do
                        local found_unit = false
                        for _, prev_object in ipairs(prev_raycast_unitids) do
                            if prev_object == ray_object then
                                found_unit = true
                                break
                            end
                        end

                        if not found_unit then
                            updatecode = 1
                            break
                        end
                    end
                end
            end
            if #all_rayunits == 0 then
                curr_raycast_data.raycast_unitids = nil
            else
                curr_raycast_data.raycast_unitids = all_rayunits
            end
        end
    end

    -- Updating the set of relay indicators
    if not keep_relay_indicators then
        for indicator_key, indicator in pairs(relay_indicators) do
            if not found_relay_indicators[indicator_key] then
                delunit(indicator)
                MF_cleanremove(indicator)
                relay_indicators[indicator_key] = nil
            end
        end
    end
    for indicator_key, indicator in pairs(new_relay_indicators) do 
        relay_indicators[indicator_key] = indicator
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

function get_raycast_units(this_text_unitid, checkblocked, checkpass, checkrelay)
    if is_this_unit_in_stablerule(this_text_unitid) then
        return get_stable_this_raycast_units(tonumber(this_text_unitid))
    end

    local raycast_units = raycast_data[this_text_unitid].raycast_unitids
    if raycast_units ~= nil and #raycast_units > 0 then
        if checkblocked or checkpass then
            local unitid, x, y, tileid = utils.parse_object(raycast_units[1])
            if checkblocked then
                if blocked_tiles[tileid] then
                    local dbg_str = string.format("@TODO: We called get_raycast_units with checkblocked = true. And found blocked units at (%d, %d)", x, y)
                    -- utils.debug_assert(false, dbg_str)
                    if THIS_LOGGING then
                        print(dbg_str)
                    end
                    return {}
                end
            end
            if checkpass then
                if explicit_passed_tiles[tileid] then
                    local dbg_str = string.format("@TODO: We called get_raycast_units with checkpass = true. And found passed units at (%d, %d)", x, y)
                    -- utils.debug_assert(false, dbg_str)
                    if THIS_LOGGING then
                        print(dbg_str)
                    end
                    return {}
                end
            end
            
            if checkrelay then
                if explicit_relayed_tiles[tileid] then
                    local dbg_str = string.format("@TODO: We called get_raycast_units with checkrelay = true. And found relayed units at (%d, %d)", x, y)
                    if THIS_LOGGING then
                        print(dbg_str)
                    end
                    -- utils.debug_assert(false, dbg_str)
                    return {}
                end
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

    return raycast_data[this_text_unitid].raycast_positions
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
local function get_raycast_property_units(this_text_unitid, checkblocked, checkpass, checkrelay, verb)
    if not raycast_data[this_text_unitid] then
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
        
        for curr_raycast_tileid, raycast_objects in pairs(raycast_data[curr_this_unitid].raycast_positions) do
            if checkblocked and blocked_tiles[curr_raycast_tileid] then
                -- do nothing if blocked
            elseif checkpass and explicit_passed_tiles[curr_raycast_tileid] then
                -- do nothing if the tile is explicitly passed
            elseif checkrelay and explicit_relayed_tiles[curr_raycast_tileid] then
                -- do nothing if the tile is explicitly relayed
            elseif visited_tileids[curr_raycast_tileid] then

            elseif curr_raycast_tileid then
                visited_tileids[curr_raycast_tileid] = true
                lit_up_this_texts[curr_this_unitid] = true

                for i, ray_object in ipairs(raycast_objects) do
                    local ray_unitid = utils.parse_object(ray_object)
                    if ray_unitid == 2 then
                        table.insert(out_raycast_units, ray_object)
                    else
                        local ray_unit = mmf.newObject(ray_unitid)

                        if is_name_text_this(ray_unit.strings[NAME]) then
                            table.insert(raycast_this_texts, ray_unitid)
                            table.insert(all_redirected_this_units, ray_unitid)
                        elseif is_unit_valid_this_property(ray_unitid, verb) then
                            table.insert(out_raycast_units, ray_object)
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
--@TODO: move curr_phase to before checkblocked
local function process_this_rules(this_rules, filter_property_func, checkblocked, checkpass, curr_phase, checkrelay)
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
            if this_text_unitid then
                local raycast_objects, redirected_this_units = get_raycast_property_units(this_text_unitid, checkblocked, checkpass, checkrelay, verb)
                for _, object in ipairs(raycast_objects) do
                    local unitid = utils.parse_object(object)
                    local ray_unit = mmf.newObject(unitid)
                    local rulename = ""
                    if unitid == 2 then
                        rulename = "empty"
                    else
                        rulename = ray_unit.strings[NAME]
                        if is_turning_text(rulename) then
                            rulename = get_turning_text_interpretation(unitid)
                        end
                    end

                    if filter_property_func(rulename) then
                        if rulename ~= "empty" then
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
        end

        -- Process target next
        local target_options = {}
        if not is_name_text_this(target) then
            target_options = property_options
        elseif #property_options > 0 then
            local this_text_unitid = get_target_unitid_from_rule(rules)
            if this_text_unitid then
                local this_unit_as_param_id = convert_this_unit_to_param_id(this_text_unitid)
                if target_isnot then
                    for i,mat in pairs(objectlist) do
                        if (findnoun(i) == false) then
                            for _, option in ipairs(property_options) do
                                local newrule = {i, option.rule[2], option.rule[3]}
                                local newconds = {}
                                table.insert(newconds, {"not this", {this_unit_as_param_id} })
                                for a,b in ipairs(option.conds) do
                                    table.insert(newconds, b)
                                end
                                table.insert(target_options, {rule = newrule, conds = newconds, notrule = true, showrule = false})
                            end
                        end
                    end
                    
                    -- Rule display in pause menu
                    if #target_options > 0 and filter_property_func(property) then
                        local raycast_names = {}
                        for _, ray_object in ipairs(get_raycast_units(this_text_unitid, checkblocked, checkpass, checkrelay)) do
                            local ray_unitid = utils.parse_object(ray_object)
                            local ray_unit = mmf.newObject(ray_unitid)
                            local ray_name = getname(ray_unit)

                            if raycast_names[ray_name] == nil then
                                local newrule = {ray_name, rule[2], rule[2]}
                                local newconds = {}
                                table.insert(newconds, {"not this", {this_unit_as_param_id} })
                                for a,b in ipairs(conds) do
                                    table.insert(newconds, b)
                                end
                                table.insert(visualfeatures, {newrule, newconds, ids, tags})
                            end
                        end 
                    end
                else
                    for _, ray_object in ipairs(get_raycast_units(this_text_unitid, checkblocked, checkpass, checkrelay)) do
                        local ray_unitid, _, _, ray_tileid = utils.parse_object(ray_object)
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
                            if (curr_phase == "block" or curr_phase == "pass" or curr_phase == "relay" or curr_phase == "ray-block" or curr_phase == "ray-pass" or curr_phase == "ray-relay") and #conds > 0 then
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
local function relay_filter(name)
    return name == "relay"
end
local function other_filter(name)
    return name ~= "block" and name ~= "pass"
end

function do_subrule_this()
    blocked_tiles = {}
    explicit_passed_tiles = {}
    explicit_relayed_tiles = {}

    -- Used for preventing certain this texts from updating their raycast units in later phases.
    -- This is used for this texts found in "pass" phase. 
    -- The policy is that "this is block" will apply to all this texts including the "this" in the original rule. While
    -- "this is pass" will apply to all this texts *other* than the "this" in the original rule.
    -- The idea is that "block" will be "active" in enforcing its effect while "pass" will be "passive" in doing the same thing.
    local all_processed_this_units = {}

    --[[ 
        Notes:
        - update_raycast_units considers block/pass rules in the current featureindex at that time
            - checkblocked/checkpass in update_raycast_units means whether or not to consider the existing block/pass rules in featureindex when updating rayunits
            - it also calls hasfeature to check if a unit is blocked/pass, which calls testcond, which if there is a rule with block/pass that also has THIS, would also call get_raycast_units()
        - process_this_rules
            - checkblocked/checkpass in process_this_rules is mainly a proxy for calling the same in get_raycast_units()
                - checkblocked/checkpass in get_raycast_units means whether or not to consider if the raycast position is marked as block or pass (see set_blocked_tile(), set_passed_tile())
    ]]

    if THIS_LOGGING then
        print("block phase---------")
    end
    update_raycast_units(true, true, false, {}, true) -- @TODO: not sure if I like setting the last param to true. This would rely on the update_raycast_units() call in {{mod_injections}} to clear the relay indicators
    local processed_block_this_units = process_this_rules(deferred_rules_with_this, block_filter, true, false, "block", true)

    for unit, _ in pairs(processed_block_this_units) do
        if THIS_LOGGING then
            print(utils.unitstring(unit))
        end
        all_processed_this_units[unit] = true
    end
    
    if THIS_LOGGING then
        print("relay phase---------")
    end
    update_raycast_units(true, true, false, all_processed_this_units, true)
    local processed_relay_this_units = process_this_rules(deferred_rules_with_this, relay_filter, true, false, "relay", true)
    for unit, _ in pairs(processed_relay_this_units) do
        if THIS_LOGGING then
            print(utils.unitstring(unit))
        end
        all_processed_this_units[unit] = true
    end
    
    if THIS_LOGGING then
        print("pass phase---------")
    end
    update_raycast_units(true, true, false, all_processed_this_units, true)
    local processed_pass_this_units = process_this_rules(deferred_rules_with_this, pass_filter, true, false, "pass", true)
    for unit, _ in pairs(processed_pass_this_units) do
        if THIS_LOGGING then
            print(utils.unitstring(unit))
        end
        all_processed_this_units[unit] = true
    end
    
    -- @Note (resolve before publish): - I claim that we don't need these phases since the block and pass phase above also covers "X is this(block)" and all variations. Check that this is correct
    -- print("ray-block phase")
    -- update_raycast_units(true, true, false, all_processed_this_units)
    -- local processed_block_this_units2 = process_this_rules(deferred_rules_with_this, block_filter, true, false, "ray-block")
    
    -- for unit, _ in pairs(processed_block_this_units2) do
    --     print(utils.unitstring(unit))
    --     all_processed_this_units[unit] = true
    --     processed_block_this_units[unit] = true
    -- end
    
    -- print("ray-pass phase")
    -- update_raycast_units(true, true, false, all_processed_this_units)
    -- local processed_pass_this_units2 = process_this_rules(deferred_rules_with_this, pass_filter, true, false, "ray-pass")
    -- for unit, _ in pairs(processed_pass_this_units2) do
    --     print(utils.unitstring(unit))
    --     all_processed_this_units[unit] = true
    --     processed_pass_this_units[unit] = true
    -- end

    for this_unitid, _ in pairs(processed_block_this_units) do
        for tileid, ray_objects in pairs(raycast_data[this_unitid].raycast_positions) do
            for _, ray_object in ipairs(ray_objects) do
                local ray_unitid, x, y, tileid = utils.parse_object(ray_object)
                
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
    end

    for this_unitid, _ in pairs(processed_relay_this_units) do
        for tileid, ray_objects in pairs(raycast_data[this_unitid].raycast_positions) do
            for _, ray_object in ipairs(ray_objects) do
                local ray_unitid, x, y, tileid = utils.parse_object(ray_object)
                local has_relay = false
                local has_not_relay = false
                if ray_unitid == 2 then
                    has_relay = hasfeature("empty", "is", "relay", 2, x, y)
                    has_not_relay = hasfeature("empty", "is", "not relay", 2, x, y)
                else
                    local ray_unit = mmf.newObject(ray_unitid)
                    local ray_unit_name = ray_unit.strings[NAME]
                    if ray_unit.strings[UNITTYPE] == "text" then
                        ray_unit_name = "text"
                    end
                    has_relay = hasfeature(ray_unit_name, "is", "relay", ray_unitid)
                    has_not_relay = hasfeature(ray_unit_name, "is", "not relay", ray_unitid)
                end
                
                if has_relay and not has_not_relay then
                    set_relay_tile(tileid)
                end
            end
        end
    end

    for this_unitid, _ in pairs(processed_pass_this_units) do
        for tileid, ray_objects in pairs(raycast_data[this_unitid].raycast_positions) do
            for _, ray_object in ipairs(ray_objects) do
                local ray_unitid, x, y, tileid = utils.parse_object(ray_object)
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

    if THIS_LOGGING then
        print("other phase---------")
    end
    update_raycast_units(true, true, false, all_processed_this_units, true)
    process_this_rules(deferred_rules_with_this, other_filter, true, true, "other", true)

    deferred_rules_with_this = {}
    if THIS_LOGGING then
        print("end---------")
    end
end