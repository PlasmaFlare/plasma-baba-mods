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

local COND_CATEGORIES = {
    existence = { -- if these conditions exist, check when the appropriate unit exists (addundo({"create"}) or addundo({"delete"}))
        without= {check = "condparam"},
    },
    features = { -- if you have these conditions, check when featureindex gets updated ("rule_update_after" modhook)
        powered=true, -- note: special case for powered since there are now multiple powers and the condtype is "powered<some string>". So we need a special case to handle that
        feeling=true
    },
    update = { -- if these conditions exist, check on addundo({"update"})
        lonely= {check= "target"},
        this=true,
        stable=true   
    },
    onturnstart = { -- if these conditions exist, always recalculate guard units at command_given
        seldom=true,
        often=true,
        idle=true
    },
    ignore = { -- exclude these conditions when considering to recalculate guard units 
        never=true
    },

    --[[ 
        - If #conds == 0, then check based on addundo({"create"}) or addundo({"delete"})
        - If #conds > 0, but it only consists of conds in the "ignore" category, do not recalculate guards at all
        - If a condtype is not found here, but has parameters, check based on addundo({"update"})
        - Otherwise, always recalculate guards on every guard checkpoint

        - if at any point featureindex gets updated, then recalculate guards. (This will make the "features" category seem obsolete, but it still counts as a nontrivial condition)
    ]]
}

local guard_relation_map = {} -- <guardee name> -> list of unitids to destroy if a unit named <guardee name> is about to be destroyed
local processed_destroyed_units = {} -- list of objects which we already handled delete()-ing of, whether normally or through guards
local units_to_guard_destroy = {} -- list of objects that we marked for guard destroys on handle_guard_dels()
local units_to_save = {} -- list of objects that we marked to set deleted[unitid] = nil on between guard checkpoints
local update_guards = false -- when set to true during a turn, guard_checkpoint() calls recalculate_guards().
local too_complex_guard = false

-- List of objects that were saved by a guard unit during a turn. Saved units cannot be normal destroyed until the end of the turn.
-- This implements what I call the "pin cushion effect", where a guard unit would take the blow for all direct hits.
-- Note: Saved units can still be destroyed from guarding other units
local all_saved_units = {}

local enable_guard_chaining = not get_toggle_setting("disable_guard_chain") 

local utils = plasma_utils

local GUARD_LOGGING = true
local GUARD_ALG_LOGGING = true

local function clear_guard_mod()
    guard_relation_map = {}
    processed_destroyed_units = {}
    units_to_guard_destroy = {}
    units_to_save = {}
    update_guards = false
    too_complex_guard = false
end

local function is_unit_guarded(name)
    return guard_relation_map[name] ~= nil
end

local function add_guard_units(name)
    return guard_relation_map[name]
end

local function serialize_guard_feature(feature)
    -- print(serialized)
    return utils.serialize_feature(feature)
    -- local test = get_ruleid(feature[3], feature[1])
    -- print(test)
    -- return test
end

table.insert(mod_hook_functions["level_start"],
    function()
        clear_guard_mod()
        enable_guard_chaining = not get_toggle_setting("disable_guard_chain")

        update_guards = true -- On start, set up guard_relation_map
        guard_checkpoint("level_start")
    end
)

