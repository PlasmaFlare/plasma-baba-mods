splice_mod_globals = {}

function reset_splice_mod_globals()
    splice_mod_globals = {
        editor_objlist_letter_indexes = {},
        exclude_from_cut_blocking = {},
        cut_texts = {},
        calculated_text_packs = {},
        pack_texts = {},
        calling_push_check_on_pull = false,
    }
end

function reset_splice_mod_globals_per_take()
    splice_mod_globals.exclude_from_cut_blocking = {}
    splice_mod_globals.cut_texts = {}
    splice_mod_globals.calculated_text_packs = {}
    splice_mod_globals.pack_texts = {}
    splice_mod_globals.calling_push_check_on_pull = false
end

function splice_initialize()
    -- Store indexes of letterunits in editor_objectlist so that we can reference them faster
    splice_mod_globals.editor_objlist_letter_indexes = {}
    for i, v in pairs(editor_objlist) do
        if v.type == 5 and v.unittype == "text" then
            if string.sub(v.name, 1, 5) == "text_" then
                local character = string.sub(v.name, 6)
                if character ~= "sharp" and character ~= "flat" and not tonumber(character) then
                    table.insert(splice_mod_globals.editor_objlist_letter_indexes, i)
                end
            end
        end
    end     
end
reset_splice_mod_globals()
splice_initialize()

