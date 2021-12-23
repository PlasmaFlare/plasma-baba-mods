--[[ 
    Which functions to inject:
    Definetly - clearunits(), findnoun(), delunit()
    Maybe - all functions in features.lua, getunitswitheffect("select",true), addunit()
    Partially - code()

 ]]

--[[ 
    @mods(this) - Provide hook for updating raycast units
    @mods(stable) - Provide hook for updating stable state
    @mods(guard) - Injection reaon: provide a guard checkpoint
]]
local old_code = code
function code(alreadyrun_, ...)
    local alreadyrun = alreadyrun_ or false
    if this_mod_has_this_text() then
		if this_mod_globals.undoed_after_called then
			update_raycast_units(true, true, true)
		elseif updatecode == 0 and not turning_text_mod_globals.tt_executing_code then
			update_raycast_units(true, true, true)
			if updatecode == 0 then
				check_cond_rules_with_this_noun()
			end
		end
	end

	if not alreadyrun then
		update_stable_state()
	end

    local ret = table.pack(old_code(alreadyrun_, ...))
    guard_checkpoint("code")
    return table.unpack(ret)
end


-- @mods(this), @mods(stable) - Injection reason: provide hook for clearing mod globals/locals
local old_clearunits = clearunits

function clearunits(...)
    local ret = old_clearunits(...)
    reset_this_mod()
	clear_stable_mod()

    return ret
end


local old_addunit = addunit
function addunit(id, ...)
    local ret = old_addunit(id, ...)

    local unit = mmf.newObject(id)
    local name = getname(unit)
	local name_ = unit.strings[NAME]

	if is_name_text_this(name_) then
		on_add_this_text(unit.fixed)
	end

	on_add_stableunit(unit.fixed)
    ack_unit_update_for_guard(unitid)
end

-- @mods(stable), @mods(this) - Injection reason: provide hook for when a unit gets deleted. This is to clear that unit from each mod's internal tables
local old_delunit = delunit
function delunit(unitid)
    local ret = old_delunit(unitid)
    on_delete_stableunit(unitid)
    on_delele_this_text(unitid)
    ack_unit_update_for_guard(unitid)

    return ret
end

--[[ 
    @mods(this) - Injection reason: in the many cases where the game iterates through objectlist, it uses this function to exclude special nouns from "all". 
    Since we want THIS and all of its variations to be excluded, override this function, not just nlist.full 
]]
local old_findnoun = findnoun
function findnoun(noun, ...)
    if is_name_text_this(noun) then
		return true
	else
        return old_findnoun(noun, ...)
    end
end

--[[ 
    @mods(guard) - Injection reaon: provide a guard checkpoint after every handledels call
]]
local old_handledels = handledels
function handledels(delthese, ...)
    local ret = table.pack(old_handledels(delthese, ...))
    guard_checkpoint("handledels")
    return table.unpack(ret)
end