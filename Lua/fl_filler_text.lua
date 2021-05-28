filler_mod_globals = {
    active_filler_text = {}
}

table.insert(mod_hook_functions["rule_update"], 
    function()
        filler_mod_globals.active_filler_text = {}
    end
)