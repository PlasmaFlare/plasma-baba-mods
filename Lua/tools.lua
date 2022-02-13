function writerules(parent,name,x_,y_)
	--[[ 
		@mods(this) - Override reason: Custom "this" rule display. Also remove unitid display when 
			forming "this(X) is float" and "Y mimic X"
	 ]]
	local basex = x_
	local basey = y_
	local linelimit = 12
	local maxcolumns = 4
	
	local x,y = basex,basey
	
	if (#visualfeatures > 0) then
		writetext(langtext("rules_colon"),0,x,y,name,true,2,true)
	end
	
	local i_ = 1
	
	local count = 0
	local allrules = {}
	
	local custom = MF_read("level","general","customruleword")
	
	for i,rules in ipairs(visualfeatures) do
		local text = ""
		local rule = rules[1]
		
		if (#custom == 0) then
			text = text .. rule[1] .. " "
		else
			text = text .. custom .. " "
		end
		
		local conds = rules[2]
		local ids = rules[3]
		local tags = rules[4]
		
		local fullinvis = true
		for a,b in ipairs(ids) do
			for c,d in ipairs(b) do
				local dunit = mmf.newObject(d)
				
				if dunit.visible then
					fullinvis = false
				end
			end
		end
		
		if (fullinvis == false) then
			if (#conds > 0) then
				local num_this_conds = 0
				local this_cond = ""
				for a,cond in ipairs(conds) do
					if cond[1] == "this" or cond[1] == "not this" then
						num_this_conds = num_this_conds + 1
						local pnoun_unitid = parse_this_unit_from_param_id(cond[2][1])
						local pnoun_unit = mmf.newObject(pnoun_unitid)

						if cond[1] == "this" then
							this_cond = pnoun_unit.strings[NAME]
						else
							this_cond = "not "..pnoun_unit.strings[NAME]
						end
					end
				end
				if num_this_conds > 0 then
					text = this_cond.." ("..rule[1]..")".." "
				end 

				for a,cond in ipairs(conds) do
					local middlecond = true
					
					if (cond[2] == nil) or ((cond[2] ~= nil) and (#cond[2] == 0)) then
						middlecond = false
					end
					if cond[1] == "this" or cond[1] == "not this" then
					elseif middlecond then
						if (#custom == 0) then
							local target = cond[1]
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
							
							text = text .. target .. " "
						else
							text = text .. custom .. " "
						end
						
						if (cond[2] ~= nil) then
							if (#cond[2] > 0) then
								for c,d in ipairs(cond[2]) do
									local this_param_name = parse_this_param_and_get_raycast_units(d)
									if this_param_name then
										text = text .. this_param_name.." "
									elseif (#custom == 0) then
										local target = d
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
										
										text = text .. target .. " "
									else
										text = text .. custom .. " "
									end
									
									if (#cond[2] > 1) and (c ~= #cond[2]) then
										text = text .. "& "
									end
								end
							end
						end
						
						if (a < #conds - num_this_conds) then
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
			
			if (allrules[text] == nil) then
				allrules[text] = 1
				count = count + 1
			else
				allrules[text] = allrules[text] + 1
			end
			i_ = i_ + 1
		end
	end
	
	local columns = math.min(maxcolumns, math.floor((count - 1) / linelimit) + 1)
	local columnwidth = math.min(screenw - f_tilesize * 2, columns * f_tilesize * 10) / columns
	
	i_ = 1
	
	local maxlimit = 4 * linelimit
	
	for i,v in pairs(allrules) do
		local text = i
		
		if (i_ <= maxlimit) then
			local currcolumn = math.floor((i_ - 1) / linelimit) - (columns * 0.5)
			x = basex + columnwidth * currcolumn + columnwidth * 0.5
			y = basey + (((i_ - 1) % linelimit) + 1) * f_tilesize * 0.8
		end
		
		if (i_ <= maxlimit-1) then
			if (v == 1) then
				writetext(text,0,x,y,name,true,2,true)
			elseif (v > 1) then
				writetext(tostring(v) .. " x " .. text,0,x,y,name,true,2,true)
			end
		end
		
		i_ = i_ + 1
	end
	
	if (i_ > maxlimit-1) then
		writetext("(+ " .. tostring(i_ - maxlimit) .. ")",0,x,y,name,true,2,true)
	end
end

