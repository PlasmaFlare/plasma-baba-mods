# Plasma's mods - Baba Is You

**Current compatable Baba Is You version: Beta 407 on PC**

This is a merged collection of all of my Baba mods I made so far. Download this if you want to use all of my mods at once rather than individually.

**Note:** in the future I'll add more mods directly to this modpack rather than making a github page for each of them. But since the below mods are pretty big I'll keep the old github pages open in case anyone wants to download them seperately.

Total list of mods (Click on one to get a *stylized* description of each mod)
- [Arrow Properties Plus/Turning Text](docs/arrow_properties_plus.md)
- [Omni Connectors](docs/omni_connectors.md)
- [Filler Text](docs/filler_text.md)
- [THIS](docs/this.md)

Mods with seperate repositories
- [Arrow Properties Plus/Turning Text](https://github.com/PlasmaFlare/Baba-Is-You-Arrow-Properties-Plus)
- [Omni Connectors](https://github.com/PlasmaFlare/Baba-Is-You-Mod-Omni-Connectors)


# Installation
### A few notes before installing
- **This modpack is not guaranteed to be compatable with mods created by other people.**
- If you are switching from using one of my mods to this modpack, you'll have to uninstall the single mod first. **Backup your worlds if you do this.** Normally, deleting all lua files from my mod will achieve this. 

### Brief installation instructions
To install, copy both Lua and Sprites folder into the levelpack you want to include the mod. Make sure the world_data.txt in the levelpack folder has `mods=1` set underneath the `[General]` section.

**If you are new to baba modding**, [check this more detailed guide I made for installing this mod.](docs/installation_guide.md)

----
## Known Bugs that might be too complex to fix
- Omni "play" does not work with letters (A#, Cb, etc) unless normal "play" text is in the palette.
- "This is group is block" does not work.
## Potential bugs that might also be too complex to fix
- Messing around with THIS + special nouns (All, Empty, Group) will most likely encounter some weird behaviors
- Experimenting with Omni text layouts may possibly yield incorrect repeated parsing amounts of the same sentence

# Changelog
- **1.1.2** (4/27/21)
  - Reworked how rules involving `this` and `block/pass` are processed. (Technical details [here](docs/this.md#block-and-pass-edge-cases))
  - Added indicator when an object is refered to by `this is pass`.
  - Various adjustments to backend code.
- **1.1.1** (4/24/21)
  - THIS can bounce off other THIS's when using THIS as a property.
  - Empty is pass is now a baserule!
  - Adjustments to backend code to try and reduce lag
  - Fixed This indicator not changing scale based on zoom settings
  - Fixed property text pointed by THIS not updating to active color after breaking "text is \<color\>"
- **1.1.0** (4/17/21)
  - Updated for Beta 405 (Also works with beta 406 and 407)
  - New mod: THIS
  - Added BLOCK and PASS
  - Added a detailed guide for mod installation
  - (Mostly) Fixed omni text not working when normal variation isn't in palette
- **1.0.0** (4/2/21)
  - Initial Release