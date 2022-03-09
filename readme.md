# Plasma's mods - Baba Is You

**Current compatable Baba Is You version: 462 on PC**

This is a merged collection of all of my Baba mods I made so far.

Total list of mods (Click on one to get a *stylized* description of each mod)
- [Arrow Properties Plus/Turning Text](docs/arrow_properties_plus.md)
- [Omni/Pivot Connectors](docs/omni_connectors.md)
- [Filler Text](docs/filler_text.md)
- [THIS](docs/this.md)
- [CUT and PACK](docs/textcraft.md)
- [STABLE](docs/stable.md)
- [GUARD](docs/guard.md)


# Installation
### A few notes before installing
- **This modpack is not guaranteed to be compatable with mods created by other people.**
- Please note the supported Baba version number when downloading the modpack. Feel free to use this modpack in earlier or later versions of Baba Is You. However, it isn't guaranteed that it will be completely compatable without bugs. So if the game updates and you encounter a bug with my modpack, sometimes it could be because of the update.
  - If you need this modpack for an older baba verison, I have also been maintaining older versions of my modpack here: https://github.com/PlasmaFlare/plasma-baba-mods/releases

### Brief installation instructions
To install, copy both Lua and Sprites folder into the levelpack you want to include the mod. Make sure the world_data.txt in the levelpack folder has `mods=1` set underneath the `[General]` section.

**If you are new to baba modding**, [check this more detailed guide I made for installing this mod.](docs/installation_guide.md)

### Installing future updates
If you previously installed my modpack and it has updated since then, the safest bet is to uninstall the old version before installing the new version. **BACKUP YOUR LEVELPACKS BEFORE DOING THIS.** Reinstalling involves:
  1) Deleting all files that are part of the modpack in both `Sprites` and `Lua` folder.
  2) Download the release you want to install
  3) Copy all lua files in the release into the levelpack's `Lua` folder
  4) Copy all png files in the release into the levelpack's `Sprites` folder

# Accessing Modpack Settings
Since version 1.4.0, I've added a GUI menu for editing modpack settings per level. More info [here](docs/modpack_settings.md).

# Where to report bugs
Feel free to submit an issue to this Github repository to report bugs.

