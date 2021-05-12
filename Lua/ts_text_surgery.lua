splice_mod_globals = {}

function reset_splice_mod_globals()
    splice_mod_globals = {
        editor_objlist_letter_indexes = {},
        exclude_from_cut_blocking = {},
    }
end

function splice_initialize()
    -- Store indexes of letterunits in editor_objectlist so that we can reference them faster
    splice_mod_globals.editor_objlist_letter_indexes = {}
    for i, v in pairs(editor_objlist) do
        if v.type == 5 and v.unittype == "text" then
            if string.sub(v.name, 1, 5) == "text_" then
                local character = string.sub(v.name, 6)
                table.insert(splice_mod_globals.editor_objlist_letter_indexes, i)
                print(character)
            end
        end
    end     
end
reset_splice_mod_globals()
splice_initialize()

table.insert(mod_hook_functions["command_given"], 
    function()
        splice_mod_globals.exclude_from_cut_blocking = {}
    end
)

function add_letterobjects_if_added_cut(editor_currobjlist, data)
    if data.name == "text_cut" then
        for _, index in pairs(splice_mod_globals.editor_objlist_letter_indexes) do
            if (#editor_currobjlist >= 150) then
                return
            end

            local alreadyadded = false
            local checkname = editor_objlist[index]
            for i,v in ipairs(editor_currobjlist) do
				if (v.name == checkname) then
                    alreadyadded = true
                    break
				end
            end
            
            if not alreadyadded then
                editor_currobjlist_add(index,false,nil,nil,nil,false)
            end
        end
    end
end

function add_moving_units_to_exclude_from_cut_blocking(moving_units)
    for i,data in ipairs(moving_units) do
        splice_mod_globals.exclude_from_cut_blocking[data.unitid] = true
    end
end

function check_text_cutting(cutterunitid, textunitid, pulling, x, y, levelcut)
    if textunitid == 2 then
        return false
    end

    local textunit = mmf.newObject(textunitid)
    if pulling or textunit.strings[UNITTYPE] ~= "text" or textunit.values[TYPE] == 5 then
        return false
    end

    if not x or not y then
        x = textunit.values[XPOS]
        y = textunit.values[YPOS]
    end

    if issafe(textunit.fixed) then
        return false
    end

    if levelcut then
        if not floating_level(textunitid) then
            return false
        end
    else
        if not floating(cutterunitid,textunitid,x,y) then
            return false
        end
    end

    -- check that all characters in the text are valid
    local name = textunit.strings[NAME]
    if not get_cut_text(name) then 
        return false 
    end

    splice_mod_globals.exclude_from_cut_blocking[textunitid] = true
    return true
end

function handle_text_cutting(unitid, dir, overlap_case)
    local bunit = mmf.newObject(unitid)
    local bname = bunit.strings[NAME]
    local leveldata = {bunit.strings[U_LEVELFILE],bunit.strings[U_LEVELNAME],bunit.flags[MAPLEVEL],bunit.values[VISUALLEVEL],bunit.values[VISUALSTYLE],bunit.values[COMPLETED],bunit.strings[COLOUR],bunit.strings[CLEARCOLOUR]}
    local x = bunit.values[XPOS]
    local y = bunit.values[YPOS]

    local dirvec = dirs[dir+1]
    local ox = dirvec[1]
    local oy = dirvec[2]

    local outstr = get_cut_text(bname)
    if outstr then
        if dir == 1 or dir == 2 then
            outstr = outstr:reverse()
        end

        for c in outstr:gmatch"." do
            local obs = findobstacle(x+ox,y-oy)
            local valid = true
            if (#obs > 0) then
                for a,b in ipairs(obs) do
                    if not splice_mod_globals.exclude_from_cut_blocking[b] then
                        if (b == -1) then
                            valid = false
                        elseif (b ~= 0) and (b ~= -1) then
                            local bunit = mmf.newObject(b)
                            local obsname = getname(bunit)
                            
                            local obsstop = hasfeature(obsname,"is","stop",b,x+ox,y+oy)
                            local obspush = hasfeature(obsname,"is","push",b,x+ox,y+oy)
                            local obspull = hasfeature(obsname,"is","pull",b,x+ox,y+oy)
                            
                            if (obsstop ~= nil) or (obspush ~= nil) or (obspull ~= nil) or (obsname == name) then
                                valid = false
                                break
                            end
                        end
                    end
                end
            else
                local obsstop = hasfeature("empty","is","stop",2,x+ox,y+oy)
                local obspush = hasfeature("empty","is","push",2,x+ox,y+oy)
                local obspull = hasfeature("empty","is","pull",2,x+ox,y+oy)
                
                if (obsstop ~= nil) or (obspush ~= nil) or (obspull ~= nil) then
                    valid = false
                end
            end

            if valid then
                objectlist[c] = 1
                local newunitid = create("text_"..c, x + ox, y - oy, 0, x, y, nil, nil, leveldata)

                splice_mod_globals.exclude_from_cut_blocking[newunitid] = true
                ox = ox + dirvec[1]
                oy = oy + dirvec[2]
            else
                break
            end
        end
        
        local pmult,sound = checkeffecthistory("cut")
        MF_particles("destroy",x,y,5 * pmult,0,3,1,1)
        generaldata.values[SHAKE] = 3

        -- @Note: if
        if not overlap_case then
            delete(unitid,x,y)
        end
        setsoundname("removal",1,sound)
    end
end

function handle_level_cutting()
    --@BIG NOTE: 
    splice_mod_globals.exclude_from_cut_blocking = {}
    local cut_textunits = {} 
    timedmessage(#codeunits)
    for a,unitid in ipairs(codeunits) do
        if check_text_cutting(nil, unitid, false, nil, nil, true) then
            table.insert(cut_textunits, unitid)
        end
    end
    for _, unitid in ipairs(cut_textunits) do
        local textunit = mmf.newObject(unitid)
        handle_text_cutting(unitid, textunit.values[DIR], false)
    end
    splice_mod_globals.exclude_from_cut_blocking = {}
end