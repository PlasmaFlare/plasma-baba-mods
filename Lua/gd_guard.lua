table.insert(editor_objlist_order, "text_guard")

editor_objlist["text_guard"] = 
{
	name = "text_guard",
	sprite_in_root = false,
	unittype = "text",
	tags = {"plasma's mods", "text", "abstract"},
	tiling = -1,
	type = 1,
	layer = 20,
	colour = {2, 1},
    colour_active = {2, 2},
}

formatobjlist()

local guard_relation_map = {} -- <guardee name> -> list of unitids to destroy if a unit named <guardee name> is about to be destroyed
local processed_destroyed_units = {} -- list of unitids 
local units_to_guard_destroy = {}
local units_to_save = {}
local update_guards = false

local utils = plasma_utils

local GUARD_LOGGING = false

local function clear_guard_mod()
    guard_relation_map = {}
    processed_destroyed_units = {}
    units_to_guard_destroy = {}
    units_to_save = {}
    update_guards = false
end

local function make_object(unitid, x, y)
    if unitid == 2 then
        return 200 + x + y * roomsizex -- JAAAAAAANK
    elseif unitid == 1 then
        return 1
    else
        return unitid
    end
end

local function parse_object(object)
    utils.debug_assert(object)
    if object >= 200 then
        local tileid = object - 200
        local x = tileid % roomsizex
        local y = math.floor(tileid / roomsizex)
        return 2, x, y
    elseif object == 1 then
        return 1
    else
        local unit = mmf.newObject(object)
        utils.debug_assert(unit)
        return object, unit.values[XPOS], unit.values[YPOS]
    end
end

local function unitstring(object)
    local unitid, x, y = parse_object(object)
    if unitid == 1 then
        return "(Level)"
    elseif unitid == 2 then
        return string.format("(Empty at %d,%d)", x, y)
    else
        local unit = mmf.newObject(unitid)
        return string.format("(%s with id %d at %d,%d)", unit.strings[NAME], unit.values[ID], unit.values[XPOS], unit.values[YPOS])
    end
end

local function is_unit_guarded(name)
    return guard_relation_map[name] ~= nil
end

local function duptable(table)
    local newtable = {}
    for k, v in pairs(table) do
        newtable[k] = v
    end
    return newtable
end

local function get_deleted_unitid_key(object)
    local unitid, x, y = parse_object(object)
    local deleted_unitid = unitid
    if unitid == 1 then
        return nil
    elseif unitid == 2 then
        -- JANK WARNING!!! This formula is apparently how the game determines the key for marking an empty to be "deleted".
        deleted_unitid = 200 + x + y * roomsizex
    end
    return deleted_unitid
end

local function serialize_guard_feature(feature)
    return get_ruleid(feature[4], feature[1])
end

table.insert(mod_hook_functions["level_start"],
    function()
        clear_guard_mod()
        update_guards = true
        guard_checkpoint("level_start")
    end
)

table.insert(mod_hook_functions["command_given"],
    function()
        if GUARD_LOGGING then
            print("---")
        end
        guard_checkpoint("command_given")
    end
)

table.insert(mod_hook_functions["turn_end"],
    function()
        guard_checkpoint("turn_end")
    end
)

table.insert(mod_hook_functions["rule_update_after"],
    function()
        update_guards = true
    end
)

local funcs_to_ignore_guard_units = {
    [destroylevel_do] = true,
    [createall] = true,
    [ending] = true
}
-- Called on delete(). Returns true if the about-to-be-deleted unit is guarded. 
-- Used for proceeding with the regular delete() logic if the unit isn't guarded.
function handle_guard_delete_call(unitid, x, y, caller_func)
    local object = make_object(unitid, x, y)
    -- Neat trick to figure out calling function. Can't use debug.getinfo(2).name since it returns nil.
    if funcs_to_ignore_guard_units[caller_func] then
        processed_destroyed_units[object] = true
        return false
    end
    
    local is_guarded = ack_endangered_unit(object)
    if is_guarded then
        if GUARD_LOGGING then
            print("Marking a guarded unit in danger: "..unitstring(object))
        end
        return true
    elseif processed_destroyed_units[object] then
        if GUARD_LOGGING then
            print("handle_guard_delete_call: Already destroyed "..unitstring(object))
        end
        return true
    else
        if GUARD_LOGGING then
            print("Normal destroy "..unitstring(object))
        end
        processed_destroyed_units[object] = true
        return false
    end
end

function ack_unit_update_for_guard(unitid)
    update_guards = true
end

function ack_endangered_unit(object)
    local unitid, x, y = parse_object(object)
    local unitname = nil
    if unitid == 1 then
        unitname = "level"
    elseif unitid == 2 then
        unitname = "empty"
    else
        local unit = mmf.newObject(unitid)
        unitname = getname(unit)
    end
    if is_unit_guarded(unitname) then
        for unitid, _ in pairs(guard_relation_map[unitname]) do
            units_to_guard_destroy[unitid] = true
            if GUARD_LOGGING then
                print("Marking unit to destroy: ", unitstring(unitid))
            end 
        end
        units_to_save[object] = true
        return true
    else
        return false
    end
end

