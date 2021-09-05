--[[ 
    Some semantics/definitions:
    - su_key: stableunit key - equal to unit.values[ID]. An ID for identifying units to apply "stable" to. We use unit.values[ID] since it is persistent across undos
    - ruleid - a string identifying a sentence in string form, regardless of what text unitids form it (i.e. "baba on keke is you", "hedge is stop", etc)
    - stableid - an int that increments every call to code(). Used for identifying the group of unitids to assign to a set of rules. Currently used for debug purposes
 ]]

local stablestate = {
    units = {},
    --[[ 
        unit.values[ID] (call this stableunit key) -> {
            stableid: int
            ruleids: [ruleids: string]
        }
     ]]

    rules = {},
    --[[ 
        ruleids: int -> {
            feature : featureindex item
            unit_count : int 
        }
     ]]

    empties = {},
    --[[ 
       tileid -> {
           stableid: int
           ruleids: [ruleids: string]
       }  
     ]]

    stable_this_raycast_units = {},
    --[[ 
        stable_this_id -> {
            ids: [list of raycast units], 
            tileid: int
        }
     ]]
}

local stable_undo_stack = {}
--[[ 
    Array of {
        turnid: int
        stablestate.units
        stablestate.rules
    }
]]
local stable_indicators = {}
--[[ 
    stableunit key -> {
        unitid of indicator: unitid
        unitid of target: unitid
    }
 ]]

 local stable_empty_indicators = {}
 --[[ 
     tileid -> unitid of indicator: unitid
  ]]
    
local LEVEL_SU_KEY = -1
local STABLE_THIS_ID_BASE = -50
local STABLE_THIS_ID_EMPTY = -49
local stableid = 1
local turnid = 1
local curr_stable_this_id = STABLE_THIS_ID_BASE
local on_undo = false
local stable_state_updated = false
local stablerule_timer = 0 -- Used mainly for changing color on stablerule display
local TIMER_PERIOD = 400 -- Used mainly for changing color on stablerule display

local STABLE_LOGGING = false

-- Stores the previous length of the global, undobuffer. This gets recorded at the beginning of the turn so that we can determine whether or
-- not to add an entry to stable_undo_stack, based on if the undobuffer has added an entry. This may feel like a silly way to do this, but
-- at least it doesn't override more functions. 
local prev_undobuffer_len = 0 

checking_stable = false

local function clear_stable_mod()
    stablestate = {
        units = {},
        rules = {},
        empties = {},
        stable_this_raycast_units = {},
    }
    stable_undo_stack = {}
    stableid = 1
    turnid = 1
    curr_stable_this_id = STABLE_THIS_ID_BASE

    local count = 0
    for _, v in pairs(stable_indicators) do
        MF_cleanremove(v.indicator_id)
        count = count + 1
    end
    stable_indicators = {}
    stable_empty_indicators = {}
end

local function deep_copy_table(table)
    local copy = {}
    for k,v in pairs(table) do
        if type(v) == "table" then
            v = deep_copy_table(v)
        end
        copy[k] = v
    end

    return copy
end

local function get_stableunit_key(unitid)
    if unitid == 2 then
        return nil
    elseif unitid == 1 then
        return LEVEL_SU_KEY
    end

    local unit = mmf.newObject(unitid)
    if unit and not unit.flags[CONVERTED] and not unit.flags[DEAD] then -- need the second condition since apparently, the converted unit still exists for a time before being deleted
        return unit.values[ID]
    else
        return nil
    end
end

local function get_ruleid(id_list, option)
    local ruleid = ""
    
    for i, id in ipairs(id_list) do
        local unitid = id[1]
        if unitid == 2 then
            ruleid = ruleid + "empty"
        else
            local unit = mmf.newObject(unitid)
            if unit.strings[UNITTYPE] ~= "text" then
                -- Handling objects under "X is word"
                ruleid = ruleid..unit.strings[UNITNAME]
            else
                ruleid = ruleid..unit.strings[NAME]
                if unit.strings[NAME] == "this" then
                    ruleid = ruleid..tostring(unit.values[ID])
                end
            end
        end
        if i ~= #id_list then
            ruleid = ruleid.." "
        end
    end

    if #ruleid > 0 then
        return ruleid
    else
        if #option >= 3 then
            return option[1] .. " " .. option[2] .. " " .. option[3]
        end
    end
    return nil
