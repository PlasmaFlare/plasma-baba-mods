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

