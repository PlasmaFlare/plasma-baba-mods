function clearunits(restore_)
	-- @Mods(this) - Override reason: clear globals when we exit the editor
	units = {}
	tiledunits = {}
	codeunits = {}
	animunits = {}
	unitlists = {}
	undobuffer = {}
	unitmap = {}
	unittypeshere = {}
	prevunitmap = {}
	ruleids = {}
	objectlist = {}
	objectpalette = {}
	updatelist = {}
	objectcolours = {}
	wordunits = {}
	wordrelatedunits = {}
	letterunits = {}
	letterunits_map = {}
	paths = {}
	paradox = {}
	movelist = {}
	deleted = {}
	effecthistory = {}
	notfeatures = {}
	groupfeatures = {}
	groupmembers = {}
	pushedunits = {}
	customobjects = {}
	cobjects = {}
	condstatus = {}
	emptydata = {}
	leveldata = {}
	leveldata.colours = {}
	leveldata.currcolour = 0
	
	visiontargets = {}
	vision_rendered = {}
	revertlist = {}
	
	generaldata.values[CURRID] = 1
	updateundo = true
	hiddenmap = nil
	levelconversions = {}
	last_key = 0
	auto_dir = {}
	destroylevel_check = false
	destroylevel_style = ""
	
	HACK_MOVES = 0
	HACK_INFINITY = 0
	movemap = {}
	
	local restore = true
	if (restore_ ~= nil) then
		restore = norestore_
	end

	reset_this_mod()
	clear_stable_mod()
	
	if restore then
		newundo()
		
		print("clearunits")
		
		restoredefaults()
	end
end

