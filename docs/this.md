# Baba is You mod - THIS
THIS mod adds THIS, a new special noun whose meaning is whichever objects THIS points to. Bab inspired, but taken up a notch.

Here it is in action:

<img src="gifs/this_mod_demo.gif" alt="drawing" width="400"/>

Seems pretty op right? Well to control this, this mod also adds a few properties that limit what THIS points to.

---
##  **BLOCK**

Objects that are block prevent itself and any objects on it from being referred by any this. It also stops THIS from raycasting any further when it reaches the blocked object.

<img src="gifs/this_mod_block.gif" alt="drawing" width="400"/>

---

##  **PASS**
Pass objects will be ignored by any other raycasts coming from THIS texts. This allows for background objects to be ignored as if they were empty. 

<img src="gifs/this_mod_pass.gif" alt="drawing" width="400"/>

---

## **Multiple thises with different colors**
The THIS indicators change color depending on the color of THIS. This can help differentiate between the different THIS's and which objects each of the are pointing to.

Unfortunately baba doesn't allow two objects to share the exact name. So I programmed this mod to treat all objects with the name "text_this\<string_with_no_spaces>" to treat as "this". (So text_this2, text_this34, text_thiswhyisthissolong, are all valid).

Here are the steps to add a THIS with different color:
1. In the object palette, click the baba icon with "abc" to make it checked. Then select an object in the palette that you want to change into a THIS object.
2. Click "Change Sprite" and select the THIS sprite
3. Click "Change Name" and rename to "text_this\<string_with_no_spaces>"
4. Click "Change Type" and input "Text"
5. Configure "Base Color" and "Active Color" to whatever color you want.
6. Set "Animation Type" to "directions"
7. Set "Text Type" to "baba"

The THIS text should now be ready to use.

---

## **Block and Pass edge cases**
*Warning: Technical stuff ahead. Feel free to ignore this if you don't want to bother with the details*

Sentences involving `this is pass/block` or `X is this(pass/block)` are tricky to interpret without resorting to infinite loops. Generally, if you want to avoid weird interactions, I recommend not playing around with combinations of THIS and block/pass. However, as of version 1.1.2, these kind of interactions have a more solid set of rules that I feel should resolve most edge cases. 

### Priorities
The mod processes rules involving THIS and/or block/pass in the order below. The effects calculated from each bullet are only applied to THISes found in later bullets.

(`X` = static noun or property, `this(X)` = THIS pointing to X):
- `X is block` 
- `X is pass`
- `this(X) is block` | `X is this(block)` | `this(X) is this(block)`
- `this(X) is pass` | `X is this(pass)` | `this(X) is this(pass)`
- `<Other rules with THIS>`

General rules of thumb:
- Static rules get processed before THIS rules
- Block rules get processed before pass rules
- Other rules with THIS get processed last

### Other Notes
- Block and pass don't work with group. Since group is being reworked by Hempuli, I won't bother fixing this until the group code is stable.