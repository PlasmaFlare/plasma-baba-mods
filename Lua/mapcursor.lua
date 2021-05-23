function mapcursor_move(ox,oy,mdir)
	-- @Mods
	-- Turning text - Override reason: mod hook for directional select
	local dir = mdir or 4
    
    group_arrow_properties = false
    local cursors = getunitswitheffect("select",true)
    for i,dircursorunit in ipairs(do_directional_select(mdir)) do
        table.insert(cursors, dircursorunit)
    end
    group_arrow_properties = true
	
	for i,unit in ipairs(cursors) do
		local x_,y_,dir_ = unit.values[XPOS],unit.values[YPOS],unit.values[DIR]
		local currlevel = unit.values[CURSOR_ONLEVEL]
		
		local unitname = getname(unit)
		local still = hasfeature(unitname,"is","still",unit.fixed,x_,y_)
		
		local x = x_ + ox
		local y = y_ + oy
		
		unit.flags[CURSOR_LIMITER] = false
		local levelfound = false
		local moved = false
		
		if (still == nil) then
			local targets = findallhere(x,y,unit.fixed,true)
			
			for a,b in ipairs(targets) do
				local lunit = mmf.newObject(b)
				
				if lunit.visible and (lunit.flags[DEAD] == false) and (lunit.values[COMPLETED] > 1) then
					editor.values[NAMEFLAG] = 0
					moved = true
					
					if (unit.flags[CURSOR_LIMITER] == false) and (string.len(lunit.strings[U_LEVELFILE]) == 0) then
						unit.values[CURSOR_ONLEVEL] = b
						break
					elseif (string.len(lunit.strings[U_LEVELFILE]) > 0) then
						unit.values[CURSOR_ONLEVEL] = b
						unit.flags[CURSOR_LIMITER] = true
						levelfound = true
						break
					end
				end
			end
		end
		
		if moved then
			unit.values[XPOS] = x
			unit.values[YPOS] = y
			unit.values[DIR] = dir
			unit.values[POSITIONING] = 0
			addundo({"mapcursor",currlevel,x_,y_,dir_,unit.values[CURSOR_ONLEVEL],x,y,dir,unit.values[ID]})
			updateundo = true
			
			checkwordchanges(unit.fixed,unit.strings[UNITNAME])
			
			if (levelfound == false) then
				editor.values[NAMEFLAG] = 0
				unit.values[CURSOR_ONLEVEL] = 0
			end
			
			if (unit.strings[UNITTYPE] == "text") then
				updatecode = 1
			end
			
			if (generaldata5.values[AUTO_ON] == 1) and (generaldata2.strings[TURNSOUND] == "") and (dir == 4) then
				generaldata2.strings[TURNSOUND] = "silent"
			end
		end
	end
end