local function handle_guard_dels()
    for saved_object, _ in pairs(units_to_save) do
        local unitid, x, y = parse_object(saved_object)
        if unitid ~= 1 then
            local deleted_unitid = unitid
            if unitid == 2 then
                -- JANK WARNING!!! This formula is apparently how the game determines the key for marking an empty to be "deleted".
                guard_deleted_unitid = 200 + x + y * roomsizex
            end
            deleted[deleted_unitid] = nil
        end
    end
    for guard, _ in pairs(units_to_guard_destroy) do
        if not processed_destroyed_units[guard] then
            local unitid, x, y = parse_object(guard)
            if unitid == 1 then
                if not issafe(unitid) then
                    destroylevel()
                end
            else
                if GUARD_LOGGING then
                    print("- Destroying unit: ", unitstring(guard))
                end

                local unit = mmf.newObject(unitid)
        
                if not units_to_save[guard] then
                    local pmult,sound = checkeffecthistory("defeat")
                    MF_particles("destroy", x, y, 5 * pmult, 0, 3, 1, 1)
                    setsoundname("removal", 1, sound)
                end
        
                if not issafe(unitid) then
                    local deleted_unitid = get_deleted_unitid_key(guard)
                    deleted[deleted_unitid] = nil
                    delete(unitid, x, y, nil, nil, true)
                end
            end

            processed_destroyed_units[guard] = true
        else
            if GUARD_LOGGING then
                print("- Already destroyed unit: ", unitstring(guard))
            end
        end
    end
    units_to_save = {}
    processed_destroyed_units = {}
    units_to_guard_destroy = {}
end

local function recalculate_guards()
    if GUARD_LOGGING then
        print("- Recalculating guards")
    end
    guard_relation_map = {}

    local features_by_guardee = {} -- <guardee name> -> list of features with rhs equal to <guardee name>
    local names_to_resolve = {} -- set of unique guardee names found from scanning featureindex
    
    if featureindex["guard"] ~= nil then
        for _, feature in ipairs(featureindex["guard"]) do
            local guardee_name = feature[1][3]
            if not features_by_guardee[guardee_name] then
                features_by_guardee[guardee_name] = {feature}
            else
                table.insert(features_by_guardee[guardee_name], feature)
            end

            names_to_resolve[guardee_name] = true
        end
    end

    for curr_name, _ in pairs(names_to_resolve) do
        local stack = {}
        local guard_features = features_by_guardee[curr_name]
        local guard_units = {}
        if guard_features then
            for _, feature in ipairs(guard_features) do
                local guard_name = feature[1][1]
                local conds = feature[2]
                local typedata = {guard_name, conds}

                local found_branch = #findall(typedata, false, true) > 0
                if guard_name == "level" then
                    found_branch = found_branch or testcond(conds, 1)
                elseif guard_name == "empty" then
                    found_branch = found_branch or #findempty(conds, true) > 0
                end
                if found_branch then
                    table.insert(stack, {
                        feature = feature,
                        visited = {}
                    })
                end
            end
        end
    
        local visited_features = {}
        local found_guard = false
        
        while #stack > 0 do
            local entry = table.remove(stack)
            local curr_feature = entry.feature
    
            entry.visited[serialize_guard_feature(curr_feature)] = true
            
            local curr_guard_name = curr_feature[1][1]
            utils.debug_assert(curr_guard_name)
            
            local add_guard_units = false
            local added_to_stack = false
            local guard_features = features_by_guardee[curr_guard_name]
            if guard_features then
                for _, feature in ipairs(guard_features) do
                    if entry.visited[serialize_guard_feature(feature)] then
                        add_guard_units = true
                    else
                        local guard_name = feature[1][1]
                        local conds = feature[2]
                        local typedata = {guard_name, conds}

                        local found_branch = #findall(typedata, false, true) > 0
                        if guard_name == "level" then
                            found_branch = found_branch or testcond(conds, 1)
                        elseif guard_name == "empty" then
                            found_branch = found_branch or #findempty(conds, true) > 0
                        end
                        if found_branch then
                            table.insert(stack, {
                                feature = feature,
                                visited = duptable(entry.visited)
                            })
                            added_to_stack = true
                        end
                    end
                end
            end
            if not added_to_stack then
                add_guard_units = true
            end
            
            if add_guard_units then
                local conds = curr_feature[2]
                local typedata = {curr_guard_name, conds}
                for _, unitid in ipairs(findall(typedata, false, false)) do
                    found_guard = true
                    local object = make_object(unitid)
                    guard_units[object] = true
                end

                if curr_guard_name == "empty" then
                    for _, tileid in ipairs(findempty(conds, false)) do
                        found_guard = true

                        local x = tileid % roomsizex
                        local y = math.floor(tileid / roomsizex)
                        local empty_object = make_object(2, x, y)
                        guard_units[empty_object] = true
                    end
                end

                if curr_guard_name == "level" then
                    if testcond(conds, 1) then
                        found_guard = true

                        local level_object = make_object(1)
                        guard_units[level_object] = true
                    end
                end
            end
        end

        if found_guard then
            guard_relation_map[curr_name] = guard_units

            if GUARD_LOGGING then
                for unitid, _ in pairs(guard_units) do
                    print("- "..curr_name.." -> "..unitstring(unitid))
                end
            end
        end
    end
end

-- The main entrypoint for guard logic. This gets called from: start and end of turn, after code(), after handledels(), and after levelblock()
function guard_checkpoint(calling_func)
    if GUARD_LOGGING then
        print(string.format("> guard_checkpoint from %s", calling_func))
    end
    handle_guard_dels()
    
    if update_guards then
        recalculate_guards()
        update_guards = false
    end
end