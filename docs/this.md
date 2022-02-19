# Baba is You mod - THIS / POINTER NOUNS
THIS mod adds THIS, a new special noun whose meaning is whichever objects THIS points to. Bab inspired, but taken up a notch.

Here it is in action:

<img src="gifs/this_mod_demo.gif" alt="drawing" width="600"/>

---

## More pointer nouns!
As of v1.5, I updated the THIS mod to add more pointer nouns! (Or that's what I'm calling them anyway). They differ from THIS by how they tend to select objects in the level. Here's a summary of all pointer nouns:
- **THIS** - refers to the closet object in front of it
- **THAT** - refers to the *farthest* object in front of it
- **THESE** - refers to all objects *between* two THESE texts (meaning THESE works in pairs)
- **THOSE** - refers to all *connecting* objects, starting from the object right in front of THOSE

Here's all the pointer nouns in action:

<img src="gifs/pointer_nouns.gif" alt="drawing" width="600"/>

---

Being able to refer to specific objects in the level seems pretty OP right? Well to control this, this mod also adds a few properties that limit what can be referred by a pointer noun.

---
##  **BLOCK**

Objects that are block prevent itself and any objects on it from being referred by any this. It also stops THIS from raycasting any further when it reaches the blocked object.

<img src="gifs/this_mod_block.gif" alt="drawing" width="600"/>

---

##  **PASS**
Pass objects will be ignored by any other raycasts coming from THIS texts. This allows for background objects to be ignored as if they were empty. 

<img src="gifs/this_mod_pass.gif" alt="drawing" width="600"/>

---

##  **RELAY**
Recently added in v1.5, RELAY objects *redirect* raycasting in the direction of the raycasted object. Similar to a mirror in a laser puzzle. The RELAY object and all objects on the same space are not selected by the raycast.

<img src="gifs/this_mod_relay.gif" alt="drawing" width="600"/>

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

## **Block/Pass/Relay edge cases**
*Warning: Technical stuff ahead. Feel free to ignore this if you don't want to bother with the details*

Sentences involving `this is pass/block` or `X is this(pass/block)` are tricky to interpret without resorting to infinite loops. Generally, if you want to avoid weird interactions, I recommend not playing around with combinations of THIS and block/pass. However, as of version 1.5.0 these kind of interactions have a more solid set of rules that I feel should resolve most edge cases. 

### Priorities
The mod processes rules involving THIS and/or block/pass in the order below. The effects calculated from each step are only applied to THISes found in later step.

(`X` = static noun or property, `this(X)` = THIS pointing to X):
   1. `X is block` 
1. `X is relay` 
1. `X is pass`
1. `this(X) is block`
1. `this(X) is relay`
1. `this(X) is pass`
1. `X is this(block)` | `this(X) is this(block)`
1. `X is this(relay)` | `this(X) is this(relay)`
1. `X is this(pass)` | `this(X) is this(pass)`
1. (If at this point there are more rules that fit in any of 7, 8 or 9, start again at 7. Otherwise go to 11)
1. `<Other rules with THIS>`

General rules of thumb:
- Static rules get processed before THIS rules
- `THIS is block/relay/pass` get processed before other THIS rules. (Since the `block/relay/pass` part is static, not determined by a THIS)
- In order of priority: BLOCK -> RELAY -> PASS
- Rules with THIS that do not have BLOCK, RELAY or PASS get processed last