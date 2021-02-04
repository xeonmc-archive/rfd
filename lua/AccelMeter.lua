require "base/internal/ui/reflexcore"

AccelMeter =
{
  -- user data, we'll save this into engine so it's persistent across loads
  userData = {}
};
registerWidget("AccelMeter");

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function AccelMeter:initialize()
  -- load data stored in engine
  self.userData = loadUserData();
  
  -- ensure it has what we need
  CheckSetDefaultValue(self, "userData", "table", {});
  CheckSetDefaultValue(self.userData, "raceModeToggle", "boolean", false);
  CheckSetDefaultValue(self.userData, "trainingModeToggle", "boolean", false);
  CheckSetDefaultValue(self.userData, "hideDot", "boolean", false);
  CheckSetDefaultValue(self.userData, "innerDiameter", "number", 78);
  CheckSetDefaultValue(self.userData, "cjSpeed", "number", 390);
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function AccelMeter:drawOptions(x, y, intensity)
  local optargs = {};
  optargs.intensity = intensity;

  local user = self.userData;

  user.raceModeToggle = ui2RowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Race Mode Only", user.raceModeToggle, optargs);
  y = y + 60;

  user.trainingModeToggle = ui2RowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Training Mode Only", user.trainingModeToggle, optargs);
  y = y + 60;

  user.hideDot = ui2RowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Hide Dot", user.hideDot, optargs);
  y = y + 60;

  user.innerDiameter = ui2RowSliderEditBox0Decimals(x, y, WIDGET_PROPERTIES_COL_INDENT, WIDGET_PROPERTIES_COL_WIDTH, 80, "Inner Diameter", user.innerDiameter, 50, 100, optargs);
  y = y + 60;

  user.cjSpeed = ui2RowSliderEditBox0Decimals(x, y, WIDGET_PROPERTIES_COL_INDENT, WIDGET_PROPERTIES_COL_WIDTH, 80, "Circlejump Takeoff Speed", user.cjSpeed, 320, 500, optargs);
  y = y + 60;

  saveUserData(user);

end
-------------------------------------------------------------------------
-- Vector2D Class --
-------------------------------------------------------------------------

local Vector2D = {}
Vector2D.__index = Vector2D

function ColorA(color, alpha)
	return Color(color.r, color.g, color.b, alpha);
end

function Vector2D.new(x, y)
  local self = setmetatable({}, Vector2D)
  self.x = x or 0
  self.y = y or 0
  return self
end

function Vector2D:update(x, y)
  self.x = x or self.x
  self.y = y or self.y
end

function Vector2D:size()
  return math.sqrt(self.x*self.x + self.y*self.y)
end

function Vector2D:rotate(ang)
  local x = self.x
  local y = self.y
  self.x = x*math.cos(ang) - y*math.sin(ang)
  self.y = x*math.sin(ang) + y*math.cos(ang)
end

function Vector2D:dotProduct(vec2)
  assert(type(vec2) == "table", "vec2 must be a table")
  assert(type(vec2.x) ~= "nil", "vec2 must have an x value")
  assert(type(vec2.y) ~= "nil", "vec2 must have an y value")
  return (self.x*vec2.x)+(self.y*vec2.y)
end

-------------------------------------------------------------------------
-------------------------------------------------------------------------

local function make_buffer(frames)
    local array = {}
    for i=1,frames do
      array[i] = 0
    end
    return array
end

local function rolling_average(index,array,frames)
    local length = # array
    local weight = 1
    local sum = array[index]*weight
    local j = math.max(frames-1,1)
    local ctr = index-1
    for i=1,j do
        if ctr<1 then ctr = ctr + length end
        sum = sum + array[ctr]
        ctr = ctr - 1
    end
    return sum/(j+weight)
end

local outerRadius, innerRadius, outerSQRT, innerSQRT, cjSpeed, lastVertSpeed
local bufferLength = 100
local bufferIndex = 1
local bufferTime = 0.1
local effBuffer = make_buffer(bufferLength)


