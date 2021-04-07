-- @mods turning text
function codecheck(unitid,ox,oy,cdir_,ignore_end_)
	local unit = mmf.newObject(unitid)
	local ux,uy = unit.values[XPOS],unit.values[YPOS]
	local x = unit.values[XPOS] + ox
	local y = unit.values[YPOS] + oy
	local result = {}
	local letters = false
	local justletters = false
	local cdir = cdir_ or 0
	
	local ignore_end = false
	if (ignore_end_ ~= nil) then
		ignore_end = ignore_end_
	end

	if (cdir == 0) then
		MF_alert("CODECHECK - CDIR == 0 - why??")
	end
	local tileid = x + y * roomsizex
	
	if (unitmap[tileid] ~= nil) then
		for i,b in ipairs(unitmap[tileid]) do
			local v = mmf.newObject(b)
			local w = 1
			
			if (v.values[TYPE] ~= 5) then
				if (v.strings[UNITTYPE] == "text") then
					--@Turning text: reinterpret the meaning of the turning text by replacing its parsed name with an existing name
					local v_name = get_turning_text_interpretation(b)
					--@ Turning text

					table.insert(result, {{b}, w, v_name, v.values[TYPE], cdir})
				else
					if (#wordunits > 0) then
						for c,d in ipairs(wordunits) do
							if (b == d[1]) and testcond(d[2],d[1]) then
								table.insert(result, {{b}, w, v.strings[UNITNAME], v.values[TYPE], cdir})
							end
						end
					end
				end
			else
				justletters = true
			end
		end
	end
	
	if (letterunits_map[tileid] ~= nil) then
		for i,v in ipairs(letterunits_map[tileid]) do
			local unitids = v[7]
			local width = v[6]
			local word = v[1]
			local wtype = v[2]
			local dir = v[5]
			
			if (string.len(word) > 5) and (string.sub(word, 1, 5) == "text_") then
                word = string.sub(v[1], 6)
			end
			
			local valid = true
			if ignore_end and ((x ~= v[3]) or (y ~= v[4])) and (width > 1) then
				valid = false
			end
			
			if (cdir ~= 0) and (width > 1) then
				if ((cdir == 1) and (ux > v[3]) and (ux < v[3] + width)) or ((cdir == 2) and (uy > v[4]) and (uy < v[4] + width)) then
					valid = false
				end
			end
			
			--MF_alert(word .. ", " .. tostring(valid) .. ", " .. tostring(dir) .. ", " .. tostring(cdir))
			
			if (dir == cdir) and valid then
				table.insert(result, {unitids, width, word, wtype, dir})
				letters = true
			end
		end
	end
	
	return result,letters,justletters
end

-- @mods omni connectors
function calculatesentences(unitid,x,y,dir)
	local drs = dirs[dir]
	local ox,oy = drs[1],drs[2]
	
	local finals = {}
	local sentences = {}
	local sents = {}
	local done = false
	
	local step = 0
	local combo = {}
	local variantshere = {}
	local totalvariants = 1
	local maxpos = 0
	
	local limiter = 3000
	
	local combospots = {}
	
	local unit = mmf.newObject(unitid)

	local branches = {} -- keep track of which points in the sentence parsing we parse vertically
	local found_branch_on_last_word = false -- flag for detecting if the tail end of a sentence parsed in one direction continues perpendicularly without branching
	local br_and_text_with_split_parsing = {} -- List of branching ands with next text in both directions. Used to determine which sentences to potentially eliminate in docode.

	local br_dir = nil
	local br_dir_vec = nil
	if dir == 1 then
		br_dir = 2
	elseif dir == 2 then
		br_dir = 1
	end
	br_dir_vec = dirs[br_dir]
	
	local done = false
	-- @Phase 1
	while (done == false) and (totalvariants < limiter) do
		local words,letters,jletters = codecheck(unitid,ox*step,oy*step,dir,true)
		
		--MF_alert(tostring(unitid) .. ", " .. unit.strings[UNITNAME] .. ", " .. tostring(#words))
		
		step = step + 1
		
		if (totalvariants >= limiter) then
			MF_alert("Level destroyed - too many variants A")
			destroylevel("toocomplex")
			return nil
		end
		
		if (totalvariants < limiter) then
			if (#words > 0) then
				totalvariants = totalvariants * #words
				variantshere[step] = #words
				sents[step] = {}
				combo[step] = 1
				
				if (totalvariants >= limiter) then
					MF_alert("Level destroyed - too many variants B")
					destroylevel("toocomplex")
					return nil
				end
				
				if (#words > 1) then
					combospots[#combospots + 1] = step
				end
				
				if (totalvariants > #finals) then
					local limitdiff = totalvariants - #finals
					for i=1,limitdiff do
						table.insert(finals, {})
					end
				end
				
				local branching_texts = {}

				for i,v in ipairs(words) do
					--unitids, width, word, wtype, dir
					
					--MF_alert("Step " .. tostring(step) .. ", word " .. v[3] .. " here")
					table.insert(sents[step], v)

					local text_name = v[3]
					if name_is_branching_text(text_name) then
						-- Gather all branching texts to do the perp calculatesentences on
						table.insert(branching_texts, v)

						-- initialize every branching text to not use sentence elimination by default
						local br_unitid = v[1][1]
						local br_unit = mmf.newObject(br_unitid)
						br_and_text_with_split_parsing[br_unitid] = nil
					end
				end

				-- Get a test unit id from branching texts to use in codecheck. (Used to "step" perpendicularly)
				local test_br_unitid = nil
				if #branching_texts > 0 then
					test_br_unitid = branching_texts[1][1][1]
				end

				found_branch_on_last_word = false
				if br_dir_vec and test_br_unitid then
					-- Step perpendicularly. If there's text there, record essential information needed to parse that branch.
					local br_x = x + ox*step + br_dir_vec[1]
					local br_y = y + oy*step + br_dir_vec[2]
					local br_tileid = br_x + br_y * roomsizex
					local br_words, br_letters, br_justletters = codecheck(test_br_unitid, br_dir_vec[1], br_dir_vec[2], br_dir, true)
					

					if #br_words > 0 then
						local br_firstwords = {}

						--@cleanup: Normally we shouldn't need to record an entire list of firstwords, 
						-- but weirdly enough, directly recording the first element and using it in the later codecheck that steps perpendicularly
						-- causes a stack overflow error for some reason... Note that this was during setting br_unit.br_detected_splitted_parsing flag
						--  inside a unit object. Could that be the reason?
						for _, word in ipairs(br_words) do
							table.insert(br_firstwords, word[1][1])
						end
						for _, br_text in ipairs(branching_texts) do
							if name_is_branching_and(br_text[3]) then
								local br_unitid = br_text[1][1]
								local br_unit = mmf.newObject(br_unitid)
								br_and_text_with_split_parsing[br_unitid] = true
							end
						end
						local t = {
							branching_texts = branching_texts,
							step_index = step, 
							lhs_totalvariants = totalvariants/#words*#branching_texts,
							x = br_x,
							y = br_y,
							firstwords = br_firstwords,
							num_combospots = #combospots
						}

						table.insert(branches, t)
						found_branch_on_last_word = true
					end
				end

			else
				--MF_alert("Step " .. tostring(step) .. ", no words here, " .. tostring(letters) .. ", " .. tostring(jletters))
				
				if jletters then
					variantshere[step] = 0
					sents[step] = {}
					combo[step] = 0
				else
					if found_branch_on_last_word then
						-- If the last word is a branching_and with a perp branch but no parallel branch, treat this perp branch as if it was directly appended
						-- to the parallel sentence
						local branch_on_last_word = branches[#branches]
						for _, br_text in ipairs(branch_on_last_word.branching_texts) do
							if name_is_branching_and(br_text[3]) then
								local br_unitid = br_text[1][1]
								local br_unit = mmf.newObject(br_unitid)
								br_and_text_with_split_parsing[br_unitid] = nil
							end
						end

						-- We process this branch first in this case since it appends to the original parallel sentences
						table.remove(branches, #branches)
						table.insert(branches, 1, branch_on_last_word)
					end
					done = true
				end
			end
		end
	end
	-- @End Phase 1
	
	--MF_alert(tostring(step) .. ", " .. tostring(totalvariants))
	
	if (totalvariants >= limiter) then
		MF_alert("Level destroyed - too many variants C")
		destroylevel("toocomplex")
		return nil
	end
	
	maxpos = step
	
	local combostep = 0
	
	-- @Phase 2
	for i=1,totalvariants do
		step = 1
		sentences[i] = {}
		
		while (step < maxpos) do
			local c = combo[step]
			
			if (c ~= nil) then
				if (c > 0) then
					local s = sents[step]
					local word = s[c]
					
					local w = word[2]
					
					--MF_alert(tostring(i) .. ", step " .. tostring(step) .. ": " .. word[3] .. ", " .. tostring(#word[1]) .. ", " .. tostring(w))
					local text_name = parse_branching_text(word[3])
					if text_name == "and" then
						text_name = word[3]
					end
					table.insert(sentences[i], {text_name, word[4], word[1], word[2]})
					
					step = step + w
				else
					break
				end
			else
				MF_alert("c is nil, " .. tostring(step))
				break
			end
		end
		
		if (#combospots > 0) then
			combostep = 0
			
			local targetstep = combospots[combostep + 1]
			
			combo[targetstep] = combo[targetstep] + 1
			
			while (combo[targetstep] > variantshere[targetstep]) do
				combo[targetstep] = 1
				
				combostep = (combostep + 1) % #combospots
				
				targetstep = combospots[combostep + 1]
				
				combo[targetstep] = combo[targetstep] + 1
			end
		end
	end
	-- @End Phase 2
	for br_index, branch in ipairs(branches) do
		br_sentences,br_finals,br_maxpos,br_totalvariants,perp_br_and_texts_with_split_parsing = calculatesentences(branch.firstwords[1], branch.x, branch.y, br_dir)
		maxpos = math.max(maxpos, br_maxpos + branch.step_index)

		if (br_totalvariants >= limiter) then
			MF_alert("Level destroyed - too many variants C")
			destroylevel("toocomplex")
			return nil
		end

		for unitid, _ in pairs(perp_br_and_texts_with_split_parsing) do
			br_and_text_with_split_parsing[unitid] = true
		end

		-- If the end of the original sentence has a valid branch, then append that branch onto the main sentences
		if found_branch_on_last_word and br_index == 1 then -- 
			local oldtotalvariants = totalvariants
			totalvariants = totalvariants * br_totalvariants
			
			if (totalvariants >= limiter) then
				MF_alert("Level destroyed - too many variants F")
				destroylevel("toocomplex")
				return nil
			end

			for s, rhs_sentence in ipairs(br_sentences) do
				if s == #br_sentences then
					for a=1,oldtotalvariants do
						local lhs_sentence = sentences[a]
						for _, word in ipairs(rhs_sentence) do
							table.insert(lhs_sentence, word)
						end
					end
				else
					local final_sentence = {}
					for a=1,oldtotalvariants do
						local lhs_sentence = sentences[a]
						for _, word in ipairs(lhs_sentence) do
							table.insert(final_sentence, word)
						end
						for _, word in ipairs(rhs_sentence) do
							table.insert(final_sentence, word)
						end
					end
					table.insert(sentences, final_sentence)
					table.insert(finals, {})
				end
			end
		else
			if #branch.branching_texts > 0 then
				totalvariants = totalvariants + branch.lhs_totalvariants * br_totalvariants
				if (totalvariants >= limiter) then
					MF_alert("Level destroyed - too many variants E")
					destroylevel("toocomplex")
					return nil
				end

				for step = 1, branch.step_index do
					combo[step] = 1
				end

				local branch_text_combo = 1

				for i = 1, branch.lhs_totalvariants do
					local br_step = 1
					local lhs_sentence = {}

					while (br_step <= branch.step_index) do
						local c = combo[br_step]
						
						if (c ~= nil) then
							if (c > 0) then
								
								local word = nil
								if br_step == branch.step_index then
									word = branch.branching_texts[c]
								else
									local s = sents[br_step]
									word = s[c]
								end
								
								local w = word[2]
								
								-- table.insert(sentences[i], {word[3], word[4], word[1], word[2]})
								local text_name = parse_branching_text(word[3])
								if text_name == "and" then
									text_name = word[3]
								end
								table.insert(lhs_sentence, {text_name, word[4], word[1], word[2]})
								
								br_step = br_step + w
							else
								break
							end
						else
							MF_alert("c is nil, " .. tostring(step))
							break
						end
					end

					for _, rhs_sent in ipairs(br_sentences) do
						local final_sentence = {}
						for _, sent_word in ipairs(lhs_sentence) do
							table.insert(final_sentence, sent_word)
						end
						
						for _, sent_word in ipairs(rhs_sent) do
							table.insert(final_sentence, sent_word)
						end

						table.insert(sentences, final_sentence)
						table.insert(finals, {})
					end

					if (branch.num_combospots > 0) then
						combostep = 0
						
						local targetstep = combospots[combostep + 1]
						
						combo[targetstep] = combo[targetstep] + 1

						local combo_num = 0
						local maxcombo = 0
						if targetstep == branch.step_index then
							combo_num = branch_text_combo
							maxcombo = #branch.branching_texts
						else
							combo_num = combo[targetstep]
							maxcombo = variantshere[targetstep]
						end
						
						while (combo_num > maxcombo) do
							if targetstep == branch.step_index then
								branch_text_combo = 1
							else
								combo[targetstep] = 1
							end
							
							combostep = (combostep + 1) % branch.num_combospots
							
							targetstep = combospots[combostep + 1]
							
							
							if targetstep == branch.step_index then
								branch_text_combo = branch_text_combo + 1
								combo_num = branch_text_combo
								maxcombo = #branch.branching_texts
							else
								combo[targetstep] = combo[targetstep] + 1
								combo_num = combo[targetstep]
								maxcombo = variantshere[targetstep]
							end
						end
					end
				end
			end
		end
	end
	--[[
	MF_alert(tostring(totalvariants) .. ", " .. tostring(#sentences))
	for i,v in ipairs(sentences) do
		local text = ""
		
		for a,b in ipairs(v) do
			text = text .. b[1] .. " "
		end
		
		MF_alert(text)
	end
	]]--
	
	return sentences,finals,maxpos,totalvariants,br_and_text_with_split_parsing
end

-- @mods omni connectors
function docode(firstwords)
	local donefirstwords = {}
	local limiter = 0
	local no_firstword_br_text = {} -- Record of branching texts that should not be processed as a firstword (prevents double parsing in certain cases)
	
	if (#firstwords > 0) then
		for k,unitdata in ipairs(firstwords) do
			if (type(unitdata[1]) == "number") then
				timedmessage("Old rule format detected. Please replace modified .lua files to ensure functionality.")
			end

			local unitids = unitdata[1]
			local unitid = unitids[1]
			local dir = unitdata[2]
			local width = unitdata[3]
			local word = unitdata[4]
			local wtype = unitdata[5]
			
			if (string.sub(word, 1, 5) == "text_") then
				word = string.sub(word, 6)
			end
			
			local unit = mmf.newObject(unitid)
			local x,y = unit.values[XPOS],unit.values[YPOS]
			local tileid = x + y * roomsizex
			
			--MF_alert("Testing " .. word .. ": " .. tostring(donefirstwords[tileid]) .. ", " .. tostring(dir) .. ", " .. tostring(unitid))
			limiter = limiter + 1
			
			if (limiter > 5000) then
				MF_alert("Level destroyed - firstwords run too many times")
				destroylevel("toocomplex")
				return
			end
			
			if (not no_firstword_br_text[unitid]) and ((donefirstwords[tileid] == nil) or ((donefirstwords[tileid] ~= nil) and (donefirstwords[tileid][dir] == nil)) and (limiter < 5000)) then
				local ox,oy = 0,0
				local name = word
				
				local drs = dirs[dir]
				ox = drs[1]
				oy = drs[2]
				
				if (donefirstwords[tileid] == nil) then
					donefirstwords[tileid] = {}
				end
				
				donefirstwords[tileid][dir] = 1

				local sents_that_might_be_removed = {}
				local and_index = 0
				local and_unitid_to_index = {}
				
				local sentences,finals,maxlen,variations,br_and_text_with_split_parsing = calculatesentences(unitid,x,y,dir)
				
				if (sentences == nil) then
					return
				end
				
				--MF_alert(tostring(k) .. ", " .. tostring(variations))
				if (maxlen > 2) then
					for i=1,variations do
						local current = finals[i]
						local letterword = ""
						local stage = 0
						local prevstage = 0
						local tileids = {}
						
						local notids = {}
						local notwidth = 0
						local notslot = 0
						
						local stage3reached = false
						local stage2reached = false
						local doingcond = false
						local nocondsafterthis = false
						local condsafeand = false
						
						local firstrealword = false
						local letterword_prevstage = 0
						local letterword_firstid = 0
						
						local currtiletype = 0
						local prevtiletype = 0
						
						local prevsafewordid = 0
						local prevsafewordtype = 0
						
						local stop = false
						
						local sent = sentences[i]
						
						local thissent = ""
						
						local do_branching_and_sentence_elimination = false
						
						for wordid=1,#sent do
							local s = sent[wordid]
							local nexts = sent[wordid + 1] or {-1, -1, {-1}, 1}
							
							prevtiletype = currtiletype
							
							local tilename = s[1]
							local tiletype = s[2]
							local tileid = s[3][1]
							local tilewidth = s[4]
							
							local wordtile = false
							
							currtiletype = tiletype
							
							local dontadd = false
							
							thissent = thissent .. tilename .. "," .. tostring(wordid) .. "  "
							
							for a,b in ipairs(s[3]) do
								table.insert(tileids, b)
							end
							
							--[[
								0 = objekti
								1 = verbi
								2 = quality
								3 = alkusana (LONELY)
								4 = Not
								5 = letter
								6 = And
								7 = ehtosana
								8 = customobject
							]]--
							
							-- @filler text
							if (tiletype == 11) then
								stop = false
							else
							if (tiletype ~= 5) then
								if (stage == 0) then
									if (tiletype == 0) then
										prevstage = stage
										stage = 2
									elseif (tiletype == 3) then
										prevstage = stage
										stage = 1
									elseif (tiletype ~= 4) then
										prevstage = stage
										stage = -1
										stop = true
									end
								elseif (stage == 1) then
									if (tiletype == 0) then
										prevstage = stage
										stage = 2
									elseif (tiletype == 6) then
										prevstage = stage
										stage = 6
									elseif (tiletype ~= 4) then
										prevstage = stage
										stage = -1
										stop = true
									end
								elseif (stage == 2) then
									if (wordid ~= #sent) then
										if (tiletype == 1) and (prevtiletype ~= 4) and ((prevstage ~= 4) or doingcond or (stage3reached == false)) then
											stage2reached = true
											doingcond = false
											prevstage = stage
											nocondsafterthis = true
											stage = 3
										elseif ((tiletype == 7) and (stage2reached == false) and (nocondsafterthis == false)) then
											doingcond = true
											condsafeand = true
											prevstage = stage
											stage = 3
										elseif (tiletype == 6) and (prevtiletype ~= 4) then
											prevstage = stage
											stage = 4
										elseif (tiletype ~= 4) then
											prevstage = stage
											stage = -1
											stop = true
										end
									else
										stage = -1
										stop = true
									end
								elseif (stage == 3) then
									stage3reached = true
									
									if (tiletype == 0) or (tiletype == 2) or (tiletype == 8) then
										prevstage = stage
										stage = 5
									elseif (tiletype ~= 4) then
										stage = -1
										stop = true
									end
								elseif (stage == 4) then
									if (wordid <= #sent) then
										if (tiletype == 0) or ((tiletype == 2) and stage3reached) or ((tiletype == 8) and stage3reached) then
											prevstage = stage
											stage = 2
										elseif ((tiletype == 1) and stage3reached) and (doingcond == false) and (prevtiletype ~= 4) then
											stage2reached = true
											nocondsafterthis = true
											prevstage = stage
											stage = 3
										elseif (tiletype == 7) and (nocondsafterthis == false) and ((prevtiletype ~= 6) or ((prevtiletype == 6) and condsafeand)) then
											doingcond = true
											stage2reached = true
											condsafeand = true
											prevstage = stage
											stage = 3
										elseif (tiletype ~= 4) then
											prevstage = stage
											stage = -1
											stop = true
										end
									else
										stage = -1
										stop = true
									end
								elseif (stage == 5) then
									if (wordid ~= #sent) then
										if (tiletype == 1) and doingcond and (prevtiletype ~= 4) then
											stage2reached = true
											doingcond = false
											prevstage = stage
											nocondsafterthis = true
											stage = 3
										elseif (tiletype == 6) and (prevtiletype ~= 4) then
											prevstage = stage
											stage = 4
										elseif (tiletype ~= 4) then
											prevstage = stage
											stage = -1
											stop = true
										end
									else
										stage = -1
										stop = true
									end
								elseif (stage == 6) then
									if (tiletype == 3) then
										prevstage = stage
										stage = 1
									elseif (tiletype ~= 4) then
										prevstage = stage
										stage = -1
										stop = true
									end
								end
							end
							end
							
							if stage3reached and not stop and tilename == "branching_and" then
								local br_and_unit = mmf.newObject(tileid)
								if br_and_text_with_split_parsing[tileid] then
									do_branching_and_sentence_elimination = true
								end
							end
							
							if (stage > 0) then
								firstrealword = true
							end
							
							if (tiletype == 4) then
								if (#notids == 0) then
									notids = s[3]
									notwidth = tilewidth
									notslot = wordid
								end
							else
								if (stop == false) and (tiletype ~= 0) then
									notids = {}
									notwidth = 0
									notslot = 0
								end
							end
							
							if (prevtiletype ~= 4) then
								prevsafewordid = wordid - 1
								prevsafewordtype = prevtiletype
							end
							
							--MF_alert(tilename .. ", " .. tostring(wordid) .. ", " .. tostring(stage) .. ", " .. tostring(#sent) .. ", " .. tostring(tiletype) .. ", " .. tostring(prevtiletype) .. ", " .. tostring(stop))
							
							--MF_alert(tostring(k) .. "_" .. tostring(i) .. "_" .. tostring(wordid) .. ": " .. tilename .. ", " .. tostring(tiletype) .. ", " .. tostring(stop) .. ", " .. tostring(stage) .. ", " .. tostring(letterword_firstid).. ", " .. tostring(prevtiletype))
							
							if (stop == false) then
								-- @filler text
								if tiletype ~= 11 then
								if (dontadd == false) then
									table.insert(current, {tilename, tiletype, tileids, tilewidth})
									tileids = {}
								end
								end
							else
								for a=1,#s[3] do
									if (#tileids > 0) then
										table.remove(tileids, #tileids)
									end
								end
								
								if (tiletype == 0) and (prevtiletype == 0) and (#notids > 0) then
									notids = {}
									notwidth = 0
								end
								
								if (wordid < #sent) then
									if (wordid > 1) then
										if (#notids > 0) and firstrealword and (notslot > 1) and (tiletype ~= 7) and ((tiletype ~= 1) or ((tiletype == 1) and (prevtiletype == 0))) then
											--MF_alert("Notstatus added to firstwords" .. ", " .. tostring(wordid) .. ", " .. tostring(nexts[2]))
											table.insert(firstwords, {notids, dir, notwidth, "not", 4})
											
											if (nexts[2] ~= nil) and ((nexts[2] == 0) or (nexts[2] == 3) or (nexts[2] == 4)) and (tiletype ~= 3) then
												--MF_alert("Also added " .. tostring(wordid) .. ", " .. tilename)
												table.insert(firstwords, {s[3], dir, tilewidth, tilename, tiletype})
											end
										else
											if (prevtiletype == 0) and ((tiletype == 1) or (tiletype == 7)) then
												--MF_alert("Added previous word: " .. sent[wordid - 1][1] .. " to firstwords")
												table.insert(firstwords, {sent[wordid - 1][3], dir, tilewidth, tilename, tiletype})
											elseif (prevsafewordtype == 0) and (prevsafewordid > 0) and (prevtiletype == 4) and (tiletype ~= 1) and (tiletype ~= 2) then
												--MF_alert("Added previous safe word: " .. sent[prevsafewordid][1] .. " to firstwords")
												table.insert(firstwords, {sent[prevsafewordid][3], dir, tilewidth, tilename, tiletype})
											else
												--MF_alert("Added the current word: " .. s[1] .. " to firstwords")
												table.insert(firstwords, {s[3], dir, tilewidth, tilename, tiletype})
											end
										end
										
										break
									elseif (wordid == 1) then
										if (nexts[3][1] ~= -1) then
											--MF_alert(nexts[1] .. " added to firstwords E" .. ", " .. tostring(wordid))
											table.insert(firstwords, {nexts[3], dir, nexts[4], nexts[1], nexts[2]})
										end
										
										break
									end
								end
							end
						end

						if do_branching_and_sentence_elimination then
							print("run eliminate on this sentence:")
							for _,v in ipairs(current) do
								print(v[1])
							end
							local and_units = {}
							for _,v in ipairs(current) do
								local tilename = v[1]
								if tilename == "branching_and" then
									table.insert(and_units, tileid)
									if and_unitid_to_index[tileid] == nil then
										and_unitid_to_index[tileid] = and_index
										and_index = and_index + 1
									end
								end
							end
							table.insert(sents_that_might_be_removed, {index = i, and_units = and_units})
						end

						--MF_alert(thissent)
					end
				end

				local and_combo_count = {}
				for _, sent_entry in ipairs(sents_that_might_be_removed) do
					local and_bitmask = 0
					for _, unitid in ipairs(sent_entry.and_units) do
						local bitindex = and_unitid_to_index[unitid]
						and_bitmask = and_bitmask | (1 << bitindex)
					end
					if and_combo_count[and_bitmask] == nil then
						and_combo_count[and_bitmask] = 1
					else 	
						and_combo_count[and_bitmask] = and_combo_count[and_bitmask] + 1
					end

					sent_entry.and_bitmask = and_bitmask
				end
				for _, sent_entry in ipairs(sents_that_might_be_removed) do
					local current = finals[sent_entry.index]

					-- eliminate any extra verbs and nots
					for i=1,#current do
						local word = current[#current]
						local wordtype = word[2]
						if wordtype == 4 or wordtype == 1 or wordtype == 7 then
							table.remove(current, #current)
						end
					end
					-- if the resulting sentence has a dangling and, remove the sentence
					if current[#current][2] == 6 then
						local curr_count = and_combo_count[sent_entry.and_bitmask]
						if curr_count - 1 > 0 then
							print("eliminating sentence:")
							for _,v in ipairs(current) do
								print(v[1])
							end
							local sentlen = #current
							for i=1,sentlen do
								table.remove(current, #current)
							end

							and_combo_count[sent_entry.and_bitmask] = curr_count - 1
						end
					end
				end
				
				if (#finals > 0) then
					for i,sentence in ipairs(finals) do
						local group_objects = {}
						local group_targets = {}
						local group_conds = {}
						
						local group = group_objects
						local stage = 0
						
						local prefix = ""
						
						local allowedwords = {0}
						local allowedwords_extra = {}
						
						local testing = ""
						
						local extraids = {}
						local extraids_current = ""
						local extraids_ifvalid = {}
						
						local valid = true
						
						if (#finals > 1) then
							for a,b in ipairs(finals) do
								if (#b == #sentence) and (a > i) then
									local identical = true
									
									for c,d in ipairs(b) do
										local currids = d[3]
										local equivids = sentence[c][3] or {}
										
										for e,f in ipairs(currids) do
											--MF_alert(tostring(a) .. ": " .. tostring(f) .. ", " .. tostring(equivids[e]))
											if (f ~= equivids[e]) then
												identical = false
											end
										end
									end
									
									if identical then
										--MF_alert(sentence[1][1] .. ", " .. sentence[2][1] .. ", " .. sentence[3][1] .. " (" .. tostring(i) .. ") is identical to " .. b[1][1] .. ", " .. b[2][1] .. ", " .. b[3][1] .. " (" .. tostring(a) .. ")")
										valid = false
									end
								end
							end
						end
						
						if valid then
							for index,wdata in ipairs(sentence) do
								local wname = wdata[1]
								local wtype = wdata[2]
								local wid = wdata[3]

								-- Record all branching text that is part of a valid sentence
								for _, unitid in ipairs(wid) do
									local unit = mmf.newObject(unitid)
									if name_is_branching_text(unit.strings[NAME]) and (wtype == 6 or wtype == 7) and (stage == 0 or stage == 7) then
										no_firstword_br_text[unitid] = true
									end
								end
								
								testing = testing .. wname .. ", "
								
								local wcategory = -1
								
								if (wtype == 1) or (wtype == 3) or (wtype == 7) then
									wcategory = 1
								elseif (wtype ~= 4) and (wtype ~= 6) then
									wcategory = 0
								else
									table.insert(extraids_ifvalid, {prefix .. wname, wtype, wid})
									extraids_current = wname
								end
								
								if (wcategory == 0) then
									local allowed = false
									
									for a,b in ipairs(allowedwords) do
										if (b == wtype) then
											allowed = true
											break
										end
									end
									
									if (allowed == false) then
										for a,b in ipairs(allowedwords_extra) do
											if (wname == b) then
												allowed = true
												break
											end
										end
									end
									
									if allowed then
										table.insert(group, {prefix .. wname, wtype, wid})
									else
										table.insert(firstwords, {{wid[1]}, dir, 1, wname, wtype})
										break
									end
								elseif (wcategory == 1) then
									if (index < #sentence) then
										allowedwords = {0}
										allowedwords_extra = {}
										
										local realname = unitreference["text_" .. wname]
										local cargtype = false
										local cargextra = false
										
										local argtype = {0}
										local argextra = {}
										
										if (changes[realname] ~= nil) then
											local wchanges = changes[realname]
											
											if (wchanges.argtype ~= nil) then
												argtype = wchanges.argtype
												cargtype = true
											end
											
											if (wchanges.argextra ~= nil) then
												argextra = wchanges.argextra
												cargextra = true
											end
										end
										
										if (cargtype == false) or (cargextra == false) then
											local wvalues = tileslist[realname] or {}
											
											if (cargtype == false) then
												argtype = wvalues.argtype or {0}
											end
											
											if (cargextra == false) then
												argextra = wvalues.argextra or {}
											end
										end
										
										--MF_alert(wname .. ", " .. tostring(realname) .. ", " .. "text_" .. wname)
										
										if (realname == nil) then
											MF_alert("No object found for " .. wname .. "!")
											valid = false
											break
										else
											if (wtype == 1) then
												allowedwords = argtype
												
												stage = 1
												local target = {prefix .. wname, wtype, wid}
												table.insert(group_targets, {target, {}})
												local sid = #group_targets
												group = group_targets[sid][2]
												
												newcondgroup = 1
											elseif (wtype == 3) then
												allowedwords = {0}
												local cond = {prefix .. wname, wtype, wid}
												table.insert(group_conds, {cond, {}})
											elseif (wtype == 7) then
												allowedwords = argtype
												allowedwords_extra = argextra
												
												stage = 2
												local cond = {prefix .. wname, wtype, wid}
												table.insert(group_conds, {cond, {}})
												local sid = #group_conds
												group = group_conds[sid][2]
											end
										end
									end
								end
								
								if (wtype == 4) then
									if (prefix == "not ") then
										prefix = ""
									else
										prefix = "not "
									end
								else
									prefix = ""
								end
								
								if (wname ~= extraids_current) and (string.len(extraids_current) > 0) and (wtype ~= 4) then
									for a,extraids_valid in ipairs(extraids_ifvalid) do
										table.insert(extraids, {prefix .. extraids_valid[1], extraids_valid[2], extraids_valid[3]})
									end
									
									extraids_ifvalid = {}
									extraids_current = ""
								end
							end
							--MF_alert("Testing: " .. testing)
							
							local conds = {}
							local condids = {}
							for c,group_cond in ipairs(group_conds) do
								local rule_cond = group_cond[1][1]
								--table.insert(condids, group_cond[1][3])
								
								condids = copytable(condids, group_cond[1][3])
								
								table.insert(conds, {rule_cond,{}})
								local condgroup = conds[#conds][2]
								
								for e,condword in ipairs(group_cond[2]) do
									local rule_condword = condword[1]
									--table.insert(condids, condword[3])
									
									condids = copytable(condids, condword[3])
									
									table.insert(condgroup, rule_condword)
								end
							end
							
							for c,group_object in ipairs(group_objects) do
								local rule_object = group_object[1]
								
								for d,group_target in ipairs(group_targets) do
									local rule_verb = group_target[1][1]
									
									for e,target in ipairs(group_target[2]) do
										local rule_target = target[1]
										
										local finalconds = {}
										for g,finalcond in ipairs(conds) do
											table.insert(finalconds, {finalcond[1], finalcond[2]})
										end
										
										local rule = {rule_object,rule_verb,rule_target}
										
										local ids = {}
										ids = copytable(ids, group_object[3])
										ids = copytable(ids, group_target[1][3])
										ids = copytable(ids, target[3])
										
										for g,h in ipairs(extraids) do
											ids = copytable(ids, h[3])
										end
										
										for g,h in ipairs(condids) do
											ids = copytable(ids, h)
										end
									
										addoption(rule,finalconds,ids)
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

