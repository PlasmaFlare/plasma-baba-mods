# Baba Is You Mod - CUT/PACK
Ever feel like you wanted to take the individial letters of a text block and rearrange them to make new words out of them? Well now you can in this BRAND NEW MOD!

Introducing *two* **NEW** properties that give you the means to CUT, rearrange and PACK text together in a whole new ***text crafting*** experience!

(Don't ask me why I chose to write this as an ad lol)

A nice demo:

<img src="gifs/textcraft.gif" alt="drawing" width="800"/>
---





## Important note about using cut/pack with the object pallete
Both `cut` and `pack` require that the text being produced is in the object pallete. `cut` needs the letter texts while `pack` needs the "full" text objects (`back`, `turnip` etc). If the object that would be produced by `cut` or `pack` is not in the pallete, then it won't complete the cut/pack. 

Adding `cut` through the editor should auto add all alphabetical texts. But for `pack`, you have to add the texts yourself. You can use @slabdrill's [Baba Anagram Finder](https://1234abcdcba4321.github.io/babaanagram/) to help with this. Remember that it's common courtesy to add all spellable words into the pallete.

## Other edge cases:
- If `text is pack` is active, letter texts cannot pack themselves or each other. This might change in the future, but I found that it causes a lot of weird interactions otherwise. Note that normal "full" text objects can still pack letter texts together
  
- Be careful when using `cut` to produce stacked texts. Due to how the parser works, the game can lag exponentially if you have a line of stacked texts, which is something that `cut` can do easily. This is especially true with `level is cut` and `baba is cut and fall` while baba is falling onto a line of text 

- Cutting a directional fall, locked, nudge or one of my modded directional properties will spit out the base property without the direction  