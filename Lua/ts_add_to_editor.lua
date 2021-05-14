table.insert(editor_objlist_order, "text_cut")

editor_objlist["text_cut"] = 
{
	name = "text_cut",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {5, 2},
    colour_active = {5, 4},
}
table.insert(editor_objlist_order, "text_pack")

editor_objlist["text_pack"] = 
{
	name = "text_pack",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {2, 2},
    colour_active = {2, 3},
}

formatobjlist()