end

local function get_stablerule_display(feature)
    local custom = MF_read("level","general","customruleword")

    local text = ""
   
    local rule = feature[1]
    if (#custom == 0) then
        text = text .. rule[1] .. " "
    else
        text = text .. custom .. " "
    end

    local conds = feature[2]
    local ids = feature[3]
    local tags = feature[4]

    if #ids == 0 then
        if (#custom == 0) then
            return rule[1].." "..rule[2].." "..rule[3]
        else
            return custom.." "..custom.." "..custom 
        end
    end

    if (#conds > 0) then
        for a,cond in ipairs(conds) do
            if cond[1] ~= "this" and cond[1] ~= "not this" then
                local middlecond = true
                
                if (cond[2] == nil) or ((cond[2] ~= nil) and (#cond[2] == 0)) then
                    middlecond = false
                end
                
                if middlecond then
                    if (#custom == 0) then
                        text = text .. cond[1] .. " "
                    else
                        text = text .. custom .. " "
                    end
                    
                    if (cond[2] ~= nil) then
                        if (#cond[2] > 0) then
                            for c,d in ipairs(cond[2]) do
                                local this_param_name = parse_this_param_and_get_raycast_units(d)
                                if this_param_name then
                                    text = text .. this_param_name.." "
                                else
                                    if (#custom == 0) then
                                        text = text .. d .. " "
                                    else
                                        text = text .. custom .. " "
                                    end
                                    
                                    if (#cond[2] > 1) and (c ~= #cond[2]) then
                                        text = text .. "& "
                                    end
                                end
                            end
                        end
                    end
                    
                    if (a < #conds) then
                        text = text .. "& "
                    end
                else
                    if (#custom == 0) then
                        text = cond[1] .. " " .. text
                    else
                        text = custom .. " " .. text
                    end
                end
            end
        end
    end
    
    local target = rule[3]
    local isnot = string.sub(target, 1, 4)
    local target_ = target
    
    if (isnot == "not ") then
        target_ = string.sub(target, 5)
    else
        isnot = ""
    end
    
    if (word_names[target_] ~= nil) then
        target = isnot .. word_names[target_]
    end
    
    if (#custom == 0) then
        text = text .. rule[2] .. " " .. target
    else
        text = text .. custom .. " " .. custom
    end
    
    for a,b in ipairs(tags) do
        if (b == "mimic") then
            text = text .. " (mimic)"
        end
    end

    return text
end

local function register_this_text_in_stablerule(this_unitid)
    local raycast_units = get_raycast_units(this_unitid, true)
    local raycast_tileid = get_raycast_tileid(this_unitid)

    -- @NOTE: if THIS mod changes get_raycast_units() to output values[ID] instead of unitid, then delete this block
    local ids = {}
    for _, ray_unitid in ipairs(raycast_units) do
        if ray_unitid == 2 then
            table.insert(ids, STABLE_THIS_ID_EMPTY)
        else
            local u = mmf.newObject(ray_unitid)
            table.insert(ids, u.values[ID])
        end
    end

    local stable_this_id = curr_stable_this_id  
    curr_stable_this_id = curr_stable_this_id - 1

    stablestate.stable_this_raycast_units[stable_this_id] = {ids = ids, tileid = raycast_tileid}
    return stable_this_id
end

local function remove_this_text_in_stablerule(stable_this_id)
    stablestate.stable_this_raycast_units[stable_this_id] = nil
end

local function remove_stable_this_in_conds(conds)
    for _, cond in ipairs(conds) do
        local condtype = cond[1]
        local params = cond[2]

        if condtype == "this" or condtype == "not this" then
            local this_unitid = params[1]
            if is_this_unit_in_stablerule(this_unitid) then
                remove_this_text_in_stablerule(this_unitid)
            end
        else
            for a,b in ipairs(params) do
                local pname = b
                local isnot_prefix = ""
                if (string.sub(b, 1, 4) == "not ") then
                    pname = string.sub(b, 5)
                    isnot_prefix = "not "
                end
                local this_param_name,_,_,_,this_unitid = parse_this_param_and_get_raycast_units(pname)
                if is_this_unit_in_stablerule(this_unitid) then
                    remove_this_text_in_stablerule(tonumber(this_unitid))
                end
            end
        end
    end
end

function get_stable_this_raycast_units(stable_this_id)
    if stablestate.stable_this_raycast_units[stable_this_id] then
        local unitids = {} -- @TODO: when THIS mod converts to using values[ID], just return stablestate.stable_this_raycast_units[stable_this_id] directly
        for _, id in ipairs(stablestate.stable_this_raycast_units[stable_this_id].ids) do
            if id == STABLE_THIS_ID_EMPTY then
                table.insert(unitids, 2)
            else    
                local unitid = MF_getfixed(id)
                table.insert(unitids, unitid)
            end
        end
        return unitids
    else
        return {}
    end
end

function get_stable_this_raycast_pos(stable_this_id)
    return stablestate.stable_this_raycast_units[stable_this_id].tileid
end

function is_this_unit_in_stablerule(this_unitid)
    return tonumber(this_unitid) and tonumber(this_unitid) <= STABLE_THIS_ID_BASE
end 

local function get_stablefeatures_from_name(name)
    local stable_features = {}
    for _, feature in ipairs(featureindex[name]) do
        local rule = feature[1]
        local tags = feature[4]
        local is_stablerule = false
        for _, tag in ipairs(tags) do
            if tag == "stable" then
                is_stablerule = true
                break
            end
        end
        
        if not is_stablerule and rule[1] == name and rule[3] ~= "stable" then
            -- Copy the feature and add an additional condition for stable
            local ruleid = get_ruleid(feature[3], feature[1])
            assert(ruleid)
            local dup_feature = deep_copy_table(feature)
            local rule_display = get_stablerule_display(dup_feature)

            local newcond = {}
            for i, cond in ipairs(dup_feature[2]) do
                local condtype = cond[1]
                local params = cond[2]

                if condtype == "this" or condtype == "not this" then
                    local this_unitid = params[1]
                    local stable_this_id = register_this_text_in_stablerule(this_unitid)
                    table.insert(newcond, {condtype, { stable_this_id } })
                else
                    local new_params = {}
                    for a,b in ipairs(params) do
                        local pname = b
                        local isnot_prefix = ""
                        if (string.sub(b, 1, 4) == "not ") then
                            pname = string.sub(b, 5)
                            isnot_prefix = "not "
                        end
                        local this_param_name,_,_,_,this_unitid = parse_this_param_and_get_raycast_units(pname)
                        if this_param_name then
                            local stable_this_id = register_this_text_in_stablerule(this_unitid)
                            local this_param = make_this_param(this_param_name, tostring(stable_this_id))
                            table.insert(new_params, isnot_prefix..this_param)
                        else
                            table.insert(new_params, b)
                        end
                    end
                    table.insert(newcond, {condtype, new_params})
                end
            end

            table.insert(newcond, {"stable", { ruleid }})
            dup_feature[2] = newcond
            
            table.insert(dup_feature[4], "stable")
            
            
            stable_features[ruleid] = {feature = dup_feature, display = rule_display}

            local rule = dup_feature[1]

            if STABLE_LOGGING then
                print("recorded stable feature for name"..name..": "..rule[1].." "..rule[2].." "..rule[3])
            end
        end
    end

    return stable_features
end

local function record_stable_undo()
    if STABLE_LOGGING then
        print("recording stable undo")
    end
    local feature_dup = {}

    table.insert(stable_undo_stack, {
        turnid = turnid,
        stablestate = deep_copy_table(stablestate)
    })

    if STABLE_LOGGING then
        print("num undo entries: "..tostring(#stable_undo_stack))
    end
end

local function apply_stable_undo()
    local top_entry = stable_undo_stack[#stable_undo_stack]
    if top_entry.turnid == turnid then
        table.remove(stable_undo_stack, #stable_undo_stack)
        local next_entry = stable_undo_stack[#stable_undo_stack]
        stablestate = deep_copy_table(next_entry.stablestate)

        local c = 0
        for su_key,v in pairs(stablestate.units) do
            c = c + 1
        end
        
        if STABLE_LOGGING then
            print("applying stable undo. Num of units: "..tostring(c).. " | num remaining undo entries: "..tostring(#stable_undo_stack))
        end

        return true
    end
    return false
end

local function make_stable_indicator()
    local indicator_id = MF_create("customsprite")
    local indicator = mmf.newObject(indicator_id)

    indicator.values[ONLINE] = 1
    indicator.layer = 1
    indicator.direction = 27
    indicator.values[ZLAYER] = 30
    MF_loadsprite(indicator_id,"stable_indicator_0",27,true)
    MF_setcolour(indicator_id,3,3)
    return indicator_id
end

-- Inefficient function for reloading indicators after undp
local function reload_indicators()
    for su_key, v in pairs(stable_indicators) do
        on_delete_stableunit_key(su_key)
    end
    for tileid, v in pairs(stable_empty_indicators) do
        delete_empty_stable_indicator(tileid)
    end
    stable_indicators = {}
    stable_empty_indicators = {}

    checking_stable = true
    local code_stableunits, code_stableempties = findallfeature(nil, "is", "stable")
    checking_stable = false
    for _, unitid in ipairs(code_stableunits) do
        on_add_stableunit(unitid)
    end
    for _, group in ipairs(code_stableempties) do
        for tileid, _ in pairs(group) do
            add_empty_stable_indicator(tileid)
        end
    end
end

table.insert(mod_hook_functions["level_start"],
    function()
        clear_stable_mod()
        record_stable_undo()
    end
)
table.insert( mod_hook_functions["level_restart"],
    function()
        clear_stable_mod()
        record_stable_undo()
    end
)

function is_stableunit(unitid, x, y)
    if unitid == 2 then
        local tileid = x + y * roomsizex
        return stablestate.empties[tileid]
    else
        local key = get_stableunit_key(unitid)
        return key and stablestate.units[key]
    end    
end

function stableunit_has_ruleid(unitid, ruleid, x, y)
    local ruleid_list = {}
    if unitid == 2 then
        local tileid = x + y * roomsizex
        if stablestate.empties[tileid] then
            ruleid_list = stablestate.empties[tileid].ruleids
        end
    else
        local key = get_stableunit_key(unitid)
        if key and stablestate.units[key] then
            ruleid_list = stablestate.units[key].ruleids
        end
    end
    for _, stable_ruleid in ipairs(ruleid_list) do
        if ruleid == stable_ruleid then
            return true
        end
    end
    return false
end

--[[ Core logic ]]
function update_stable_state()
    if STABLE_LOGGING then
        print("----update_stable_state")
    end
    if on_undo then
        return
    end

    checking_stable = true
    local code_stablestate, code_stableempties = findallfeature(nil, "is", "stable")
    if hasfeature("level", "is", "stable", 1) then
        table.insert(code_stablestate, 1)
    end
    checking_stable = false
    
    local stable_rules = {}
    local code_stablestate_lookup = {}
    local new_stableunit_count = 0
    for _, unitid in ipairs(code_stablestate) do
        if unitid ~= 2 then
            local su_key = get_stableunit_key(unitid)
            if su_key then
                code_stablestate_lookup[su_key] = true

                -- Add new stablestate.units
                if not stablestate.units[su_key] then
                    local name = ""
                    if su_key == LEVEL_SU_KEY then
                        name = "level"
                    else
                        local unit = mmf.newObject(unitid)
                        name = getname(unit)
                    end

                    if not stable_rules[name] then
                        -- If we haven't recorded the set of features for this name, get the features
                        stable_rules[name] = get_stablefeatures_from_name(name)
                    end
                    
                    local ruleids = {} -- Get a list of ruleids 
                    for ruleid, v in pairs(stable_rules[name]) do
                        local conds_to_test = {}
                        for _, cond in ipairs(v.feature[2]) do
                            local condtype = cond[1]
                            if condtype == "this" or condtype == "not this" then
                                table.insert(conds_to_test, cond)
                            end
                        end

                        local add_ruleid = true
                        if #conds_to_test ~= 0 then
                            if su_key == LEVEL_SU_KEY then
                                add_ruleid = testcond(conds_to_test, 1)
                            else
                                add_ruleid = testcond(conds_to_test, unitid)
                            end
                        end

                        if add_ruleid then
                            table.insert(ruleids, ruleid)

                            if not stablestate.rules[ruleid] then
                                stablestate.rules[ruleid] = {
                                    feature = v.feature,
                                    unit_count = 1,
                                    display = v.display,
                                }
                            else
                                stablestate.rules[ruleid].unit_count = stablestate.rules[ruleid].unit_count + 1
                            end
                        end
                    end

                    stablestate.units[su_key] = {
                        stableid = stableid,
                        name = name,
                        ruleids = ruleids,
                    }
                    new_stableunit_count = new_stableunit_count + 1

                    if STABLE_LOGGING then
                        print("adding targetunit name "..name.." su_key: "..su_key.." as stable unit for stable id: "..stableid.." | num ruleids: ")
                    end

                    on_add_stableunit(unitid)
                end
            end
        end
    end

    -- Deleting items from stablestate.units and rules
    local deleted_su_key_count = 0
    for su_key, v in pairs(stablestate.units) do
        if not code_stablestate_lookup[su_key] then
            if STABLE_LOGGING then
                print("deleting unit with su key: "..tostring(su_key))
            end
            on_delete_stableunit_key(su_key)
            deleted_su_key_count = deleted_su_key_count + 1

            local deleted_stableid = v.stableid
            
            for _, ruleid in ipairs(v.ruleids) do
                stablestate.rules[ruleid].unit_count = stablestate.rules[ruleid].unit_count - 1

                if STABLE_LOGGING then
                    print("decreasing stablestate rule count for rule id: "..ruleid..". Remaining count: "..tostring(stablestate.rules[ruleid].unit_count))
                end
            
                if stablestate.rules[ruleid].unit_count == 0 then
                    if STABLE_LOGGING then
                        print("deleting stableid sentence "..tostring(ruleid))
                    end

                    remove_stable_this_in_conds(stablestate.rules[ruleid].feature[2])
                    stablestate.rules[ruleid] = nil
                end
            end
            stablestate.units[su_key] = nil
        end
    end

    local stable_empty_tileids = {}
    for _, group in ipairs(code_stableempties) do
        for tileid, _ in pairs(group) do
            stable_empty_tileids[tileid] = true
        end
    end
    -- Deleting stable empties

    for tileid, v in pairs(stablestate.empties) do
        if not stable_empty_tileids[tileid] then
            deleted_su_key_count = deleted_su_key_count + 1
            
            delete_empty_stable_indicator(tileid)
            local deleted_stableid = stablestate.empties[tileid].stableid
            
            for _, ruleid in ipairs(v.ruleids) do
                stablestate.rules[ruleid].unit_count = stablestate.rules[ruleid].unit_count - 1
                
                if stablestate.rules[ruleid].unit_count == 0 then
                    if STABLE_LOGGING then
                        print("deleting stableid sentences "..tostring(ruleid))
                    end
                    stablestate.rules[ruleid] = nil
                end
                
                local x = math.floor(tileid % roomsizex)
                local y = math.floor(tileid / roomsizex)
                if STABLE_LOGGING then
                    print("deleting empty stableunit with position: ("..tostring(x)..","..tostring(y)..")")
                end
            end

            stablestate.empties[tileid] = nil
        end
    end
    
    for tileid, _ in pairs(stable_empty_tileids) do
        if not stablestate.empties[tileid] then
            local x = math.floor(tileid % roomsizex)
            local y = math.floor(tileid / roomsizex)

            if STABLE_LOGGING then
                print("adding targetunit name ".."empty".." with position: ("..tostring(x)..","..tostring(y)..")".." as stable unit for stable id: "..stableid)
            end

            local name = "empty"
            if not stable_rules[name] then
                -- If we haven't recorded the set of features for this name, get the features
                stable_rules[name] = get_stablefeatures_from_name(name)
            end
            
            local ruleids = {} -- Get a list of ruleids 
            for ruleid, v in pairs(stable_rules[name]) do
                table.insert(ruleids, ruleid)

                if not stablestate.rules[ruleid] then
                    stablestate.rules[ruleid] = {
                        feature = v.feature,
                        unit_count = 1,
                        display = v.display,
                    }
                else
                    stablestate.rules[ruleid].unit_count = stablestate.rules[ruleid].unit_count + 1
                end
            end

            stablestate.empties[tileid] = {
                stableid = stableid,
                ruleids = ruleids,
            }
            add_empty_stable_indicator(tileid)
            new_stableunit_count = new_stableunit_count + 1
        end
    end


    if new_stableunit_count > 0 then
        stableid = stableid + 1
    end

    if new_stableunit_count > 0 or deleted_su_key_count > 0 then
        updatecode = 1
        stable_state_updated = true
    end
end


table.insert(mod_hook_functions["rule_baserules"],
    function()
        -- adding all stablestate.rules into the featureindex
        for _, v in pairs(stablestate.rules) do
            local feature = v.feature
            addoption(feature[1], feature[2], feature[3], false, nil, feature[4], true)
            local option, conds = feature[1], feature[2]

            if STABLE_LOGGING then
                print("adding stablerule: "..option[1].." "..option[2].." "..option[3])
            end
        end
    end
)

table.insert(mod_hook_functions["rule_update_after"],
    function()
        if on_undo then
            reload_indicators()
            on_undo = false
        end
    end
)

--[[ UNDO Management ]]
table.insert(mod_hook_functions["turn_end"],
    function()        
        --Record stable undo only if turn at (previd) had some significant change to stablestate.units or stablerule
        if #undobuffer > prev_undobuffer_len then -- This check ensures that during this turn, there is some nontrivial update to any object. Prevents incremeting turnid unessescarily when the game doesn't update from player input
            turnid = turnid + 1
            if stable_state_updated then
                record_stable_undo()
            end
        end
        
        stable_state_updated = false
    end
)

-- Note: we use "undoed" instead of "undoed_after" since the former fires if the game's undo stack has an entry to pop.
-- Ideally: we won't need to rely on the undo entry being applied *before* calling this function 
table.insert(mod_hook_functions["undoed"],
    function()
        --[[ 
            Apply stable undo only if top of undo stack had turn id = previd. If so:
                - pop undo stack from back
                - peek at next elem at back and apply undo
         ]]
        local undo_applied = apply_stable_undo()
        if undo_applied then
            updatecode = 1
            on_undo = true
        end
        turnid = turnid - 1

        if STABLE_LOGGING then
            print_stable_state()
        end
    end
)

table.insert(mod_hook_functions["command_given"],
    function()
        if STABLE_LOGGING then
            print("--------turn start--------")
        end
        prev_undobuffer_len = #undobuffer
    end
)

--@cleanup: debug function. Comment out on release
table.insert(mod_hook_functions["turn_end"],
    function()
        if STABLE_LOGGING then
            print_stable_state()
            print("--------turn end--------")
        end
    end
)

--@cleanup: debug function. Comment out on release
function print_stable_state()
    print("--------Stable State---------")
    print("===stableunits===")
    for k,v in pairs(stablestate.units) do
        print("su_key: "..k.. " | Name: "..v.name.." | Stable Id: "..v.stableid)
        for _, ruleid in ipairs(v.ruleids) do
            print("\t"..ruleid)
        end
    end
    print("===stablerules===")
    -- for k,v in pairs(stablestate.rules) do
    --     print(k.." = { featurecount = "..#v.features.." | unit_count = "..v.unit_count)
    --     print("---")
    --     for _, feature in ipairs(v.features) do
    --         print(feature[1][1].." "..feature[1][2].." "..feature[1][3])
    --     end
    --     print("---")
    --     print("}")
    -- end
    
    print("------------------------")
end

--[[ Stable Indicator management ]]
function on_add_stableunit(unitid)
    local su_key = get_stableunit_key(unitid)
    if su_key and su_key ~= LEVEL_SU_KEY and stablestate.units[su_key] and not stable_indicators[su_key] then
        local stable_indicator_id = make_stable_indicator()
        stable_indicators[su_key] = { 
            indicator_id = stable_indicator_id,
            unitid = unitid
        }
    end
end

function on_delete_stableunit_key(su_key)
    if su_key and su_key ~= LEVEL_SU_KEY and stable_indicators[su_key] then
        MF_cleanremove(stable_indicators[su_key].indicator_id)
        stable_indicators[su_key] = nil
    end
end

function on_delete_stableunit(unitid)
    local su_key = get_stableunit_key(unitid)
    on_delete_stableunit_key(su_key)
end

function add_empty_stable_indicator(tileid)
    assert(tileid)
    assert(not stable_empty_indicators[tileid])
    local stable_indicator_id = make_stable_indicator()
    stable_empty_indicators[tileid] = stable_indicator_id
end

function delete_empty_stable_indicator(tileid)
    assert(tileid)
    if stable_empty_indicators[tileid] then
        MF_cleanremove(stable_empty_indicators[tileid])
        stable_empty_indicators[tileid] = nil
    end
end

function update_stable_indicator(unitid, indicator_id, tileid)
    local indicator_unit = mmf.newObject(indicator_id)

    if unitid == 2 then
        local nx = math.floor(tileid % roomsizex)
        local ny = math.floor(tileid / roomsizex)
        local indicator_tilesize = f_tilesize * generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
        indicator_unit.values[XPOS] = nx * indicator_tilesize + Xoffset + (indicator_tilesize / 2)
        indicator_unit.values[YPOS] = ny * indicator_tilesize + Yoffset + (indicator_tilesize / 2)
    else
        local unit = mmf.newObject(unitid)
        indicator_unit.values[XPOS] = unit.x
        indicator_unit.values[YPOS] = unit.y
        indicator_unit.visible = unit.visible
    end

    indicator_unit.scaleX = generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
    indicator_unit.scaleY = generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
end

local LETTER_HEIGHT = 24
local LETTER_WIDTH = 8
local LETTER_SPACING = 2
local LINE_SPACING = LETTER_HEIGHT - 4
local MARGIN = 12
local PADDING = 4

local function write_stable_rules(su_key_list, x, y, empty_tileid, timer)
    local ruleids = {}
    local ruleid_count = 0
    for _, su_key in ipairs(su_key_list) do
        for i,ruleid in ipairs(stablestate.units[su_key].ruleids) do
            if not ruleids[ruleid] then
                ruleid_count = ruleid_count + 1
            end
            ruleids[ruleid] = true
        end
    end
    if empty_tileid then
        local level_x = empty_tileid % roomsizex
        local level_y = empty_tileid / roomsizex
        assert(stablestate.empties[empty_tileid], "Stable empty at ("..tostring(level_x)..","..tostring(level_y)..") is not in stablestate")

        for i,ruleid in ipairs(stablestate.empties[empty_tileid].ruleids) do
            ruleids[ruleid] = true
            ruleid_count = ruleid_count + 1
        end
    end

    -- Determine final X
    local list_width = 0
    for ruleid, _ in pairs(ruleids) do
        local display = stablestate.rules[ruleid].display
        list_width = math.max(list_width, LETTER_WIDTH * #display + LETTER_SPACING * (#display - 1))
    end

    local x_lower_bound = Xoffset
    local x_upper_bound = Xoffset + f_tilesize * roomsizex * spritedata.values[TILEMULT] * generaldata2.values[ZOOM]

    local final_x = x
    if final_x - list_width/2 < x_lower_bound then
        final_x = x_lower_bound + list_width/2
    elseif final_x + list_width/2 > x_upper_bound then
        final_x = x_upper_bound - list_width/2
    end
    
    -- Determine final Y
    local y_lower_bound = Yoffset
    local y_upper_bound = Yoffset + f_tilesize * roomsizey * spritedata.values[TILEMULT] * generaldata2.values[ZOOM]
    local list_height = LINE_SPACING * ruleid_count
    
    local final_y = y + (f_tilesize + 4) * generaldata2.values[ZOOM]
    if final_y + list_height > y_upper_bound then
        final_y = y - list_height
        if final_y - LINE_SPACING/2 < y_lower_bound then
            final_y = y - list_height/2
        end
    end

    -- Write the rules
    local y_offset = 0
    for ruleid,_ in pairs(ruleids) do
        local display = stablestate.rules[ruleid].display
        local color = nil
        if timer < TIMER_PERIOD/2 then
            color = {3,2}
        else
            color = {1,4}
        end
        writetext(display,-1, final_x, final_y + y_offset,"stablerules",true,1,true, color)

        y_offset = y_offset + LINE_SPACING
    end
end

table.insert(mod_hook_functions["effect_always"],
    function()
        for su_key, v in pairs(stable_indicators) do
            update_stable_indicator(v.unitid, v.indicator_id)
        end
        for tileid, indicator_id in pairs(stable_empty_indicators) do
            update_stable_indicator(2, indicator_id, tileid)
        end

        local mouse_x, mouse_y = MF_mouse()
        MF_letterclear("stablerules")
        MF_letterclear("cursorpos")

        local displayed_su_keys = {}
        local half_tilesize = f_tilesize * generaldata2.values[ZOOM] * spritedata.values[TILEMULT] / 2
        local unit_x = nil
        local unit_y = nil
        for su_key, _ in pairs(stablestate.units) do
            local unitid = MF_getfixed(su_key)
            local unit = mmf.newObject(unitid)
            if unit.visible and mouse_x >= unit.x - half_tilesize and mouse_x < unit.x + half_tilesize and mouse_y >= unit.y - half_tilesize and mouse_y < unit.y + half_tilesize then
                table.insert(displayed_su_keys, su_key)
                unit_x = unit.x
                unit_y = unit.y
            end
        end

        local level_mouse_x = mouse_x - Xoffset
        local level_mouse_y = mouse_y - Yoffset
        local tile_scale = (f_tilesize * generaldata2.values[ZOOM] * spritedata.values[TILEMULT])
        local grid_x = math.floor(level_mouse_x / tile_scale)
        local grid_y = math.floor(level_mouse_y / tile_scale)

        local tileid = grid_x + grid_y * roomsizex
        local empty_tileid = nil
        if stablestate.empties[tileid] then
            unit_x = mouse_x - (level_mouse_x % tile_scale) + tile_scale / 2
            unit_y = mouse_y - (level_mouse_y % tile_scale) + tile_scale / 2
            empty_tileid = tileid
        end

        if #displayed_su_keys > 0 or empty_tileid then
            write_stable_rules(displayed_su_keys, unit_x, unit_y, empty_tileid, stablerule_timer)
        end
        stablerule_timer = stablerule_timer + 1
        if stablerule_timer >= TIMER_PERIOD then
            stablerule_timer = 0
        end
    end
)