table.insert(mod_hook_functions["command_given"], 
    function()
        splice_mod_globals.exclude_from_cut_blocking = {}
        splice_mod_globals.calculated_text_packs = {}
        splice_mod_globals.cut_texts = {}
        splice_mod_globals.pack_texts = {}
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
    if pulling or textunit.strings[UNITTYPE] ~= "text" or (textunit.values[TYPE] == 5 and #textunit.strings[NAME] == 1) then
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
    -- This is to prevent stacked cut objects cutting the same text
    if splice_mod_globals.cut_texts[unitid] then
        return
    end

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
                local newunitid = create("text_"..c, x + ox, y - oy, dir, x, y, nil, nil, leveldata)

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

        if not overlap_case then
            delete(unitid,x,y)
        end
        splice_mod_globals.cut_texts[unitid] = true
        setsoundname("removal",1,sound)
    end
end

function handle_level_cutting()
    splice_mod_globals.exclude_from_cut_blocking = {}
    local cut_textunits = {} 
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


function check_text_packing(packerunitid, textunitid, dir, pulling, packer_pushed_against)
    if textunitid == 2 then
        return false
    end
    if splice_mod_globals.calling_push_check_on_pull then
        return false
    end
    local packerunit = mmf.newObject(packerunitid)
    if packerunit.strings[UNITTYPE] == "text" and packerunit.values[TYPE] == 5 then
        -- NOTE: disable any letterunits from packing for now. Actually making this work seems like a lot of wrangling with the movement system
        return false
    end

    local textunit = mmf.newObject(textunitid)
    if pulling or textunit.strings[UNITTYPE] ~= "text" or textunit.values[TYPE] ~= 5 then
        return false
    end

    local reverse = dir == 1 or dir == 2
    local dirvec = dirs[dir+1]
    
    -- local is_packer_text = false
    -- local packerunit = mmf.newObject(packerunitid)
    -- if packerunit.strings[UNITTYPE] == "text" and packerunit.values[TYPE] == 5 then
    --     is_packer_text = true
    --     local pushtest = trypush(textunitid, dirvec[1], dirvec[2], dir, false, nil, nil, "pack", packerunitid)
    --     if pushtest ~= 1 then
    --         return false
    --     end
    -- end

    local x = nil
    local y = nil
    -- if is_packer_text then
    --     x = packerunit.values[XPOS]
    --     y = packerunit.values[YPOS]
    -- else
    x = textunit.values[XPOS]
    y = textunit.values[YPOS]
    -- end

    local ox = 0
    local oy = 0
    local letterunits = {}
    local packed_text_name = ""
    local packed_text_pos = {x,y}

    if not packer_pushed_against then
        packed_text_pos[1] = packed_text_pos[1] + dirvec[1]
        packed_text_pos[2] = packed_text_pos[2] - dirvec[2]
    end

    local letterwidths = {}

    while true do
        local texts = findtext(x+ox, y-oy)
        -- Stop at stacked texts or when there's no texts
        if #texts ~= 1 then
            break
        end

        local letterunitid = texts[1]
        local letterunit = mmf.newObject(letterunitid)
        if letterunit.values[TYPE] ~= 5 then
            break
        end

        if splice_mod_globals.pack_texts[letterunitid] then
            break
        end

        if reverse then
            packed_text_name = letterunit.strings[NAME]..packed_text_name
            table.insert(letterunits, 1, letterunitid)
            table.insert(letterwidths, 1, #letterunit.strings[NAME])
        else
            packed_text_name = packed_text_name..letterunit.strings[NAME]
            table.insert(letterunits, letterunitid)
            table.insert(letterwidths, #letterunit.strings[NAME])
        end

        -- packed_text_pos[1] = x+ox
        -- packed_text_pos[2] = y-oy

        ox = ox + dirvec[1]
        oy = oy + dirvec[2]
    end

    if #letterunits == 0 then
        return false
    end

    local length = #packed_text_name 
    for i=1,length do
        if #packed_text_name > 1 and unitreference["text_"..packed_text_name] ~= nil then
            -- Due to weird legacy systems of object indexing, we have to check if the current
            -- packed text name's unit reference (i.e "object034") refers to the actual text object
            local realname = unitreference["text_"..packed_text_name]
            local dname = getactualdata_objlist(realname,"name")
            if dname == "text_"..packed_text_name then
                objectlist["text_"..packed_text_name] = 1
                break
            end
        end
        
        if reverse then
            if #letterwidths > 0 then
                for c=1,letterwidths[1] do
                    packed_text_name = packed_text_name:sub(2)
                end
            end
            table.remove(letterunits, 1)
            table.remove(letterwidths, 1)
        else
            if #letterwidths > 0 then
                for c=1,letterwidths[#letterwidths] do
                    packed_text_name = packed_text_name:sub(1,-2)
                end
            end
            table.remove(letterunits, #letterunits)
            table.remove(letterwidths, #letterwidths)
        end
        -- packed_text_pos[1] = packed_text_pos[1] - dirvec[1]
        -- packed_text_pos[2] = packed_text_pos[2] + dirvec[2]
    end

    if #letterunits <= 1 or #packed_text_name <= 1 then
        return false
    end
    
    for _, letter in ipairs(letterunits) do
        splice_mod_globals.pack_texts[letter] = true
    end
    splice_mod_globals.calculated_text_packs[textunitid] = true
    data = {
        letterunits = letterunits,
        packed_text_name = packed_text_name,
        packed_text_pos = packed_text_pos,
        packerunitid = packerunitid,
    }

    return true, data
end

function handle_text_packing(unitid, dir, pack_entry)
    if splice_mod_globals.cut_texts[unitid] then
        return
    end

    if pack_entry then
        local firstunit = mmf.newObject(unitid)
        local old_x = firstunit.values[XPOS]
        local old_y = firstunit.values[YPOS]
        for _,letterunit in ipairs(pack_entry.letterunits) do
            local u = mmf.newObject(letterunit)
            u.values[EFFECT] = 1

            local pmult,sound = checkeffecthistory("smoke")
            MF_particles("eat",u.values[XPOS],u.values[YPOS],5 * pmult,0,3,1,1)
            delete(letterunit,u.values[XPOS],u.values[YPOS])
        end
        local newunitid = create("text_"..pack_entry.packed_text_name, pack_entry.packed_text_pos[1], pack_entry.packed_text_pos[2], dir, old_x, old_y, nil, nil, nil)
        local newunit = mmf.newObject(newunitid)
        newunit.values[EFFECT] = 1

        local c1,c2 = getcolour(newunitid)
        local pmult,sound = checkeffecthistory("bling")
        MF_particles("bling",pack_entry.packed_text_pos[1],pack_entry.packed_text_pos[2],5 * pmult,c1,c2,1,1)
        generaldata.values[SHAKE] = 3
        setsoundname("turn",9,sound)
    end 

end