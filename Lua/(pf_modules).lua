PlasmaModules = {}

local all_modules = {
    ["general/undo_analyzer"] = true,
    ["general/gui"] = true,
    ["general/directional_text_display"] = true,
    ["cutpack/word_verify"] = true,
    ["this/pnoun_group_defs"] = true,
    ["this/pnoun_raycast_trace"] = true,
}
local pf_module_dir = pf_lua_dir.."modules/"

local function reload_module(module)
    local module_path = pf_module_dir..module
    return dofile(module_path..".lua")
end

for module in pairs(all_modules) do
    print("[Plasma Modpack] Loading module "..module)
    all_modules[module] = reload_module(module)
end
print("[Plasma Modpack] Finished loading all modules")

function PlasmaModules.load_module(module)
    if all_modules[module] == nil then
        error(string.format("Error: cannot load Plasma Module %s as it's not defined in (pf_modules).lua", module))
    end
    return all_modules[module]
end

local UndoAnalyzer = PlasmaModules.load_module("general/undo_analyzer")
pf_undo_analyzer = UndoAnalyzer:new()
pf_dir_text_display = PlasmaModules.load_module("general/directional_text_display")

--[[ 
    This module system is a start. But it is still a bit flawed if I want to maintain robustness in the long term. I don't know if that is going to be a goal
    for this modpack. While this modpack has grown a lot, its still limited in that it isn't easily compatable with other mods. And that is something that
    cannot be easily changed. Overall, I don't know how far I want to go in terms of organization of this modpack if it only *really* is for the sake of organization.
    Still, it would be nice to do, but not a high priority

    Flaws/Improvements to make:
    - we have to define all module paths in the "all_modules" table
    - move load_module and reload_module to here and export the functions
    - we have to force reload modules whenever we reload the modpack. This is to maintain the fact that when we reload the levelpack, it refreshes the modpack.
        - this is why we have to list all modules here and reload them on start. When actually programming new mods, I don't want to worry about whether or not
          I should load or reload the modules when Im using them. Just call load_module() and then I'm done.
    - because of the force reloading, we have to ensure that every time we call load_module(), its in the list of all_modules

]]