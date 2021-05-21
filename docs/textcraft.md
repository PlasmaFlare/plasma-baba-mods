# Baba Is You Mod - CUT/PACK
Ever feel like you wanted to take the individial letters of a text block and rearrange them to make new words out of them? Well now you can in this BRAND NEW MOD!

Introducing *two* **NEW** properties that give you the means to CUT, rearrange and PACK text together in a whole new ***text crafting*** experience!

(Don't ask me why I chose to write this as an ad lol)

A nice demo:

<img src="gifs/textcraft.gif" alt="drawing" width="800"/>
---





## Important note about using cut/pack with the object pallete
Both `cut` and `pack` require that the text being produced is in the object pallete (with special exceptions explained below). `cut` needs the letter texts while `pack` needs the "full" text objects (`back`, `turnip` etc). If the object that would be produced by `cut` or `pack` is not in the pallete, then it won't complete the cut/pack. 

Adding `cut` through the editor should auto add all alphabetical texts. But for `pack`, you have to add the texts yourself. You can use @slabdrill's [Baba Anagram Finder](https://1234abcdcba4321.github.io/babaanagram/) to help with this. Remember that it's common courtesy to add all spellable words into the pallete.

### **Special Exceptions to the Object Pallete requirement**
UPDATE: I compiled a current list of texts that cut/pack can use without adding to the pallete. See the list [here](default_text.txt). Follow the instructions below if you want to directly look at the source in case the game updates it.

Most of the common texts, like "baba" and "keke", don't actually need to be in the pallete. This is because the game has two systems for maintaining definitions of object types. There's a "recent" system where you add the objects to the pallete and it assigns a unique id dynamically for each object. Then there's a "legacy" system where 100 objects are predefined and auto added to the list of objects avaliable. This list defines which objects cut/pack can produce without adding to the pallete. To see the full list, go to your game's directory and look at `values.lua` and you'll see a giant table that starts like below. Any entries that have `text_<someobject>`, you don't have to include in the pallete.
```
tileslist =
{
	edge =
	{
		-- SPECIAL CASE
		colour = {0, 2},
		tile = {0, 0},
	},
	object000 =
	{
		name = "baba",
		sprite = "baba",
		sprite_in_root = true,
		unittype = "object",
		tiling = 2,
		type = 0,
		colour = {0, 3},
		tile = {1, 0},
		grid = {0, 1},
		layer = 18,
	},
	object001 =
	{
		name = "keke",
		sprite = "keke",
		sprite_in_root = true,
		unittype = "object",
		tiling = 2,
		type = 0,
		colour = {2, 2},
		tile = {2, 0},
		grid = {0, 2},
		layer = 18,
	},
    ... 
```


## Other edge cases:
- If `text is pack` is active, letter texts cannot pack themselves or each other. This might change in the future, but I found that it causes a lot of weird interactions otherwise. Note that normal "full" text objects can still pack letter texts together
  
- Be careful when using `cut` to produce stacked texts. Due to how the parser works, the game can lag exponentially if you have a line of stacked texts, which is something that `cut` can do easily. This is especially true with `level is cut` and `baba is cut and fall` while baba is falling onto a line of text 

- Cutting a directional fall, locked, nudge or one of my modded directional properties will spit out the base property without the direction
  
- Cutting and packing text does not trigger `text has X`. This is something I debated for a while, but decided that it seems cheap for pack and cut to trigger has since you can keep on cutting and packing.