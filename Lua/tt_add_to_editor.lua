enable_directional_shift = true

table.insert(editor_objlist_order, "text_turning_fall")
table.insert(editor_objlist_order, "text_turning_nudge")
table.insert(editor_objlist_order, "text_turning_dir")
table.insert(editor_objlist_order, "text_turning_locked")

table.insert(editor_objlist_order, "text_youdown")
table.insert(editor_objlist_order, "text_youright")
table.insert(editor_objlist_order, "text_youup")
table.insert(editor_objlist_order, "text_youleft")
table.insert(editor_objlist_order, "text_turning_you")

table.insert(editor_objlist_order, "text_you2down")
table.insert(editor_objlist_order, "text_you2right")
table.insert(editor_objlist_order, "text_you2up")
table.insert(editor_objlist_order, "text_you2left")
table.insert(editor_objlist_order, "text_turning_you2")

table.insert(editor_objlist_order, "text_pushdown")
table.insert(editor_objlist_order, "text_pushright")
table.insert(editor_objlist_order, "text_pushup")
table.insert(editor_objlist_order, "text_pushleft")
table.insert(editor_objlist_order, "text_turning_push")

table.insert(editor_objlist_order, "text_pulldown")
table.insert(editor_objlist_order, "text_pullright")
table.insert(editor_objlist_order, "text_pullup")
table.insert(editor_objlist_order, "text_pullleft")
table.insert(editor_objlist_order, "text_turning_pull")

table.insert(editor_objlist_order, "text_swapdown")
table.insert(editor_objlist_order, "text_swapright")
table.insert(editor_objlist_order, "text_swapup")
table.insert(editor_objlist_order, "text_swapleft")
table.insert(editor_objlist_order, "text_turning_swap")

table.insert(editor_objlist_order, "text_moredown")
table.insert(editor_objlist_order, "text_moreright")
table.insert(editor_objlist_order, "text_moreup")
table.insert(editor_objlist_order, "text_moreleft")
table.insert(editor_objlist_order, "text_turning_more")

table.insert(editor_objlist_order, "text_stopdown")
table.insert(editor_objlist_order, "text_stopright")
table.insert(editor_objlist_order, "text_stopup")
table.insert(editor_objlist_order, "text_stopleft")
table.insert(editor_objlist_order, "text_turning_stop")

table.insert(editor_objlist_order, "text_shiftdown")
table.insert(editor_objlist_order, "text_shiftright")
table.insert(editor_objlist_order, "text_shiftup")
table.insert(editor_objlist_order, "text_shiftleft")
table.insert(editor_objlist_order, "text_turning_shift")

table.insert(editor_objlist_order, "text_selectdown")
table.insert(editor_objlist_order, "text_selectright")
table.insert(editor_objlist_order, "text_selectup")
table.insert(editor_objlist_order, "text_selectleft")
table.insert(editor_objlist_order, "text_turning_select")

editor_objlist["text_turning_fall"] = 
{
	name = "text_turning_fall",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = 0,
	type = 2,
	layer = 20,
	colour = {5, 1},
	colour_active = {5, 3},
	pairedwith = "text_fall",
}
editor_objlist["text_turning_nudge"] = 
{
	name = "text_turning_nudge",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = 0,
	type = 2,
	layer = 20,
	colour = {5, 1},
	colour_active = {5, 3},
	pairedwith = "text_nudge",
}
editor_objlist["text_turning_dir"] = 
{
	name = "text_turning_dir",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = 0,
	type = 2,
	layer = 20,
	colour = {1, 3},
	colour_active = {1, 4},
}
editor_objlist["text_turning_locked"] = 
{
	name = "text_turning_locked",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = 0,
	type = 2,
	layer = 20,
	colour = {4, 1},
	colour_active = {4, 2},
	pairedwith = "text_locked",
}

