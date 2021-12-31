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
            return 2, x, y
        elseif object == 1 then
            return 1
        else
            local unit = mmf.newObject(object)
            utils.debug_assert(unit)
            return object, unit.values[XPOS], unit.values[YPOS]
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
    end
}

plasma_utils = utils