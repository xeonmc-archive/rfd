--------------------------------------------------------------------------------
-- This is an official Reflex script. Do not modify.
--------------------------------------------------------------------------------

require "base/internal/ui/reflexcore"

ReplayEditor =
{
	time = 0,
	hideButtonPressTime = 0,
	showButtonPressTime = 0,
	hidden = false,
	canPosition = false,
	canHide = false,
	isMenu = true,
	comboBoxDataExportSecondsList = {},
	comboBoxDataExportSecondsListSelected = nil,
	comboBoxDataplayerList = {},
	comboBoxDataplayerListSelected = nil,

	showOnScreen = true
};
registerWidget("ReplayEditor");

local TimecodeScale = 50
local TimecodeOffset = 0

local function TimecodeToPixel(timecode)
	local ix = (timecode - (replay.timecodeStart+TimecodeOffset)) / TimecodeScale -- .1 seconds = 1pixel
	ix = ix - (viewport.width/2-5);
	return ix
end

local function PixelToTimecode(pixel)
	return (pixel + (viewport.width/2-5)) * TimecodeScale + (replay.timecodeStart+TimecodeOffset)
end

--------------------------------------------------------------------------------
-- aim to keep timecode within the center 1/2 of the screen
--------------------------------------------------------------------------------
local function UpdateOffset()
	local left = -viewport.width/4
	local right = viewport.width/4

	local x = TimecodeToPixel(replay.timecodeCurrent)

	if x > right then
		local pixelCorrection = x - right
		TimecodeOffset = TimecodeOffset + pixelCorrection * TimecodeScale
	elseif x < left then
		local pixelCorrection = x - left
		TimecodeOffset = TimecodeOffset + pixelCorrection * TimecodeScale
		TimecodeOffset = math.max(TimecodeOffset, 0)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ReplayEditor:drawRulerTop(x, y, w, h)
	nvgStrokeColor(Color(64,64,64));

	-- line
	nvgBeginPath();
	nvgMoveTo(x, y);
	nvgLineTo(x+w, y);
	nvgStroke();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ReplayEditor:drawRulerBottom(x, y, w, h)
	-- prep colours
	nvgStrokeColor(Color(64,64,64));
	nvgFillColor(Color(92,92,92));
	nvgFontFace("TitilliumWeb-Bold");
	nvgFontSize(16)

	-- line
	nvgBeginPath();
	nvgMoveTo(x, y);
	nvgLineTo(x+w, y);
	nvgStroke();

	local timecode = PixelToTimecode(x)
	local timecodeStep = 10000

	-- round to nearest step (aligning to start)
	local timecode = round((timecode  - replay.timecodeStart) / timecodeStep) * timecodeStep + replay.timecodeStart

	-- determine end case
	local timecodeEnd = PixelToTimecode(x+w + 100)

	-- bit of protection incase scale goes crazy
	local steps = (timecodeEnd - timecode) / timecodeStep
	steps = math.floor(steps + 1)
	steps = math.min(100, steps)
	--consolePrint(steps)
	
	--while timecode < timecodeEnd do
	for i = 1, steps do
		local ix = TimecodeToPixel(timecode)
		nvgBeginPath();
		nvgMoveTo(ix, y);
		nvgLineTo(ix, y+10);
		nvgStroke();
	
		--local relativeTimecode = timecode - replay.timecodeStart
		--consolePrint(string.format("timecode: %d (%d) = pixel: %d", timecode, relativeTimecode, ix))
		
		local timeSinceStart = timecode - replay.timecodeStart
		local ms = timeSinceStart % 1000;
		timeSinceStart = math.floor(timeSinceStart / 1000);
		local seconds = timeSinceStart % 60;
		timeSinceStart = math.floor(timeSinceStart / 60);
		local minutes = timeSinceStart % 60;
		timeSinceStart = math.floor(timeSinceStart / 60);
		local hours = timeSinceStart % 60;
		timeSinceStart = math.floor(timeSinceStart / 60);
		local timeSinceStartFormatted = string.format("%02d:%02d:%02d:%03d", hours, minutes, seconds, ms);

		nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_TOP);
		nvgText(ix, iy+10, timeSinceStartFormatted);
	
		timecode = timecode + timecodeStep
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ReplayEditor:drawTimelineCut(keyStartIndex, keyEndIndex, iy, h)
	-- look up end timecode, comes from either next key, or end of replay if no next key
	timecodeEnd = replay.timecodeEnd
	if keyEndIndex ~= nil then
		timecodeEnd = replay.keys[keyEndIndex].timecode
	end
	
	keyStart = replay.keys[keyStartIndex]
	timecodeStart = keyStart.timecode

	local ix = TimecodeToPixel(timecodeStart)
	local iw = TimecodeToPixel(timecodeEnd) - ix

	local colBg = Color(232,232,232)
	colBg.r = (timecodeStart * 123) % 128 + 64
	colBg.g = (timecodeStart * 523) % 128 + 48
	colBg.b = (timecodeStart * 27) % 128 + 64

	local colEdge = Color(128,128,128)
	if timecodeStart <= replay.timecodeCurrent and replay.timecodeCurrent < timecodeEnd then
		colEdge.r = colEdge.r + 64
		colEdge.g = colEdge.g + 64
		colEdge.b = colEdge.b + 64
		colBg.r = colBg.r + 16
		colBg.g = colBg.g + 16
		colBg.b = colBg.b + 16
	end

	nvgSave()

	nvgBeginPath();
	nvgRect(ix, iy, iw, h);
	nvgFillColor(colBg);
	nvgFill();
	nvgStrokeColor(colEdge);
	nvgStroke();

	-- draw internal keys (if any)
	if keyEndIndex ~= nil then
		local keyIndex = keyStartIndex;
		while true do
			keyIndex = keyIndex + 1
			if keyIndex == keyEndIndex then break end
			local key = replay.keys[keyIndex]
			if key == nil then break end

			local timecode = key.timecode
			local ix = TimecodeToPixel(timecode)

			local colKey = Color(colEdge.r, colEdge.g, colEdge.b, 112)

			nvgBeginPath();
			nvgMoveTo(ix, iy)
			nvgLineTo(ix, iy+h)
			nvgStrokeColor(colKey);
			nvgStroke();
		end
	end
	
	nvgIntersectScissor(ix, iy, iw - 5, h);

	nvgFillColor(Color(232,232,232));
	nvgFontFace("TitilliumWeb-Bold");
	nvgFontSize(16)
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);

	-- header
	local header = ""
	if keyStart.entityIdAttachedTo > 0 then
		header = string.format("Attached To: %s (entity: %d)", keyStart.entityNameAttachedTo, keyStart.entityIdAttachedTo)
	end
	if keyStart.entityIdLookingTowards > 0 then
		if string.len(header) > 0 then
			header = header .. ", "
		end
		header = header .. string.format("Looking Towards: %s (entity: %d)", keyStart.entityNameLookingTowards, keyStart.entityIdLookingTowards)
	end
	nvgText(ix+5, iy+10, header);

	-- footer
	nvgFontFace("TitilliumWeb-Regular");
	nvgText(ix+5, iy+h-10, string.format("PosLerp %s, AngleLerp %s", keyStart.positionLerp, keyStart.angleLerp));

	nvgRestore()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ReplayEditor:drawFilmStrip(y, h)
	-- film background
	local ix = TimecodeToPixel(replay.timecodeStart)
	local iw = TimecodeToPixel(replay.timecodeEnd) - ix
	nvgBeginPath();
	nvgRoundedRect(ix, y, iw, h, 14);
	nvgFillColor(Color(48,48,48));
	nvgFill();

	-- film circles
	local timecode = PixelToTimecode(-viewport.width/2)
	local timecodeStep = 1000

	-- round to nearest step (aligning to start)
	local timecode = round((timecode - replay.timecodeStart) / timecodeStep) * timecodeStep + replay.timecodeStart + 650

	-- determine end case
	local timecodeEnd = PixelToTimecode(viewport.width/2 + 100)

	-- bit of protection incase scale goes crazy
	local steps = (timecodeEnd - timecode) / timecodeStep
	steps = math.floor(steps + 1)
	steps = math.min(100, steps)
	--consolePrint(steps)
	
	--while timecode < timecodeEnd do
	nvgFillColor(Color(34, 36, 40))
	for i = 1, steps do
		local ix = TimecodeToPixel(timecode)

		nvgBeginPath()
		nvgCircle(ix, y + 9, 5)
		nvgFill()

		nvgBeginPath()
		nvgCircle(ix, y + h - 9, 5)
		nvgFill()

		timecode = timecode + timecodeStep
	end

	if replay.isLoading then
		local endx = math.floor(ix + iw + 10)--TimecodeToPixel(timecodeEnd) + 10

		ui2FontSmall()
		nvgFillColor(Color(128,128,128))
		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
		nvgText(endx, y + h/2, "Loading..")
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ReplayEditor:drawTimeline(y)
	local w = viewport.width;
	local hFilm = 100;
	local x = -viewport.width/2;
	local optargs = {}
	local hRuler = 24
	local hPad = 5

	-- ruler top
	iy = y
	self:drawRulerTop(x, iy, w, hRuler)

	-- film strip
	self:drawFilmStrip(y, hFilm)

	-- draw "cuts" on top
	local keyStartIndex = 1
	local keyCount = 0
	for k, v in ipairs(replay.keys) do
		keyCount = keyCount + 1
	end
	for keyEndIndex = 2, keyCount do
		keyStart = replay.keys[keyStartIndex]
		keyEnd = replay.keys[keyEndIndex]

		if  keyStart.entityIdAttachedTo ~= keyEnd.entityIdAttachedTo or
			keyStart.entityIdLookingTowards ~= keyEnd.entityIdLookingTowards or
			keyStart.fovLerp ~= keyEnd.fovLerp or
			keyStart.angleLerp ~= keyEnd.angleLerp or
			keyStart.positionLerp ~= keyEnd.positionLerp then

			-- this key is different => new cut
			self:drawTimelineCut(keyStartIndex, keyEndIndex, iy+20, hFilm-40)
			keyStartIndex = keyEndIndex
		end
	end
	self:drawTimelineCut(keyStartIndex, nil, iy+20, hFilm-40)
	
	iy = iy + hFilm + hPad

	-- ruler bottom
	self:drawRulerBottom(x, iy, w, hRuler)

	-- cursor
	local ix = TimecodeToPixel(replay.timecodeCurrent)
	nvgBeginPath()
	nvgMoveTo(ix, y-5)
	nvgLineTo(ix, iy+5)
	nvgStrokeColor(Color(232,0,0))
	nvgStroke()

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ReplayEditor:drawToolbar()
	local w = viewport.width;
	local h = 240;
	local x = -viewport.width/2;
	local y = viewport.height/2 - h;
	local optargs = {}

	-- header / controls
	local toolbarHeight = viewport.height/2 - h
	local pad = 10
	local ix = x + pad
	local iy = y + pad
	local showY = y + pad
	local hideY = y + toolbarHeight - pad - 55
	local hideDuration = 0.1

	self.time = self.time + deltaTimeRaw;

	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	optargs.enabled = true;
	optargs.icon = ""
	optargs.iconSize = 11;
	optargs.nofont = true
	ui2FontSmall()

	local threshold = 0.95;
	
	-- s1 == current settings
	local s1 = {};
	s1.re_export_depth				= consoleGetVariable("re_export_depth");
	
	-- s2 = new settings
	local s2 = {};

	-- HIDE
	local durationHideTimeRemaining = 0;
	if (self.hideButtonPressTime > self.time) then
		durationHideTimeRemaining = (self.hideButtonPressTime - self.time) / hideDuration;
		--iy = lerp(hideY, showY, durationHideTimeRemaining);
		iy = LerpWithFunc(EaseInOut, durationHideTimeRemaining, iy, 0, 1, hideY, showY);

		if (iy >= (hideY*threshold)) then
			iy = hideY
			self.hidden = true
		end
	end

	-- SHOW
	local durationShowTimeRemaining = 0
	if (self.showButtonPressTime >= self.time) then
		durationShowTimeRemaining = (self.showButtonPressTime - self.time) / hideDuration;
		--iy = lerp(showY, hideY, durationShowTimeRemaining);
		iy = LerpWithFunc(EaseInOut, durationShowTimeRemaining, iy, 0, 1, showY, hideY);

		if (iy <= (showY*threshold)) then
			iy = showY
			self.hidden = false
		end
	end

	if (self.hidden == true) then
		iy = hideY
		optargs.icon = "internal/ui/icons/upArrow"
		if ui2Button("", x+w-40, iy-35, 40, 35, optargs) then
			self.showButtonPressTime = self.time + hideDuration
			self.hidden = false
		end
	else
		optargs.icon = "internal/ui/icons/downArrow"
		if ui2Button("", x+w-40, iy-35, 40, 35, optargs) then
			self.hideButtonPressTime = self.time + hideDuration
		end
	end

	optargs.icon = nil

	-- bg
	nvgBeginPath();
	nvgRect(x, iy, w, h);
	--nvgFillColor(Color(34, 36, 40, 242));
	nvgFillColor(Color(34, 36, 40, 255));
	nvgFill();

	-- edge	
	nvgBeginPath();
	nvgMoveTo(x, iy);
	nvgLineTo(x+w, iy);
	nvgStrokeColor(Color(100, 100, 100, 255));
	nvgStroke();

    iy = iy + pad

	-- timeline
	nvgSave();
	local ix = x + pad
	optargs.intensity = 0.5
	ix = ix + ui2Label("TIMELINE: ", ix, iy + 45, optargs) + pad
	self:drawTimeline(iy + 80)
	
	local key = bindReverseLookup("+editortimelinedrag", "re");
	local tip = string.format("Hold %s and drag mouse left/right to move cursor", string.upper(key))
	ui2TooltipBox(tip, ix-15, iy + 45, 500, optargs)
	optargs.intensity = 1.0
	nvgRestore();

	-- edit toggle
	local ix = x + pad
	ix = ix + ui2Label("MODE: ", ix, iy, optargs) + pad
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	local editText = replay.isEditing and "EDITING" or "WATCHING"
	if replay.isEditing then
		optargs.bgcoltype = UI2_COLTYPE_BUTTON_RED_REPLAYEDITOR;
	end
	if ui2Button(editText, ix, iy, 95, 35, optargs) then
		consolePerformCommand("re_edit_toggle")	
	end
	ix = ix + 95 + pad

	-- spacer
	nvgBeginPath();
	nvgMoveTo(ix, iy);
	nvgLineTo(ix, iy+35);
	nvgStrokeColor(Color(100, 100, 100, 255));
	nvgStroke();
	ix = ix + pad

	-- save
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	if ui2Button("SAVE", ix, iy, 60, 35, optargs) then
		consolePerformCommand("re_save")
	end
	ix = ix + 60 + pad

	-- spacer
	nvgBeginPath();
	nvgMoveTo(ix, iy);
	nvgLineTo(ix, iy+35);
	nvgStrokeColor(Color(100, 100, 100, 255));
	nvgStroke();
	ix = ix + pad

	-- replay controls

	ix = ix + ui2Label("REPLAY CONTROLS: ", ix, iy, optargs) + pad

	-- prev keyframe
	optargs.icon = "internal/ui/icons/prevKeyFrame"
	if ui2Button("", ix, iy, 35, 35, optargs) then
		consolePerformCommand("re_prev_keyframe")
	end
	ix = ix + 35 + pad
	
	-- prev frame
	optargs.icon = "internal/ui/icons/prevFrame"
	if ui2Button("", ix, iy, 35, 35, optargs) then
		consolePerformCommand("re_prev_frame")		
	end
	ix = ix + 35 + pad
	
	-- pause/play
	local c = ""
	if consoleGetVariable("re_speed") == 0 then
		optargs.icon = "internal/ui/icons/play"
		c = "re_speed 1"
	else
		optargs.icon = "internal/ui/icons/pause"
		c = "re_speed 0"
	end
	if ui2Button("", ix, iy, 35, 35, optargs) then
		consolePerformCommand(c)
	end
	ix = ix + 35 + pad
	
	-- next frame
	optargs.icon = "internal/ui/icons/nextFrame"
	if ui2Button("", ix, iy, 35, 35, optargs) then
		consolePerformCommand("re_next_frame")
	end
	ix = ix + 35 + pad
	
	-- next keyframe
	optargs.icon = "internal/ui/icons/nextKeyframe"
	if ui2Button("", ix, iy, 35, 35, optargs) then
		consolePerformCommand("re_next_keyframe")
	end
	ix = ix + 35 + pad
	optargs.icon = nil
	optargs.iconSize = nil;
	optargs.bgcoltype = nil;
	
	-- spacer
	nvgBeginPath();
	nvgMoveTo(ix, iy);
	nvgLineTo(ix, iy+35);
	nvgStrokeColor(Color(100, 100, 100, 255));
	nvgStroke();
	ix = ix + pad
	
	-- prev/next marker
	ix = ix + ui2Label("MARKERS: ", ix, iy, optargs) + pad

	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	if ui2Button("PREV", ix, iy, 60, 35, optargs) then
		consolePerformCommand("re_prev_marker")
	end
	ix = ix + 60 + pad

	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	if ui2Button("NEXT", ix, iy, 60, 35, optargs) then
		consolePerformCommand("re_next_marker")
	end
	ix = ix + 60 + pad

	-- spacer
	nvgBeginPath();
	nvgMoveTo(ix, iy);
	nvgLineTo(ix, iy+35);
	nvgStrokeColor(Color(100, 100, 100, 255));
	nvgStroke();
	ix = ix + pad

	-- keyframes
	ix = ix + ui2Label("EDIT KEYFRAMES: ", ix, iy, optargs) + pad

	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	if ui2Button("ADD", ix, iy, 50, 35, optargs) then
		consolePerformCommand("re_add_keyframe")
	end
	ix = ix + 50 + pad

	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	if ui2Button("DEL", ix, iy, 50, 35, optargs) then
		consolePerformCommand("re_remove_keyframe")
	end
	ix = ix + 50 + pad

	-- set positions and angles
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	local localPlayer = getLocalPlayer()
	if ui2Button("UPDATE", ix, iy, 70, 35, optargs) then
		local angles = camera.anglesDegrees
		consolePerformCommand(("re_set_angle %f %f %f"):format(angles.x, angles.y, angles.z))
		local position = camera.position
		consolePerformCommand(("re_set_position %f %f %f"):format(position.x, position.y, position.z))
	end
	ix = ix + 70 + pad

	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	if ui2Button("0 ROLL", ix, iy, 60, 35, optargs) then
		consolePerformCommand("re_zero_roll")
	end
	ix = ix + 60 + pad

	-- reset camera angles hack fix for fil <3
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	if ui2Button("RESET", ix, iy, 70, 35, optargs) then
		local angles = camera.anglesDegrees
		consolePerformCommand("re_set_angle 0 0 0")
	end
	ix = ix + 70 + pad

	-- spacer
	nvgBeginPath();
	nvgMoveTo(ix, iy);
	nvgLineTo(ix, iy+35);
	nvgStrokeColor(Color(100, 100, 100, 255));
	nvgStroke();
	local ix_Players = ix;
	ix = ix + pad

	-- combo: player list
	local playerListPopulated = {};

	for k, player in pairs(players) do
		if player.connected and player.state == PLAYER_STATE_INGAME then
			playerListPopulated[k] = player.name
		end
	end

	if self.comboBoxDataplayerListSelected == nil and playerListPopulated[1] ~= nil then
		self.comboBoxDataplayerListSelected = playerListPopulated[1]
	end
	
	ui2Label("PLAYERS:", ix, iy, optargs);
	ix = ix + 75
 	local playerListComboX = ix;
 	local playerListComboY = iy;
 	local playerListComboWidth = 175

 	ix = ix + playerListComboWidth + pad

 	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	optargs.enabled = self.comboBoxDataplayerListSelected ~= nil
	if ui2Button("ATTACH", ix, iy, 70, 35, optargs) then
		for k, player in pairs(players) do
			if (player.name == self.comboBoxDataplayerListSelected) then
				consolePerformCommand(("re_set_player_attached_to %d"):format(k-1))
				break
			end
		end
	end
	optargs.enabled = true
	ix = ix + 70 + pad

	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	if ui2Button("DETACH", ix, iy, 70, 35, optargs) then
		consolePerformCommand("re_set_player_attached_to")
	end
	ix = ix + 70 + pad
	
	-- move down
	local ix = ix_Players;
	local iy = iy + 40

	-- spacer
	nvgBeginPath();
	nvgMoveTo(ix, iy);
	nvgLineTo(ix, iy+35);
	nvgStrokeColor(Color(100, 100, 100, 255));
	nvgStroke();
	ix = ix + pad

	ix = ix + ui2Label("EXPORT:", ix, iy, optargs) + 11;

	-- exporting
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	optargs.enabled = self.comboBoxDataExportSecondsListSelected ~= nil
	if ui2Button("START", ix, iy, 70, 35, optargs) then
		consolePerformCommand(("re_export %d"):format(self.comboBoxDataExportSecondsListSelected))
	end
	optargs.enabled = nil
	ix = ix + 77
	
	ix = ix + ui2Label("SECONDS: ", ix, iy, optargs) + 4
	local exportSecondsComboX = ix;
 	local exportSecondsComboY = iy;
 	local exportSecondsComboWidth = 73;
	ix = ix + exportSecondsComboWidth + 8

	ix = ix + ui2Label("DEPTH: ", ix, iy, optargs) + 4
	s2.re_export_depth = ui2CheckBox(s1.re_export_depth ~= 0, ix, iy, optargs) and 1 or 0;

	-- combo: export seconds amount
 	optargs.enabled = true;	
	local exportSecondsOptions = { "5", "10", "30", "60", "300", "600", "900" };
	if self.comboBoxDataExportSecondsListSelected == nil then
		self.comboBoxDataExportSecondsListSelected = exportSecondsOptions[1]
	end
	self.comboBoxDataExportSecondsListSelected = ui2ComboBox(exportSecondsOptions, self.comboBoxDataExportSecondsListSelected, exportSecondsComboX, exportSecondsComboY, exportSecondsComboWidth, self.comboBoxDataExportSecondsList, optargs);
	
	-- combo: select player
 	optargs.enabled = true;
 	local playerListUi = ui2ComboBox(playerListPopulated, self.comboBoxDataplayerListSelected, playerListComboX, playerListComboY, playerListComboWidth, self.comboBoxDataplayerList, optargs);
 	self.comboBoxDataplayerListSelected = playerListUi

	-- apply new settings (if anything has changed)
	applySettingsTable(s2, s1);
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ReplayEditor:draw()
	-- only display when in replay mode
    if not replayActive or isInMenu() or replayName == "menu" then
		self.showOnScreen = true
		return
	end
	if not self.showOnScreen then
		return
	end
	if (replay.isExporting) then
		return
	end
	--if not shouldShowHUD() then return end;
    if	loading.loadScreenVisible or consoleGetVariable("cl_show_hud") == 0 then
		return false;
	end
	
	UpdateOffset()

	self:drawToolbar()
end