If you are on the [Baba Is You Discord](https://discord.gg/GGbUUse), you can report bugs in #plasmaflare-mod-collection-bugs, which is a thread of #asset-is-make. You can also report bugs in #asset-is-make, but I recommend the first channel just to avoid spamming the other channels.

# Changelog
- **1.5.3** (3/8/22)
  - [THIS]: Fixed the cursor not updating from THIS is block/pass/relay
  - Fixed NOT X is NOT Y not working properly
- **1.5.2** (3/6/22)
  - Updated for Version 462
  - [THIS] Fixed lua error from `THIS above THIS is BLOCK`
  - [THIS] Fixed `THIS is group` not lighting up when there isn't a `group is X` active
  - [THIS] Fixed lua error when a THIS is used as a property and noun in two different sentences
  - [STABLE] Fixed showing excessively weird stablerules when making `book is group` + `ice mimic group` + `ice is stable`
  - [STABLE] Fixed more cases of stable rules displaying weirdly from "X is not Y" rules
  - [STABLE] Fixed `rocket is group is pipe` + `rocket is stable` still transforming rocket into pipe
  - [STABLE] Fixed preservation of stablerules when transforming from one stable unit to another
  - [STABLE] Fixed `X is word` not working if X is a stableunit
  - [STABLE + THIS] Fixed `THIS(X) is not Y` + `X is stable` not evaluating properly
- **1.5.1** (2/19/21)
  - Fixed THIS redirection not working
  - Fixed THESE not lighting up when being referred by X is THIS 
  - Fixed various errors from undo-related functions
- **1.5.0** (2/19/21)
  - Updated for Version 458
  - BIG restructuring of the codebase.
  - BIG refactoring of the underlying system that made THIS work.
  - Added THAT, THESE, THOSE, and RELAY!
  - Added a new "pointer noun" tag to the editor.
  - [THIS] Extended the meaning of BLOCK to balance against THESE and THOSE. If raycasting reaches a BLOCK object at *any* point, raycasting will stop and the pointer noun will not refer to any object.
  - [THIS] Better handling of several edge cases involving mixing rules with THIS + block/pass/relay (I still recommend you avoid them if you don't want confusing results)
  - [THIS] Actually fixed THIS + group + block/pass/relay not working
  - [THIS] If two indicators of different types overlap each other, they will cycle z-layering to clarify which indicator is on which space
  - [THIS] THIS: Fixed `THIS is move` stacking move if two objects are being pointed by THIS
  - [STABLE] Fixed `teeth eat baba` not working when `baba is stable`
  - [STABLE] Fixed `X is stable and flag` making 2 flags
  - [THIS + STABLE] Fixed `idle THIS(empty) make book` and `empty is stable` showing the former rule when hovering over unaffected empties
- **1.4.0** (1/12/22)
  - Updated for Version 454
  - GUARD rework! (Sorry for the wait)
  - [TURNING TEXT] Added turning beside! (Idk what else to name this) 
  - [TURNING TEXT] Fixed conditional `level is shift` not working
  - [OMNI TEXT] Added omni/pivot besideleft and besideright!
  - [STABLE] Fixed rules from `All is X` not being copied properly into STABLE
  - [THIS] Fixed `level near this is flag` (and similar conditions with level + this) not doing anything
  - [CUT/PACK] Fixed "level is cut" and "empty is cut" giving a lua error and duplicating text
  - [FILLER] Fixed filler text lighting up in `baba is you ... ... push`
  - Fixed modpack settings not loading when first opening the modpack
- **1.3.9** (1/7/22)
  - Quick update to version 453
- **1.3.8** (1/2/22)
  - Updated for 451D
  - WIP GUARD mod (Some features of it might not work with other mods)
  - Added a modpack settings GUI menu! (Fancy!)
  - [THIS] Fixed THIS + group not working (again)
  - [THIS] Fixed a lua error from forming `T H I S is X`
    - Note: I cannot think of what should happen when you form "this" with letters, so I'm leaving it to do nothing for now.
  - [THIS + STABLE] Fixed inf loop case with `THIS is stable and pass`
  - [OMNI TEXT + CUT/PACK] Fixed not being able to pack "OMNIAND" and "PIVOTAND"
  - [CUT/PACK] "cut" objects that are also "weak" will be destroyed if that object cuts something
  - [STABLE] fixed weird case where "text is not push" + "text on baba is stable" caused text to be pushable when a text becomes stable
- **1.3.7** (11/25/21)
  - Fixed regression bug that caused directional you to not win
- **1.3.6** (11/17/21)
  - Fixed "done" and "end" endings not working
- **1.3.5** (11/17/21)
  - Updated for the level editor release! (438C)
  - [TURNING TEXT] Added directional **BOOM**!
  - [TURNING TEXT] Fixed weird interactions with stacked directional shifts
  - [FILLER TEXT] Fixed `baba is baba <filler> is you` not parsing correctly
- **1.3.4** (10/30/21)
  - Updated for beta 433c
  - Added custom level editor tags!
  - [STABLE] Fixed an order of operations case where removing "Flag is stable" while also making "Flag is wall" does not transform flag until the next turn.
  - [STABLE] Fixed indicator for stablerule "X near THIS is Y" not scaling according to level scaling. 
- **1.3.3** (10/29/21)
  - Updated for beta 433b
  - [CUT/PACK] Added directional packing!
  - [CUT/PACK] In the editor pallete, adding pack or adding a directional text with pack auto-adds corresponding texts to support directional packing
  - [CUT/PACK] Made the editor auto-add numbers when adding CUT to palette
  - [CUT/PACK] Added a few other edge cases for cut.
  - [TURNING TEXT] Fixed a case where having turning dir + a bunch of letters lagged the game
- **1.3.2** (10/3/21)
  - [STABLE] Stable will not copy over rules made from mimic (but can still copy "X mimic Y")
  - [STABLE] Fixed "X feeling stable is Y" not working
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