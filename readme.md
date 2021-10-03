# Plasma's mods - Baba Is You

**Current compatable Baba Is You version: Beta 431D on PC**

This is a merged collection of all of my Baba mods I made so far. Download this if you want to use all of my mods at once rather than individually.

**Note:** in the future I'll add more mods directly to this modpack rather than making a github page for each of them. But since the below mods are pretty big I'll keep the old github pages open in case anyone wants to download them seperately.

Total list of mods (Click on one to get a *stylized* description of each mod)
- [Arrow Properties Plus/Turning Text](docs/arrow_properties_plus.md)
- [Omni/Pivot Connectors](docs/omni_connectors.md)
- [Filler Text](docs/filler_text.md)
- [THIS](docs/this.md)
- [CUT and PACK](docs/textcraft.md)
- [STABLE](docs/stable.md)

Mods with seperate repositories (old and deprecated)
- [Arrow Properties Plus/Turning Text](https://github.com/PlasmaFlare/Baba-Is-You-Arrow-Properties-Plus)
- [Omni Connectors](https://github.com/PlasmaFlare/Baba-Is-You-Mod-Omni-Connectors)


# Installation
### A few notes before installing
- **This modpack is not guaranteed to be compatable with mods created by other people.**
- If you are switching from using one of my mods to this modpack, you'll have to uninstall the single mod first. **Backup your worlds if you do this.** Normally, deleting all lua files from my mod will achieve this. 

### Brief installation instructions
To install, copy both Lua and Sprites folder into the levelpack you want to include the mod. Make sure the world_data.txt in the levelpack folder has `mods=1` set underneath the `[General]` section.

**If you are new to baba modding**, [check this more detailed guide I made for installing this mod.](docs/installation_guide.md)

### Installing future updates
If you previously installed my modpack and it has updated since then, the safest bet is to uninstall the old version before installing the new version. **BACKUP YOUR LEVELPACKS BEFORE DOING THIS.** Reinstalling involves:
  1) Deleting all files that are part of the modpack in both `Sprites` and `Lua` folder.
  2) Download the release you want to install
  3) Copy all lua files in the release into the levelpack's `Lua` folder
  4) Copy all png files in the release into the levelpack's `Sprites` folder


----
## Known Bugs that might be too complex to fix
- Omni "play" does not work with letters (A#, Cb, etc) unless normal "play" text is in the palette.

# Changelog
- **1.3.1** (10/2/21)
  - [STABLE] Fixed "X is Y" not working as a stable rule
  - [STABLE] Fixed case where if "baba is red" becomes a stablerule, forming "baba is not red" completely cancels out the stablerule
  - [STABLE] Fixed lua error when exiting a level with "empty is stable"
  - [STABLE] (I think) Fixed "THIS is stable" carrying over previous stablerules whenever THIS changes what it is pointing to
  - [STABLE] Fixed stable indicator not appearing when starting a level with an objecct already stable
  - [STABLE] Fixed stable rule hover text displaying differently when "X is Y" + "X is not Y" are stable rules
  - [OMNI TEXT] Fixed common pivot text parsing jank cases, mainly because the systems meant to handle these cases was not enabled for pivot text LOL
  - [OMNI TEXT] Fixed "too complex" situations with omni text not handling properly
  - [TURNING TEXT] Fixed directional more firing twice
  - [STABLE+THIS] Stable and THIS indicators are toggleable through "disable particle effects" options
- **1.3.0** (9/29/21)
  - Updated for Beta 431D
  - STABLE mod!
  - Added **pivot text** as part of the omni text mod. This is a more restricted version of omni text where parsing doesn't split, but changes direction
      - Pivot text sprites will use the old omni text sprites. New omni text sprites have another glow layer to make it feel more potent. 
  - Heavily reworked omni text code to reduce several rule duplication cases
  - Updated THIS text sprite so that arrow looks a bit more defined
  - Added a small black border around the THIS indicator arrows to see it better against different backgrounds
  - Bug-fix: "THIS is group is block/pass" now works! 
  - Bug-fix: stacking filler text now works 
  - Bug-fix: omni text works with letters 
  - Bug-fix: "Level is auto" does not cause "you" and "you2(dir)" objects to move at the same time with one button
- **1.2.5** (6/4/21)
  - Updated for Beta 418b
- **1.2.4** (5/28/21)
  - Updated for Beta 415
  - Made THIS work with "beside"
- **1.2.3** (5/27/21)
  - fixed double more trigger from more + directional more
  - fixed a neutral net shift causing the shifted unit to face a direction
  - fixed you2(down) and you moving at the same time if down is pressed (doesn't work when level is auto is on)
  - fixed omni facing and feeling not working with properties
  - fixed weak collisions not triggering has
- **1.2.2** (5/22/21)
  - Fixed pushing a packer not packing text
  - Adding variants of turning text and omni text auto adds normal variation of texts to editor
  - Cutting a special variant gives you only the text that's displayed on the text itself. (So locked (right) only gives you `L O C K E D`)
     - Exception: Deturn gives you `D E T U R N`
  - You can pack omni text and turning text. Omni "has" requires `O M N I H A S`, turning "more" requires `T U R N I N G M O R E`
- **1.2.1** (5/21/21)
  - Forgot to implement `empty is cut` and `empty is pack`
- **1.2.0** (5/21/21)
  - Updated for Beta 413
  - New mod! CUT and PACK
  - Updated omni text to (hopefully) work with the new parsing changes
- **1.1.3** (5/6/21)
  - Updated for Beta 410
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