this_mod_globals = {}
local function reset_this_mod_globals()
    this_mod_globals = {
        active_this_property_text = {}, -- keep track of texts 
        undoed_after_called = false, -- flag for providing a specific hook of when we call code() after an undo
    }
end   
reset_this_mod_globals()

local utils = plasma_utils

local DirTextDisplay = PlasmaModules.load_module("general/directional_text_display")
local UndoAnalyzer = PlasmaModules.load_module("general/undo_analyzer") 
local RaycastTrace = PlasmaModules.load_module("this/pnoun_raycast_trace")
local Pnoun = PlasmaModules.load_module("this/pnoun_group_defs")

local blocked_tiles = {} -- all positions where "X is block" is active
local explicit_passed_tiles = {} -- all positions pointed by a "this is pass" rule. Used for cursor display 
local explicit_relayed_tiles = {} -- all positions pointed by a "this is relay" rule. Used for cursor display 
local cond_features_with_this_noun = {} -- list of all condition rules with "this" as a noun and "block/pass" as properties. Used to check if updatecode should be set to 1 to recalculate which units are blocked/pass
local on_level_start = false
local NO_POSITION = -1
local THIS_LOGGING = false

local function set_blocked_tile(tileid)
    if tileid then
        blocked_tiles[tileid] = true
    end
end
local function set_relay_tile(tileid)
    if tileid then
        explicit_relayed_tiles[tileid] = true
    end
end
local function set_passed_tile(tileid)
    if tileid then
        explicit_passed_tiles[tileid] = true
    end
end

local Pnoun_Op_To_Explicit_Tile_Func = {
    block = set_blocked_tile,
    relay = set_relay_tile,
    pass = set_passed_tile,
}

--[[ 
    local deferred_pnoun_subrules = {
        <Pnoun_Group> = {
            pnoun_features = [<feature>, <feature>],
            pnoun_units = (<pnoun unitid>, <pnoun unitid>),
        }
    }
]]
local deferred_pnoun_subrules = {}

--[[ 
    local pnoun_subrule_data = {
        pnoun_to_groups = {
            <pnoun unitid> = <Pnoun_Group>
            ...    
        }
    }    
]]
local pnoun_subrule_data = {}

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
            
            pnoun_group = <Pnoun_Group>,
        }
    }
 ]]
local raycast_data = {}

local raycast_trace_tracker = RaycastTrace:new()

--[[ 
    local relay_indicators = {
        <tileid + dir> = <unitid of indicator>,
        <tileid + dir> = <unitid of indicator>,
        ...
    }    
]]
local relay_indicators = {}

local PointerNouns = {
    this = true,
    that = true,
    these = true,
    those = true,
}

local function reset_this_mod_locals()
    blocked_tiles = {}
    explicit_passed_tiles = {}
    explicit_relayed_tiles = {}
    cond_features_with_this_noun = {}
    raycast_data = {}
    relay_indicators = {}
    deferred_pnoun_subrules = {}
    pnoun_subrule_data = {}

    raycast_trace_tracker:clear()
    pf_undo_analyzer:reset()
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
        blocked_tiles = {}
        this_mod_globals.undoed_after_called = true
    end
)

table.insert(mod_hook_functions["rule_update"],
    function(is_this_a_repeated_update)
        this_mod_globals.active_this_property_text = {}
        blocked_tiles = {}
        explicit_passed_tiles = {}
        explicit_relayed_tiles = {}
        cond_features_with_this_noun = {}
        raycast_trace_tracker:clear()
        pnoun_subrule_data = {
            pnoun_to_groups = {},
        }
        deferred_pnoun_subrules = {}
        for pnoun_group, value in pairs(Pnoun.Groups) do
            deferred_pnoun_subrules[value] = {
                pnoun_features = {},
                pnoun_units = {},
            }
        end

        if THIS_LOGGING then
            print(">>>>>>>>>>>>>>> rule_update start")
        end
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

        pf_undo_analyzer:reset()

        if THIS_LOGGING then
            print("<<<<<<<<<<<<<< rule_update end")
        end
    end
)

