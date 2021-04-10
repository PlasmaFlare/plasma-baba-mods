filler_mod_globals = {
    active_filler_text = {}
}

table.insert(mod_hook_functions["rule_update"], 
    function()
        filler_mod_globals.active_filler_text = {}
    end
)

function filler_text_play_rule_effects()
    local playrulesound = false
    for _, unitid in ipairs(filler_mod_globals.active_filler_text) do
        local unit = mmf.newObject(unitid)
        setcolour(unitid,"active")
        newruleids[unitid] = 1
        if (ruleids[unitid] == nil) and (#undobuffer > 1) and (alreadyrun == false) and (generaldata5.values[LEVEL_DISABLERULEEFFECT] == 0) then
            if (ruleeffectlimiter[unitid] == nil) then
                local x,y = unit.values[XPOS],unit.values[YPOS]
                local c1,c2 = getcolour(unitid,"active")
                MF_particles_for_unit("bling",x,y,5,c1,c2,1,1,unitid)
                ruleeffectlimiter[unitid] = 1
            end
            
            playrulesound = true
        end
    end

    return playrulesound
end