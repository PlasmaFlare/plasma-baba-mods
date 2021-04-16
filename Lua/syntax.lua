function createall(matdata,x_,y_,id_,dolevels_,leveldata_)
    --@This - Override reason: prevent MF_emptycreate error. Since "this" is a special noun, it doesn't have an actual object associated
    -- with it. Therefore, exclude "this" from "all" 
	local all = {}
	local empty = false
	local dolevels = dolevels_ or false
	
	local leveldata = leveldata_ or {}
	
	if (x_ == nil) and (y_ == nil) and (id_ == nil) then
		if (matdata[1] ~= "empty") and (matdata[1] ~= "group") then
			all = findall(matdata)
		elseif (matdata[1] == "empty") then
			all = findempty(matdata[2])
			empty = true
		end
	end
	local test = {}
	
	if (x_ ~= nil) and (y_ ~= nil) and (id_ ~= nil) then
		local check = findtype(matdata,x_,y_,id_)
		
		if (#check > 0) then
			for i,v in ipairs(check) do
				if (v ~= 0) then
					table.insert(test, v)
				end
			end
		end
	end
	
	if (#all > 0) then
		for i,v in ipairs(all) do
			table.insert(test, v)
		end
	end
	
	local delthese = {}
	
	if (#test > 0) then
		for i,v in ipairs(test) do
			if (empty == false) then
				local vunit = mmf.newObject(v)
				local x,y,dir = vunit.values[XPOS],vunit.values[YPOS],vunit.values[DIR],vunit.values[MOVED]
				
				for b,unit in pairs(objectlist) do
					if (b ~= "empty") and (b ~= "all") and (b ~= "level") and (b ~= "group") and (b ~= matdata[1]) and (b ~= "text") and (not is_name_text_this(b)) then
						local protect = hasfeature(matdata[1],"is","not " .. b,v,x,y)
						
						if (protect == nil) then
							local mat = findtype({b},x,y,v)
							--local tmat = findtext(x,y)
							
							if (#mat == 0) then
								create(b,x,y,dir,nil,nil,nil,nil,leveldata)
								
								
								if (matdata[1] == "text") or (matdata[1] == "level") then
									table.insert(delthese, v)
								end
							end
						end
					end
				end
			else
				local x = v % roomsizex
				local y = math.floor(v / roomsizex)
				local dir = 4
				
				local blocked = {}
				
				if (featureindex["empty"] ~= nil) then
					for i,rules in ipairs(featureindex["empty"]) do
						local rule = rules[1]
						local conds = rules[2]
						
						if (rule[1] == "empty") and (rule[2] == "is") and (string.sub(rule[3], 1, 4) == "not ") then
							if testcond(conds,1,x,y) then
								local target = string.sub(rule[3], 5)
								blocked[target] = 1
							end
						end
					end
				end
				
				if (blocked["all"] == nil) then
					for b,mat in pairs(objectlist) do
						if (b ~= "empty") and (b ~= "all") and (b ~= "level") and (b ~= "group") and (b ~= "text") and (blocked[target] == nil) and (not is_name_text_this(b)) then
							create(b,x,y,dir,nil,nil,nil,nil,leveldata)
						end
					end
				end
			end
		end
	end
	
	for a,b in ipairs(delthese) do
		delete(b)
	end
	
	if (matdata[1] == "level") and dolevels then
		local blocked = {}
		
		if (featureindex["level"] ~= nil) then
			for i,rules in ipairs(featureindex["level"]) do
				local rule = rules[1]
				local conds = rules[2]
				
				if (rule[1] == "level") and (rule[2] == "is") and (string.sub(rule[3], 1, 4) == "not ") then
					if testcond(conds,1,x,y) then
						local target = string.sub(rule[3], 5)
						blocked[target] = 1
					end
				end
			end
		end
		
		if (blocked["all"] == nil) and ((matdata[2] == nil) or testcond(matdata[2],1)) then
			for b,unit in pairs(objectlist) do
				if (b ~= "empty") and (b ~= "all") and (b ~= "level") and (b ~= "group") and (blocked[target] == nil) and (not is_name_text_this(b)) then
					table.insert(levelconversions, {b, {}})
				end
			end
		end
	end
end

