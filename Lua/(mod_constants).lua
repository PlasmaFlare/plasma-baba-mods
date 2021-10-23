br_prefix = "branching_"
br_prefix_len = string.len(br_prefix)
pivot_prefix = "pivot_"
pivot_prefix_len = string.len(pivot_prefix)

dirfeaturemap = {"right", "up", "left", "down"}

arrow_properties = {
    you=true,
    you2=true,
    push=true,
    pull=true,
    swap=true,
    stop=true,
    more=true,
	shift=true,
	select=true,
}

turning_word_names = {
    fall=true, 
    nudge=true, 
    locked=true, 
    dir=true, 
    you=true,
    you2=true,
    push=true,
    pull=true,
    swap=true,
    stop=true,
    shift=true,
    more=true,
    select=true,
}

arrow_property_display = {
    youright="you (right)",
    youup="you (up)",
    youleft="you (left)",
    youdown="you (down)",
    you2right="you2 (right)",
    you2up="you2 (up)",
    you2left="you2 (left)",
    you2down="you2 (down)",
    pushright="push (right)",
    pushup="push (up)",
    pushleft="push (left)",
    pushdown="push (down)",
    pullright="pull (right)",
    pullup="pull (up)",
    pullleft="pull (left)",
    pulldown="pull (down)",
    swapright="swap (right)",
    swapup="swap (up)",
    swapleft="swap (left)",
    swapdown="swap (down)",
    stopright="stop (right)",
    stopup="stop (up)",
    stopleft="stop (left)",
    stopdown="stop (down)",
    moreright="more (right)",
    moreup="more (up)",
    moreleft="more (left)",
	moredown="more (down)",
	shiftright="shift (right)",
	shiftup="shift (up)",
	shiftleft="shift (left)",
	shiftdown="shift (down)",
	selectright="select (right)",
	selectup="select (up)",
	selectleft="select (left)",
	selectdown="select (down)",
}