table.insert(mod_hook_functions["command_given"],
    function()
        if GUARD_LOGGING then
            print("---")
        end
        clear_guard_mod()
        guard_checkpoint("command_given")
        all_saved_units = {}
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

-- A special list of functions to forcibly ignore guard logic, due to special cases
local funcs_to_ignore_guard_units = {
    [destroylevel_do] = true,
    [createall] = true,
    [ending] = true
}
-- Called on delete(). Returns true if the about-to-be-deleted unit is guarded. 
-- Used for proceeding with the regular delete() logic if the unit isn't guarded.
function handle_guard_delete_call(unitid, x, y, caller_func)
    local object = utils.make_object(unitid, x, y)
    -- Neat trick to figure out calling function. Can't use debug.getinfo(2).name since it returns nil.
    if funcs_to_ignore_guard_units[caller_func] then
        processed_destroyed_units[object] = true
        return false
    end
    
    local is_guarded = ack_endangered_unit(object)
    if is_guarded then
        if GUARD_LOGGING then
            print("Endangered unit is guarded: "..utils.unitstring(object))
        end
        return true
    elseif processed_destroyed_units[object] then
        if GUARD_LOGGING then
            print("handle_guard_delete_call: Already destroyed "..utils.unitstring(object))
        end
        return true
    else
        if GUARD_LOGGING then
            print("Normal destroy "..utils.unitstring(object))
        end
        processed_destroyed_units[object] = true
        return false
    end
end

function ack_unit_update_for_guard(unitid)
    update_guards = true
end

function ack_endangered_unit(object)
    if all_saved_units[object] then
        if GUARD_LOGGING then
            print("Endangered unit is already saved: ", utils.unitstring(object))
        end 
        return true
    end
    local unitid, x, y = utils.parse_object(object)
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
        for unitid, _ in pairs(add_guard_units(unitname)) do
            units_to_guard_destroy[unitid] = true
            if GUARD_LOGGING then
                print("Marking guard unit to destroy: ", utils.unitstring(unitid))
            end 
        end
        units_to_save[object] = true
        return true
    else
        return false
    end
end

-- Destroys all marked objects from units_to_guard_destroy, if not already deleted
local function handle_guard_dels()
    for saved_object, _ in pairs(units_to_save) do
        local unitid, x, y = utils.parse_object(saved_object)
        if unitid ~= 1 then
            local deleted_unitid = utils.get_deleted_unitid_key(saved_object)
            deleted[deleted_unitid] = nil
        end

        all_saved_units[saved_object] = true
    end
    for guard, _ in pairs(units_to_guard_destroy) do
        if not processed_destroyed_units[guard] then
            local unitid, x, y = utils.parse_object(guard)
            if unitid == 1 then
                if not issafe(unitid) then
                    destroylevel()
                end
            else
                if GUARD_LOGGING then
                    print("- Destroying unit: ", utils.unitstring(guard))
                end

                local unit = mmf.newObject(unitid)
        
                if not units_to_save[guard] then
                    local pmult,sound = checkeffecthistory("defeat")
                    MF_particles("destroy", x, y, 5 * pmult, 0, 3, 1, 1)
                    setsoundname("removal", 1, sound)
                end
        
                if not issafe(unitid) then
                    local deleted_unitid = utils.get_deleted_unitid_key(guard)
                    deleted[deleted_unitid] = nil
                    delete(unitid, x, y, nil, nil, true)
                end
            end

            processed_destroyed_units[guard] = true
        else
            if GUARD_LOGGING then
                print("- Already destroyed unit: ", utils.unitstring(guard))
            end
        end
    end
    units_to_save = {}
    processed_destroyed_units = {}
    units_to_guard_destroy = {}
end

local function get_table_value(table, key)
    if not table[key] then
        table[key] = {}
    end
    return table[key]
end

local function make_typedata(feature)
    return {feature[1][1], feature[2]}
end

local function found_units_for_feature(feature)
    local name = feature[1][1]
    local conds = feature[2]
    local typedata = {name, conds}
    
    local found_units = #findall(typedata, false, true) > 0
    if not found_units then
        if name == "level" then
            found_units = testcond(conds, 1)
        elseif name == "empty" then
            found_units = #findempty(conds, true) > 0
        end
    end

    return found_units
end

local function found_units_for_typedata(typedata)
    local guard_name = typedata[1]
    
    local found_units = false
    if guard_name == "empty" then
        found_units = #findempty(conds, true) > 0
    else
        found_units = #findall(typedata, false, true) > 0
        if not found_units then
            if name == "level" then
                found_units = testcond(conds, 1)
            end
        end
    end

    return found_units
end

local function print_scc(scc)
    local v = {}
    for _, vertex in ipairs(scc) do
        table.insert(v, vertex.typedata_hash)
    end

    return string.format("{%s}", table.concat(v, " | "))
end

-- Recalculates guard_relation_map, accounting guard chaining into its logic
-- local function recalculate_guards()
--     if GUARD_LOGGING then
--         print("- Recalculating guards")
--     end
--     guard_relation_map = {}

--     local features_by_guardee = {} -- <guardee name> -> list of features with rhs equal to <guardee name>
--     local names_to_resolve = {} -- set of unique guardee names found from scanning featureindex

--     -- Populate features_by_guardee
--     if featureindex["guard"] ~= nil then
--         for _, feature in ipairs(featureindex["guard"]) do
--             if feature[1][3] ~= "all" and feature[1][1] ~= "all" then
--                 local guardee_name = feature[1][3]
--                 if string.sub(guardee_name, 1, 4) ~= "not " then
--                     local vertexlist = get_table_value(features_by_guardee, guardee_name)
--                     table.insert(features_by_guardee[guardee_name], feature)
                    
--                     names_to_resolve[guardee_name] = true
--                 end
--             end
--         end
--     end

--     local calculated_guard_units = {} -- serialized typedata -> list of guard units, used for saving results of findall() calls
--     local resolved_names = {} -- set of guardee names who's set of guard units was calculated. Used for skipping parts of the below for loop

--     for curr_name, _ in pairs(names_to_resolve) do
--         if resolved_names[curr_name] ~= nil then
--             if GUARD_LOGGING then
--                 print("skipping "..curr_name)
--             end
--         else
--             if GUARD_LOGGING then
--                 print("running for "..curr_name)
--             end
--             local stack = {} -- The stack for DFS traversal
--             local resolved_side_names = {} -- Resolved guardee names within this iteration
--             local start_guard_features = features_by_guardee[curr_name] -- Get the starting points of traversal based on guardee name

--             if start_guard_features then
--                 for _, feature in ipairs(start_guard_features) do
--                     if found_units_for_feature(feature) then
--                         local guard_name = feature[1][1]
--                         if resolved_names[guard_name] then
--                             -- Optimization! If traversal ends in a guardee name we've already resolved, add the guardee's guard units to the final list for curr_name's guards
--                             if GUARD_LOGGING then
--                                 print("copying guard units from resolved name "..guard_name.." into "..curr_name)
--                             end
--                             local guard_unit_list = get_table_value(guard_relation_map, curr_name)
--                             for guard_unit, _ in pairs(guard_relation_map[guard_name]) do
--                                 guard_unit_list[guard_unit] = true
--                             end

--                             resolved_side_names[curr_name] = true
--                         else
--                             -- Traverse the graph of guard relations by adding to the stack. Entries added to the stack represent features that *have at least one valid guard unit*.
--                             stack[#stack + 1] = {
--                                 -- the feature, aka the data entry in featureindex used to describe a rule
--                                 feature = feature,

--                                 -- serialized feature -> {feature = <feature>, order = int}, set of visited features used for detecting loops. "order" is the index of the feature in the current 
--                                 visited = {},

--                                 -- int -> feature, records indexes of traversed features in current guard chain. Used for figuring out which features to get guards from after detecting a loop
--                                 visited_order = {}
--                             }
--                         end
--                     end
--                 end
--             end
            
--             local visited_features = {}
--             local count = 0
--             while #stack > 0 do
--                 count = count + 1

--                 if count > 100 then
--                     too_complex_guard = true
--                     timedmessage(count)
--                     destroylevel("toocomplex")
--                     return
--                 end

--                 local entry = stack[#stack]
--                 stack[#stack] = nil

--                 local curr_feature = entry.feature
        
--                 table.insert(entry.visited_order, make_typedata(curr_feature))
--                 local curr_order = #entry.visited_order
--                 entry.visited[serialize_guard_feature(curr_feature)] = {
--                     guardee_name = curr_feature[1][3],
--                     order = curr_order
--                 }
                
--                 local lowest_loop_index = nil -- If we found a loop, keep track of the lowest index in the guard chain where we found a loop. Smaller indexes mean larger loops.
--                 local add_guard_units = false -- Whether or not we calculate the guard units for the current feature (or the found loop) and add to the final list of guard units
--                 local added_to_stack = false -- Whether or not we found another feature to traverse
--                 local curr_guard_name = curr_feature[1][1]

--                 if enable_guard_chaining then
--                     local guard_features = features_by_guardee[curr_guard_name]
--                     if guard_features then
--                         for _, feature in ipairs(guard_features) do
--                             local serialized_feature = serialize_guard_feature(feature)
--                             -- Check for a loop
--                             if entry.visited[serialized_feature] then
--                                 add_guard_units = true
--                                 if lowest_loop_index == nil or entry.visited[serialized_feature].order < lowest_loop_index then
--                                     lowest_loop_index = entry.visited[serialized_feature].order
--                                 end
--                             else
--                                 if found_units_for_feature(feature) then
--                                     local guard_name = feature[1][1]
--                                     if resolved_names[guard_name] then
--                                         -- Optimization! If traversal ends in a guardee name we've already resolved, add the guardee's guard units to the final list for curr_name's guards
--                                         if GUARD_LOGGING then
--                                             print("copying guard units from resolved name "..guard_name.." into "..curr_name)
--                                         end

--                                         local guard_unit_list = get_table_value(guard_relation_map, curr_name)
--                                         for guard_unit, _ in pairs(guard_relation_map[guard_name]) do
--                                             guard_unit_list[guard_unit] = true
--                                         end

--                                         resolved_side_names[curr_name] = true
--                                     elseif resolved_side_names[guard_name] then
                                        
--                                     else
--                                         -- Do another traversal
--                                         if GUARD_LOGGING then
--                                             print("adding to stack "..serialized_feature)
--                                         end


--                                         -- Deep copy tables before adding to the stack
--                                         local visited_copy = nil
--                                         local visited_order_copy = nil
--                                         if #guard_features == 1 then
--                                             visited_copy = entry.visited
--                                             visited_order_copy = entry.visited_order
--                                         else
--                                             visited_copy = utils.deep_copy_table(entry.visited)
--                                             visited_order_copy = utils.deep_copy_table(entry.visited_order)
--                                         end

--                                         stack[#stack + 1] = {
--                                             feature = feature,
--                                             visited = visited_copy,
--                                             visited_order = visited_order_copy
--                                         }
--                                         added_to_stack = true
--                                     end
--                                 end
--                             end
--                         end
--                     end
--                 end
--                 if not added_to_stack then
--                     add_guard_units = true
--                 end
                
--                 if add_guard_units then
--                     local typedata_to_extract_guard_units = {}
--                     local final_guard_units = {}

--                     if lowest_loop_index ~= nil then
--                         for i = lowest_loop_index, curr_order do
--                             local typedata = entry.visited_order[i]
--                             local typedata_serialize = utils.serialize_typedata(typedata)
--                             if not typedata_to_extract_guard_units[typedata_serialize] then
--                                 typedata_to_extract_guard_units[typedata_serialize] = typedata
--                             end
--                         end
--                     else
--                         local typedata = make_typedata(curr_feature)
--                         local typedata_serialize = utils.serialize_typedata(typedata)
--                         typedata_to_extract_guard_units[typedata_serialize] = typedata
--                     end

--                     local found_guard = false
--                     for typedata_serialize, typedata in pairs(typedata_to_extract_guard_units) do
--                         local found_guards = {}
--                         if calculated_guard_units[typedata_serialize] then
--                             found_guards = calculated_guard_units[typedata_serialize]
--                             found_guard = true

--                             if GUARD_LOGGING then
--                                 print("using calculated guards for "..typedata_serialize)
--                             end
--                         else
--                             if GUARD_LOGGING then
--                                 print("calculating guards for "..typedata_serialize)
--                             end
--                             for _, unitid in ipairs(findall(typedata, false, false)) do
--                                 found_guard = true
--                                 local object = utils.make_object(unitid)
--                                 found_guards[object] = true
--                             end
    
--                             local conds = typedata[2]
--                             if curr_guard_name == "empty" then
--                                 for _, tileid in ipairs(findempty(conds, false)) do
--                                     found_guard = true
    
--                                     local x = tileid % roomsizex
--                                     local y = math.floor(tileid / roomsizex)
--                                     local empty_object = utils.make_object(2, x, y)
--                                     found_guards[empty_object] = true
--                                 end
--                             elseif curr_guard_name == "level" then
--                                 if testcond(conds, 1) then
--                                     found_guard = true
    
--                                     local level_object = utils.make_object(1)
--                                     found_guards[level_object] = true
--                                 end
--                             end
    
--                             calculated_guard_units[typedata_serialize] = found_guards
--                         end

--                         for guard_unit, _ in pairs(found_guards) do
--                             final_guard_units[guard_unit] = true
--                         end
--                     end

--                     if found_guard then
--                         for key, v in pairs(entry.visited) do
--                             local guard_unit_list = get_table_value(guard_relation_map, v.guardee_name)

--                             for guard_unit, _ in pairs(final_guard_units) do
--                                 guard_unit_list[guard_unit] = true
--                             end

--                             resolved_side_names[v.guardee_name] = true
--                         end
--                     end
--                 end
--             end
--             if GUARD_LOGGING then
--                 print("stack pop count", count)
--             end

--             for name, _ in pairs(resolved_side_names) do
--                 if GUARD_LOGGING then
--                     for unitid, _ in pairs(guard_relation_map[name]) do
--                         print("- "..name.." -> "..utils.unitstring(unitid))
--                     end
--                     print("resolved for "..name)
--                 end

--                 resolved_names[name] = true
--             end
--         end
--     end
-- end

--[[ 
    vertex = represents each unique typedata
    scc = list of vertices
]]

-- Following Tarjan's algorithm for generating SCC https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm
-- Note that the algorithm doesn't do anything to link each scc together in a super graph. This is what the "predecessor" field is for.
local function strongconnect(vertex, data)
    vertex.index = data.index
    vertex.lowlink = data.index
    data.index = data.index + 1

    table.insert(data.stack, vertex)
    vertex.on_stack = true

    local curr_guard_name = vertex.typedata[1]

    if GUARD_ALG_LOGGING then
        print("current guard "..curr_guard_name)
    end

    local guardee_vertices = data.guard_graph[curr_guard_name] or {}
    for typedata_hash, next_vertex in pairs(guardee_vertices) do
        utils.debug_assert(next_vertex, curr_guard_name)

        if next_vertex.index == nil then
            next_vertex.predecessor = vertex
            strongconnect(next_vertex, data)
            vertex.lowlink = math.min(vertex.lowlink, next_vertex.lowlink)
        elseif next_vertex.on_stack then
            vertex.lowlink = math.min(vertex.lowlink, next_vertex.index)
        elseif next_vertex.containing_scc ~= nil then
            -- If we already created the scc that the next vertex belongs to, note the vertex -> scc edge in scc_graph
            local scc_list = get_table_value(data.scc_graph, vertex)

            if not scc_list[next_vertex.containing_scc] then
                scc_list[next_vertex.containing_scc] = true

                if GUARD_LOGGING then
                    print(string.format("%s -> %s (Copy)", vertex.typedata_hash, print_scc(next_vertex.containing_scc)))
                end
            end
        end
    end

    if (vertex.lowlink == vertex.index) then
        local predecessor = vertex.predecessor or data.start_vertex
        local pred_scc_list = get_table_value(data.scc_graph, predecessor)

        -- Make a new scc
        local new_scc = {}
        local stack_vertex = vertex
        repeat
            stack_vertex = table.remove(data.stack)
            stack_vertex.on_stack = false
            table.insert(new_scc, stack_vertex)

            stack_vertex.containing_scc = new_scc -- Make all vertices point to the scc that contains the vertices
        until stack_vertex == vertex

        -- Add the vertex -> scc link, aka the predecessor -> new scc
        pred_scc_list[new_scc] = true

        if GUARD_LOGGING then
            print(string.format("%s -> %s", predecessor.typedata_hash, print_scc(new_scc)))
        end
    end
end

local function recalculate_guards_v2()
    if GUARD_LOGGING then
        print("- Recalculating guards")
    end
    guard_relation_map = {}

    --[[ 
        Recalculating guards is divided into two phases:
        - Phase 1: 
            - build a guard graph of guard relations based on all guard features.
            - Then run Tarjan's algorithm to generate a super graph of Strongly Connected Components (SCC).
                - SCCs are subgraphs where all vertices can be accessed from any other vertex in the graph.
                - By building a super graph of SCCs, where each SCC can be thought as its own vertex, it simplifies the original guard graph to eliminate all loops
        - Phase 2:
            - Run a DFS traversal on the super graph to apply guard chaining logic and calculate guard units 
    ]]

    --[[ Start of Phase 1 ]]

    local guard_graph = {} -- guardee name -> list of vetices. An adjacency list that provides each traversal option in terms of the guardee name
    local guardee_vertices = {} -- guardee name -> vertex. The mapped vertex represents the starting point of iteration for each guardee name in the guard graph
    local all_vertices = {} -- typedata_hash -> vertex. This tracks each uniquely created vertex in the guard graph. Its mainly used to avoid duplications based on the typedata_hash

    -- Go through all guard features and populate the guard_graph and guardee_vertices
    if featureindex["guard"] ~= nil then
        for _, feature in ipairs(featureindex["guard"]) do
            if feature[1][3] ~= "all" and feature[1][1] ~= "all" then
                local guardee_name = feature[1][3]

                if string.sub(guardee_name, 1, 4) ~= "not " then

                    -- Check that a unit with the guardee name exists before checking the guard typedata
                    local check_guard_typedata = false
                    if guardee_vertices[guardee_name] then
                        check_guard_typedata = true
                    else
                        local guardee_typedata = {guardee_name, {}}
                        if found_units_for_typedata(guardee_typedata) then
                            check_guard_typedata = true
                            
                            -- Make a "guardee" vertex. This represents a starting point for getting all guard units of a guardee
                            local guardee_typedata_hash = "[start] "..utils.serialize_typedata(guardee_typedata)
                            local name_vertex = {
                                -- Tarjan's algorithm fields
                                index = nil,
                                lowlink = nil,
                                on_stack = false,
                
                                -- Other fields
                                typedata = guardee_typedata,
                                typedata_hash = guardee_typedata_hash,
                                predecessor = nil, -- Will point to the previous vertex used to go to the current vertex. Used for linking each scc in the scc_graph
                                containing_scc = nil, -- Will point to the scc that contains this vertex.
                            }
                            guardee_vertices[guardee_name] = name_vertex
                        end
                    end

                    if check_guard_typedata then
                        local typedata = make_typedata(feature)
                        local typedata_hash = utils.serialize_typedata(typedata)
                        
                        local found_units = found_units_for_typedata(typedata)
                        if found_units then
                            local vertexlist = get_table_value(guard_graph, guardee_name)

                            if all_vertices[typedata_hash] == nil then
                                local new_vertex = {
                                    -- Tarjan's algorithm fields
                                    index = nil,
                                    lowlink = nil,
                                    on_stack = false,

                                    -- Other fields
                                    typedata = typedata,
                                    typedata_hash = typedata_hash,
                                    predecessor = nil, -- Will point to the previous vertex used to go to the current vertex. Used for linking each scc in the scc_graph
                                    containing_scc = nil -- Will point to the scc that contains this vertex.
                                }
                                
                                vertexlist[typedata_hash] = new_vertex
                                all_vertices[typedata_hash] = new_vertex
        
                                if GUARD_ALG_LOGGING then
                                    print("Adding vertex with typedata: "..typedata_hash.." for guardee "..guardee_name)
                                end
                            else
                                if GUARD_ALG_LOGGING then
                                    print("Copying vertex with typedata: "..typedata_hash.." for guardee "..guardee_name)
                                end
                                vertexlist[typedata_hash] = all_vertices[typedata_hash]
                            end    
                        end
                    end
                end
            end
        end
    end

    -- Persistent data used for running Tarjan's algorithm
    local scc_data = {
        -- Tarjan's algorithm fields
        stack = {},
        index = 0,
        
        -- Other fields
        guard_graph = guard_graph, -- Save reference to the guard graph

        -- vertex -> scc. This gets populated with all edges from a vertex (V) to an scc (S) such that V is not in S.
        -- Used for traversing through a super graph that only consists of sccs from guard_graph.
        scc_graph = {},

        -- A dummy vertex used when the current vertex does not have a predecessor. Represents the singular starting point for traversal
        start_vertex = {
            typedata = {"start_vertex", {}},
            typedata_hash = "start_vertex",
            
            index = nil,
            lowlink = nil,
            on_stack = false,
            predecessor = nil,
        },
    }

    -- Run Tarjan's algorithm
    for _, guardee_vertex in pairs(guardee_vertices) do
        strongconnect(guardee_vertex, scc_data)
    end

    if GUARD_LOGGING or GUARD_ALG_LOGGING then
        print("=================")
    end

    --[[ Start of Phase 2 ]]
    --[[ 
        The next section is several DFS traversals on the scc_graph, one traversal for each guardee name to resolve.
        This is where we calculate the final set of guard units for each guardee.
     ]]
    
    -- typedata_hash -> list of units. Optimization: this saves the list of guard units calculated from a given typedata.
    -- Used for avoiding redundant calculations when processing duplicate typedata
    local calculated_guard_units = {}
    
    for guardee_name, _ in pairs(guardee_vertices) do
        if GUARD_ALG_LOGGING then
            print("resolving guardee name "..guardee_name)
        end
        local starting_vertices = guard_graph[guardee_name] or {}
        
        local stack = {}
        local guardee_sccs = {}
        -- Initially populate the stack with all unique sccs that contain the guardee
        for typedata_hash, vertex in pairs(starting_vertices) do
            if not guardee_sccs[vertex.containing_scc] then
                guardee_sccs[vertex.containing_scc] = true
                table.insert(stack, vertex.containing_scc)
            end
        end

        local final_guard_units = {}
        local found_guard = false
        while #stack > 0 do
            local curr_scc = table.remove(stack)

            if GUARD_ALG_LOGGING then
                print("Processing scc with verticies: "..print_scc(curr_scc))
            end
            
            -- Find any sccs branching off from this current scc and add to the stack.
            local add_guard_units = true
            local sccs_to_insert = {}
            for _, vertex in ipairs(curr_scc) do
                local successor_sccs = scc_data.scc_graph[vertex] or {}
                for next_scc, _ in pairs(successor_sccs) do
                    if next_scc ~= curr_scc then
                        sccs_to_insert[next_scc] = true
                        add_guard_units = false
                    end
                end
            end
            for scc, _ in pairs(sccs_to_insert) do
                table.insert(stack, scc)

                if GUARD_ALG_LOGGING then
                    print("Adding to stack scc with verticies: "..print_scc(curr_scc))
                end
            end
            

            if add_guard_units then
                -- At this point, we've determined that the current scc has no other sccs to branch to. So add the guard units of the scc to the final guard list
                for _, curr_vertex in ipairs(curr_scc) do
                    local found_guards = {}
                    if calculated_guard_units[curr_vertex.typedata_hash] then
                        found_guards = calculated_guard_units[curr_vertex.typedata_hash]

                        if GUARD_ALG_LOGGING then
                            print("using calculated guards for "..curr_vertex.typedata_hash)
                        end
                    else
                        if GUARD_ALG_LOGGING then
                            print("calculating guards for "..curr_vertex.typedata_hash)
                        end
                        for _, unitid in ipairs(findall(curr_vertex.typedata, false, false)) do
                            found_guard = true
                            local object = utils.make_object(unitid)
                            found_guards[object] = true
                        end

                        local conds = curr_vertex.typedata[2]
                        if curr_guard_name == "empty" then
                            for _, tileid in ipairs(findempty(conds, false)) do
                                found_guard = true

                                local x = tileid % roomsizex
                                local y = math.floor(tileid / roomsizex)
                                local empty_object = utils.make_object(2, x, y)
                                found_guards[empty_object] = true
                            end
                        elseif curr_guard_name == "level" then
                            if testcond(conds, 1) then
                                found_guard = true

                                local level_object = utils.make_object(1)
                                found_guards[level_object] = true
                            end
                        end

                        calculated_guard_units[curr_vertex.typedata_hash] = found_guards
                    end
                    for guard_unit, _ in pairs(found_guards) do
                        if GUARD_LOGGING and not final_guard_units[guard_unit] then
                            print(string.format("%s => %s", guardee_name, utils.unitstring(guard_unit)))
                        end

                        final_guard_units[guard_unit] = true 
                        found_guard = true
                    end
                end
            end
        end

        if found_guard then
            guard_relation_map[guardee_name] = final_guard_units
        end
    end
end

-- The main entrypoint for guard logic. This gets called from: start and end of turn, after code(), after handledels(), and after levelblock()
function guard_checkpoint(calling_func)
    if not too_complex_guard then
        if GUARD_LOGGING then
            print(string.format("> guard_checkpoint from %s", calling_func))
        end
        handle_guard_dels()

        -- if calling_func == "command_given" or calling_func == "level_start" then
        --     recalculate_guards_v2()
        -- end
        recalculate_guards_v2()
        
        -- recalculate_guards()
        if update_guards then
            update_guards = false
        end
    end
end