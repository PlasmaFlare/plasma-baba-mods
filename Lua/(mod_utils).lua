local utils = {}
utils = {
    debug_assert = function(expr, err_msg)
        if not expr then
            if not err_msg then
                err_msg = ""
            end
            error("Assertion failed: "..err_msg.."\n"..debug.traceback(), 2)
        end
    end,

    make_object = function(unitid, x, y)
        if unitid == 2 then
            utils.debug_assert(unitid)
            utils.debug_assert(x)
            utils.debug_assert(y)
            return -(200 + x + y * roomsizex) -- JAAAAAAANK
        elseif unitid == 1 then
            return -1
        else
            local unit = mmf.newObject(unitid)
            utils.debug_assert(unit, tostring(unitid))
            return unit.values[ID]
            -- return unitid
        end
    end,

    parse_object = function(object)
        utils.debug_assert(object)
        if object <= -200 then
            local tileid = (-object) - 200
            local x = tileid % roomsizex
            local y = math.floor(tileid / roomsizex)
            return 2, x, y, tileid
        elseif object == -1 then
            return 1
        else
            -- local unit = mmf.newObject(object)
            local unitid = MF_getfixed(object)
            utils.debug_assert(unitid, "Cannot find unitid of object: "..tostring(object))
            local unit = mmf.newObject(unitid)
            utils.debug_assert(unit, "Cannot find unit of object: "..tostring(object))

            return unitid, unit.values[XPOS], unit.values[YPOS], unit.values[XPOS] + unit.values[YPOS] * roomsizex
        end
    end,

    unitstring = function(object)
        local unitid, x, y = utils.parse_object(object)
        if unitid == 1 then
            return "(Level)"
        elseif unitid == 2 then
            return string.format("(Empty at %d,%d)", x, y)
        else
            local unit = mmf.newObject(unitid)
            return string.format("(%s with id %d at %d,%d | unitid %s)", unit.strings[NAME], unit.values[ID], unit.values[XPOS], unit.values[YPOS], tostring(unitid))
        end
    end,

    deep_copy_table = function(table)
        local copy = {}
        for k,v in pairs(table) do
            if type(v) == "table" then
                v = utils.deep_copy_table(v)
            end
            copy[k] = v
        end
    
        return copy
    end,

    get_deleted_unitid_key = function(object)
        local unitid, x, y = utils.parse_object(object)
        local deleted_unitid = unitid
        if unitid == 1 then
            return nil
        elseif unitid == 2 then
            -- JANK WARNING!!! This formula is apparently how the game determines the key for marking an empty to be "deleted".
            deleted_unitid = 200 + x + y * roomsizex
        end
        return deleted_unitid
    end,

    condsort = function(a,b)
        if a[1] ~= b[1] then
            return a[1] < b[1]
        else
            if #a[2] ~= #b[2] then
                return #a[2] < #b[2]
            else
                local param_a = utils.deep_copy_table(a[2])
                local param_b = utils.deep_copy_table(b[2])

                table.sort(param_a)
                table.sort(param_b)

                for i = 1, #param_a do
                    if param_a[i] ~= param_b[i] then
                        return param_a[i] < param_b[i]
                    end
                end
            end
        end
    end,

    serialize_feature = function(feature)
        local tokens = {}
        local baserule = feature[1]
        for i, word in ipairs(baserule) do
            tokens[#tokens + 1] = word
            if i ~= #baserule then
                tokens[#tokens + 1] = " "
            end
        end
        tokens[#tokens + 1] = " => "

        if #feature[2] > 0 then
            local conds = utils.deep_copy_table(feature[2])
            table.sort(conds, utils.condsort)

            for j, cond in ipairs(conds) do
                tokens[#tokens + 1] = cond[1]
                tokens[#tokens + 1] = "["
                for i, param in ipairs(cond[2]) do
                    tokens[#tokens + 1] = "("
                    tokens[#tokens + 1] = param
                    tokens[#tokens + 1] = ")"

                    if i ~= #cond[2] then
                        tokens[#tokens + 1] = ","
                    end
                end

                -- Serialization with THIS as a cond
                -- if is_name_text_this(cond[1]) then
                --     local this_text_unitid = parse_this_unit_from_param_id(cond[2][1])
                --     for _, ray_object in ipairs(get_raycast_units(this_text_unitid)) do
                --         local ray_unitid, _, _, ray_tileid = utils.parse_object(ray_object)
                --         if ray_unitid == 2 then
                --             tokens[#tokens + 1] = "empty{"..tostring(ray_tileid).."}"
                --         else
                --             local ray_unit = mmf.newObject(ray_unitid)
                --             tokens[#tokens + 1] = tostring(ray_unit.values[ID])
                --         end
                --     end
                -- end

                tokens[#tokens + 1] = "]"
                if j ~= #conds then
                    tokens[#tokens + 1] = " | "
                end
            end
        end
        return table.concat(tokens)
    end,

    serialize_typedata = function(typedata)
        local tokens = {}
        tokens[#tokens + 1] = typedata[1]
        
        if #typedata[2] > 0 then
            tokens[#tokens + 1] = "("
            local conds = utils.deep_copy_table(typedata[2])
            table.sort(conds, utils.condsort)
            
            for _, cond in ipairs(conds) do
                tokens[#tokens + 1] = cond[1]
                tokens[#tokens + 1] = ">"
                for _, param in ipairs(cond[2]) do
                    tokens[#tokens + 1] = param
                    tokens[#tokens + 1] = ","
                end
                tokens[#tokens + 1] = "|"
            end
            tokens[#tokens + 1] = ")"
        end
        return table.concat(tokens)
    end,
}

plasma_utils = utils

-- DEBUG STUFF
-- Set to true if you want to test that utils.make_object() and utils.parse_object() work
if false then
    local function test_make_parse_object()
        local all_test_objects = {}
        for id, _ in pairs(units) do
            local unitid = MF_getfixed(id)
            local object = utils.make_object(unitid)
            local changed_unitid = utils.parse_object(object)
            utils.debug_assert(unitid == changed_unitid, utils.unitstring(utils.make_object(unitid)).." failed the object check")

            utils.debug_assert(all_test_objects[object] == nil, "Found two units that map to the same object: "..object..". Unit 1:"..tostring(unitid).." Unit 2:"..tostring(all_test_objects[object]))
            all_test_objects[object] = unitid
            if unitid > 2 and unitid < 3 then
            end
        end
        for i=0,roomsizex-1 do
            for j=0,roomsizey-1 do
                local object = utils.make_object(2, i, j)
                local unitid, x, y = utils.parse_object(object)

                utils.debug_assert(unitid == 2, utils.unitstring(object).." failed the object check")
                utils.debug_assert(x == i and y == j, utils.unitstring(object).." failed the object check through different coords: "..x..","..y)

                utils.debug_assert(all_test_objects[object] == nil, "Found two units that map to the same object: "..object..". Unit 1:"..tostring(2).." Unit 2:"..tostring(all_test_objects[object]))
                all_test_objects[object] = 2
            end
        end

        local levelobject = utils.make_object(1)
        local level_unitid = utils.parse_object(levelobject)
        utils.debug_assert(level_unitid == 1, utils.unitstring(levelobject).." failed the object check")

        utils.debug_assert(all_test_objects[levelobject] == nil, "Found two units that map to the same object: "..levelobject..". Unit 1:"..tostring(2).." Unit 2:"..tostring(all_test_objects[levelobject]))
        all_test_objects[levelobject] = 1
    end

    table.insert(mod_hook_functions["command_given"], test_make_parse_object)
    table.insert(mod_hook_functions["undoed"], test_make_parse_object)
end