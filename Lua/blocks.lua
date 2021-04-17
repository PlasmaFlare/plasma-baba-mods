function moveblock(onlystartblock_)
	local onlystartblock = onlystartblock_ or false
	
	local isshift,istele = {},{}
	local isfollow = findfeature(nil,"follow",nil,true)
	
	if (onlystartblock == false) then
		isshift = findallfeature(nil,"is","shift",true)
		istele = findallfeature(nil,"is","tele",true)
	end
	
	local doned = {}
	
	if (isfollow ~= nil) then
		for h,j in ipairs(isfollow) do
			local allfollows = findall(j)
			
			if (#allfollows > 0) then
				for k,l in ipairs(allfollows) do
					if (issleep(l) == false) then
						local unit = mmf.newObject(l)
						local x,y,name,dir = unit.values[XPOS],unit.values[YPOS],unit.strings[UNITNAME],unit.values[DIR]
						local unitrules = {}
						local followedfound = false
						
						if (unit.strings[UNITTYPE] == "text") then
							name = "text"
						end
						
						if (featureindex[name] ~= nil) then					
							for a,b in ipairs(featureindex[name]) do
								local baserule = b[1]
								local conds = b[2]
								
								local verb = baserule[2]
								
								if (verb == "follow") then
									if testcond(conds,l) then
										table.insert(unitrules, b)
									end
								end
							end
						end
						
						local follow = xthis(unitrules,name,"follow")
						
						if (#follow > 0) and (unit.flags[DEAD] == false) then
							local distance = 9999
							local targetdir = -1
							local stophere = false
							local highesttarget = false
							local counterclockwise = false
							
							local priorityfollow = -1
							local priorityfollowdir = -1
							
							local highpriorityfollow = -1
							local highpriorityfollowdir = -1
							
							for i,v in ipairs(follow) do
								local these = findall({v})
								
								if (#these > 0) and (stophere == false) then
									for a,b in ipairs(these) do
										if (b ~= unit.fixed) and (stophere == false) then
											local funit = mmf.newObject(b)
											
											local fx,fy = funit.values[XPOS],funit.values[YPOS]
											
											local xdir = fx-x
											local ydir = fy-y
											local dist = math.abs(xdir) + math.abs(ydir)
											local fdir = -1
											
											if (math.abs(xdir) <= math.abs(ydir)) then
												if (ydir >= 0) then
													fdir = 3
												else
													fdir = 1
												end
											else
												if (xdir > 0) then
													fdir = 0
												else
													fdir = 2
												end
											end
											
											if (dist <= distance) and (dist > 0) then
												distance = dist
												targetdir = fdir
												
												--MF_alert(name .. ": suggested dir " .. tostring(targetdir))
												
												if (dist == 1) then
													if (unit.followed ~= funit.values[ID]) then
														local ndrs = ndirs[dir + 1]
														local ox,oy = ndrs[1],ndrs[2]
														
														priorityfollow = funit.values[ID]
														priorityfollowdir = targetdir
														
														if (x + ox == fx) and (y + oy == fy) then
															highpriorityfollow = funit.values[ID]
															highpriorityfollowdir = targetdir
															highesttarget = true
															--MF_alert(tostring(unit.fixed) .. " moves forward: " .. tostring(dir) .. ", " .. tostring(targetdir))
														elseif (highesttarget == false) then
															local turnl = (dir + 1 + 4) % 4
															local ndrsl = ndirs[turnl + 1]
															local oxl,oyl = ndrsl[1],ndrsl[2]
															
															if (x + oxl == fx) and (y + oyl == fy) then
																highpriorityfollow = funit.values[ID]
																highpriorityfollowdir = targetdir
																counterclockwise = true
																--MF_alert(tostring(unit.fixed) .. " turns left: " .. tostring(dir) .. ", " .. tostring(turnl) .. ", " .. tostring(targetdir))
															elseif (counterclockwise == false) then
																local turnr = (dir - 1 + 4) % 4
																local ndrsr = ndirs[turnr + 1]
																local oxr,oyr = ndrsr[1],ndrsr[2]
																
																if (x + oxr == fx) and (y + oyr == fy) then
																	highpriorityfollow = funit.values[ID]
																	highpriorityfollowdir = targetdir
																	--MF_alert(tostring(unit.fixed) .. " turns right: " .. tostring(dir) .. ", " .. tostring(turnr) .. ", " .. tostring(targetdir))
																end
															end
														end
													else
														followedfound = true
														stophere = true
														break
													end
												end
											end
										end
									end
									
									if stophere then
										break
									end
								end
								
								if stophere then
									break
								end
							end
							
							if (followedfound == false) then
								if (highpriorityfollow > -1) then
									if (onlystartblock == false) then
										addundo({"followed",unit.values[ID],unit.followed,highpriorityfollow},unit.fixed)
									end
									unit.followed = highpriorityfollow
									targetdir = highpriorityfollowdir
									stophere = true
									followedfound = true
								elseif (priorityfollow > -1) then
									if (onlystartblock == false) then
										addundo({"followed",unit.values[ID],unit.followed,priorityfollow},unit.fixed)
									end
									unit.followed = priorityfollow
									targetdir = priorityfollowdir
									stophere = true
									followedfound = true
								elseif (unit.followed > -1) then
									if (onlystartblock == false) then
										addundo({"followed",unit.values[ID],unit.followed,0},unit.fixed)
									end
									unit.followed = -1
								end
							end
			
							if (targetdir >= 0) then
								--MF_alert(unit.strings[UNITNAME] .. " faces to " .. tostring(targetdir))
								updatedir(unit.fixed,targetdir,onlystartblock)
							end
						end
					end
				end
			end
		end
	end
	
	if (onlystartblock == false) then
		local isback = findallfeature(nil,"is","back",true)
		
		for i,unitid in ipairs(isback) do
			local unit = mmf.newObject(unitid)
			
			local undooffset = #undobuffer - unit.back_init
			
			local undotargetid = undooffset * 2 + 1
			
			if (undotargetid <= #undobuffer) and (unit.back_init > 0) and (unit.flags[DEAD] == false) then
				local currentundo = undobuffer[undotargetid]
				
				particles("wonder",unit.values[XPOS],unit.values[YPOS],1,{3,0})
				
				updateundo = true
				
				if (currentundo ~= nil) then
					for a,line in ipairs(currentundo) do
						local style = line[1]
						
						if (style == "update") and (line[9] == unit.values[ID]) then
							local uid = line[9]
							
							if (paradox[uid] == nil) then
								local ux,uy = unit.values[XPOS],unit.values[YPOS]
								local oldx,oldy = line[6],line[7]
								local x,y,dir = line[3],line[4],line[5]
								
								local ox = x - oldx
								local oy = y - oldy
								
								--[[
								Enable this to make the Back effect relative to current position
								x = ux + ox
								y = uy + oy
								]]--
								
								--MF_alert(unit.strings[UNITNAME] .. " is being updated from " .. tostring(ux) .. ", " .. tostring(uy) .. ", offset " .. tostring(ox) .. ", " .. tostring(oy))
								
								if (ox ~= 0) or (oy ~= 0) then
									addaction(unitid,{"update",x,y,dir})
								else
									addaction(unitid,{"updatedir",dir})
								end
								updateundo = true
								
								if (objectdata[unitid] == nil) then
									objectdata[unitid] = {}
								end
								
								local odata = objectdata[unitid]
								
								odata.tele = 1
							else
								particles("hot",line[3],line[4],1,{1, 1})
								updateundo = true
							end
						elseif (style == "create") and (line[3] == unit.values[ID]) then
							local uid = line[4]
							
							--MF_alert(unit.strings[UNITNAME] .. " back: " .. tostring(uid) .. ", " .. tostring(line[3]))
							
							if (paradox[uid] == nil) then
								local name = unit.strings[UNITNAME]
								
								local delname = {}
								
								for b,bline in ipairs(currentundo) do
									--MF_alert(" -- " .. bline[1] .. ", " .. tostring(bline[6]))
									
									if (bline[1] == "remove") and (bline[6] == uid) then
										local x,y,dir,levelfile,levelname,vislevel,complete,visstyle,maplevel,colour,clearcolour,followed,back_init = bline[3],bline[4],bline[5],bline[8],bline[9],bline[10],bline[11],bline[12],bline[13],bline[14],bline[15],bline[16],bline[17]
										
										local newname = bline[2]
										
										local newunitname = ""
										local newunitid = 0
										
										local ux,uy = unit.values[XPOS],unit.values[YPOS]
										
										newunitname = unitreference[newname]
										newunitid = MF_emptycreate(newunitname,ux,uy)
										
										local newunit = mmf.newObject(newunitid)
										newunit.values[ONLINE] = 1
										newunit.values[XPOS] = ux
										newunit.values[YPOS] = uy
										newunit.values[DIR] = dir
										newunit.values[ID] = bline[6]
										newunit.flags[9] = true
										
										newunit.strings[U_LEVELFILE] = levelfile
										newunit.strings[U_LEVELNAME] = levelname
										newunit.flags[MAPLEVEL] = maplevel
										newunit.values[VISUALLEVEL] = vislevel
										newunit.values[VISUALSTYLE] = visstyle
										newunit.values[COMPLETED] = complete
										
										newunit.strings[COLOUR] = colour
										newunit.strings[CLEARCOLOUR] = clearcolour
										
										if (newunit.className == "level") then
											MF_setcolourfromstring(newunitid,colour)
										end
										
										addunit(newunitid,true)
										addunitmap(newunitid,x,y,newunit.strings[UNITNAME])
										dynamic(unitid)
										
										newunit.followed = followed
										newunit.back_init = back_init
										
										if (newunit.strings[UNITTYPE] == "text") then
											updatecode = 1
										end
										
										local undowordunits = currentundo.wordunits
										local undowordrelatedunits = currentundo.wordrelatedunits
										
										if (#undowordunits > 0) then
											for a,b in ipairs(undowordunits) do
												if (b == bline[6]) then
													updatecode = 1
												end
											end
										end
										
										local uname = getname(newunit)
										
										if (#undowordrelatedunits > 0) then
											for a,b in ipairs(undowordrelatedunits) do
												if (b == bline[6]) then
													updatecode = 1
												end
											end
										end
										
										table.insert(delname, {newunit.strings[UNITNAME], bline[6]})
									end
								end
								
								addundo({"remove",unit.strings[UNITNAME],unit.values[XPOS],unit.values[YPOS],unit.values[DIR],unit.values[ID],unit.values[ID],unit.strings[U_LEVELFILE],unit.strings[U_LEVELNAME],unit.values[VISUALLEVEL],unit.values[COMPLETED],unit.values[VISUALSTYLE],unit.flags[MAPLEVEL],unit.strings[COLOUR],unit.strings[CLEARCOLOUR],unit.followed,unit.back_init})
								
								for a,b in ipairs(delname) do
									MF_alert("added undo for " .. b[1] .. " with ID " .. tostring(b[2]))
									addundo({"create",b[1],b[2],b[2],"back"})
								end
								
								delunit(unitid)
								dynamic(unitid)
								MF_specialremove(unitid,2)
							end
						end
					end
				end
			end
		end
		
		doupdate()
		
		for i,unitid in ipairs(istele) do
			if (isgone(unitid) == false) then
				local unit = mmf.newObject(unitid)
				local name = getname(unit)
				local x,y = unit.values[XPOS],unit.values[YPOS]
			
				local targets = findallhere(x,y)
				local telethis = false
				local telethisx,telethisy = 0,0
				
				if (#targets > 0) then
					for i,v in ipairs(targets) do
						local vunit = mmf.newObject(v)
						local thistype = vunit.strings[UNITTYPE]
						local vname = getname(vunit)
						
						local targetvalid = isgone(v)
						local targetstill = hasfeature(vname,"is","still",v,x,y)
						-- Luultavasti ei väliä onko kohde tuhoutumassa?
						
						if (targetstill == nil) and floating(v,unitid,x,y) then
							local targetname = getname(vunit)
							if (objectdata[v] == nil) then
								objectdata[v] = {}
							end
							
							local odata = objectdata[v]
							
							if (odata.tele == nil) then
								if (targetname ~= name) and (v ~= unitid) then
									local teles = istele
									
									if (#teles > 1) then
										local teletargets = {}
										local targettele = 0
										
										for a,b in ipairs(teles) do
											local tele = mmf.newObject(b)
											local telename = getname(tele)
											
											if (b ~= unitid) and (telename == name) and (tele.flags[DEAD] == false) then
												table.insert(teletargets, b)
											end
										end
										
										if (#teletargets > 0) then
											local randomtarget = fixedrandom(1, #teletargets)
											targettele = teletargets[randomtarget]
											local limit = 0
											
											while (targettele == unitid) and (limit < 10) do
												randomtarget = fixedrandom(1, #teletargets)
												targettele = teletargets[randomtarget]
												limit = limit + 1
											end
											
											odata.tele = 1
											
											local tele = mmf.newObject(targettele)
											local tx,ty = tele.values[XPOS],tele.values[YPOS]
											local vx,vy = vunit.values[XPOS],vunit.values[YPOS]
										
											update(v,tx,ty)
											
											local pmult,sound = checkeffecthistory("tele")
											
											MF_particles("glow",vx,vy,5 * pmult,1,4,1,1)
											MF_particles("glow",tx,ty,5 * pmult,1,4,1,1)
											setsoundname("turn",6,sound)
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	
	if enable_directional_shift then
		--@Turning Text(shift)
		do_directional_shift_moveblock()
	else
		for a,unitid in ipairs(isshift) do
			if (unitid ~= 2) and (unitid ~= 1) then
				local unit = mmf.newObject(unitid)
				local x,y,dir = unit.values[XPOS],unit.values[YPOS],unit.values[DIR]
				
				local things = findallhere(x,y,unitid)
				
				if (#things > 0) and (isgone(unitid) == false) then
					for e,f in ipairs(things) do
						if floating(unitid,f,x,y) and (issleep(unitid,x,y) == false) then
							local newunit = mmf.newObject(f)
							local name = newunit.strings[UNITNAME]
							
							if (newunit.flags[DEAD] == false) then
								addundo({"update",name,x,y,newunit.values[DIR],x,y,unit.values[DIR],newunit.values[ID]})
								newunit.values[DIR] = unit.values[DIR]
								
								--@ Turning text --
								if is_turning_text(newunit.strings[NAME]) then
									updatecode = 1
								end
								--@ Turning text --
							end
						end
					end
				end
			end
		end
		
		doupdate()
	end
end

function block(small_)
	local delthese = {}
	local doned = {}
	local unitsnow = #units
	local removalsound = 1
	local removalshort = ""
	
	local small = small_ or false
	
	local doremovalsound = false

	--@Turning Text ----------------
	group_arrow_properties = false
	----------------------
	
	if (small == false) then
		if (generaldata2.values[ENDINGGOING] == 0) then
			local isdone = getunitswitheffect("done",false,delthese)
			
			for id,unit in ipairs(isdone) do
				table.insert(doned, unit)
			end
			
			if (#doned > 0) then
				setsoundname("turn",10)
			end
		end
		
		local ismore = getunitswitheffect("more",false,delthese)

		for id,unit in ipairs(ismore) do
			local x,y = unit.values[XPOS],unit.values[YPOS]
			local name = getname(unit)
			local doblocks = {}
			
			for i=1,4 do
				local drs = ndirs[i]
				ox = drs[1]
				oy = drs[2]
				
				local valid = true
				local obs = findobstacle(x+ox,y+oy)
				local tileid = (x+ox) + (y+oy) * roomsizex
				
				if (#obs > 0) then
					for a,b in ipairs(obs) do
						if (b == -1) then
							valid = false
						elseif (b ~= 0) and (b ~= -1) then
							local bunit = mmf.newObject(b)
							local obsname = getname(bunit)
							
							local obsstop = hasfeature(obsname,"is","stop",b,x+ox,y+oy)
							local obspush = hasfeature(obsname,"is","push",b,x+ox,y+oy)
							local obspull = hasfeature(obsname,"is","pull",b,x+ox,y+oy)

							obsstop, obspush, obspull = do_directional_collision(i-1, obsname, b, obsstop, obspush, obspull, x,y,ox,oy, false)
							
							if (obsstop ~= nil) or (obspush ~= nil) or (obspull ~= nil) or (obsname == name) then
								valid = false
								break
							end
						end
					end
				else
					local obsstop = hasfeature("empty","is","stop",2,x+ox,y+oy)
					local obspush = hasfeature("empty","is","push",2,x+ox,y+oy)
					local obspull = hasfeature("empty","is","pull",2,x+ox,y+oy)

					obsstop, obspush, obspull = do_directional_collision(i-1, obsname, 2, obsstop, obspush, obspull, x,y,ox,oy, false)
					
					if (obsstop ~= nil) or (obspush ~= nil) or (obspull ~= nil) then
						valid = false
					end
				end
				
				if valid then
					local newunit = copy(unit.fixed,x+ox,y+oy)
				end
			end
		end

		--@Turning Text(more)
		do_directional_more(ismore, delthese)
		group_arrow_properties = true
	end

	
	local isplay = getunitswithverb("play",delthese)
	
	for id,ugroup in ipairs(isplay) do
		local sound_freq = ugroup[1]
		local sound_units = ugroup[2]
		local sound_name = ugroup[3]
		
		if (#sound_units > 0) then
			local ptunes = play_data.tunes
			local pfreqs = play_data.freqs
			local multisample = false
			
			local tune = "beep"
			local freq = pfreqs[sound_freq] or 24000
			
			if (ptunes[sound_name] ~= nil) then
				if (type(ptunes[sound_name]) == "string") then
					tune = ptunes[sound_name]
				elseif (type(ptunes[sound_name]) == "table") then
					multisample = true
				end
			end
			
			if multisample then
				if (tonumber(string.sub(sound_freq, -1)) ~= nil) then
					local octave = math.min(math.max(tonumber(string.sub(sound_freq, -1)) - base_octave, 1), #ptunes[sound_name])
					local truefreq = string.sub(sound_freq, 1, #sound_freq-1)
					tune = ptunes[sound_name][octave]
					freq = pfreqs[truefreq]
				else
					tune = ptunes[sound_name][2]
				end
			end
			
			--MF_alert(sound_name .. " played at " .. tostring(freq) .. " (" .. sound_freq .. ")")
			
			MF_playsound_freq(tune,freq)
			setsoundname("turn",11,nil)
			
			if (sound_name ~= "empty") then
				for a,unit in ipairs(sound_units) do
					local x,y = unit.values[XPOS],unit.values[YPOS]
					
					MF_particles("music",unit.values[XPOS],unit.values[YPOS],1,0,3,3,1)
				end
			end
		end
	end
	
	local issink = getunitswitheffect("sink",false,delthese)
	
	for id,unit in ipairs(issink) do
		local x,y = unit.values[XPOS],unit.values[YPOS]
		local tileid = x + y * roomsizex
		
		if (unitmap[tileid] ~= nil) then
			local water = findallhere(x,y)
			local sunk = false
			
			if (#water > 0) then
				for a,b in ipairs(water) do
					if floating(b,unit.fixed,x,y) then
						if (b ~= unit.fixed) then
							local dosink = true
							
							for c,d in ipairs(delthese) do
								if (d == unit.fixed) or (d == b) then
									dosink = false
								end
							end
							
							local safe1 = issafe(b)
							local safe2 = issafe(unit.fixed)
							
							if safe1 and safe2 then
								dosink = false
							end
							
							if dosink then
								generaldata.values[SHAKE] = 3
								
								if (safe1 == false) then
									table.insert(delthese, b)
								end
								
								local pmult,sound = checkeffecthistory("sink")
								removalshort = sound
								removalsound = 3
								local c1,c2 = getcolour(unit.fixed)
								MF_particles("destroy",x,y,15 * pmult,c1,c2,1,1)
								
								if (b ~= unit.fixed) and (safe2 == false) then
									sunk = true
								end
							end
						end
					end
				end
			end
			
			if sunk then
				table.insert(delthese, unit.fixed)
			end
		end
	end
	
	delthese,doremovalsound = handledels(delthese,doremovalsound)
	
	local isweak = getunitswitheffect("weak",false,delthese)
	
	for id,unit in ipairs(isweak) do
		if (issafe(unit.fixed) == false) and (unit.new == false) then
			local x,y = unit.values[XPOS],unit.values[YPOS]
			local stuff = findallhere(x,y)
			
			if (#stuff > 0) then
				for i,v in ipairs(stuff) do
					if floating(v,unit.fixed,x,y) then
						local vunit = mmf.newObject(v)
						local thistype = vunit.strings[UNITTYPE]
						if (v ~= unit.fixed) then
							local pmult,sound = checkeffecthistory("weak")
							MF_particles("destroy",x,y,5 * pmult,0,3,1,1)
							removalshort = sound
							removalsound = 1
							generaldata.values[SHAKE] = 4
							table.insert(delthese, unit.fixed)
							break
						end
					end
				end
			end
		end
	end
	
	delthese,doremovalsound = handledels(delthese,doremovalsound)
	
	local ismelt = getunitswitheffect("melt",false,delthese)
	
	for id,unit in ipairs(ismelt) do
		local hot = findfeature(nil,"is","hot")
		local x,y = unit.values[XPOS],unit.values[YPOS]
		
		if (hot ~= nil) then
			for a,b in ipairs(hot) do
				local lava = findtype(b,x,y,0)
			
				if (#lava > 0) and (issafe(unit.fixed) == false) then
					for c,d in ipairs(lava) do
						if floating(d,unit.fixed,x,y) then
							local pmult,sound = checkeffecthistory("hot")
							MF_particles("smoke",x,y,5 * pmult,0,1,1,1)
							generaldata.values[SHAKE] = 5
							removalshort = sound
							removalsound = 9
							table.insert(delthese, unit.fixed)
							break
						end
					end
				end
			end
		end
	end
	
	delthese,doremovalsound = handledels(delthese,doremovalsound)
	
	local isyou = getunitswitheffect("you",false,delthese)
	local isyou2 = getunitswitheffect("you2",false,delthese)
	local isyou3 = getunitswitheffect("3d",false,delthese)
	
	for i,v in ipairs(isyou2) do
		table.insert(isyou, v)
	end
	
	for i,v in ipairs(isyou3) do
		table.insert(isyou, v)
	end
	
	for id,unit in ipairs(isyou) do
		local x,y = unit.values[XPOS],unit.values[YPOS]
		local defeat = findfeature(nil,"is","defeat")
		
		if (defeat ~= nil) then
			for a,b in ipairs(defeat) do
				if (b[1] ~= "empty") then
					local skull = findtype(b,x,y,0)
					
					if (#skull > 0) and (issafe(unit.fixed) == false) then
						for c,d in ipairs(skull) do
							local doit = false
							
							if (d ~= unit.fixed) then
								if floating(d,unit.fixed,x,y) then
									local kunit = mmf.newObject(d)
									local kname = getname(kunit)
									
									local weakskull = hasfeature(kname,"is","weak",d)
									
									if (weakskull == nil) or ((weakskull ~= nil) and issafe(d)) then
										doit = true
									end
								end
							else
								doit = true
							end
							
							if doit then
								local pmult,sound = checkeffecthistory("defeat")
								MF_particles("destroy",x,y,5 * pmult,0,3,1,1)
								generaldata.values[SHAKE] = 5
								removalshort = sound
								removalsound = 1
								table.insert(delthese, unit.fixed)
							end
						end
					end
				end
			end
		end
	end
	
	delthese,doremovalsound = handledels(delthese,doremovalsound)
	
	local isshut = getunitswitheffect("shut",false,delthese)
	
	for id,unit in ipairs(isshut) do
		local open = findfeature(nil,"is","open")
		local x,y = unit.values[XPOS],unit.values[YPOS]
		
		if (open ~= nil) then
			for i,v in ipairs(open) do
				local key = findtype(v,x,y,0)
				
				if (#key > 0) then
					local doparts = false
					for a,b in ipairs(key) do
						if (b ~= 0) and floating(b,unit.fixed,x,y) then
							if (issafe(unit.fixed) == false) then
								generaldata.values[SHAKE] = 8
								table.insert(delthese, unit.fixed)
								doparts = true
								online = false
							end
							
							if (b ~= unit.fixed) and (issafe(b) == false) then
								table.insert(delthese, b)
								doparts = true
							end
							
							if doparts then
								local pmult,sound = checkeffecthistory("unlock")
								setsoundname("turn",7,sound)
								MF_particles("unlock",x,y,15 * pmult,2,4,1,1)
							end
							
							break
						end
					end
				end
			end
		end
	end
	
	delthese,doremovalsound = handledels(delthese,doremovalsound)
	
	local iseat = getunitswithverb("eat",delthese)
	local iseaten = {}
	
	for id,ugroup in ipairs(iseat) do
		local v = ugroup[1]
		
		if (ugroup[3] ~= "empty") then
			for a,unit in ipairs(ugroup[2]) do
				local x,y = unit.values[XPOS],unit.values[YPOS]
				local things = findtype({v,nil},x,y,unit.fixed)
				
				if (#things > 0) then
					for a,b in ipairs(things) do
						if (issafe(b) == false) and floating(b,unit.fixed,x,y) and (b ~= unit.fixed) and (iseaten[b] == nil) then
							generaldata.values[SHAKE] = 4
							table.insert(delthese, b)
							
							iseaten[b] = 1
							
							local pmult,sound = checkeffecthistory("eat")
							MF_particles("eat",x,y,5 * pmult,0,3,1,1)
							removalshort = sound
							removalsound = 1
						end
					end
				end
			end
		end
	end
	
	delthese,doremovalsound = handledels(delthese,doremovalsound)
	
	if (small == false) then
		local ismake = getunitswithverb("make",delthese)
		
		for id,ugroup in ipairs(ismake) do
			local v = ugroup[1]
			
			for a,unit in ipairs(ugroup[2]) do
				local x,y,dir,name = 0,0,4,""
				
				local leveldata = {}
				
				if (ugroup[3] ~= "empty") then
					x,y,dir = unit.values[XPOS],unit.values[YPOS],unit.values[DIR]
					name = getname(unit)
					leveldata = {unit.strings[U_LEVELFILE],unit.strings[U_LEVELNAME],unit.flags[MAPLEVEL],unit.values[VISUALLEVEL],unit.values[VISUALSTYLE],unit.values[COMPLETED],unit.strings[COLOUR],unit.strings[CLEARCOLOUR]}
				else
					x = math.floor(unit % roomsizex)
					y = math.floor(unit / roomsizex)
					name = "empty"
					dir = emptydir(x,y)
				end
				
				if (dir == 4) then
					dir = fixedrandom(0,3)
				end
				
				local exists = false
				
				if (v ~= "text") and (v ~= "all") then
					for b,mat in pairs(objectlist) do
						if (b == v) then
							exists = true
						end
					end
				else
					exists = true
				end
				
				if exists then
					local domake = true
					
					if (name ~= "empty") then
						local thingshere = findallhere(x,y)
						
						if (#thingshere > 0) then
							for a,b in ipairs(thingshere) do
								local thing = mmf.newObject(b)
								local thingname = thing.strings[UNITNAME]
								
								if (thing.flags[CONVERTED] == false) and ((thingname == v) or ((thing.strings[UNITTYPE] == "text") and (v == "text"))) then
									domake = false
								end
							end
						end
					end
					
					if domake then
						if (findnoun(v,nlist.short) == false) then
							create(v,x,y,dir,x,y,nil,nil,leveldata)
						elseif (v == "text") then
							if (name ~= "text") and (name ~= "all") then
								create("text_" .. name,x,y,dir,x,y,nil,nil,leveldata)
								updatecode = 1
							end
						elseif (string.sub(v, 1, 5) == "group") then
							local mem = findgroup(v)
							
							for c,d in ipairs(mem) do
								create(d,x,y,dir,x,y,nil,nil,leveldata)
							end
						end
					end
				end
			end
		end
		
		for i,unit in ipairs(doned) do
			addundo({"done",unit.strings[UNITNAME],unit.values[XPOS],unit.values[YPOS],unit.values[DIR],unit.values[ID],unit.fixed,unit.values[FLOAT]})
			updateundo = true
			
			unit.values[FLOAT] = 2
			unit.values[EFFECTCOUNT] = math.random(-10,10)
			unit.values[POSITIONING] = 7
			unit.flags[DEAD] = true
			
			delunit(unit.fixed)
		end
	end
	
	delthese,doremovalsound = handledels(delthese,doremovalsound)
	
	isyou = getunitswitheffect("you",false,delthese)
	isyou2 = getunitswitheffect("you2",false,delthese)
	isyou3 = getunitswitheffect("3d",false,delthese)
	
	for i,v in ipairs(isyou2) do
		table.insert(isyou, v)
	end
	
	for i,v in ipairs(isyou3) do
		table.insert(isyou, v)
	end
	
	for id,unit in ipairs(isyou) do
		if (unit.flags[DEAD] == false) and (delthese[unit.fixed] == nil) then
			local x,y = unit.values[XPOS],unit.values[YPOS]
			
			if (small == false) then
				local bonus = findfeature(nil,"is","bonus")
				
				if (bonus ~= nil) then
					for a,b in ipairs(bonus) do
						if (b[1] ~= "empty") then
							local flag = findtype(b,x,y,0)
							
							if (#flag > 0) then
								for c,d in ipairs(flag) do
									if floating(d,unit.fixed,x,y) then
										local pmult,sound = checkeffecthistory("bonus")
										MF_particles("bonus",x,y,10 * pmult,4,1,1,1)
										removalshort = sound
										removalsound = 2
										MF_playsound("bonus")
										MF_bonus(1)
										addundo({"bonus",1})
										generaldata.values[SHAKE] = 5
										table.insert(delthese, d)
									end
								end
							end
						end
					end
				end
				
				local ending = findfeature(nil,"is","end")
				
				if (ending ~= nil) then
					for a,b in ipairs(ending) do
						if (b[1] ~= "empty") then
							local flag = findtype(b,x,y,0)
							
							if (#flag > 0) then
								for c,d in ipairs(flag) do
									if floating(d,unit.fixed,x,y) and (generaldata.values[MODE] == 0) then
										if (generaldata.strings[WORLD] == generaldata.strings[BASEWORLD]) then
											MF_particles("unlock",x,y,10,1,4,1,1)
											MF_end(unit.fixed,d)
											break
										elseif (editor.values[INEDITOR] ~= 0) then
											local pmult = checkeffecthistory("win")
									
											MF_particles("win",x,y,10 * pmult,2,4,1,1)
											MF_end_single()
											MF_win()
											break
										else
											local pmult = checkeffecthistory("win")
											
											local mods_run = do_mod_hook("levelpack_end", {})
											
											if (mods_run == false) then
												MF_particles("win",x,y,10 * pmult,2,4,1,1)
												MF_end_single()
												MF_win()
												MF_credits(1)
											end
											break
										end
									end
								end
							end
						end
					end
				end
			end
			
			local win = findfeature(nil,"is","win")
			
			if (win ~= nil) then
				for a,b in ipairs(win) do
					if (b[1] ~= "empty") then
						local flag = findtype(b,x,y,0)
						if (#flag > 0) then
							for c,d in ipairs(flag) do
								if floating(d,unit.fixed,x,y) and (hasfeature(b[1],"is","done",d,x,y) == nil) and (hasfeature(b[1],"is","end",d,x,y) == nil) then
									local pmult = checkeffecthistory("win")
									
									MF_particles("win",x,y,10 * pmult,2,4,1,1)
									MF_win()
									break
								end
							end
						end
					end
				end
			end
		end
	end
	
	delthese,doremovalsound = handledels(delthese,doremovalsound)
	
	for i,unit in ipairs(units) do
		if (inbounds(unit.values[XPOS],unit.values[YPOS],1) == false) then
			--MF_alert("DELETED!!!")
			table.insert(delthese, unit.fixed)
		end
	end
	
	delthese,doremovalsound = handledels(delthese,doremovalsound)
	
	if (small == false) then
		local iscrash = getunitswitheffect("crash",false,delthese)
		
		if (#iscrash > 0) then
			HACK_INFINITY = 200
			destroylevel("infinity")
			return
		end
	end
	
	if doremovalsound then
		setsoundname("removal",removalsound,removalshort)
	end
end

