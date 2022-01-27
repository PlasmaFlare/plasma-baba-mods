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
            return 200 + x + y * roomsizex -- JAAAAAAANK
        elseif unitid == 1 then
            return 1
        else
            return unitid
        end
    end,

    parse_object = function(object)
        utils.debug_assert(object)
        if object >= 200 then
            local tileid = object - 200
            local x = tileid % roomsizex
            local y = math.floor(tileid / roomsizex)
            return 2, x, y, tileid
        elseif object == 1 then
            return 1
        else
            local unit = mmf.newObject(object)
            utils.debug_assert(unit)

            return object, unit.values[XPOS], unit.values[YPOS], unit.values[XPOS] + unit.values[YPOS] * roomsizex
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
        for _, word in ipairs(baserule) do
            tokens[#tokens + 1] = word
            tokens[#tokens + 1] = " "
        end
        tokens[#tokens + 1] = ":"

        if #feature[2] > 0 then
            local conds = utils.deep_copy_table(feature[2])
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