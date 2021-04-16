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

### Note about Block and Pass edge cases
- Blocks should have priority over passes
- "This is pass" or "This is block" works, but trying to mix these together will reveal weird edge cases with some experimentation
- Since block and pass were designed to be used in constant rules (e.g: wall is stop and block), I'm not too inclined to fix edge cases where block and/or pass are being used dynamically.

## **Multiple thises with different colors**
The THIS indicators change color depending on the color of THIS. This can help differentiate between the different THIS's and which objects each of the are pointing to.

Unfortunately baba doesn't allow two objects to share the exact name. So I programmed this mod to treat all objects with the name "text_this\<string_with_no_spaces>" to treat as "this". (So text_this2, text_this34, text_thiswhyisthissolong, are all valid).

Here are the steps to add a THIS with different color:
1. In the object palette, click the baba icon with "abc" to make it checked. Then select an object in the palette that you want to change into a THIS object.
2. Click "Change Sprite" and select the THIS sprite
3. Click "Change Name" and rename to "text_this\<string_with_no_spaces>"
4. Click "Change Type" and input "Text"
5. Configure "Base Color" and "Active Color" to whatever color you want.
6. Set "Animation Type" to "none"
7. Set "Text Type" to "baba"

The THIS text should now be ready to use.