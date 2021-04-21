function testcond(conds,unitid,x_,y_,autofail_,limit_,checkedconds_,ignorebroken_,subgroup_)
	-- @This mod - Override reason: Handle infix conditions with "this" as param. Also handle "this is X"
	local result = true
	
	local orhandling = false
	local orresult = false
	
	local x,y,name,dir,broken = 0,0,"",4,0
	local surrounds = {}
	local autofail = autofail_ or {}
	local limit = limit_ or 0
	
	limit = limit + 1
	if (limit > 80) then
		HACK_INFINITY = 200
		destroylevel("infinity")
		return
	end
	
	local checkedconds = {}
	local ignorebroken = ignorebroken_ or false
	local subgroup = subgroup_ or {}
	
	if (checkedconds_ ~= nil) then
		for i,v in pairs(checkedconds_) do
			checkedconds[i] = v
		end
	end
	
	if (#features == 0) then
		return false
	end
	
	-- 0 = bug, 1 = level, 2 = empty
	
	if (unitid ~= 0) and (unitid ~= 1) and (unitid ~= 2) and (unitid ~= nil) then
		local unit = mmf.newObject(unitid)
		x = unit.values[XPOS]
		y = unit.values[YPOS]
		name = unit.strings[UNITNAME]
		dir = unit.values[DIR]
		broken = unit.broken or 0
		
		if (unit.strings[UNITTYPE] == "text") then
			name = "text"
		end
	elseif (unitid == 2) then
		x = x_
		y = y_
		name = "empty"
		broken = 0
		
		if (featureindex["broken"] ~= nil) and (ignorebroken == false) and (checkedconds[tostring(conds)] == nil) then
			checkedconds[tostring(conds)] = 1
			broken = isitbroken("empty",2,x,y,checkedconds)
		end
	elseif (unitid == 1) then
		name = "level"
		surrounds = parsesurrounds()
		dir = tonumber(surrounds.dir) or 4
		broken = 0
		
		if (featureindex["broken"] ~= nil) and (ignorebroken == false) and (checkedconds[tostring(conds)] == nil) then
			checkedconds[tostring(conds)] = 1
			broken = isitbroken("level",1,x,y,checkedconds)
		end
	end
	
	checkedconds[tostring(conds)] = 1
	
	if (unitid == 0) or (unitid == nil) then
		print("WARNING!! Unitid is " .. tostring(unitid))
	end
	
	if ignorebroken then
		broken = 0
	end
	
	if (broken == 1) then
		result = false
	end
	
	if (conds ~= nil) and ((broken == nil) or (broken == 0)) then
		if (#conds > 0) then
			local valid = false
			
			for i,cond in ipairs(conds) do
				local condtype = cond[1]
				local params_ = cond[2]
				local params = {}
				
				local extras = {}
				
				if (string.sub(condtype, 1, 1) == "(") then
					condtype = string.sub(condtype, 2)
					orhandling = true
					orresult = false
				end
				
				if (string.sub(condtype, -1) == ")") then
					condtype = string.sub(condtype, 1, string.len(condtype) - 1)
				end
				
				local isnot = string.sub(condtype, 1, 4)
				
				if (isnot == "not ") then
					isnot = string.sub(condtype, 5)
				else
					isnot = condtype
				end
				
				if (condtype ~= "never") then
					local condname = unitreference["text_" .. isnot]
					
					local conddata = conditions[condname] or {}
					if (conddata.argextra ~= nil) then
						extras = conddata.argextra
					end
				end
				
				for a,b in ipairs(autofail) do
					if (condtype == b) then
						result = false
						valid = true
					end
				end
				
				if (result == false) and valid then
					break
				end
				if (params_ ~= nil) then
					local handlegroup = false
					for a,b in ipairs(params_) do
						if condtype == "this" or condtype == "not this" then
                            table.insert(params, params_[1])
                            break
                        end
						if (string.sub(b, 1, 4) == "not ") then
							table.insert(params, b)
						else
							table.insert(params, 1, b)
						end
						
						if (string.sub(b, 1, 5) == "group") or (string.sub(b, 1, 9) == "not group") then
							handlegroup = true
						end
					end
					
					local removegroup = {}
					local removegroupoffset = 0
					
					if handlegroup then
						local plimit = #params
						
						for a=1,plimit do
							local b = params[a]
							local mem = subgroup_
							local notnoun = false
							
							if (string.sub(b, 1, 5) == "group") then
								if (mem == nil) then
									mem = findgroup(b,false,limit,checkedconds)
								end
								table.insert(removegroup, a)
							elseif (string.sub(b, 1, 9) == "not group") then
								notnoun = true
								
								if (mem == nil) then
									mem = findgroup(string.sub(b, 5),true,limit,checkedconds)
								else
									local memfound = {}
									
									for c,d in ipairs(mem) do
										memfound[d] = 1
									end
									
									mem = {}
		
									for c,mat in pairs(objectlist) do
										if (memfound[c] == nil) and (findnoun(c,nlist.short) == false) then
											table.insert(mem, c)
										end
									end
								end
								table.insert(removegroup, a)
							end
							
							if (mem ~= nil) then
								for c,d in ipairs(mem) do
									if notnoun then
										table.insert(params, d)
									else
										table.insert(params, 1, d)
										removegroupoffset = removegroupoffset - 1
									end
								end
							end
							
							if (mem == nil) or (#mem == 0) then
								table.insert(params, "_NONE_")
								break
							end
						end
						
						for a,b in ipairs(removegroup) do
							table.remove(params, b - removegroupoffset)
							removegroupoffset = removegroupoffset + 1
						end
					end
				end
				
				if (condtype == "never") then
					valid = true
					if (orhandling == false) then
						result = false
						break
					end
				elseif (condtype == "on") then
					valid = true
					local allfound = 0
					local alreadyfound = {}
					
					local tileid = x + y * roomsizex
					
					if (name ~= "empty") then
						if (#params > 0) then
							for a,b in ipairs(params) do
								local pname = b
								local pnot = false
								if (string.sub(b, 1, 4) == "not ") then
									pnot = true
									pname = string.sub(b, 5)
								end

								local is_param_this, raycast_units = parse_this_param_and_get_raycast_units(pname)
								
								local bcode = b .. "_" .. tostring(a)
								
								if (string.sub(pname, 1, 5) == "group") then
									result = false
									break
								end
								
								if (unitid ~= 1) then
									if ((b ~= "empty") and (b ~= "level")) or ((b == "level") and (alreadyfound[1] ~= nil)) then
										if (unitmap[tileid] ~= nil) then
											for c,d in ipairs(unitmap[tileid]) do
												if (d ~= unitid) and (alreadyfound[d] == nil) then
													local unit = mmf.newObject(d)
													local name_ = getname(unit)
													
													if (pnot == false) then
														if is_param_this then
															if raycast_units[d] and alreadyfound[bcode] == nil then
																alreadyfound[bcode] = 1
																alreadyfound[d] = 1
																allfound = allfound + 1
															end
														elseif (name_ == pname) and (alreadyfound[bcode] == nil) then
															alreadyfound[bcode] = 1
															alreadyfound[d] = 1
															allfound = allfound + 1
														end
													else
														if is_param_this then
															if raycast_units and not raycast_units[d] and alreadyfound[bcode] == nil and name_ ~= "text" then
																alreadyfound[bcode] = 1
																alreadyfound[d] = 1
																allfound = allfound + 1
															end
														elseif (name_ ~= pname) and (alreadyfound[bcode] == nil) and (name_ ~= "text") then
															alreadyfound[bcode] = 1
															alreadyfound[d] = 1
															allfound = allfound + 1
														end
													end
												end
											end
										else
											print("unitmap is nil at " .. tostring(x) .. ", " .. tostring(y) .. " for object " .. tostring(name) .. " (" .. tostring(unitid) .. ")!")
										end
									elseif (b == "empty") then
										result = false
									elseif (b == "level") and (alreadyfound[bcode] == nil) and (alreadyfound[1] == nil) then
										alreadyfound[bcode] = 1
										alreadyfound[1] = 1
										allfound = allfound + 1
									end
								else
									local ulist = false
									
									if (b ~= "empty") and (b ~= "level") then
										if (pnot == false) then
											if (unitlists[b] ~= nil) and (#unitlists[b] > 0) and (alreadyfound[bcode] == nil) then
												for c,d in ipairs(unitlists[b]) do
													if (alreadyfound[d] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[d] = 1
														ulist = true
														break
													end
												end
											end
										else
											for c,d in pairs(unitlists) do
												local tested = false
												
												if (c ~= pname) and (#d > 0) then
													for e,f in ipairs(d) do
														if (alreadyfound[f] == nil) and (alreadyfound[bcode] == nil) then
															alreadyfound[bcode] = 1
															alreadyfound[f] = 1
															ulist = true
															tested = true
															break
														end
													end
												end
												
												if tested then
													break
												end
											end
										end
									elseif (b == "empty") then
										local empties = findempty()
										
										if (#empties > 0) then
											for c,d in ipairs(empties) do
												if (alreadyfound[d] == nil) and (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													alreadyfound[d] = 1
													ulist = true
													break
												end
											end
										end
									elseif (b == "level") then
										for c,unit in ipairs(units) do
											if (unit.className == "level") and (alreadyfound[unit.fixed] == nil) and (alreadyfound[bcode] == nil) then
												alreadyfound[bcode] = 1
												alreadyfound[unit.fixed] = 1
												ulist = true
												break
											end
										end
									end
									
									if (b ~= "text") and (ulist == false) then
										if (surrounds["o"] ~= nil) then
											for c,d in ipairs(surrounds["o"]) do
												if (pnot == false) then
													if (d == pname) and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														ulist = true
													end
												else
													if (d ~= pname) and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														ulist = true
													end
												end
											end
										end
									end
									
									if ulist or (b == "text") then
										alreadyfound[bcode] = 1
										allfound = allfound + 1
									end
								end
							end
						else
							print("no parameters given!")
							result = false
						end
					else
						for a,b in ipairs(params) do
							local bcode = b .. "_" .. tostring(a)
							
							if (b == "level") and (alreadyfound[bcode] == nil) then
								alreadyfound[bcode] = 1
								allfound = allfound + 1
							else
								result = false
							end
						end
					end
					
					if (allfound ~= #params) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "not on") then
					valid = true
					local allfound = 0
					local alreadyfound = {}
					
					local tileid = x + y * roomsizex
					
					if (#params > 0) then
						for a,b in ipairs(params) do
							local pname = b
							local pnot = false
							if (string.sub(b, 1, 4) == "not ") then
								pnot = true
								pname = string.sub(b, 5)
							end

							local is_param_this, raycast_units = parse_this_param_and_get_raycast_units(pname)
							
							local bcode = b .. "_" .. tostring(a)
							
							if (string.sub(pname, 1, 5) == "group") then
								result = false
								break
							end
							
							if (unitid ~= 1) then
								if ((b ~= "empty") and (b ~= "level")) or ((b == "level") and (alreadyfound[1] ~= nil)) then
									if (unitmap[tileid] ~= nil) then
										for c,d in ipairs(unitmap[tileid]) do
											if (d ~= unitid) and (alreadyfound[d] == nil) then
												local unit = mmf.newObject(d)
												local name_ = getname(unit)
												
												if (pnot == false) then
													if is_param_this then
														if raycast_units and raycast_units[d] and alreadyfound[bcode] == nil then
															alreadyfound[bcode] = 1
															alreadyfound[d] = 1
															allfound = allfound + 1
														end
													elseif (name_ == pname) and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[d] = 1
														allfound = allfound + 1
													end
												else
													if is_param_this then
														if raycast_units and not raycast_units[d] and alreadyfound[bcode] == nil and name_ ~= "text" then
															alreadyfound[bcode] = 1
															alreadyfound[d] = 1
															allfound = allfound + 1
														end
													elseif (name_ ~= pname) and (name_ ~= "text") and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[d] = 1
														allfound = allfound + 1
													end
												end
											end
										end
									else
										print("unitmap is nil at " .. tostring(x) .. ", " .. tostring(y) .. "!")
									end
								elseif (b == "empty") then
									local onempty = false

									if (unitmap[tileid] == nil) or (#unitmap[tileid] == 0) then 
										onempty = true
									end
									
									if onempty and (alreadyfound[bcode] == nil) then
										alreadyfound[bcode] = 1
										allfound = allfound + 1
									end
								elseif (b == "level") and (alreadyfound[bcode] == nil) and (alreadyfound[1] == nil) then
									alreadyfound[bcode] = 1
									alreadyfound[1] = 1
									allfound = allfound + 1
								end
							else
								if (b ~= "empty") and (b ~= "text") then
									if (pnot == false) then
										if (unitlists[b] ~= nil) and (#unitlists[b] > 0) and (alreadyfound[bcode] == nil) then
											for c,d in ipairs(unitlists[b]) do
												if (alreadyfound[d] == nil) then
													alreadyfound[bcode] = 1
													alreadyfound[d] = 1
													allfound = allfound + 1
													break
												end
											end
										end
									else
										for c,d in pairs(unitlists) do
											local tested = false
											
											if (c ~= pname) and (#d > 0) and (alreadyfound[bcode] == nil) then
												for e,f in ipairs(d) do
													if (alreadyfound[f] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[f] = 1
														allfound = allfound + 1
														tested = true
														break
													end
												end
											end
											
											if tested then
												break
											end
										end
									end
								elseif (b == "empty") then
									local empties = findempty()
									
									if (#empties > 0) and (alreadyfound[bcode] == nil) then
										for c,d in ipairs(empties) do
											if (alreadyfound[d] == nil) then
												alreadyfound[bcode] = 1
												alreadyfound[d] = 1
												allfound = allfound + 1
												break
											end
										end
									end
								elseif (b == "text") and (alreadyfound[bcode] == nil) then
									alreadyfound[bcode] = 1
									allfound = allfound + 1
								end
								
								if result then
									if (surrounds["o"] ~= nil) then
										for c,d in ipairs(surrounds["o"]) do
											if (pnot == false) then
												if (d == b) and (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													allfound = allfound + 1
												end
											else
												if (d ~= b) and (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													allfound = allfound + 1
												end
											end
										end
									end
								end
							end
						end
					else
						print("no parameters given!")
						result = false
					end
					
					if (allfound == #params) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "facing") then
					valid = true
					local allfound = 0
					local alreadyfound = {}
					
					if (name == "empty") then
						dir = emptydir(x,y)
					end
					
					local ndrs = ndirs[dir+1]
					local ox = ndrs[1]
					local oy = ndrs[2]
					
					local tileid = (x + ox) + (y + oy) * roomsizex
					
					if (#params > 0) then
						for a,b in ipairs(params) do
							local pname = b
							local pnot = false
							if (string.sub(b, 1, 4) == "not ") then
								pnot = true
								pname = string.sub(b, 5)
							end

							local is_param_this, raycast_units, raycast_tileid = parse_this_param_and_get_raycast_units(pname)
							local ray_unit_is_empty = is_param_this and raycast_units[2] -- <-- this last condition checks if empty is a 
							
							local bcode = b .. "_" .. tostring(a)
							
							if (string.sub(pname, 1, 5) == "group") then
								result = false
								break
							end
							
							if (unitid ~= 1) then
								if not ray_unit_is_empty and (((pname ~= "empty") and (b ~= "level")) or ((b == "level") and (alreadyfound[1] ~= nil))) then
									if (stringintable(pname, extras) == false) then
										if (unitmap[tileid] ~= nil) and (dir ~= 4) then
											for c,d in ipairs(unitmap[tileid]) do
												if (d ~= unitid) and (alreadyfound[d] == nil) then
													local unit = mmf.newObject(d)
													local name_ = getname(unit)
													
													if (pnot == false) then
														if is_param_this then
															if raycast_units and raycast_units[d] and alreadyfound[bcode] == nil then
																alreadyfound[bcode] = 1
																alreadyfound[d] = 1
																allfound = allfound + 1
															end
														elseif (name_ == pname) and (alreadyfound[bcode] == nil) then
															alreadyfound[bcode] = 1
															alreadyfound[d] = 1
															allfound = allfound + 1
														end
													else
														if is_param_this then
															if raycast_units and not raycast_units[d] and alreadyfound[bcode] == nil and name_ ~= "text" then
																alreadyfound[bcode] = 1
																alreadyfound[d] = 1
																allfound = allfound + 1
															end
														elseif (name_ ~= pname) and (alreadyfound[bcode] == nil) and (name_ ~= "text") then
															alreadyfound[bcode] = 1
															alreadyfound[d] = 1
															allfound = allfound + 1
														end
													end
												end
											end
										end
									else
										if (pnot == false) then
											if ((pname == "right") and (dir == 0)) or ((pname == "up") and (dir == 1)) or ((pname == "left") and (dir == 2)) or ((pname == "down") and (dir == 3)) then
												if (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													allfound = allfound + 1
												end
											end
										else
											if ((pname == "right") and (dir ~= 0)) or ((pname == "up") and (dir ~= 1)) or ((pname == "left") and (dir ~= 2)) or ((pname == "down") and (dir ~= 3)) then
												if (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													allfound = allfound + 1
												end
											end
										end
									end
								elseif (pname == "empty" or ray_unit_is_empty) and (dir ~= 4) then
									local l = map[0]
									local tile = l:get_x(x + ox,y + oy)
									
									if (pnot == false) then
										local this_cond = not ray_unit_is_empty or (ray_unit_is_empty and tileid == raycast_tileid)
										if ((unitmap[tileid] == nil) or (#unitmap[tileid] == 0)) and (tile == 255) and this_cond then
											if (alreadyfound[bcode] == nil) then
												alreadyfound[bcode] = 1
												allfound = allfound + 1
											end
										end
									else
										if ((unitmap[tileid] ~= nil) and (#unitmap[tileid] > 0)) or (tile ~= 255) then
											if (alreadyfound[bcode] == nil) then
												alreadyfound[bcode] = 1
												allfound = allfound + 1
											end
										end
									end
								elseif (b == "level") and (dir ~= 4) and (alreadyfound[bcode] == nil) and (alreadyfound[1] == nil) then
									alreadyfound[bcode] = 1
									alreadyfound[1] = 1
									allfound = allfound + 1
								end
							else
								local dirids = {"r","u","l","d"}
								local dirid = dirids[dir + 1]
								
								if (surrounds[dirid] ~= nil) and (dir ~= 4) then
									for c,d in ipairs(surrounds[dirid]) do
										if (pnot == false) then
											if (d == pname) and (alreadyfound[bcode] == nil) then
												alreadyfound[bcode] = 1
												allfound = allfound + 1
											end
										else
											if (d ~= pname) and (alreadyfound[bcode] == nil) then
												alreadyfound[bcode] = 1
												allfound = allfound + 1
											end
										end
									end
								end
							end
						end
					else
						print("no parameters given!")
						result = false
					end
					
					if (allfound ~= #params) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "not facing") then
					valid = true
					
					local allfound = 0
					local alreadyfound = {}
					
					if (name == "empty") then
						dir = emptydir(x,y)
					end

					local ndrs = ndirs[dir+1]
					local ox = ndrs[1]
					local oy = ndrs[2]
					
					local tileid = (x + ox) + (y + oy) * roomsizex
					
					if (#params > 0) then
						for a,b in ipairs(params) do
							local pname = b
							local pnot = false
							if (string.sub(b, 1, 4) == "not ") then
								pnot = true
								pname = string.sub(b, 5)
							end

							local is_param_this, raycast_units, raycast_tileid = parse_this_param_and_get_raycast_units(pname)
							local ray_unit_is_empty = is_param_this and raycast_units[2] -- <-- this last condition checks if empty is a 
							
							local bcode = b .. "_" .. tostring(a)
							
							if (string.sub(pname, 1, 5) == "group") then
								result = false
								break
							end
							
							if (unitid ~= 1) then
								if not ray_unit_is_empty and (((pname ~= "empty") and (b ~= "level")) or ((b == "level") and (alreadyfound[1] ~= nil))) then
									if (stringintable(pname, extras) == false) then
										if (dir ~= 4) then
											if (unitmap[tileid] ~= nil) then
												for c,d in ipairs(unitmap[tileid]) do
													if (d ~= unitid) and (alreadyfound[d] == nil) then
														local unit = mmf.newObject(d)
														local name_ = getname(unit)
														
														if (pnot == false) then
															if is_param_this then
																if raycast_units and raycast_units[d] and alreadyfound[bcode] == nil then
																	alreadyfound[bcode] = 1
																	alreadyfound[d] = 1
																	allfound = allfound + 1
																end
															elseif (name_ == pname) and (alreadyfound[bcode] == nil) then
																alreadyfound[bcode] = 1
																alreadyfound[d] = 1
																allfound = allfound + 1
															end
														else
															if is_param_this then
																if raycast_units and not raycast_units[d] and alreadyfound[bcode] == nil and name_ ~= "text" then
																	alreadyfound[bcode] = 1
																	alreadyfound[d] = 1
																	allfound = allfound + 1
																end
															elseif (name_ ~= pname) and (name_ ~= "text") and (alreadyfound[bcode] == nil) then
																alreadyfound[bcode] = 1
																alreadyfound[d] = 1
																allfound = allfound + 1
															end
														end
													end
												end
											end
										elseif (alreadyfound[bcode] == nil) then
											alreadyfound[bcode] = 1
											allfound = allfound + 1
										end
									else
										if (pnot == false) then
											if ((pname == "right") and (dir == 0)) or ((pname == "up") and (dir == 1)) or ((pname == "left") and (dir == 2)) or ((pname == "down") and (dir == 3)) then
												if (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													allfound = allfound + 1
												end
											end
										else
											if ((pname == "right") and (dir ~= 0)) or ((pname == "up") and (dir ~= 1)) or ((pname == "left") and (dir ~= 2)) or ((pname == "down") and (dir ~= 3)) then
												if (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													allfound = allfound + 1
												end
											end
										end
									end
								elseif (pname == "empty") or ray_unit_is_empty then
									local l = map[0]
									local tile = l:get_x(x + ox,y + oy)
									
									if (dir ~= 4) then
										if (pnot == false) then
											local this_cond = not ray_unit_is_empty or (ray_unit_is_empty and tileid == raycast_tileid)
											if ((unitmap[tileid] == nil) or (#unitmap[tileid] == 0)) and (tile == 255) and this_cond then
												if (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													allfound = allfound + 1
												end
											end
										else
											-- local this_cond = not ray_unit_is_empty or (ray_unit_is_empty and tileid == raycast_tileid))
											if ((unitmap[tileid] ~= nil) and (#unitmap[tileid] > 0)) or (tile ~= 255) then
												if (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													allfound = allfound + 1
												end
											end
										end
									elseif (alreadyfound[bcode] == nil) then
										alreadyfound[bcode] = 1
										allfound = allfound + 1
									end
								elseif (b == "level") and (alreadyfound[bcode] == nil) and (alreadyfound[1] == nil) then
									alreadyfound[bcode] = 1
									alreadyfound[1] = 1
									allfound = allfound + 1
								end
							else
								local dirids = {"r","u","l","d"}
								local dirid = dirids[dir + 1]
								
								if (surrounds[dirid] ~= nil) and (dir ~= 4) then
									for c,d in ipairs(surrounds[dirid]) do
										if (pnot == false) then
											if (d == pname) and (alreadyfound[bcode] == nil) then
												alreadyfound[bcode] = 1
												allfound = allfound + 1
											end
										else
											if (d ~= pname) and (alreadyfound[bcode] == nil) then
												alreadyfound[bcode] = 1
												allfound = allfound + 1
											end
										end
									end
								end
							end
						end
					else
						print("no parameters given!")
						result = false
					end
					
					if (allfound == #params) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "near") then
					valid = true
					local allfound = 0
					local alreadyfound = {}
					
					if (#params > 0) then
						for a,b in ipairs(params) do
							local pname = b
							local pnot = false
							if (string.sub(b, 1, 4) == "not ") then
								pnot = true
								pname = string.sub(b, 5)
							end
							
							local is_param_this, raycast_units, raycast_tileid = parse_this_param_and_get_raycast_units(pname)
							local ray_unit_is_empty = is_param_this and raycast_units[2] -- <-- this last condition checks if empty is a raycast unit
							
							local bcode = b .. "_" .. tostring(a)
							
							if (string.sub(pname, 1, 5) == "group") then
								result = false
								break
							end
							
							if (unitid ~= 1) then
								if (b ~= "level") or ((b == "level") and (alreadyfound[1] ~= nil)) then
									for g=-1,1 do
										for h=-1,1 do
											if (pname ~= "empty") and not ray_unit_is_empty then
												local tileid = (x + g) + (y + h) * roomsizex
												if (unitmap[tileid] ~= nil) then
													for c,d in ipairs(unitmap[tileid]) do
														if (d ~= unitid) and (alreadyfound[d] == nil) then
															local unit = mmf.newObject(d)
															local name_ = getname(unit)
															
															if (pnot == false) then
																if is_param_this then
																	if raycast_units[d] and alreadyfound[bcode] == nil then
																		alreadyfound[bcode] = 1
																		alreadyfound[d] = 1
																		allfound = allfound + 1
																	end
																elseif (name_ == pname) and (alreadyfound[bcode] == nil) then
																	alreadyfound[bcode] = 1
																	alreadyfound[d] = 1
																	allfound = allfound + 1
																end
															else
																if is_param_this then
																	if not raycast_units[d] and alreadyfound[bcode] == nil and name_ ~= "text" then
																		alreadyfound[bcode] = 1
																		alreadyfound[d] = 1
																		allfound = allfound + 1
																	end
																elseif (name_ ~= pname) and (alreadyfound[bcode] == nil) and (name_ ~= "text") then
																	alreadyfound[bcode] = 1
																	alreadyfound[d] = 1
																	allfound = allfound + 1
																end
															end
														end
													end
												end
											else
												local nearempty = false
										
												local tileid = (x + g) + (y + h) * roomsizex
												local l = map[0]
												local tile = l:get_x(x + g,y + h)
												
												local tcode = tostring(tileid) .. "e"
												
												if ((unitmap[tileid] == nil) or (#unitmap[tileid] == 0)) and (tile == 255) and (alreadyfound[tcode] == nil) then 
													nearempty = true
												end
												
												if nearempty and (unitid == 2) and (g == 0) and (h == 0) then
													nearempty = false
												end
												
												if (nearempty == false) and (unitid ~= 2) and (unitid ~= 1) and (g == 0) and (h == 0) and pnot then
													if (unitmap[tileid] == nil) or (#unitmap[tileid] == 1) then
														nearempty = true
													end
												end

												-- added "not pnot" since being near "not empty" means near any nonempty object
												if nearempty and not pnot and ray_unit_is_empty and tileid ~= raycast_tileid then
													nearempty = false
												end
												
												if (pnot == false) then
													if nearempty and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[tcode] = 1
														allfound = allfound + 1
													end
												else
													if (nearempty == false) and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[tcode] = 1
														allfound = allfound + 1
													end
												end
											end
										end
									end
								elseif (b == "level") and (alreadyfound[bcode] == nil) and (alreadyfound[1] == nil) then
									alreadyfound[bcode] = 1
									alreadyfound[1] = 1
									allfound = allfound + 1
								end
							else
								local ulist = false
							
								if (b ~= "empty") and (b ~= "level") then
									if (pnot == false) then
										if (unitlists[pname] ~= nil) and (#unitlists[pname] > 0) then
											for c,d in ipairs(unitlists[pname]) do
												if (alreadyfound[d] == nil) and (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													alreadyfound[d] = 1
													ulist = true
													break
												end
											end
										end
									else
										for c,d in pairs(unitlists) do
											local tested = false
											
											if (c ~= pname) and (#d > 0) then
												for e,f in ipairs(d) do
													if (alreadyfound[f] == nil) and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[f] = 1
														ulist = true
														tested = true
														break
													end
												end
											end
											
											if tested then
												break
											end
										end
									end
								elseif (b == "empty") then
									local empties = findempty()
									
									if (#empties > 0) then
										for c,d in ipairs(empties) do
											if (alreadyfound[d] == nil) and (alreadyfound[bcode] == nil) then
												alreadyfound[bcode] = 1
												alreadyfound[d] = 1
												ulist = true
												break
											end
										end
									end
								end
								
								if (b ~= "text") and (ulist == false) then
									for e,f in pairs(surrounds) do
										if (e ~= "dir") then
											for c,d in ipairs(f) do
												if (pnot == false) then
													if (ulist == false) and (d == pname) and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														ulist = true
													end
												else
													if (ulist == false) and (d ~= pname) and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														ulist = true
													end
												end
											end
										end
									end
								end
								
								if ulist or (b == "text") then
									alreadyfound[bcode] = 1
									allfound = allfound + 1
								end
							end
						end
					else
						print("no parameters given!")
						result = false
					end

					if (allfound ~= #params) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "not near") then
					valid = true
					
					local allfound = 0
					local alreadyfound = {}
					
					if (#params > 0) then
						for a,b in ipairs(params) do
							local pname = b
							local pnot = false
							if (string.sub(b, 1, 4) == "not ") then
								pnot = true
								pname = string.sub(b, 5)
							end

							local is_param_this, raycast_units, raycast_tileid = parse_this_param_and_get_raycast_units(pname)
							local ray_unit_is_empty = is_param_this and raycast_units[2] -- <-- this last condition checks if empty is a raycast unit
							
							local bcode = b .. "_" .. tostring(a)
							
							if (string.sub(pname, 1, 5) == "group") then
								result = false
								break
							end
							
							if (unitid ~= 1) then
								if (b ~= "level") or ((b == "level") and (alreadyfound[1] ~= nil)) then
									for g=-1,1 do
										for h=-1,1 do
											if (pname ~= "empty") and not ray_unit_is_empty then
												local tileid = (x + g) + (y + h) * roomsizex
												if (unitmap[tileid] ~= nil) then
													for c,d in ipairs(unitmap[tileid]) do
														if (d ~= unitid) and (alreadyfound[d] == nil) then
															local unit = mmf.newObject(d)
															local name_ = getname(unit)
															
															if (pnot == false) then
																if is_param_this then
																	if raycast_units and raycast_units[d] and alreadyfound[bcode] == nil then
																		alreadyfound[bcode] = 1
																		alreadyfound[d] = 1
																		allfound = allfound + 1
																	end
																elseif (name_ == pname) and (d ~= unitid) and (alreadyfound[bcode] == nil) then
																	alreadyfound[bcode] = 1
																	alreadyfound[d] = 1
																	allfound = allfound + 1
																end
															else
																if is_param_this then
																	if raycast_units and not raycast_units[d] and alreadyfound[bcode] == nil and name_ ~= "text" then
																		alreadyfound[bcode] = 1
																		alreadyfound[d] = 1
																		allfound = allfound + 1
																	end
																elseif (name_ ~= pname) and (d ~= unitid) and (name_ ~= "text") and (alreadyfound[bcode] == nil) then
																	alreadyfound[bcode] = 1
																	alreadyfound[d] = 1
																	allfound = allfound + 1
																end
															end
														end
													end
												end
											else
												local nearempty = false
										
												local tileid = (x + g) + (y + h) * roomsizex
												local l = map[0]
												local tile = l:get_x(x + g,y + h)
												
												local tcode = tostring(tileid) .. "e"
												
												if ((unitmap[tileid] == nil) or (#unitmap[tileid] == 0)) and (tile == 255) and (alreadyfound[tcode] == nil) then 
													nearempty = true
												end
												
												if nearempty and (unitid == 2) and (g == 0) and (h == 0) then
													nearempty = false
												end

												if nearempty and ray_unit_is_empty and tileid ~= raycast_tileid then
													nearempty = false
												end
												
												if (pnot == false) then
													if nearempty and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[tcode] = 1
														allfound = allfound + 1
													end
												else
													if (nearempty == false) and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[tcode] = 1
														allfound = allfound + 1
													end
												end
											end
										end
									end
								elseif (b == "level") and (alreadyfound[bcode] == nil) and (alreadyfound[1] == nil) then
									alreadyfound[bcode] = 1
									alreadyfound[1] = 1
									allfound = allfound + 1
								end
							else
								local ulist = false
							
								if (b ~= "empty") and (b ~= "text") then
									if (pnot == false) then
										if (unitlists[b] ~= nil) and (#unitlists[b] > 0) and (alreadyfound[bcode] == nil) then
											for c,d in ipairs(unitlists[b]) do
												if (alreadyfound[d] == nil) then
													alreadyfound[bcode] = 1
													alreadyfound[d] = 1
													allfound = allfound + 1
													break
												end
											end
										end
									else
										for c,d in pairs(unitlists) do
											local tested = false
											
											if (c ~= pname) and (#d > 0) and (alreadyfound[bcode] == nil) then
												for e,f in ipairs(d) do
													if (alreadyfound[f] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[f] = 1
														allfound = allfound + 1
														tested = true
														break
													end
												end
											end
											
											if tested then
												break
											end
										end
									end
								elseif (b == "empty") then
									local empties = findempty()
									
									if (#empties > 0) and (alreadyfound[bcode] == nil) then
										for c,d in ipairs(empties) do
											if (alreadyfound[d] == nil) then
												alreadyfound[bcode] = 1
												alreadyfound[d] = 1
												allfound = allfound + 1
												break
											end
										end
									end
								elseif (b == "text") and (alreadyfound[bcode] == nil) then
									alreadyfound[bcode] = 1
									allfound = allfound + 1
								end
								
								if (p ~= "text") and (alreadyfound[bcode] == nil) then
									for e,f in pairs(surrounds) do
										local tested = false
										
										if (e ~= "dir") then
											for c,d in ipairs(f) do
												if (pnot == false) then
													if (d == pname) and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														allfound = allfound + 1
														tested = true
														break
													end
												else
													if (d ~= pname) and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														allfound = allfound + 1
														tested = true
														break
													end
												end
											end
										end
										
										if tested then
											break
										end
									end
								end
							end
						end
					else
						print("no parameters given!")
						result = false
					end
					
					if (allfound == #params) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "without") then
					valid = true
					local allfound = 0
					local alreadyfound = {}
					local unitcount = {}
					
					if (#params > 0) then
						for a,b in ipairs(params) do
							if (unitcount[b] == nil) then
								unitcount[b] = 0
							end
							
							unitcount[b] = unitcount[b] + 1
						end
						
						if (unitcount["level"] ~= nil) and (unitcount["level"] > 0) then
							unitcount["level"] = unitcount["level"] - 1
						end
							
						for a,b in ipairs(params) do
							local pname = b
							local pnot = false
							if (string.sub(b, 1, 4) == "not ") then
								pnot = true
								pname = string.sub(b, 5)
							end
							
							local bcode = b .. "_" .. tostring(a)
							
							if (string.sub(pname, 1, 5) == "group") then
								result = false
								break
							end
							
							local is_param_this, raycast_units, raycast_tileid, count = parse_this_param_and_get_raycast_units(pname)
							if is_param_this then
								if count == 0 or (count > 0 and raycast_units[unitid]) then
									alreadyfound[bcode] = 1
									allfound = allfound + 1
								end
							elseif ((b ~= "level") and (b ~= "empty")) or ((b == "level") and (unitcount["level"] > 0)) then
								if (pnot == false) then
									if (alreadyfound[bcode] == nil) then
										if (unitlists[b] == nil) or (#unitlists[b] == 0) and (alreadyfound[bcode] == nil) then
											alreadyfound[bcode] = 1
											allfound = allfound + 1
										elseif (unitlists[b] ~= nil) and (#unitlists[b] > 0) then
											local found = false
											
											if (b ~= name) then
												if (#unitlists[b] < unitcount[b]) then
													found = true
												end
											else
												if (#unitlists[b] < unitcount[b] + 1) then
													found = true
												end
											end
											
											if found then
												alreadyfound[bcode] = 1
												allfound = allfound + 1
											end
										end
									end
								else
									local foundunits = 0
									
									for c,d in pairs(unitlists) do
										if (c ~= pname) and (#unitlists[c] > 0) and (c ~= "text") then
											for e,f in ipairs(d) do
												if (f ~= unitid) and (alreadyfound[f] == nil) then
													alreadyfound[f] = 1
													foundunits = foundunits + 1
													
													if (foundunits >= unitcount[b]) then
														break
													end
												end
											end
										end
										
										if (foundunits >= unitcount[b]) then
											break
										end
									end
									
									if (foundunits < unitcount[b]) and (alreadyfound[bcode] == nil) then
										alreadyfound[bcode] = 1
										allfound = allfound + 1
									end
								end
							elseif (b == "empty") then
								local empties = findempty()
								
								if (name ~= "empty") then
									if (#empties < unitcount[b]) and (alreadyfound[bcode] == nil) then
										alreadyfound[bcode] = 1
										allfound = allfound + 1
									end
								else
									if (#empties < unitcount[b] + 1) and (alreadyfound[bcode] == nil) then
										alreadyfound[bcode] = 1
										allfound = allfound + 1
									end
								end
							elseif (b == "level") then
								allfound = -99
								break
							end
						end
					else
						print("no parameters given!")
						result = false
					end

					if (allfound ~= #params) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "not without") then
					valid = true
					local allfound = 0
					local alreadyfound = {}
					local unitcount = {}
					
					if (#params > 0) then
						for a,b in ipairs(params) do
							if (unitcount[b] == nil) then
								unitcount[b] = 0
							end
							
							unitcount[b] = unitcount[b] + 1
						end
						
						if (unitcount["level"] ~= nil) and (unitcount["level"] > 0) then
							unitcount["level"] = unitcount["level"] - 1
						end
						
						for a,b in ipairs(params) do
							local pname = b
							local pnot = false
							if (string.sub(b, 1, 4) == "not ") then
								pnot = true
								pname = string.sub(b, 5)
							end
							
							local bcode = b .. "_" .. tostring(a)
							
							if (string.sub(pname, 1, 5) == "group") then
								result = false
								break
							end
							
							local is_param_this, raycast_units, raycast_tileid, count = parse_this_param_and_get_raycast_units(pname)
							if is_param_this then
								if count > 0 and not (raycast_units[unitid] and count == 1) then
									alreadyfound[bcode] = 1
									allfound = allfound + 1
								end
							elseif ((b ~= "level") and (b ~= "empty")) or ((b == "level") and (unitcount["level"] > 0)) then
								if (pnot == false) then
									if (unitlists[b] ~= nil) and (#unitlists[b] > 0) and (alreadyfound[bcode] == nil) then
										local found = false
										
										for c,d in ipairs(unitlists[b]) do
											if (d ~= unitid) and (alreadyfound[d] == nil) then
												alreadyfound[d] = 1
												found = true
												break
											end
										end
										
										if found then
											alreadyfound[bcode] = 1
											allfound = allfound + 1
										end
									end
								else
									local found = false
									
									for c,d in pairs(unitlists) do
										if (c ~= pname) and (#unitlists[c] > 0) and (c ~= "text") then
											for e,f in ipairs(d) do
												if (f ~= unitid) and (alreadyfound[f] == nil) then
													alreadyfound[f] = 1
													found = true
													break
												end
											end
										end
										
										if found then
											break
										end
									end
									
									if found and (alreadyfound[bcode] == nil) then
										alreadyfound[bcode] = 1
										allfound = allfound + 1
									end
								end
							elseif (b == "empty") then
								local empties = findempty()
								
								if (name ~= "empty") then
									if (#empties >= unitcount[b]) and (alreadyfound[bcode] == nil) then
										alreadyfound[bcode] = 1
										allfound = allfound + 1
									end
								else
									if (#empties >= unitcount[b] + 1) and (alreadyfound[bcode] == nil) then
										alreadyfound[bcode] = 1
										allfound = allfound + 1
									end
								end
							elseif (b == "level") and (alreadyfound[bcode] == nil) then
								alreadyfound[bcode] = 1
								allfound = allfound + 1
							end
						end
					else
						print("no parameters given!")
						result = false
					end

					if (allfound ~= #params) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "below") then
					valid = true
					local allfound = 0
					local alreadyfound = {}
					
					if (#params > 0) then
						for a,b in ipairs(params) do
							local pname = b
							local pnot = false
							if (string.sub(b, 1, 4) == "not ") then
								pnot = true
								pname = string.sub(b, 5)
							end

							local is_param_this, raycast_units, raycast_tileid = parse_this_param_and_get_raycast_units(pname)
							local ray_unit_is_empty = is_param_this and raycast_units[2] -- <-- this last condition checks if empty is a raycast unit
							
							local bcode = b .. "_" .. tostring(a)
							
							if (string.sub(pname, 1, 5) == "group") then
								result = false
								break
							end
							
							local dist = (y - 1)
							
							if (unitid ~= 1) then
								if (b ~= "level") or ((b == "level") and (alreadyfound[1] ~= nil)) then
									if (y > 1) then
										for g=1,dist do
											if (pname ~= "empty") and not ray_unit_is_empty then
												local tileid = x + (y - g) * roomsizex
												if (unitmap[tileid] ~= nil) then
													for c,d in ipairs(unitmap[tileid]) do
														if (d ~= unitid) and (alreadyfound[d] == nil) then
															local unit = mmf.newObject(d)
															local name_ = getname(unit)
															
															if (pnot == false) then
																if is_param_this then
																	if raycast_units and raycast_units[d] and alreadyfound[bcode] == nil then
																		alreadyfound[bcode] = 1
																		alreadyfound[d] = 1
																		allfound = allfound + 1
																	end
																elseif (name_ == pname) and (alreadyfound[bcode] == nil) then
																	alreadyfound[bcode] = 1
																	alreadyfound[d] = 1
																	allfound = allfound + 1
																end
															else
																if is_param_this then
																	if raycast_units and not raycast_units[d] and alreadyfound[bcode] == nil and name_ ~= "text" then
																		alreadyfound[bcode] = 1
																		alreadyfound[d] = 1
																		allfound = allfound + 1
																	end
																elseif (name_ ~= pname) and (alreadyfound[bcode] == nil) and (name_ ~= "text") then
																	alreadyfound[bcode] = 1
																	alreadyfound[d] = 1
																	allfound = allfound + 1
																end
															end
														end
													end
												end
											else
												local nearempty = false
										
												local tileid = x + (y - g) * roomsizex
												local l = map[0]
												local tile = l:get_x(x,y - g)
												
												local tcode = tostring(tileid) .. "e"
												
												if ((unitmap[tileid] == nil) or (#unitmap[tileid] == 0)) and (tile == 255) and (alreadyfound[tcode] == nil) then 
													nearempty = true
												end

												if nearempty and ray_unit_is_empty and tileid ~= raycast_tileid and not pnot then
													nearempty = false
												end
												
												if (pnot == false) then
													if nearempty and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[tcode] = 1
														allfound = allfound + 1
													end
												else
													if (nearempty == false) and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[tcode] = 1
														allfound = allfound + 1
													end
												end
											end
										end
									end
								elseif (b == "level") and (alreadyfound[bcode] == nil) and (alreadyfound[1] == nil) then
									alreadyfound[bcode] = 1
									alreadyfound[1] = 1
									allfound = allfound + 1
								end
							else
								local ulist = false
							
								if (b ~= "empty") and (b ~= "level") then
									if (pnot == false) then
										if (unitlists[pname] ~= nil) and (#unitlists[pname] > 0) and (alreadyfound[bcode] == nil) then
											for c,d in ipairs(unitlists[pname]) do
												if (alreadyfound[d] == nil) then
													alreadyfound[bcode] = 1
													alreadyfound[d] = 1
													ulist = true
													break
												end
											end
										end
									else
										for c,d in pairs(unitlists) do
											local tested = false
											
											if (c ~= pname) and (#d > 0) and (alreadyfound[bcode] == nil) then
												for e,f in ipairs(d) do
													if (alreadyfound[f] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[f] = 1
														ulist = true
														tested = true
														break
													end
												end
											end
											
											if tested then
												break
											end
										end
									end
								elseif (b == "empty") then
									local empties = findempty()
									
									if (#empties > 0) then
										for c,d in ipairs(empties) do
											if (alreadyfound[d] == nil) and (alreadyfound[bcode] == nil) then
												alreadyfound[bcode] = 1
												alreadyfound[d] = 1
												ulist = true
												break
											end
										end
									end
								end
								
								if (b ~= "text") and (ulist == false) then
									if (surrounds.u ~= nil) then
										for c,d in ipairs(surrounds.u) do
											if (pnot == false) then
												if (ulist == false) and (d == pname) and (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													ulist = true
												end
											else
												if (ulist == false) and (d ~= pname) and (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													ulist = true
												end
											end
										end
									end
								end
								
								if ulist or (b == "text") then
									alreadyfound[bcode] = 1
									allfound = allfound + 1
								end
							end
						end
					else
						print("no parameters given!")
						result = false
					end

					if (allfound ~= #params) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "not below") then
					valid = true
					
					local allfound = 0
					local alreadyfound = {}
					
					if (#params > 0) then
						for a,b in ipairs(params) do
							local pname = b
							local pnot = false
							if (string.sub(b, 1, 4) == "not ") then
								pnot = true
								pname = string.sub(b, 5)
							end

							local is_param_this, raycast_units, raycast_tileid = parse_this_param_and_get_raycast_units(pname)
							local ray_unit_is_empty = is_param_this and raycast_units[2] -- <-- this last condition checks if empty is a raycast unit
							
							local bcode = b .. "_" .. tostring(a)
							
							if (string.sub(pname, 1, 5) == "group") then
								result = false
								break
							end
							
							local dist = (y - 1)
							
							if (unitid ~= 1) then
								if (b ~= "level") or ((b == "level") and (alreadyfound[1] ~= nil)) then
									if (y > 1) then
										for g=1,dist do
											if (pname ~= "empty") and not ray_unit_is_empty then
												local tileid = x + (y - g) * roomsizex
												if (unitmap[tileid] ~= nil) then
													for c,d in ipairs(unitmap[tileid]) do
														if (d ~= unitid) and (alreadyfound[d] == nil) then
															local unit = mmf.newObject(d)
															local name_ = getname(unit)
															
															if (pnot == false) then
																if is_param_this then
																	if raycast_units and raycast_units[d] and alreadyfound[bcode] == nil then
																		alreadyfound[bcode] = 1
																		alreadyfound[d] = 1
																		allfound = allfound + 1
																	end
																elseif (name_ == pname) and (d ~= unitid) and (alreadyfound[bcode] == nil) then
																	alreadyfound[bcode] = 1
																	alreadyfound[d] = 1
																	allfound = allfound + 1
																end
															else
																if is_param_this then
																	if raycast_units and not raycast_units[d] and alreadyfound[bcode] == nil and name_ ~= "text" then
																		alreadyfound[bcode] = 1
																		alreadyfound[d] = 1
																		allfound = allfound + 1
																	end
																elseif (name_ ~= pname) and (d ~= unitid) and (name_ ~= "text") and (alreadyfound[bcode] == nil) then
																	alreadyfound[bcode] = 1
																	alreadyfound[d] = 1
																	allfound = allfound + 1
																end
															end
														end
													end
												end
											else
												local nearempty = false
										
												local tileid = x + (y - g) * roomsizex
												local l = map[0]
												local tile = l:get_x(x,y - g)
												
												local tcode = tostring(tileid) .. "e"
												
												if ((unitmap[tileid] == nil) or (#unitmap[tileid] == 0)) and (tile == 255) and (alreadyfound[tcode] == nil) then 
													nearempty = true
												end

												if nearempty and ray_unit_is_empty and tileid ~= raycast_tileid and not pnot then
													nearempty = false
												end
												
												if (pnot == false) then
													if nearempty and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[tcode] = 1
														allfound = allfound + 1
													end
												else
													if (nearempty == false) and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[tcode] = 1
														allfound = allfound + 1
													end
												end
											end
										end
									end
								elseif (b == "level") and (alreadyfound[bcode] == nil) and (alreadyfound[1] == nil) then
									alreadyfound[bcode] = 1
									alreadyfound[1] = 1
									allfound = allfound + 1
								end
							else
								local ulist = false
							
								if (b ~= "empty") and (b ~= "text") then
									if (pnot == false) then
										if (unitlists[b] ~= nil) and (#unitlists[b] > 0) and (alreadyfound[bcode] == nil) then
											for c,d in ipairs(unitlists[b]) do
												if (alreadyfound[d] == nil) then
													alreadyfound[bcode] = 1
													alreadyfound[d] = 1
													allfound = allfound + 1
													break
												end
											end
										end
									else
										for c,d in pairs(unitlists) do
											local tested = false
											
											if (c ~= pname) and (#d > 0) and (alreadyfound[bcode] == nil) then
												for e,f in ipairs(d) do
													if (alreadyfound[f] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[f] = 1
														allfound = allfound + 1
														tested = true
														break
													end
												end
											end
											
											if tested then
												break
											end
										end
									end
								elseif (b == "empty") then
									local empties = findempty()
									
									if (#empties > 0) and (alreadyfound[bcode] == nil) then
										for c,d in ipairs(empties) do
											if (alreadyfound[d] == nil) then
												alreadyfound[bcode] = 1
												alreadyfound[d] = 1
												allfound = allfound + 1
												break
											end
										end
									end
								elseif (b == "text") and (alreadyfound[bcode] == nil) then
									alreadyfound[bcode] = 1
									allfound = allfound + 1
								end
								
								if (p ~= "text") and (alreadyfound[bcode] == nil) then
									if (surrounds.u ~= nil) then
										for c,d in ipairs(surrounds.u) do
											if (pnot == false) then
												if (d == pname) and (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													allfound = allfound + 1
												end
											else
												if (d ~= pname) and (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													allfound = allfound + 1
												end
											end
										end
									end
								end
							end
						end
					else
						print("no parameters given!")
						result = false
					end
					
					if (allfound == #params) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "above") then
					valid = true
					local allfound = 0
					local alreadyfound = {}
					
					if (#params > 0) then
						for a,b in ipairs(params) do
							local pname = b
							local pnot = false
							if (string.sub(b, 1, 4) == "not ") then
								pnot = true
								pname = string.sub(b, 5)
							end

							local is_param_this, raycast_units, raycast_tileid = parse_this_param_and_get_raycast_units(pname)
							local ray_unit_is_empty = is_param_this and raycast_units[2] -- <-- this last condition checks if empty is a raycast unit

							local bcode = b .. "_" .. tostring(a)
							
							if (string.sub(pname, 1, 5) == "group") then
								result = false
								break
							end
							
							local dist = roomsizey - y - 1
							
							if (unitid ~= 1) then
								if (b ~= "level") or ((b == "level") and (alreadyfound[1] ~= nil)) then
									if (dist > 1) then
										for g=1,dist do
											if (pname ~= "empty") and not ray_unit_is_empty then
												local tileid = x + (y + g) * roomsizex
												if (unitmap[tileid] ~= nil) then
													for c,d in ipairs(unitmap[tileid]) do
														if (d ~= unitid) and (alreadyfound[d] == nil) then
															local unit = mmf.newObject(d)
															local name_ = getname(unit)
															
															if (pnot == false) then
																if is_param_this then
																	if raycast_units and raycast_units[d] and alreadyfound[bcode] == nil then
																		alreadyfound[bcode] = 1
																		alreadyfound[d] = 1
																		allfound = allfound + 1
																	end
																elseif (name_ == pname) and (alreadyfound[bcode] == nil) then
																	alreadyfound[bcode] = 1
																	alreadyfound[d] = 1
																	allfound = allfound + 1
																end
															else
																if is_param_this then
																	if raycast_units and not raycast_units[d] and alreadyfound[bcode] == nil and name_ ~= "text" then
																		alreadyfound[bcode] = 1
																		alreadyfound[d] = 1
																		allfound = allfound + 1
																	end
																elseif (name_ ~= pname) and (alreadyfound[bcode] == nil) and (name_ ~= "text") then
																	alreadyfound[bcode] = 1
																	alreadyfound[d] = 1
																	allfound = allfound + 1
																end
															end
														end
													end
												end
											else
												local nearempty = false
										
												local tileid = x + (y + g) * roomsizex
												local l = map[0]
												local tile = l:get_x(x,y + g)
												
												local tcode = tostring(tileid) .. "e"
												
												if ((unitmap[tileid] == nil) or (#unitmap[tileid] == 0)) and (tile == 255) and (alreadyfound[tcode] == nil) then 
													nearempty = true
												end

												if nearempty and ray_unit_is_empty and tileid ~= raycast_tileid and not pnot then
													nearempty = false
												end
												
												if (pnot == false) then
													if nearempty and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[tcode] = 1
														allfound = allfound + 1
													end
												else
													if (nearempty == false) and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[tcode] = 1
														allfound = allfound + 1
													end
												end
											end
										end
									end
								elseif (b == "level") and (alreadyfound[bcode] == nil) and (alreadyfound[1] == nil) then
									alreadyfound[bcode] = 1
									alreadyfound[1] = 1
									allfound = allfound + 1
								end
							else
								local ulist = false
							
								if (b ~= "empty") and (b ~= "level") then
									if (pnot == false) then
										if (unitlists[pname] ~= nil) and (#unitlists[pname] > 0) and (alreadyfound[bcode] == nil) then
											for c,d in ipairs(unitlists[pname]) do
												if (alreadyfound[d] == nil) then
													alreadyfound[bcode] = 1
													alreadyfound[d] = 1
													ulist = true
													break
												end
											end
										end
									else
										for c,d in pairs(unitlists) do
											local tested = false
											
											if (c ~= pname) and (#d > 0) and (alreadyfound[bcode] == nil) then
												for e,f in ipairs(d) do
													if (alreadyfound[f] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[f] = 1
														ulist = true
														tested = true
														break
													end
												end
											end
											
											if tested then
												break
											end
										end
									end
								elseif (b == "empty") then
									local empties = findempty()
									
									if (#empties > 0) and (alreadyfound[bcode] == nil) then
										for c,d in ipairs(unitlists[pname]) do
											if (alreadyfound[d] == nil) then
												alreadyfound[bcode] = 1
												alreadyfound[d] = 1
												ulist = true
												break
											end
										end
									end
								end
								
								if (b ~= "text") and (ulist == false) then
									if (surrounds.d ~= nil) then
										for c,d in ipairs(surrounds.d) do
											if (pnot == false) then
												if (ulist == false) and (d == pname) and (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													ulist = true
												end
											else
												if (ulist == false) and (d ~= pname) and (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													ulist = true
												end
											end
										end
									end
								end
								
								if ulist or (b == "text") then
									alreadyfound[bcode] = 1
									allfound = allfound + 1
								end
							end
						end
					else
						print("no parameters given!")
						result = false
					end

					if (allfound ~= #params) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "not above") then
					valid = true
					
					local allfound = 0
					local alreadyfound = {}
					
					if (#params > 0) then
						for a,b in ipairs(params) do
							local pname = b
							local pnot = false
							if (string.sub(b, 1, 4) == "not ") then
								pnot = true
								pname = string.sub(b, 5)
							end

							local is_param_this, raycast_units, raycast_tileid = parse_this_param_and_get_raycast_units(pname)
							local ray_unit_is_empty = is_param_this and raycast_units[2] -- <-- this last condition checks if empty is a raycast unit
							
							local bcode = b .. "_" .. tostring(a)
							
							if (string.sub(pname, 1, 5) == "group") then
								result = false
								break
							end
							
							local dist = roomsizey - y - 1
							
							if (unitid ~= 1) then
								if (b ~= "level") or ((b == "level") and (alreadyfound[1] ~= nil)) then
									if (dist > 1) then
										for g=1,dist do
											if (pname ~= "empty") and not ray_unit_is_empty then
												local tileid = x + (y + g) * roomsizex
												if (unitmap[tileid] ~= nil) then
													for c,d in ipairs(unitmap[tileid]) do
														if (d ~= unitid) and (alreadyfound[d] == nil) then
															local unit = mmf.newObject(d)
															local name_ = getname(unit)
															
															if (pnot == false) then
																if is_param_this then
																	if raycast_units and raycast_units[d] and alreadyfound[bcode] == nil then
																		alreadyfound[bcode] = 1
																		alreadyfound[d] = 1
																		allfound = allfound + 1
																	end
																elseif (name_ == pname) and (d ~= unitid) and (alreadyfound[bcode] == nil) then
																	alreadyfound[bcode] = 1
																	alreadyfound[d] = 1
																	allfound = allfound + 1
																end
															else
																if is_param_this then
																	if raycast_units and not raycast_units[d] and alreadyfound[bcode] == nil and name_ ~= "text" then
																		alreadyfound[bcode] = 1
																		alreadyfound[d] = 1
																		allfound = allfound + 1
																	end
																elseif (name_ ~= pname) and (d ~= unitid) and (name_ ~= "text") and (alreadyfound[bcode] == nil) then
																	alreadyfound[bcode] = 1
																	alreadyfound[d] = 1
																	allfound = allfound + 1
																end
															end
														end
													end
												end
											else
												local nearempty = false
										
												local tileid = x + (y + g) * roomsizex
												local l = map[0]
												local tile = l:get_x(x,y + g)
												
												local tcode = tostring(tileid) .. "e"
												
												if ((unitmap[tileid] == nil) or (#unitmap[tileid] == 0)) and (tile == 255) and (alreadyfound[tcode] == nil) then 
													nearempty = true
												end

												if nearempty and ray_unit_is_empty and tileid ~= raycast_tileid then
													nearempty = false
												end
												
												if (pnot == false) then
													if nearempty and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[tcode] = 1
														allfound = allfound + 1
													end
												else
													if (nearempty == false) and (alreadyfound[bcode] == nil) then
														alreadyfound[bcode] = 1
														alreadyfound[tcode] = 1
														allfound = allfound + 1
													end
												end
											end
										end
									end
								elseif (b == "level") and (alreadyfound[bcode] == nil) and (alreadyfound[1] == nil) then
									alreadyfound[bcode] = 1
									alreadyfound[1] = 1
									allfound = allfound + 1
								end
							else
								local ulist = false
							
								if (b ~= "empty") and (b ~= "text") then
									if (pnot == false) then
										if (unitlists[b] ~= nil) and (#unitlists[b] > 0) and (alreadyfound[bcode] == nil) then
											for c,d in ipairs(unitlists[b]) do
												if (alreadyfound[d] == nil) then
													alreadyfound[bcode] = 1
													alreadyfound[d] = 1
													allfound = allfound + 1
													break
												end
											end
										end
									else
										for c,d in pairs(unitlists) do
											local tested = false
											
											if (c ~= pname) and (#d > 0) and (alreadyfound[bcode] == nil) then
												for e,f in ipairs(d) do
													alreadyfound[bcode] = 1
													alreadyfound[f] = 1
													allfound = allfound + 1
													tested = true
													break
												end
											end
											
											if tested then
												break
											end
										end
									end
								elseif (b == "empty") then
									local empties = findempty()
									
									if (#empties > 0) and (alreadyfound[bcode] == nil) then
										for c,d in ipairs(empties) do
											if (alreadyfound[d] == nil) then
												alreadyfound[bcode] = 1
												alreadyfound[d] = 1
												allfound = allfound + 1
												break
											end
										end
									end
								elseif (b == "text") and (alreadyfound[bcode] == nil) then
									alreadyfound[bcode] = 1
									allfound = allfound + 1
								end
								
								if (p ~= "text") and (alreadyfound[bcode] == nil) then
									if (surrounds.d ~= nil) then
										for c,d in ipairs(surrounds.d) do
											if (pnot == false) then
												if (d == pname) and (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													allfound = allfound + 1
												end
											else
												if (d ~= pname) and (alreadyfound[bcode] == nil) then
													alreadyfound[bcode] = 1
													allfound = allfound + 1
												end
											end
										end
									end
								end
							end
						end
					else
						print("no parameters given!")
						result = false
					end
					
					if (allfound == #params) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "feeling") then
					valid = true
					
					local allfound = 0
					local alreadyfound = {}
					
					if (#params > 0) then
						for a,b in ipairs(params) do
							local pname = b
							local pnot = false
							if (string.sub(b, 1, 4) == "not ") then
								pnot = true
								pname = string.sub(b, 5)
							end
							
							local bcode = b .. "_" .. tostring(a)
							
							if (featureindex[name] ~= nil) then
								for c,d in ipairs(featureindex[name]) do
									local drule = d[1]
									local dconds = d[2]
									
									if (checkedconds[tostring(dconds)] == nil) then
										if (pnot == false) then
											if (drule[1] == name) and (drule[2] == "is") and (drule[3] == b) then
												checkedconds[tostring(dconds)] = 1
												
												if (alreadyfound[bcode] == nil) and testcond(dconds,unitid,x,y,nil,limit,checkedconds) then
													alreadyfound[bcode] = 1
													allfound = allfound + 1
													break
												end
											end
										else
											if (string.sub(drule[3], 1, 4) ~= "not ") then
												local obj = unitreference["text_" .. drule[3]]
												
												if (obj ~= nil) then
													local objtype = getactualdata_objlist(obj,"type")
													
													if (objtype == 2) then
														if (drule[1] == name) and (drule[2] == "is") and (drule[3] ~= pname) then
															checkedconds[tostring(dconds)] = 1
															
															if (alreadyfound[bcode] == nil) and testcond(dconds,unitid,x,y,nil,limit,checkedconds) then
																alreadyfound[bcode] = 1
																allfound = allfound + 1
																break
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
					else
						result = false
					end
					
					if (allfound ~= #params) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "not feeling") then
					valid = true
					local failure = false
					
					if (#params > 0) then
						for a,b in ipairs(params) do
							local pname = b
							local pnot = false
							if (string.sub(b, 1, 4) == "not ") then
								pnot = true
								pname = string.sub(b, 5)
							end
							
							local bcode = b .. "_" .. tostring(a)
							
							if (featureindex[name] ~= nil) and (failure == false) then
								for c,d in ipairs(featureindex[name]) do
									local drule = d[1]
									local dconds = d[2]
									
									if (checkedconds[tostring(dconds)] == nil) then
										if (pnot == false) then
											if (drule[1] == name) and (drule[2] == "is") and (drule[3] == b) then
												checkedconds[tostring(dconds)] = 1
												
												if testcond(dconds,unitid,x,y,nil,limit,checkedconds) then
													failure = true
													break
												end
											end
										else
											if (string.sub(drule[3], 1, 4) ~= "not ") then
												local obj = unitreference["text_" .. drule[3]]
												
												if (obj ~= nil) then
													local objtype = getactualdata_objlist(obj,"type")
													
													if (objtype == 2) then
														if (drule[1] == name) and (drule[2] == "is") and (drule[3] ~= pname) then
															checkedconds[tostring(dconds)] = 1
															
															if testcond(dconds,unitid,x,y,nil,limit,checkedconds) then
																failure = true
																break
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
					else
						result = false
					end
					
					if failure then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "lonely") then
					valid = true
					local failure = false
					
					if (unitid ~= 1) then
						local tileid = x + y * roomsizex
						if (unitmap[tileid] ~= nil) then
							for c,d in ipairs(unitmap[tileid]) do
								if (d ~= unitid) then
									failure = true
									break
								end
							end
						end
					else
						failure = true
					end
					
					if failure then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "not lonely") then
					valid = true
					local failure = false
					
					if (unitid ~= 1) then
						local tileid = x + y * roomsizex
						if (unitmap[tileid] ~= nil) then
							if (#unitmap[tileid] == 1) then
								failure = true
							end
						end
					end
					
					if failure then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "idle") then
					valid = true
					
					if (last_key ~= 4) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "not idle") then
					valid = true
					
					if (last_key == 4) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "powered") then
					valid = true
					local found = false
					
					if (featureindex["power"] ~= nil) then
						for c,d in ipairs(featureindex["power"]) do
							local drule = d[1]
							local dconds = d[2]
							
							if (checkedconds[tostring(dconds)] == nil) then
								if (string.sub(drule[1], 1, 4) ~= "not ") and (drule[2] == "is") and (drule[3] == "power") then
									if (drule[1] ~= "empty") and (drule[1] ~= "level") then
										if (unitlists[drule[1]] ~= nil) then
											checkedconds[tostring(dconds)] = 1
											
											for e,f in ipairs(unitlists[drule[1]]) do
												if testcond(dconds,f,x,y,nil,limit,checkedconds) then
													found = true
													break
												end
											end
										end
									elseif (drule[1] == "empty") then
										local empties = findempty(dconds,true)
										
										if (#empties > 0) then
											found = true
										end
									elseif (drule[1] == "level") and testcond(dconds,2,x,y,nil,limit,checkedconds) then
										found = true
									end
								end
							end
							
							if found then
								break
							end
						end
					end
					
					checkedconds = checkedconds_ or {[tostring(conds)] = 1}
					
					if (found == false) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "not powered") then
					valid = true
					local found = false
					
					if (featureindex["power"] ~= nil) then
						for c,d in ipairs(featureindex["power"]) do
							local drule = d[1]
							local dconds = d[2]
							
							if (checkedconds[tostring(dconds)] == nil) then
								if (string.sub(drule[1], 1, 4) ~= "not ") and (drule[2] == "is") and (drule[3] == "power") then
									if (drule[1] ~= "empty") and (drule[1] ~= "level") then
										if (unitlists[drule[1]] ~= nil) then
											checkedconds[tostring(dconds)] = 1
											
											for e,f in ipairs(unitlists[drule[1]]) do
												if testcond(dconds,f,x,y,nil,limit,checkedconds) then
													found = true
													break
												end
											end
										end
									elseif (drule[1] == "empty") then
										local empties = findempty(dconds,true)
										
										if (#empties > 0) then
											found = true
										end
									elseif (drule[1] == "level") and testcond(dconds,2,x,y,nil,limit,checkedconds) then
										found = true
									end
								end
							end
							
							if found then
								break
							end
						end
					end
					
					checkedconds = checkedconds_ or {[tostring(conds)] = 1}
					
					if found then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "seldom") then
					valid = true
					
					if (condstatus[tostring(conds)] == nil) then
						condstatus[tostring(conds)] = {}
					end
					
					local rnd = fixedrandom(1,6)
					
					local d = condstatus[tostring(conds)]
					local id = "seldom" .. "_" .. tostring(i)
					
					if (unitid ~= 2) then
						id = id .. "_" .. tostring(unitid)
					else
						id = id .. "_" .. tostring(unitid) .. tostring(x) .. tostring(y)
					end
					
					if (d[id] ~= nil) then
						rnd = d[id]
					else
						d[id] = rnd
					end
					
					if (rnd ~= 1) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "not seldom") then
					valid = true
					
					if (condstatus[tostring(conds)] == nil) then
						condstatus[tostring(conds)] = {}
					end
					
					local rnd = fixedrandom(1,6)
					
					local d = condstatus[tostring(conds)]
					local id = "seldom" .. "_" .. tostring(i)
					
					if (unitid ~= 2) then
						id = id .. "_" .. tostring(unitid)
					else
						id = id .. "_" .. tostring(unitid) .. tostring(x) .. tostring(y)
					end
					
					if (d[id] ~= nil) then
						rnd = d[id]
					else
						d[id] = rnd
					end
					
					if (rnd == 1) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "often") then
					valid = true
					
					if (condstatus[tostring(conds)] == nil) then
						condstatus[tostring(conds)] = {}
					end
					
					local rnd = fixedrandom(1,4)
					
					local d = condstatus[tostring(conds)]
					local id = "often" .. "_" .. tostring(i)
					
					if (unitid ~= 2) then
						id = id .. "_" .. tostring(unitid)
					else
						id = id .. "_" .. tostring(unitid) .. tostring(x) .. tostring(y)
					end
					
					if (d[id] ~= nil) then
						rnd = d[id]
					else
						d[id] = rnd
					end
					
					if (rnd == 1) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "not often") then
					valid = true
					
					if (condstatus[tostring(conds)] == nil) then
						condstatus[tostring(conds)] = {}
					end
					
					local rnd = fixedrandom(1,4)
					
					local d = condstatus[tostring(conds)]
					local id = "often" .. "_" .. tostring(i)
					
					if (unitid ~= 2) then
						id = id .. "_" .. tostring(unitid)
					else
						id = id .. "_" .. tostring(unitid) .. tostring(x) .. tostring(y)
					end
					
					if (d[id] ~= nil) then
						rnd = d[id]
					else
						d[id] = rnd
					end
					
					if (rnd ~= 1) then
						if (orhandling == false) then
							result = false
							break
						end
					elseif orhandling then
						orresult = true
					end
				elseif (condtype == "this") then
                    if #params == 1 then
						valid = true
                        local this_text_unitid = params[1]
                        
						local pass = false
						for _, ray_unit in ipairs(get_raycast_units(this_text_unitid, true)) do
							if ray_unit == 2 then
								local tileid = x + y * roomsizex
								if this_mod_globals.text_to_raycast_pos[this_text_unitid] == tileid then
									pass = true
								end
								break
							elseif ray_unit == unitid then
								pass = true
								break
							end
						end
                        if not pass then
                            if orhandling == false then
                                result = false
                                break
                            end
                        elseif orhandling then
                            orresult = true
                        end
                    end
				elseif (condtype == "not this") then
                    if #params == 1 then
						valid = true
                        local this_text_unitid = params[1]
                        
						local pass = true
						for _, ray_unit in ipairs(get_raycast_units(this_text_unitid, true)) do
							if ray_unit == 2 then
								local tileid = x + y * roomsizex
								if this_mod_globals.text_to_raycast_pos[this_text_unitid] == tileid then
									pass = false
								end
								break
							elseif ray_unit == unitid then
								pass = false
								break
							end
						end
                        if not pass then
                            if orhandling == false then
                                result = false
                                break
                            end
                        elseif orhandling then
                            orresult = true
                        end
                    end
                end
				
				if (string.sub(cond[1], -1) == ")") then
					orhandling = false
					
					if (orresult == false) then
						result = false
						break
					else
						result = true
					end
				end
			end
			
			if (valid == false) then
				MF_alert("invalid condition!")
				result = true
			end
		end
	end
	
	return result
end

