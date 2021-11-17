# Baba Is You - Arrow Properties Plus

A Baba Is You mod that adds variants of existing properties as directional arrows. Also adds arrow properties where their meaning changes based on their facing direction.

Best if you look at some gifs for a full explaination:

<img src="gifs/turning_fall.gif" alt="drawing" width="800"/>
<img src="gifs/turning_text.gif" alt="drawing" width="800"/>
<img src="gifs/arrow_properties.gif" alt="drawing" width="800"/>
<img src="gifs/DIRBOOM.gif" alt="drawing" width="800"/>

# A few notes
- **Note about directional shift**: directional shift's implementation rewrites a lot of the game's code and slightly changes how stacking shifts behave. If you want to use the old behavior while keeping this mod, open `Lua\tt_add_to_editor.lua` and set `enable_directional_shift=false`. This will make the arrow shift properties behave like regular shift, regardless of direction.
