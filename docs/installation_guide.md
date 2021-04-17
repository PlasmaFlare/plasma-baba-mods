# How to install
1. This mod only works when you install into a levelpack. Pick an existing levelpack or create a new levelpack in the baba editor. (From baba title: `Level Editor -> Edit Levelpacks -> Create a new levelpack`)
    - Note that when installing a mod into a levelpack, the mod will only take effect within the levelpack itself.
2. Close the game and navigate to `<Baba game directory>\Data\Worlds\<world folder>`
    - If you created a new levelpack, `<world folder>` will most likely be named something like `63World`. To determine which folder is your levelpack, look in each folder for a `world_data.txt` file. Inside it, look for whatever you named your levelpack under `[General]`.
3. Edit `world_data.txt` and add `mods=1` underneath the `[General]` section.
    - `mods` will not be seen if you haven't configured your levelpack to enable modding.
    - At this point your levelpack will be able to activate any mods you install. The next steps are specific to my mod, but similar steps can be applied for other mods
4. Copy both `Lua` and `Sprites` folder to the levelpack folder. This should add the contents of `Sprites` to the one in the levelpack folder and also create (or update) the `Lua` folder in the levelpack.
5. And thats it! You can start baba again and navigate to the levelpack and start playing around with my mods.