table.insert( mod_hook_functions["command_given"],
    function()
        pf_undo_analyzer:reset()
    end
)
table.insert( mod_hook_functions["turn_end"],
    function()
        pf_undo_analyzer:reset()
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

    for noun, _ in pairs(PointerNouns) do
        if string.sub(name, 1, #noun) == noun then
            return noun
        end
    end
    return nil
end

local function dir_vec_to_dir_value(dir_vec)
    if dir_vec[1] > 0 and dir_vec[2] == 0 then
        return 0
    elseif dir_vec[2] < 0 and dir_vec[1] == 0 then
        return 1
    elseif dir_vec[1] < 0 and dir_vec[2] == 0 then
        return 2
    elseif dir_vec[2] > 0 and dir_vec[1] == 0 then
        return 3
    else
        return 4
    end
end

-- Determine the raycast velocity vectors, given a name of a pointer noun
local function get_rays_from_pointer_noun(name, x, y, dir, pnoun_unitid)
    local pointer_noun = is_name_text_this(name)
    local out_rays = {}

    if pointer_noun then
        local dir_vec = {dirs[dir+1][1], dirs[dir+1][2] * -1}

        if pointer_noun == "this" then
            table.insert(out_rays, {
                pos = {x, y},
                dir = dir_vec,
            })
        elseif pointer_noun == "that" then
            local cast_start_x = x
            local cast_start_y = y

            if dir == 0 then
                cast_start_x = roomsizex - 1
            elseif dir == 1 then
                cast_start_y = 0
            elseif dir == 2 then
                cast_start_x = 0
            elseif dir == 3 then
                cast_start_y = roomsizey - 1
            end
            table.insert(out_rays, {
                pos = {cast_start_x, cast_start_y},
                dir = {dir_vec[1] * -1, dir_vec[2] * -1},
            })
        elseif pointer_noun == "these" then
            table.insert(out_rays, {
                pos = {x, y},
                dir = dir_vec,
            })
        elseif pointer_noun == "those" then
            table.insert(out_rays, {
                pos = {x, y},
                dir = dir_vec,
            })
        end
    end

    return out_rays
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
    local baserule = rule[1]
    local target = baserule[1]
    local property = baserule[3]
    
    local target_is_pnoun = is_name_text_this(target) or is_name_text_this(target, true)
    local property_is_pnoun = is_name_text_this(property) or is_name_text_this(property, true)

    local pnoun_group = nil
    if target_is_pnoun and not property_is_pnoun then
        if property == "block" then
            pnoun_group = Pnoun.Groups.THIS_IS_BLOCK
        elseif property == "relay" then
            pnoun_group = Pnoun.Groups.THIS_IS_RELAY
        elseif property == "pass" then
            pnoun_group = Pnoun.Groups.THIS_IS_PASS
        end
    elseif property_is_pnoun then
        if target_is_pnoun then
            pnoun_group = Pnoun.Groups.THIS_IS_VAR
        else
            pnoun_group = Pnoun.Groups.X_IS_VAR
        end
    end
    
    if pnoun_group == nil then
        pnoun_group = Pnoun.Groups.OTHER_ACTIVE
    end
    
    -- A pnoun feature can only be in one pnoun group. There is no need to check for priority since
    -- each pnoun group is meant to be mutually exclusive in terms of features.
    table.insert(deferred_pnoun_subrules[pnoun_group].pnoun_features, rule)

    local pnouns_to_add = {}

    if target_is_pnoun then
        local target_this_unitid = get_target_unitid_from_rule(rule)
        table.insert(pnouns_to_add, target_this_unitid)
    end
    if property_is_pnoun then
        local property_this_unitid = get_property_unitid_from_rule(rule)
        table.insert(pnouns_to_add, property_this_unitid)
    end

    -- A pnoun unit can only belong to one pnoun group. If a pnoun can be categorized into two
    -- groups, only go for the group with the higher priority.
    for _, pnoun in ipairs(pnouns_to_add) do
        local prev_pnoun_group = pnoun_subrule_data.pnoun_to_groups[pnoun]

        if prev_pnoun_group ~= nil and pnoun_group < prev_pnoun_group then
            -- Replace with the pnoun group with the higher priority
            deferred_pnoun_subrules[prev_pnoun_group].pnoun_units[pnoun] = nil
            deferred_pnoun_subrules[pnoun_group].pnoun_units[pnoun] = true
            pnoun_subrule_data.pnoun_to_groups[pnoun] = pnoun_group
        elseif prev_pnoun_group == nil then
            -- Assign the pnoun group to the pnoun unit
            deferred_pnoun_subrules[pnoun_group].pnoun_units[pnoun] = true
            pnoun_subrule_data.pnoun_to_groups[pnoun] = pnoun_group
        end
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
                cursorunit.visible = false
            end
            cursorunit.scaleX = generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
            cursorunit.scaleY = generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
            
            if (generaldata.values[DISABLEPARTICLES] ~= 0 or generaldata5.values[LEVEL_DISABLEPARTICLES] ~= 0) then
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
    unit.values[ZLAYER] = 29

    MF_setcolour(unitid,5,4)
    
    return unitid
end

local function this_raycast(ray, checkemptyblock, raycast_trace, curr_cast_extradata)
    -- return values: ray_pos, is_emptyblock, select_empty, emptyrelay_dir
    local ox = ray.pos[1] + ray.dir[1]
    local oy = ray.pos[2] + ray.dir[2]
    while inbounds(ox,oy,1) do
        local tileid = ox + oy * roomsizex
        raycast_trace:add_tileid(tileid)

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

        if curr_cast_extradata.flood_fill_mode then
            break
        else
            ox = ox + ray.dir[1]
            oy = oy + ray.dir[2]
        end
    end

    return nil
end

local function make_relay_indicator_key(tileid, dir)
    return tileid + dir * roomsizex * roomsizey
end

function simulate_raycast_with_pnoun(pnoun_unitid, raycast_settings)
    --[[ 
        return value: {
            <tileid> = [<object>, <object>]
            ...
        }
     ]]
    local pointer_unit = mmf.newObject(pnoun_unitid)
    local pointer_noun = is_name_text_this(pointer_unit.strings[NAME])
    local rays = get_rays_from_pointer_noun(pointer_unit.strings[NAME], pointer_unit.values[XPOS], pointer_unit.values[YPOS], pointer_unit.values[DIR], pnoun_unitid)
    local ray_objects_by_tileid = {}
    local found_relay_indicators = {} -- indicator ids -> true
    local found_blocked_tiles = {}
    local found_ending_these_texts = {}
    local raycast_trace = RaycastTrace:new()

    local all_block = false
    local all_pass = false
    local all_relay = false
    if raycast_settings.checkblocked then
        all_block = findfeature("all", "is", "block") ~= nil
    end
    if raycast_settings.checkrelay then
        all_relay = findfeature("all", "is", "relay") ~= nil
    end
    if raycast_settings.checkpass then
        all_pass = findfeature("all", "is", "pass") ~= nil
    end

    for i, ray in ipairs(rays) do
        local stack = {
            {
                ray = ray, 
                extradata = {
                    these_ray_objects_by_tileid = {},
                    flood_fill_mode = false,
                    flood_fill_object_names = nil,
                    flood_fill_object_name_count = 0
                }
            } 
        }
        local visited_tileids = {}

        while #stack > 0 do
            local curr_cast_data = table.remove(stack)
            
            local ray_pos, is_emptyblock, select_empty, emptyrelay_dir = this_raycast(curr_cast_data.ray, raycast_settings.checkblocked, raycast_trace, curr_cast_data.extradata)
            if not ray_pos then
                -- Do nothing for now
            elseif pointer_noun == "that" and ray_pos[1] == pointer_unit.values[XPOS] and ray_pos[2] == pointer_unit.values[YPOS] then
                -- Do nothing. THAT cannot refer to itself
            else
                local blocked = false
                local new_relay_indicators = {}
                local new_stack_entries = {}
                local ray_objects = {}
                local tileid = ray_pos[1] + ray_pos[2] * roomsizex
                local found_ending_these = false
                local found_flood_fill_object = false

                if pointer_noun == "these" then
                    -- If we found another THESE pointing in the opposite direction, terminate early
                    for _, ray_unitid in ipairs(unitmap[tileid]) do
                        local ray_unit = mmf.newObject(ray_unitid)
                        if ray_unit.strings[NAME] == "these" and ray_unitid ~= pnoun_unitid then
                            local ray_dir_value = dir_vec_to_dir_value(curr_cast_data.ray.dir)
                            if rotate(ray_dir_value) == ray_unit.values[DIR] then
                                found_ending_these_texts[ray_unitid] = true
                                found_ending_these = true
                            end
                        end
                    end
                end

                if not visited_tileids[tileid] and not found_ending_these then
                    visited_tileids[tileid] = true
                    
                    if raycast_settings.checkblocked and is_emptyblock then
                        blocked = true
                    elseif emptyrelay_dir then
                        local indicator_key = make_relay_indicator_key(tileid, emptyrelay_dir)
                        new_relay_indicators[indicator_key] = {
                            x = ray_pos[1],
                            y = ray_pos[2],
                            dir = emptyrelay_dir
                        }
                        
                        for _, ray in ipairs(get_rays_from_pointer_noun(pointer_noun, ray_pos[1], ray_pos[2], emptyrelay_dir)) do
                            table.insert(new_stack_entries, {ray = ray, extradata = curr_cast_data.extradata})
                        end
                    elseif select_empty then
                        local add_to_rayunits = true
                        if pointer_noun == "those" and curr_cast_data.extradata.flood_fill_mode then
                            -- If we are in flood fill mode, only add units of the same type
                            if curr_cast_data.extradata.flood_fill_object_names["empty"] then
                                found_flood_fill_object = true
                            else
                                add_to_rayunits = false
                            end
                        end

                        if add_to_rayunits then
                            local object = utils.make_object(2, ray_pos[1], ray_pos[2])
                            table.insert(ray_objects, object)
                        end
                    else
                        local total_pass_unit_count = 0
                        local found_relay = false
                        local relay_dirs = {}

                        -- Check through every unit in the specific space
                        for _, ray_unitid in ipairs(unitmap[tileid]) do
                            local ray_unit = mmf.newObject(ray_unitid)
                            local ray_unit_name = getname(ray_unit) -- If the unit is a text block, we want the name to be "text"
                            local add_to_rayunits = true

                            -- block logic
                            if raycast_settings.checkblocked then
                                if all_block and ray_unit_name ~= "text" and ray_unit_name ~= "empty" then
                                    blocked = true
                                elseif hasfeature(ray_unit_name, "is", "block",ray_unitid) and not hasfeature(ray_unit_name, "is", "not block",ray_unitid) then
                                    blocked = true
                                end

                                if blocked then
                                    break
                                end
                            end

                            -- relay logic
                            if raycast_settings.checkrelay and not blocked then
                                if all_relay or hasfeature(ray_unit_name, "is", "relay", ray_unitid) then
                                    found_relay = true
                                    add_to_rayunits = false
                                    relay_dirs[ray_unit.values[DIR]] = true
                                    
                                    local indicator_key = make_relay_indicator_key(tileid, ray_unit.values[DIR])
                                    new_relay_indicators[indicator_key] = {
                                        x = ray_pos[1],
                                        y = ray_pos[2],
                                        dir = ray_unit.values[DIR]
                                    }
                                end
                            end

                            -- pass logic
                            if raycast_settings.checkpass and not blocked then
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

                            if pointer_noun == "those" and not blocked and curr_cast_data.extradata.flood_fill_mode and add_to_rayunits then
                                -- If we are in flood fill mode, only add units of the same type
                                if curr_cast_data.extradata.flood_fill_object_names[ray_unit_name] then
                                    found_flood_fill_object = true
                                else
                                    add_to_rayunits = false
                                end
                            end

                            if add_to_rayunits then
                                local object = utils.make_object(ray_unitid, ray_pos[1], ray_pos[2])
                                table.insert(ray_objects, object)
                            end
                        end

                        -- Consolidate findings from scanning all units in a single position.
                        if not blocked then
                            if found_relay then
                                for dir, _ in pairs(relay_dirs) do
                                    for _, ray in ipairs(get_rays_from_pointer_noun(pointer_noun, ray_pos[1], ray_pos[2], dir)) do
                                        table.insert(new_stack_entries, {ray = ray, extradata = curr_cast_data.extradata})
                                    end
                                end
                            elseif raycast_settings.checkpass and total_pass_unit_count >= #unitmap[tileid] then
                                if curr_cast_data.extradata.flood_fill_mode and not found_flood_fill_object then
                                    -- When we are in flood fill mode, if all the units in the tile are pass, do not re-reycast
                                else
                                    local new_ray = {pos = ray_pos, dir = curr_cast_data.ray.dir}
                                    table.insert(new_stack_entries, {ray = new_ray, extradata = curr_cast_data.extradata})
                                end
                            end
                        end
                    end
                end

                if found_ending_these then
                    for tileid, ray_objects in pairs(curr_cast_data.extradata.these_ray_objects_by_tileid) do
                        if ray_objects_by_tileid[tileid] == nil then
                            ray_objects_by_tileid[tileid] = ray_objects
                        end
                    end
                elseif blocked then
                    found_blocked_tiles[tileid] = true

                    local add_block_cursor = true
                    if curr_cast_data.extradata.flood_fill_mode and not found_flood_fill_object then
                        add_block_cursor = false
                    end

                    if add_block_cursor then
                        ray_objects_by_tileid[tileid] = {}
                    end
                    -- If we find that the current tileid has a blocked unit, don't submit anything
                elseif #new_stack_entries > 0 then
                    -- If we inserted into the stack, we intend to re-raycast. Don't submit the found ray objects.
                    for _, stack_entry in ipairs(new_stack_entries) do
                        table.insert(stack, stack_entry)
                    end
    
                    -- Do submit any relay indicators if we found any.
                    for indicator_key, data in pairs(new_relay_indicators) do
                        found_relay_indicators[indicator_key] = data
                    end
                else
                    -- At this point, we found a stopping point with valid ray objects.
                    if pointer_noun == "these" then
                        local new_extradata = curr_cast_data.extradata
                        if new_extradata.these_ray_objects_by_tileid[tileid] == nil then
                            new_extradata.these_ray_objects_by_tileid[tileid] = ray_objects
                        end

                        local new_ray = {pos = ray_pos, dir = curr_cast_data.ray.dir}
                        table.insert(stack, {ray = new_ray, extradata = new_extradata})
                    elseif pointer_noun == "those" and curr_cast_data.extradata.flood_fill_mode and not found_flood_fill_object then
                    else
                        if ray_objects_by_tileid[tileid] == nil then
                            -- @NOTE: for now we are assuming one cursor per cast (excluding relays). If there's a need
                            -- to distinguish between two cursors, and they both land on the same tileid, then we would
                            -- need to store this set of ray objects multiple times
                            ray_objects_by_tileid[tileid] = ray_objects
                        end
                    end
                    for indicator_key in pairs(new_relay_indicators) do
                        found_relay_indicators[indicator_key] = data
                    end

                    if pointer_noun == "those" then
                        if curr_cast_data.extradata.flood_fill_mode == false or (curr_cast_data.extradata.flood_fill_mode and found_flood_fill_object) then
                            local ray_names = {}
                            local ray_name_count = 0
                            for _, ray_object in ipairs(ray_objects) do
                                local unitid = utils.parse_object(ray_object)
                                local ray_name = ""
                                if unitid == 2 then
                                    ray_name = "empty"
                                else
                                    local unit = mmf.newObject(unitid)
                                    ray_name = getname(unit)
                                end

                                if ray_names[ray_name] == nil then
                                    ray_names[ray_name] = true
                                    ray_name_count = ray_name_count + 1
                                end
                            end

                            local insert_front = ray_name_count < curr_cast_data.extradata.flood_fill_object_name_count

                            for i = 0, 3 do
                                local new_dir = dirs[i+1]

                                -- Ensure that we are not raycasting in the direction that we just came
                                if (-new_dir[1] ~= curr_cast_data.ray.dir[1]) or (-new_dir[2] ~= curr_cast_data.ray.dir[2]) then
                                    local new_ray = {pos = ray_pos, dir = new_dir}

                                    local new_extradata = utils.deep_copy_table(curr_cast_data.extradata)
                                    new_extradata.flood_fill_mode = true
                                    new_extradata.flood_fill_object_names = ray_names
                                    new_extradata.flood_fill_object_name_count = ray_name_count

                                    if insert_front then
                                        table.insert(stack, 1, {ray = new_ray, extradata = new_extradata})
                                    else
                                        table.insert(stack, {ray = new_ray, extradata = new_extradata})
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local extra_raycast_data = {
        found_relay_indicators = found_relay_indicators, 
        found_blocked_tiles = found_blocked_tiles,
        found_ending_these_texts = found_ending_these_texts,
    }

    return ray_objects_by_tileid, extra_raycast_data, raycast_trace
end

function check_updatecode_status_from_raycasting()
    --@TODO: check changes to block/pass/relay
    for tileid in pairs(pf_undo_analyzer.tileids_updated) do
        if raycast_trace_tracker:is_tileid_recorded(tileid) then
            return true
        end
    end
    return false
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
        if checkblocked or checkpass or checkrelay then
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

condlist["this"] = function(params,checkedconds,checkedconds_,cdata)
    if #params == 1 then
        valid = true
        local unitid = cdata.unitid
        local this_text_unitid = parse_this_unit_from_param_id(params[1])
        
        local pass = false
        -- @TODO: @mods(this) deciding on when to check block and/or pass when calling get_raycast_units() is currently janky. It depends on 
        -- whether or not do_subrule_this() is being called and weird update order shennanigans somehow makes this all work out
        -- in the end. Clean this up when we revisit THIS mod.
        -- @Note - I set the checkblocked param of get_raycast_units to false. Is this incorrect? 
        --   - update: believe it of not, I think it is actually correct. I think its because of the revamp to do_subrule_this() that made the
        --   order of operations more deterministic and orderly. Still, look into this later
        for _, ray_object in ipairs(get_raycast_units(this_text_unitid, false, false, false)) do
            local ray_unit, _, _, ray_tileid = plasma_utils.parse_object(ray_object)
            if ray_unit == 2 then
                local tileid = x + y * roomsizex
                if ray_tileid == tileid then
                    return true, checkedconds
                end
            elseif ray_unit == unitid then
                return true, checkedconds
            end
        end
    end
    return false, checkedconds
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

local function populate_inactive_pnouns()
    local active_pnouns = {}
    for pnoun_group, data in pairs(deferred_pnoun_subrules) do
        for pnoun_unitid in pairs(data.pnoun_units) do
            active_pnouns[pnoun_unitid] = true
        end
    end

    local inactive_pnoun_group = deferred_pnoun_subrules[Pnoun.Groups.OTHER_INACTIVE]
    for pnoun_unitid, _ in pairs(raycast_data) do
        if not active_pnouns[pnoun_unitid] then
            inactive_pnoun_group.pnoun_units[pnoun_unitid] = true
        end
    end
end

local function mark_explicit_raycast_tileids(pnoun_units, property, valid_marked_tile_func_handler)
    --@TODO(verify) - when calling this, we need to have "transparency mode" enabled, meaning that we dont set checkblocked/checkpass etc to true
    -- this is what causes "THIS is pass" to not show the indicator
    for pnoun_unitid in pairs(pnoun_units) do
        for tileid, ray_objects in pairs(raycast_data[pnoun_unitid].raycast_positions) do
            local x, y = utils.coords_from_tileid(tileid)
            for _, ray_object in ipairs(ray_objects) do
                local ray_unitid = utils.parse_object(ray_object)
                
                local has_prop = false
                local has_not_prop = false
                if ray_unitid == 2 then
                    has_prop = hasfeature("empty", "is", property, 2, x, y)
                    has_not_prop = hasfeature("empty", "is", "not "..property, 2, x, y)
                else
                    local ray_unit = mmf.newObject(ray_unitid)
                    local ray_unit_name = ray_unit.strings[NAME]
                    if ray_unit.strings[UNITTYPE] == "text" then
                        ray_unit_name = "text"
                    end
                    has_prop = hasfeature(ray_unit_name, "is", property, ray_unitid)
                    has_not_prop = hasfeature(ray_unit_name, "is", "not "..property, ray_unitid)
                end
                
                if has_prop and not has_not_prop then
                    valid_marked_tile_func_handler(tileid)
                    break
                end    
            end
        end
    end
end

local function process_pnoun_features(pnoun_features, pnoun_units, filter_property_func, curr_pnoun_op)
    local final_options = {}
    local this_noun_cond_options_list = {}
    local processed_pnouns = {}
    local all_redirected_this_units = {}

    for i=#pnoun_features,1,-1 do
        rules = pnoun_features[i]
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
                local raycast_objects, redirected_this_units = get_raycast_property_units(this_text_unitid, true, true, true, verb)
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
                        local ray_names = {}
                        for _, ray_object in ipairs(get_raycast_units(this_text_unitid, true, true, true)) do
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

                            ray_names[ray_name] = true
                        end
                        for ray_name in pairs(ray_names) do
                            local newrule = {ray_name, rule[2], rule[3]}
                            local newconds = {}
                            table.insert(newconds, {"not this", {this_unit_as_param_id} })
                            for a,b in ipairs(conds) do
                                table.insert(newconds, b)
                            end
                            table.insert(visualfeatures, {newrule, newconds, ids, tags})
                        end 
                    end
                else
                    local ray_names = {}
                    for _, ray_object in ipairs(get_raycast_units(this_text_unitid, true, true, true)) do
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

                        ray_names[ray_name] = true
                    end
                    for ray_name in pairs(ray_names) do
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
                            -- @TODO - check on this to see it makes sense
                            if (curr_pnoun_op ~= "other") and #conds > 0 then
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
                    processed_pnouns[id[1]] = true
                end
            end
            for _, unitid in ipairs(all_redirected_this_units) do
                processed_pnouns[unitid] = true
            end

            table.remove(pnoun_features, i)
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

    for pnoun in pairs(processed_pnouns) do
        pnoun_units[pnoun] = nil
    end

    return processed_pnouns, pnoun_units, pnoun_features
end

-- Starting point where all pnoun processing is. This is like what grouprules() is to all group processing.
function do_subrule_pnouns()
    populate_inactive_pnouns()

    local raycast_settings = {
        checkblocked = true,
        checkrelay = true,
        checkpass = true,
    }
    local all_found_relay_indicators = {}
    local new_relay_indicators = {}
    for pnoun_group, data in ipairs(deferred_pnoun_subrules) do
        if THIS_LOGGING then
            print("------ Processing Pnoun Group "..pnoun_group.." ------")
        end
        for _, op in ipairs(Pnoun.Pnoun_Group_Lookup[pnoun_group].ops) do
            if THIS_LOGGING then
                print(" > New filter ")
            end

            local found_these_ending_texts = {}
            
            -- Main action 1: Update the raycast units for each pnoun
            for pnoun_unitid in pairs(data.pnoun_units) do
                if THIS_LOGGING then
                    print("-> Updating raycast units of "..utils.real_unitstring(pnoun_unitid))
                end

                local curr_raycast_data = raycast_data[pnoun_unitid]
                local raycast_objects_by_tileid, extradata, raycast_trace = simulate_raycast_with_pnoun(pnoun_unitid, raycast_settings)

                local raycast_objects = {}
                local raycast_objects_dict = {}
                for tileid, ray_objects in pairs(raycast_objects_by_tileid) do
                    for _, ray_object in ipairs(ray_objects) do
                        if not raycast_objects_dict[ray_object] then
                            raycast_objects_dict[ray_object] = true
                            table.insert(raycast_objects, ray_object)
                        end
                    end
                end

                for indicator_key, data in pairs(extradata.found_relay_indicators) do
                    all_found_relay_indicators[indicator_key] = true
                    if relay_indicators[indicator_key] == nil and new_relay_indicators[indicator_key] == nil then
                        new_relay_indicators[indicator_key] = make_relay_indicator(data.x, data.y, data.dir)
                    end
                end

                for tileid in pairs(extradata.found_blocked_tiles) do
                    set_blocked_tile(tileid)
                end

                raycast_trace_tracker:add_traces(raycast_trace)

                if pnoun_group ~= Pnoun.Groups.OTHER_INACTIVE then
                    for these_unitid in pairs(extradata.found_ending_these_texts) do
                        this_mod_globals.active_this_property_text[these_unitid] = true
                    end
                end

                curr_raycast_data.raycast_unitids = raycast_objects
                curr_raycast_data.raycast_positions = raycast_objects_by_tileid


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
            end

            if THIS_LOGGING then
                print("-> Processing pnoun features: ")
                for _, feature in ipairs(data.pnoun_features) do
                    print("- "..utils.serialize_feature(feature))
                end
                print("________________")
            end

            -- Main action 2: Evaluate and submit all pnoun features under this current pnoun group
            local processed_pnoun_units, remaining_pnoun_units, remaining_pnoun_features = process_pnoun_features(data.pnoun_features, data.pnoun_units, Pnoun.Ops[op].filter_func, op)

            if THIS_LOGGING then
                print("-> Processed pnoun units: ")
                for pnoun_unit in pairs(processed_pnoun_units) do
                    print("- "..utils.real_unitstring(pnoun_unit))
                end
                print("________________")
                print("-> Remaining pnoun units: ")
                for pnoun_unit in pairs(remaining_pnoun_units) do
                    print("- "..utils.real_unitstring(pnoun_unit))
                end
                print("________________")
                print("-> Remaining pnoun features: ")
                for _, feature in ipairs(remaining_pnoun_features) do
                    print("- "..utils.serialize_feature(feature))
                end
                print("________________")
            end

            data.pnoun_units = remaining_pnoun_units
            data.pnoun_features = remaining_pnoun_features

            -- mark explicit tiles
            local explicit_tile_func = Pnoun_Op_To_Explicit_Tile_Func[op]
            if explicit_tile_func ~= nil then
                mark_explicit_raycast_tileids(processed_pnoun_units, op, explicit_tile_func)
            end
        end

        -- If there are still features to process and pnoun units to update, add both of those to the redirected pnoun group (if defined)
        -- Otherwise, throw them away
        local redirected_pnoun_group = Pnoun.Pnoun_Group_Lookup[pnoun_group].redirect_pnoun_group
        if redirected_pnoun_group ~= nil then
            for _, pnoun_feature in ipairs(data.pnoun_features) do
                table.insert(deferred_pnoun_subrules[redirected_pnoun_group].pnoun_features, pnoun_feature)
            end
            for pnoun_unit in pairs(data.pnoun_units) do
                deferred_pnoun_subrules[redirected_pnoun_group].pnoun_units[pnoun_unit] = true
            end
        else
            if THIS_LOGGING then
                -- Purely for error checking purposes
                if #deferred_pnoun_subrules[pnoun_group].pnoun_features ~= 0 then
                    local err_str = "Reached end of processsing Pnoun Group "..tostring(pnoun_group).." but there are still features left that we are throwing out!\nList of features: "

                    local feature_list = {}
                    for _, feature in ipairs(deferred_pnoun_subrules[pnoun_group].pnoun_features) do
                        feature_list[#feature_list + 1] = utils.serialize_feature(feature)
                    end

                    print(err_str..table.concat(feature_list))
                end

                local discarded_pnoun_units = {}
                local err_str = "Reached end of processsing Pnoun Group "..tostring(pnoun_group).." but there are still pnoun units left that we are throwing out!\nList of pnoun units: "
                for pnoun_unit in pairs(deferred_pnoun_subrules[pnoun_group].pnoun_units) do
                    found_pnoun = true
                    for pnoun_unit in pairs(data.pnoun_units) do
                        discarded_pnoun_units[#discarded_pnoun_units + 1] = utils.real_unitstring(pnoun_unit)
                    end 
                end
                if #discarded_pnoun_units > 0 then
                    print(err_str..table.concat(discarded_pnoun_units))
                end
            end
        end
    end


    -- Updating the set of relay indicators
    for indicator_key, indicator in pairs(relay_indicators) do
        if not all_found_relay_indicators[indicator_key] then
            delunit(indicator)
            MF_cleanremove(indicator)
            relay_indicators[indicator_key] = nil
        end
    end
    for indicator_key, indicator in pairs(new_relay_indicators) do 
        relay_indicators[indicator_key] = indicator
    end
end