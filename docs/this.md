# Baba is You mod - THIS
THIS mod adds THIS, a new special noun whose meaning is whichever objects THIS points to. Bab inspired, but taken up a notch.

Here it is in action:

<img src="gifs/this_mod_demo.gif" alt="drawing" width="600"/>

---
Seems pretty op right? Well to control this, this mod also adds a new property: **BLOCK**

Objects that are block prevent itself and any objects on it from being referred by any this. So you can still hide text behind walls without worrying about cheese with THIS.

<img src="gifs/this_mod_block.gif" alt="drawing" width="600"/>

## **Multiple thises with different colors**
The THIS indicators change color depending on the color of THIS. This can help differentiate between the different THIS's and which objects each of the are pointing to.

Unfortunately baba doesn't allow two objects to share the exact name. So I programmed this mod to treat all objects with the name "this\<string_with_no_spaces>" to treat as "this". (So this2, this34, thiswhyisthissolong, are all valid).

Here are the steps to add a this with different color:
1. In the object palette, click the baba icon with "abc" to make it checked. Then select an object in the palette to change into a "this" object.
2. Click "Change Sprite" and select the "this" sprite
3. Click "Change Name" and rename to "text_this\<string_with_no_spaces>"
4. Click "Change Type" and input "Text"
5. Configure "Base Color" and "Active Color" to whatever color you want.
6. Set "Animation Type" to "none"
7. Set "Text Type" to "baba"

The "this" text should now be ready to use.