function undo()
	local result = 0
	
	if (#undobuffer > 1) then
		result = 1
		local currentundo = undobuffer[2]
		
		do_mod_hook("undoed")
		
		last_key = currentundo.key or 0
		Fixedseed = currentundo.fixedseed or 100
		
		if (currentundo ~= nil) then
			for i,line in ipairs(currentundo) do
				local style = line[1]
				
				if (style == "update") then
					local uid = line[9]
					
					if (paradox[uid] == nil) then
						local unitid = getunitid(line[9])
						
						local unit = mmf.newObject(unitid)
						
						local oldx,oldy = unit.values[XPOS],unit.values[YPOS]
						local x,y,dir = line[3],line[4],line[5]
						unit.values[XPOS] = x
						unit.values[YPOS] = y
						unit.values[DIR] = dir
						unit.values[POSITIONING] = 0
						
						updateunitmap(unitid,oldx,oldy,x,y,unit.strings[UNITNAME])
						dynamic(unitid)
						dynamicat(oldx,oldy)
						
						if (spritedata.values[CAMTARGET] == uid) then
							MF_updatevision(dir)
						end
						
						local ox = math.abs(oldx-x)
						local oy = math.abs(oldy-y)
						
						if (ox + oy == 1) and (unit.values[TILING] == 2) then
							unit.values[VISUALDIR] = ((unit.values[VISUALDIR] - 1)+4) % 4
							unit.direction = unit.values[DIR] * 8 + unit.values[VISUALDIR]
						end
						
						if (unit.strings[UNITTYPE] == "text") then
							updatecode = 1
						end
						
						local undowordunits = currentundo.wordunits
						local undogroupunits = currentundo.groupunits
						local undowordrelatedunits = currentundo.wordrelatedunits
						
						if (#undowordunits > 0) then
							for a,b in pairs(undowordunits) do
								if (b == line[9]) then
									updatecode = 1
								end
							end
						end
						
						if (#undogroupunits > 0) then
							for a,b in ipairs(undogroupunits) do
								if (b == unit.strings[UNITNAME]) then
									updatecode = 1
								end
							end
						end
						
						if (#undowordrelatedunits > 0) then
							for a,b in pairs(undowordrelatedunits) do
								if (b == line[9]) then
									updatecode = 1
								end
							end
						end

						-- set_tt_display_direction(unit)
					else
						particles("hot",line[3],line[4],1,{1, 1})
					end
				elseif (style == "remove") then
					local uid = line[6]
					local baseuid = line[7] or -1
					
					if (paradox[uid] == nil) and (paradox[baseuid] == nil) then
						local x,y,dir,levelfile,levelname,vislevel,complete,visstyle,maplevel,colour,clearcolour,followed,back_init = line[3],line[4],line[5],line[8],line[9],line[10],line[11],line[12],line[13],line[14],line[15],line[16],line[17]
						local name = line[2]
						
						local unitname = ""
						local unitid = 0
						
						--MF_alert("Trying to create " .. name .. ", " .. tostring(unitreference[name]))
						unitname = unitreference[name]
						unitid = MF_emptycreate(unitname,x,y)
						
						local unit = mmf.newObject(unitid)
						unit.values[ONLINE] = 1
						unit.values[XPOS] = x
						unit.values[YPOS] = y
						unit.values[DIR] = dir
						unit.values[ID] = line[6]
						unit.flags[9] = true
						
						unit.strings[U_LEVELFILE] = levelfile
						unit.strings[U_LEVELNAME] = levelname
						unit.flags[MAPLEVEL] = maplevel
						unit.values[VISUALLEVEL] = vislevel
						unit.values[VISUALSTYLE] = visstyle
						unit.values[COMPLETED] = complete
						
						unit.strings[COLOUR] = colour
						unit.strings[CLEARCOLOUR] = clearcolour
						
						if (unit.className == "level") then
							MF_setcolourfromstring(unitid,colour)
						end
						
						addunit(unitid,true)
						addunitmap(unitid,x,y,unit.strings[UNITNAME])
						dynamic(unitid)
						
						unit.followed = followed
						unit.back_init = back_init
						
						if (unit.strings[UNITTYPE] == "text") then
							updatecode = 1
						end
						
						if (spritedata.values[VISION] == 1) then
							if (unit.values[ZLAYER] <= 15) then
								if (unit.values[ZLAYER] > 10) then
									setupvision_wall(unit.fixed)
								end
								
								MF_setupvision_single(unit.fixed)
							end
						end
						
						local undowordunits = currentundo.wordunits
						local undogroupunits = currentundo.groupunits
						local undowordrelatedunits = currentundo.wordrelatedunits
						
						if (#undowordunits > 0) then
							for a,b in ipairs(undowordunits) do
								if (b == line[6]) then
									updatecode = 1
								end
							end
						end
						
						if (#undogroupunits > 0) then
							for a,b in ipairs(undogroupunits) do
								--MF_alert("Check " .. tostring(b) .. ", " .. tostring(line[6]))
								if (b == unit.strings[UNITNAME]) then
									updatecode = 1
								end
							end
						end
						
						if (#undowordrelatedunits > 0) then
							for a,b in ipairs(undowordrelatedunits) do
								if (b == line[6]) then
									updatecode = 1
								end
							end
						end
					else
						particles("hot",line[3],line[4],1,{1, 1})
					end
				elseif (style == "create") then
					local uid = line[3]
					local baseid = line[4]
					local source = line[5]
					
					if (paradox[uid] == nil) then
						local unitid = getunitid(line[3])
						
						local unit = mmf.newObject(unitid)
						local unitname = unit.strings[UNITNAME]
						local x,y = unit.values[XPOS],unit.values[YPOS]
						local unittype = unit.strings[UNITTYPE]
						
						unit = {}
						delunit(unitid)
						MF_remove(unitid)
						dynamicat(x,y)
						
						if (unittype == "text") then
							updatecode = 1
						end
						
						local undowordunits = currentundo.wordunits
						local undogroupunits = currentundo.groupunits
						local undowordrelatedunits = currentundo.wordrelatedunits
						
						if (#undowordunits > 0) then
							for a,b in ipairs(undowordunits) do
								if (b == line[3]) then
									updatecode = 1
								end
							end
						end
						
						if (#undogroupunits > 0) then
							for a,b in ipairs(undogroupunits) do
								if (b == unitname) then
									updatecode = 1
								end
							end
						end
						
						if (#undowordrelatedunits > 0) then
							for a,b in ipairs(undowordrelatedunits) do
								if (b == line[3]) then
									updatecode = 1
								end
							end
						end
					end
				elseif (style == "backset") then
					local uid = line[3]
					
					if (paradox[uid] == nil) then
						local unitid = getunitid(line[3])
						local unit = mmf.newObject(unitid)
						
						unit.back_init = line[4]
					end
				elseif (style == "done") then
					local unitid = line[7]
					--print(unitid)
					local unit = mmf.newObject(unitid)
					
					unit.values[FLOAT] = line[8]
					unit.angle = 0
					unit.values[POSITIONING] = 0
					unit.values[A] = 0
					unit.values[VISUALLEVEL] = 0
					unit.flags[DEAD] = false
					
					--print(unit.className .. ", " .. tostring(unitid) .. ", " .. tostring(line[3]) .. ", " .. unit.strings[UNITNAME])
					
					addunit(unitid,true)
				elseif (style == "float") then
					local uid = line[3]
					
					if (paradox[uid] == nil) then
						local unitid = getunitid(line[3])
						
						-- K�kk� ratkaisu!
						if (unitid ~= nil) and (unitid ~= 0) then
							local unit = mmf.newObject(unitid)
							unit.values[FLOAT] = tonumber(line[4])
						end
					end
				elseif (style == "levelupdate") then
					MF_setroomoffset(line[2],line[3])
					mapdir = line[6]
				elseif (style == "maprotation") then
					maprotation = line[2]
					MF_levelrotation(maprotation)
				elseif (style == "mapdir") then
					mapdir = line[2]
				elseif (style == "mapcursor") then
					mapcursor_set(line[3],line[4],line[5],line[10])
					
					local undowordunits = currentundo.wordunits
					local undogroupunits = currentundo.groupunits
					local undowordrelatedunits = currentundo.wordrelatedunits
					
					local unitid = getunitid(line[10])
					if (unitid ~= nil) and (unitid ~= 0) then
						local unit = mmf.newObject(unitid)
						
						if (unit.strings[UNITTYPE] == "text") then
							updatecode = 1
						end
						
						if (#undogroupunits > 0) then
							for a,b in pairs(undogroupunits) do
								if (b == unit.strings[UNITNAME]) then
									updatecode = 1
								end
							end
						end
					end
					
					if (#undowordunits > 0) then
						for a,b in pairs(undowordunits) do
							if (b == line[10]) then
								updatecode = 1
							end
						end
					end
					
					if (#undowordrelatedunits > 0) then
						for a,b in pairs(undowordrelatedunits) do
							if (b == line[10]) then
								updatecode = 1
							end
						end
					end
				elseif (style == "colour") then
					local unitid = getunitid(line[2])
					MF_setcolour(unitid,line[3],line[4])
					local unit = mmf.newObject(unitid)
					unit.values[A] = line[5]
				elseif (style == "broken") then
					local unitid = getunitid(line[3])
					local unit = mmf.newObject(unitid)
					MF_alert(unit.strings[UNITNAME])
					unit.broken = 1 - line[2]
				elseif (style == "bonus") then
					local style = 1 - line[2]
					MF_bonus(style)
				elseif (style == "followed") then
					local unitid = getunitid(line[2])
					local unit = mmf.newObject(unitid)
					
					unit.followed = line[3]
				end
			end
		end
		
		local nextundo = undobuffer[1]
		nextundo.wordunits = {}
		nextundo.groupunits = {}
		nextundo.wordrelatedunits = {}
		nextundo.fixedseed = Fixedseed
		for i,v in ipairs(currentundo.wordunits) do
			table.insert(nextundo.wordunits, v)
		end
		for i,v in ipairs(currentundo.groupunits) do
			table.insert(nextundo.groupunits, v)
		end
		for i,v in ipairs(currentundo.wordrelatedunits) do
			table.insert(nextundo.wordrelatedunits, v)
		end
        table.remove(undobuffer, 2)
        
        --@TT todo- replace this with mod hook for after undo once it has been implemented
        for i,unitid in ipairs(codeunits) do
            local unit = mmf.newObject(unitid)
            set_tt_display_direction(unit)
        end
	end
	
	--MF_alert("Current fixed seed: " .. tostring(Fixedseed))
	
	return result
end