-- YOU
editor_objlist["text_youright"] = 
{
	name = "text_youright",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {4, 0},
	colour_active = {4, 1},
	pairedwith = "text_you",
}
editor_objlist["text_youleft"] = 
{
	name = "text_youleft",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {4, 0},
	colour_active = {4, 1},
	pairedwith = "text_you",
}
editor_objlist["text_youup"] = 
{
	name = "text_youup",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {4, 0},
	colour_active = {4, 1},
	pairedwith = "text_you",
}
editor_objlist["text_youdown"] = 
{
	name = "text_youdown",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {4, 0},
	colour_active = {4, 1},
	pairedwith = "text_you",
}
editor_objlist["text_turning_you"] = 
{
	name = "text_turning_you",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = 0,
	type = 2,
	layer = 20,
	colour = {4, 0},
	colour_active = {4, 1},
	pairedwith = "text_you",
}

-- YOU2
editor_objlist["text_you2right"] = 
{
	name = "text_you2right",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {4, 0},
	colour_active = {4, 1},
	pairedwith = "text_you2",
}
editor_objlist["text_you2left"] = 
{
	name = "text_you2left",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {4, 0},
	colour_active = {4, 1},
	pairedwith = "text_you2",
}
editor_objlist["text_you2up"] = 
{
	name = "text_you2up",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {4, 0},
	colour_active = {4, 1},
	pairedwith = "text_you2",
}
editor_objlist["text_you2down"] = 
{
	name = "text_you2down",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {4, 0},
	colour_active = {4, 1},
	pairedwith = "text_you2",
}
editor_objlist["text_turning_you2"] = 
{
	name = "text_turning_you2",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = 0,
	type = 2,
	layer = 20,
	colour = {4, 0},
	colour_active = {4, 1},
	pairedwith = "text_you2",
}

-- MORE
editor_objlist["text_moreright"] = 
{
	name = "text_moreright",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {4, 0},
	colour_active = {4, 1},
	pairedwith = "text_more",
}
editor_objlist["text_moreleft"] = 
{
	name = "text_moreleft",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {4, 0},
	colour_active = {4, 1},
	pairedwith = "text_more",
}
editor_objlist["text_moreup"] = 
{
	name = "text_moreup",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {4, 0},
	colour_active = {4, 1},
	pairedwith = "text_more",
}
editor_objlist["text_moredown"] = 
{
	name = "text_moredown",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {4, 0},
	colour_active = {4, 1},
	pairedwith = "text_more",
}
editor_objlist["text_turning_more"] = 
{
	name = "text_turning_more",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = 0,
	type = 2,
	layer = 20,
	colour = {4, 0},
	colour_active = {4, 1},
	pairedwith = "text_more",
}

-- PUSH
editor_objlist["text_pushright"] = 
{
	name = "text_pushright",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {6, 0},
	colour_active = {6, 1},
	pairedwith = "text_push",
}
editor_objlist["text_pushleft"] = 
{
	name = "text_pushleft",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {6, 0},
	colour_active = {6, 1},
	pairedwith = "text_push",
}
editor_objlist["text_pushup"] = 
{
	name = "text_pushup",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {6, 0},
	colour_active = {6, 1},
	pairedwith = "text_push",
}
editor_objlist["text_pushdown"] = 
{
	name = "text_pushdown",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {6, 0},
	colour_active = {6, 1},
	pairedwith = "text_push",
}
editor_objlist["text_turning_push"] = 
{
	name = "text_turning_push",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = 0,
	type = 2,
	layer = 20,
	colour = {6, 0},
	colour_active = {6, 1},
	pairedwith = "text_push",
}

-- PULL
editor_objlist["text_pullright"] = 
{
	name = "text_pullright",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {6, 1},
	colour_active = {6, 2},
	pairedwith = "text_pull",
}
editor_objlist["text_pullleft"] = 
{
	name = "text_pullleft",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {6, 1},
	colour_active = {6, 2},
	pairedwith = "text_pull",
}
editor_objlist["text_pullup"] = 
{
	name = "text_pullup",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {6, 1},
	colour_active = {6, 2},
	pairedwith = "text_pull",
}
editor_objlist["text_pulldown"] = 
{
	name = "text_pulldown",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {6, 1},
	colour_active = {6, 2},
	pairedwith = "text_pull",
}
editor_objlist["text_turning_pull"] = 
{
	name = "text_turning_pull",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = 0,
	type = 2,
	layer = 20,
	colour = {6, 1},
	colour_active = {6, 2},
	pairedwith = "text_pull",
}

