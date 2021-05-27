table.insert(editor_objlist_order, "text_branching_is")
table.insert(editor_objlist_order, "text_branching_and")
table.insert(editor_objlist_order, "text_branching_has")
table.insert(editor_objlist_order, "text_branching_near")

table.insert(editor_objlist_order, "text_branching_make")
table.insert(editor_objlist_order, "text_branching_follow")
table.insert(editor_objlist_order, "text_branching_mimic")
table.insert(editor_objlist_order, "text_branching_play")
table.insert(editor_objlist_order, "text_branching_eat")
table.insert(editor_objlist_order, "text_branching_fear")

table.insert(editor_objlist_order, "text_branching_on")
table.insert(editor_objlist_order, "text_branching_without")
table.insert(editor_objlist_order, "text_branching_facing")
table.insert(editor_objlist_order, "text_branching_above")
table.insert(editor_objlist_order, "text_branching_below")
table.insert(editor_objlist_order, "text_branching_feeling")

editor_objlist["text_branching_is"] = 
{
	name = "text_branching_is",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract, text_verb"},
	tiling = -1,
	type = 1,
	layer = 20,
	colour = {2, 2},
	colour_active = {2, 4},
	pairedwith = "text_is",
}

editor_objlist["text_branching_and"] = 
{
	name = "text_branching_and",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract, text_verb"},
	tiling = -1,
	type = 6,
	layer = 20,
	colour = {2, 2},
	colour_active = {2, 4},
	pairedwith = "text_and",
}

editor_objlist["text_branching_has"] = 
{
	name = "text_branching_has",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract, text_verb"},
	tiling = -1,
	type = 1,
	layer = 20,
	colour = {2, 2},
	colour_active = {2, 4},
	pairedwith = "text_has",
}

editor_objlist["text_branching_fear"] = 
{
	name = "text_branching_fear",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract, text_verb"},
	tiling = -1,
	type = 1,
	layer = 20,
	colour = {4, 1},
	colour_active = {4, 2},
	pairedwith = "text_fear",
}

editor_objlist["text_branching_make"] = 
{
	name = "text_branching_make",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract, text_verb"},
	tiling = -1,
	type = 1,
	layer = 20,
	colour = {2, 2},
	colour_active = {2, 4},
	pairedwith = "text_make",
}

editor_objlist["text_branching_follow"] = 
{
	name = "text_branching_follow",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract, text_verb"},
	tiling = -1,
	type = 1,
	layer = 20,
	colour = {5, 2},
	colour_active = {5, 4},
	pairedwith = "text_follow",
}

editor_objlist["text_branching_mimic"] = 
{
	name = "text_branching_mimic",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract, text_verb"},
	tiling = -1,
	type = 1,
	layer = 20,
	colour = {4, 1},
	colour_active = {4, 2},
	pairedwith = "text_mimic",
}

editor_objlist["text_branching_play"] = 
{
	name = "text_branching_play",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract, text_verb"},
	tiling = -1,
	type = 1,
	layer = 20,
	colour = {5, 2},
	colour_active = {5, 4},
	pairedwith = "text_play",
}

editor_objlist["text_branching_eat"] = 
{
	name = "text_branching_eat",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract, text_verb"},
	tiling = -1,
	type = 1,
	layer = 20,
	colour = {4, 1},
	colour_active = {4, 2},
	pairedwith = "text_eat",
}

editor_objlist["text_branching_near"] = 
{
	name = "text_branching_near",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract, text_condition"},
	tiling = -1,
	type = 7,
	layer = 20,
	colour = {2, 2},
	colour_active = {2, 4},
	pairedwith = "text_near",
}

editor_objlist["text_branching_on"] = 
{
	name = "text_branching_on",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract, text_condition"},
	tiling = -1,
	type = 7,
	layer = 20,
	colour = {2, 2},
	colour_active = {2, 4},
	pairedwith = "text_on",
}
editor_objlist["text_branching_without"] = 
{
	name = "text_branching_without",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract, text_condition"},
	tiling = -1,
	type = 7,
	layer = 20,
	colour = {2, 2},
	colour_active = {2, 4},
	pairedwith = "text_without",
}
editor_objlist["text_branching_facing"] = 
{
	name = "text_branching_facing",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract, text_condition"},
	tiling = -1,
	type = 7,
	layer = 20,
	colour = {2, 2},
	colour_active = {2, 4},
	pairedwith = "text_facing",
	argextra = {"right","up","left","down"},
}
editor_objlist["text_branching_above"] = 
{
	name = "text_branching_above",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract, text_condition"},
	tiling = -1,
	type = 7,
	layer = 20,
	colour = {3, 2},
	colour_active = {4, 4},
	pairedwith = "text_above",
}
editor_objlist["text_branching_below"] = 
{
	name = "text_branching_below",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract, text_condition"},
	tiling = -1,
	type = 7,
	layer = 20,
	colour = {3, 2},
	colour_active = {4, 4},
	pairedwith = "text_below",
}
editor_objlist["text_branching_feeling"] = 
{
	name = "text_branching_feeling",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract, text_condition"},
	tiling = -1,
	type = 7,
	layer = 20,
	colour = {2, 2},
	colour_active = {2, 4},
	pairedwith = "text_feeling",
	argtype = {2},
}

formatobjlist()