function AccelMeter:draw()

  local user = self.userData;

  if (user == nil) then return end

  if not shouldShowHUD() then return end

  if not isRaceMode() then
    if (user.raceModeToggle == true) then
      return
    end
  end

  if not isTrainingMode() then
    if (user.trainingModeToggle == true) then
      return
    end
  end

  local hideDot = false
  if (user.hideDot == true) then
     hideDot = true
  end

  local localPl = getLocalPlayer()
  local specPl = getPlayer()
  local xkey = 0
  local ykey = 0
  local zkey = 0
  
  if specPl.buttons.right   then xkey = xkey+1 end
  if specPl.buttons.left    then xkey = xkey-1 end
  if specPl.buttons.back    then ykey = ykey+1 end
  if specPl.buttons.forward then ykey = ykey-1 end
  if specPl.buttons.jump    then zkey = zkey+1 end
  if specPl.buttons.crouch  then zkey = zkey-1 end
  local keynorm     = xkey*xkey + ykey*ykey
  local yawCartRad  = math.rad(90 - specPl.anglesDegrees.x)
  local accelVector = Vector2D.new(-ykey, -xkey)
        accelVector:rotate(yawCartRad)
  local playerSpeed = Vector2D.new(specPl.velocity.x, specPl.velocity.z)
  local vertSpeed   = specPl.velocity.y
  local mom_ang     = math.rad(specPl.anglesDegrees.x) - math.atan2(playerSpeed.x, playerSpeed.y)
  local playerups   = playerSpeed:size()

  if innerRadius ~= user.innerDiameter and user.innerDiameter ~= nil then
     outerRadius  = 75
     innerRadius  = outerRadius*user.innerDiameter/100
     outerSQRT    = 75/math.sqrt(2)
     innerSQRT    = outerRadius*user.innerDiameter/math.sqrt(2)/100
  end
  if user.cjSpeed ~= nil then cjSpeed = user.cjSpeed end
  if cjSpeed <= 0 then cjSpeed = 400 end

  -- wasd positions
  local outerX = outerRadius
  local outerY = outerRadius
  local innerX = innerRadius
  local innerY = innerRadius
  if keynorm == 2 then
     outerX = outerSQRT
     outerY = outerSQRT
     innerX = innerSQRT
     innerY = innerSQRT
  end
  outerX = outerX*xkey
  outerY = outerY*ykey
  innerX = innerX*xkey
  innerY = innerY*ykey



  local tickrate  = 125
  local baseSpeed = 320
  local baseAccel = 320

  -- wall positions
  local wallRadius = 0
  local wallDepth = outerRadius
  local wallCosine = 1
  local wallSine = 0
  local hasMom = 0
  local isCJ = false
  if playerups>0 then
    hasMom = 1
    wallCosine = math.cos(mom_ang)
    wallSine = math.sin(mom_ang)
    if playerups>baseSpeed then
      wallDepth = outerRadius*baseSpeed/playerups
      wallRadius = math.sqrt(outerRadius*outerRadius - wallDepth*wallDepth)
      if vertSpeed==0 and lastVertSpeed<=0 then isCJ = true end
    end
  end
  lastVertSpeed = vertSpeed

  -- efficiency calculation
  local tickAcc = baseAccel
  local dot = 0
  local efficiency = 0
  local power = 0
  if keynorm > 0 then 
    dot = accelVector:dotProduct(playerSpeed) / math.sqrt(keynorm)
    efficiency = dot / playerups
    if (dot>0) and (playerups>baseSpeed) then 
      tickAcc = tickrate * playerups * math.max(0, baseSpeed/dot-1)
      power = math.min(dot*baseAccel , tickrate*playerups*math.max(0, baseSpeed-dot))
      efficiency = power / baseAccel / baseSpeed
      effBuffer[bufferIndex] = efficiency
      if (deltaTimeRaw>0) and (tickAcc<=baseAccel or efficiency>0.99) then efficiency = rolling_average(bufferIndex, effBuffer, bufferTime/deltaTimeRaw) end
      bufferIndex = bufferIndex + 1
      if (bufferIndex>bufferLength) then bufferIndex = bufferIndex - bufferLength end
    end
  end

  -- throttle colour
  local effRed = 255
  local effGreen = 255
  local effBlue = 255
  local backopa = 40
  local cjopa = 0
  local ringColor = Color(0, 0, 0, 64)
  if math.floor(playerups) > baseSpeed then
     if efficiency<0 then 
       effRed = 255
       effGreen = 0
       effBlue = 0
     elseif tickAcc>baseAccel then
       effRed = math.min(255,math.max(0,255-255*efficiency*efficiency))
       effGreen = 255
       effBlue = math.min(255,math.max(0,255*efficiency))
     else
       effRed = math.min(255,math.max(0,255-255*efficiency*efficiency))
       effGreen = 255
       effBlue = 255
     end
     if isCJ then 
       cjopa = (playerups-baseSpeed)/(cjSpeed-baseSpeed)
       if cjopa >= 1 then
          cjopa = 1
          ringColor = Color(255, 255, 255, 64)
       end
       cjopa = 80*cjopa
     end
  else
    backopa = backopa * playerups/320
  end


  ----------------------
  -- Efficiency, Speed, and Keypress Display
  ----------------------

  local upArrowIcon = "internal/ui/icons/keyForward"
  local downArrowIcon = "internal/ui/icons/keyBack"

  nvgFontSize(36);
  nvgFontFace("TitilliumWeb-Bold");
  nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
  nvgFontBlur(0);
  nvgFillColor(Color(effRed, effGreen, effBlue, 192));
  nvgText(0, -outerRadius/2, math.floor(efficiency*100+0.5) .. "%");

  nvgFontSize(36);
  nvgFontFace("TitilliumWeb-Bold");
  nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
  nvgFontBlur(0);
  nvgFillColor(Color(effRed, effGreen, effBlue, 192));
  nvgText(0, outerRadius/2, "ups");

  nvgFontSize(80);
  nvgFontFace("TitilliumWeb-Bold");
  nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
  nvgFontBlur(0);
  nvgFillColor(Color(effRed, effGreen, effBlue, 192));
  nvgText(0, 0, math.floor(playerups+0.5));

  if zkey>0 then
    nvgFillColor(Color(255, 255, 255, 80));
    nvgSvg(upArrowIcon, outerRadius-4, 4-outerRadius, 8);
  elseif zkey<0 then
    nvgFillColor(Color(255, 255, 255, 80));
    nvgSvg(downArrowIcon, outerRadius-4, 4-outerRadius, 8);
  end

  if isCJ then
    nvgFontSize(36);
    nvgFontFace("TitilliumWeb-Bold");
    nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_BASELINE);
    nvgFontBlur(0);
    nvgFillColor(Color(255, 255, 255, cjopa));
    nvgText(outerRadius-4, outerRadius-4, "CJ");
  end
  ----------------------
  -- Static Background
  ----------------------

  nvgBeginPath()
  nvgMoveTo(0, -outerRadius)
  nvgLineTo(0, -innerRadius)
  nvgStrokeWidth(3)
  nvgStrokeColor(ringColor)
  nvgStroke()

  nvgBeginPath()
  nvgMoveTo(outerSQRT, -outerSQRT)
  nvgLineTo(innerSQRT, -innerSQRT)
  nvgStrokeWidth(3)
  nvgStrokeColor(ringColor)
  nvgStroke()

  nvgBeginPath()
  nvgMoveTo(outerRadius, 0)
  nvgLineTo(innerRadius, 0)
  nvgStrokeWidth(3)
  nvgStrokeColor(ringColor)
  nvgStroke()

  nvgBeginPath()
  nvgMoveTo(outerSQRT, outerSQRT)
  nvgLineTo(innerSQRT, innerSQRT)
  nvgStrokeWidth(3)
  nvgStrokeColor(ringColor)
  nvgStroke()

  nvgBeginPath()
  nvgMoveTo(0, outerRadius)
  nvgLineTo(0, innerRadius)
  nvgStrokeWidth(3)
  nvgStrokeColor(ringColor)
  nvgStroke()

  nvgBeginPath()
  nvgMoveTo(-outerSQRT, outerSQRT)
  nvgLineTo(-innerSQRT, innerSQRT)
  nvgStrokeWidth(3)
  nvgStrokeColor(ringColor)
  nvgStroke()

  nvgBeginPath()
  nvgMoveTo(-outerRadius, 0)
  nvgLineTo(-innerRadius, 0)
  nvgStrokeWidth(3)
  nvgStrokeColor(ringColor)
  nvgStroke()

  nvgBeginPath()
  nvgMoveTo(-outerSQRT, -outerSQRT)
  nvgLineTo(-innerSQRT, -innerSQRT)
  nvgStrokeWidth(3)
  nvgStrokeColor(ringColor)
  nvgStroke()

  nvgBeginPath()
  nvgCircle(0, 0, outerRadius)
  nvgStrokeWidth(3)
  nvgStrokeColor(ringColor)
  nvgStroke()

  ----------------------
  -- Lines
  ----------------------

  if hasMom == 1 then

    nvgBeginPath()
    nvgMoveTo( wallCosine*outerRadius, -wallSine*outerRadius )
    nvgLineTo(-wallCosine*outerRadius,  wallSine*outerRadius )
    nvgStrokeWidth(3)
    nvgStrokeColor(Color(255, 255, 255, backopa))
    nvgStroke()

    nvgBeginPath()
    nvgMoveTo(0, 0)
    nvgLineTo(innerX, innerY)
    nvgStrokeWidth(3)
    nvgStrokeColor(Color(0, 0, 0, 64))
    nvgStroke()

    nvgBeginPath()
    nvgMoveTo( wallCosine*( wallRadius) + wallSine*(-wallDepth), wallCosine*(-wallDepth) - wallSine*( wallRadius) )
    nvgLineTo( wallCosine*(-wallRadius) + wallSine*(-wallDepth), wallCosine*(-wallDepth) - wallSine*(-wallRadius) )
    nvgStrokeWidth(2)
    nvgStrokeColor(Color(255, 255, 255, 192*hasMom))
    nvgStroke()

    nvgBeginPath()
    nvgMoveTo(0, 0)
    if hideDot == true then
       nvgLineTo(outerX*math.abs(efficiency), outerY*math.abs(efficiency))
    else
       nvgLineTo(outerX, outerY)
    end
    nvgStrokeWidth(2)
    nvgStrokeColor(Color(effRed, effGreen, effBlue, 192))
    nvgStroke()
  end

  if (hideDot ~= true) then
    nvgBeginPath()
    nvgCircle(outerX*math.abs(efficiency), outerY*math.abs(efficiency), outerRadius*0.08)
    nvgStrokeWidth(1)
    nvgStrokeColor(Color(0, 0, 0, 154))
    nvgStroke()
    nvgFillColor(Color(effRed, effGreen, effBlue, 128))
    nvgFill()
  end

  if hasMom == 1 then

    nvgRotate(-mom_ang);
    nvgFontSize(36);
    nvgFontFace("TitilliumWeb-Bold");
    nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
    nvgFontBlur(0);
    nvgFillColor(Color(255, 255, 255, backopa*2));
    nvgText(0, -outerRadius, "^");

  end
end