-- SWAP
editor_objlist["text_swapright"] = 
{
	name = "text_swapright",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {3, 0},
	colour_active = {3, 1},
	pairedwith = "text_swap",
}
editor_objlist["text_swapleft"] = 
{
	name = "text_swapleft",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {3, 0},
	colour_active = {3, 1},
	pairedwith = "text_swap",
}
editor_objlist["text_swapup"] = 
{
	name = "text_swapup",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {3, 0},
	colour_active = {3, 1},
	pairedwith = "text_swap",
}
editor_objlist["text_swapdown"] = 
{
	name = "text_swapdown",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {3, 0},
	colour_active = {3, 1},
	pairedwith = "text_swap",
}
editor_objlist["text_turning_swap"] = 
{
	name = "text_turning_swap",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = 0,
	type = 2,
	layer = 20,
	colour = {3, 0},
	colour_active = {3, 1},
	pairedwith = "text_swap",
}

-- STOP
editor_objlist["text_stopright"] = 
{
	name = "text_stopright",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {5, 0},
	colour_active = {5, 1},
	pairedwith = "text_stop",
}
editor_objlist["text_stopleft"] = 
{
	name = "text_stopleft",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {5, 0},
	colour_active = {5, 1},
	pairedwith = "text_stop",
}
editor_objlist["text_stopup"] = 
{
	name = "text_stopup",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {5, 0},
	colour_active = {5, 1},
	pairedwith = "text_stop",
}
editor_objlist["text_stopdown"] = 
{
	name = "text_stopdown",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {5, 0},
	colour_active = {5, 1},
	pairedwith = "text_stop",
}
editor_objlist["text_turning_stop"] = 
{
	name = "text_turning_stop",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = 0,
	type = 2,
	layer = 20,
	colour = {5, 0},
	colour_active = {5, 1},
	pairedwith = "text_stop",
}

-- SHIFT
editor_objlist["text_shiftright"] = 
{
	name = "text_shiftright",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {1, 2},
	colour_active = {1, 3},
	pairedwith = "text_shift",
}
editor_objlist["text_shiftleft"] = 
{
	name = "text_shiftleft",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {1, 2},
	colour_active = {1, 3},
	pairedwith = "text_shift",
}
editor_objlist["text_shiftup"] = 
{
	name = "text_shiftup",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {1, 2},
	colour_active = {1, 3},
	pairedwith = "text_shift",
}
editor_objlist["text_shiftdown"] = 
{
	name = "text_shiftdown",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {1, 2},
	colour_active = {1, 3},
	pairedwith = "text_shift",
}
editor_objlist["text_turning_shift"] = 
{
	name = "text_turning_shift",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = 0,
	type = 2,
	layer = 20,
	colour = {1, 2},
	colour_active = {1, 3},
	pairedwith = "text_shift",
}

-- SELECT
editor_objlist["text_selectright"] = 
{
	name = "text_selectright",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {2, 3},
	colour_active = {2, 4},
	pairedwith = "text_select",
}
editor_objlist["text_selectleft"] = 
{
	name = "text_selectleft",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {2, 3},
	colour_active = {2, 4},
	pairedwith = "text_select",
}
editor_objlist["text_selectup"] = 
{
	name = "text_selectup",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {2, 3},
	colour_active = {2, 4},
	pairedwith = "text_select",
}
editor_objlist["text_selectdown"] = 
{
	name = "text_selectdown",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = -1,
	type = 2,
	layer = 20,
	colour = {2, 3},
	colour_active = {2, 4},
	pairedwith = "text_select",
}
editor_objlist["text_turning_select"] = 
{
	name = "text_turning_select",
	sprite_in_root = false,
	unittype = "text",
	tags = {"text, abstract"},
	tiling = 0,
	type = 2,
	layer = 20,
	colour = {2, 3},
	colour_active = {2, 4},
	pairedwith = "text_select",
}

formatobjlist()