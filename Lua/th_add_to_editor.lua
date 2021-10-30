table.insert(editor_objlist_order, "text_this")
table.insert(editor_objlist_order, "text_block")
table.insert(editor_objlist_order, "text_pass")

editor_objlist["text_this"] = 
{
	name = "text_this",
	sprite_in_root = false,
	unittype = "text",
	tags = {"plasma's mods", "text", "abstract", "text_noun"},
	tiling = 0,
	type = 0,
	layer = 20,
	colour = {0, 1},
    colour_active = {0, 3},
}
editor_objlist["text_block"] = 
{
	name = "text_block",
	sprite_in_root = false,
	unittype = "text",
	tags = {"plasma's mods", "text", "abstract", "text_quality"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {2, 1},
    colour_active = {2, 2},
}
editor_objlist["text_pass"] = 
{
	name = "text_pass",
	sprite_in_root = false,
	unittype = "text",
	tags = {"plasma's mods", "text", "abstract", "text_quality"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {4, 3},
    colour_active = {4, 4},
}

formatobjlist()