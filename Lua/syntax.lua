function addunit(id,undoing_,levelstart_)
	--[[ 
		@mods(this) - Override reason: provide hook for detecting when a "this" text is added, so that
			we keep track of all "this" texts
	 ]]
	local unitid = #units + 1
	
	units[unitid] = {}
	units[unitid] = mmf.newObject(id)
	
	local unit = units[unitid]
	local undoing = undoing_ or false
	local levelstart = levelstart_ or false
	
	getmetadata(unit)
	
	local truename = unit.className
	
	if (changes[truename] ~= nil) then
		dochanges(id)
	end
	
	if (unit.values[ID] == -1) then
		unit.values[ID] = newid()
	end

	if (unit.values[XPOS] > 0) and (unit.values[YPOS] > 0) then
		addunitmap(id,unit.values[XPOS],unit.values[YPOS],unit.strings[UNITNAME])
	end
	
	if (unit.values[TILING] == 1) then
		table.insert(tiledunits, unit.fixed)
	end
	
	if (unit.values[TILING] > 1) then
		table.insert(animunits, unit.fixed)
	end
	
	local name = getname(unit)
	local name_ = unit.strings[NAME]

	if is_name_text_this(name_) then
		on_add_this_text(unit.fixed)
	end

	on_add_stableunit(unit.fixed)
	
	if (unitlists[name] == nil) then
		unitlists[name] = {}
	end
	
	table.insert(unitlists[name], unit.fixed)
	
	if (unit.strings[UNITTYPE] ~= "text") or ((unit.strings[UNITTYPE] == "text") and (unit.values[TYPE] == 0)) then
		objectlist[name_] = 1
	end
	
	if (unit.strings[UNITTYPE] == "text") then
		table.insert(codeunits, unit.fixed)
		updatecode = 1
		
		if (unit.values[TYPE] == 0) then
			local matname = string.sub(unit.strings[UNITNAME], 6)
			if (unitlists[matname] == nil) then
				unitlists[matname] = {}
			end
		elseif (unit.values[TYPE] == 5) then
			table.insert(letterunits, unit.fixed)
		end
	end
	
	unit.colour = {}
	
	if (unit.strings[UNITNAME] ~= "level") and (unit.className ~= "specialobject") then
		local cc1,cc2 = setcolour(unit.fixed)
		unit.colour = {cc1,cc2}
	end
	
	unit.back_init = 0
	unit.broken = 0
	
	if (unit.className ~= "path") and (unit.className ~= "specialobject") then
		statusblock({id},undoing)
		MF_animframe(id,math.random(0,2))
	end
	
	unit.active = false
	unit.new = true
	unit.colours = {}
	unit.currcolour = 0
	unit.followed = -1
	unit.xpos = unit.values[XPOS]
	unit.ypos = unit.values[YPOS]
	
	if (spritedata.values[VISION] == 1) and (undoing == false) then
		local hasvision = hasfeature(name,"is","3d",id,unit.values[XPOS],unit.values[YPOS])
		if (hasvision ~= nil) then
			table.insert(visiontargets, id)
		elseif (spritedata.values[CAMTARGET] == unit.values[ID]) then
			visionmode(0,0,nil,{unit.values[XPOS],unit.values[YPOS],unit.values[DIR]})
		end
	end
	
	if (spritedata.values[VISION] == 1) and (spritedata.values[CAMTARGET] ~= unit.values[ID]) then
		if (unit.values[ZLAYER] <= 15) then
			if (unit.values[ZLAYER] > 10) then
				setupvision_wall(unit.fixed)
			end
			
			MF_setupvision_single(unit.fixed)
		end
	end
	
	if generaldata.flags[LOGGING] and (generaldata.flags[RESTARTED] == false) then
		if levelstart then
			dolog("init_object","event",unit.strings[UNITNAME] .. ":" .. tostring(unit.values[XPOS]) .. ":" .. tostring(unit.values[YPOS]))
		elseif (undoing == false) then
			dolog("new_object","event",unit.strings[UNITNAME] .. ":" .. tostring(unit.values[XPOS]) .. ":" .. tostring(unit.values[YPOS]))
		end
	end
end

function command(key,player_)
	--[[ 
		@mods(turning text) - Override reason: fixes a bug where if "level is auto" "baba is you" "bird is you2 (down)", pressing "S" will make both baba and bird move down. (Only bird should move down)
	 ]]
	local keyid = -1
	if (keys[key] ~= nil) then
		keyid = keys[key]
	else
		print("no such key")
		return
	end
	
	local player = 1
	if (player_ ~= nil) then
		player = player_
	end
	
	do_mod_hook("command_given", {key,player})
	
	if (keyid <= 4) then
		if (generaldata5.values[AUTO_ON] == 0) then
			local drs = ndirs[keyid+1]
			local ox = drs[1]
			local oy = drs[2]
			local dir = keyid
			
			last_key = keyid
			
			if (auto_dir[player] == nil) then
				auto_dir[player] = 4
			end
			
			auto_dir[player] = keyid
			
			if (spritedata.values[VISION] == 1) and (dir == 3) then
				if (#units > 0) then
					changevisiontarget()
				end
				movecommand(ox,oy,dir,player,nil,true)
				MF_update()
			else
				movecommand(ox,oy,dir,player)
				MF_update()
			end
		else
			if (auto_dir[player] == nil) then
				auto_dir[player] = 4
			end
			
			auto_dir[player] = keyid
			
			if (auto_dir[1] == nil) and (featureindex["you2"] == nil) 
				and featureindex["you2right"] == nil 
				and featureindex["you2left"] == nil 
				and featureindex["you2up"] == nil 
				and featureindex["you2down"] == nil 
				then
				auto_dir[1] = keyid
			end
		end
	end
	
	if (keyid == 5) then
		MF_restart(false)
		do_mod_hook("level_restart", {})
	elseif (keyid == 8) then
		MF_restart(true)
		do_mod_hook("level_restart", {})
	end
	
	dolog(key)
end

