--------------------------------------------------------------------------------
-- This is an official Reflex script. Do not modify.
--
-- If you wish to customize this widget, please:
--  * clone this file to a new file
--  * rename the widget MyWidget
--  * set this widget to not visible (via options menu)
--  * set your new widget to visible (via options menu)
--
--------------------------------------------------------------------------------

require "base/internal/ui/reflexcore"

WeaponRack =
{
	-- user data, we'll save this into engine so it's persistent across loads
	userData = {};
};
registerWidget("WeaponRack");

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function WeaponRack:initialize()
	-- load data stored in engine
	self.userData = loadUserData();
	
	-- ensure it has what we need
	CheckSetDefaultValue(self, "userData", "table", {});
	CheckSetDefaultValue(self.userData, "weaponRackVertical", "boolean", false);
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function WeaponRack:finalize()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function WeaponRack:draw()

    -- Early out if HUD shouldn't be shown.
    if not shouldShowHUD() then return end;
	if isRaceMode() then return end;

	local translucency = 192;
	
   	-- Find player
	local player = getPlayer();

    local weaponCount = 0;
	for k, v in ipairs(weaponDefinitions) do
		weaponCount = weaponCount + 1;
	end
    local spaceCount = weaponCount - 1;
    
    -- Options
    local verticalRack = self.userData.weaponRackVertical;
    local weaponWidth = 100;
    local weaponHeight = 30;
    local weaponSpacing = 5; -- 0 or -1 to remove spacing
    
    -- Helpers
    local rackWidth = (weaponWidth * weaponCount) + (weaponSpacing * spaceCount);
    local rackLeft = -(rackWidth / 2);
    local weaponX = rackLeft;
    local weaponY = 0;

    if verticalRack == true then
        rackHeight = (weaponHeight * weaponCount) + (weaponSpacing * spaceCount);
        rackTop = -(rackHeight / 2);
        weaponX = 0;
        weaponY = rackTop;
    end

    for weaponIndex = 1, weaponCount do

        local weapon = player.weapons[weaponIndex];
        local weaponDef = weaponDefinitions[weaponIndex];
		local color = Color(weaponDef.color.r, weaponDef.color.g, weaponDef.color.b, weaponDef.color.a);
    
		-- if we havent picked up the weapon, colour it grey
		if not weapon.pickedup then
			color.r = 128;
			color.g = 128;
			color.b = 128;
		end

        local backgroundColor = Color(0,0,0,65);

		local percentageAmmo = 1;
		if weaponDef.maxAmmo > 0 then
			percentageAmmo = weapon.ammo / weaponDef.maxAmmo;
		end

        -- Frame background
        nvgBeginPath();
        nvgRect(weaponX,weaponY,weaponWidth,weaponHeight);
        nvgFillColor(backgroundColor);
        nvgFill();
        
        -- Frame background
       -- nvgBeginPath();
        --nvgRect(weaponX,weaponY,weaponWidth*percentageAmmo,weaponHeight);

        if weaponIndex == player.weaponIndexSelected then 
            backgroundColor.r = lerp(backgroundColor.r, color.r, player.weaponSelectionIntensity);
            backgroundColor.g = lerp(backgroundColor.g, color.g, player.weaponSelectionIntensity);
            backgroundColor.b = lerp(backgroundColor.b, color.b, player.weaponSelectionIntensity);
            backgroundColor.a = lerp(backgroundColor.a, 128, player.weaponSelectionIntensity);

			local outlineColor = Color(
				color.r,
				color.g,
                color.b,
				lerp(0, 255, player.weaponSelectionIntensity));
				
			nvgBeginPath();
			nvgRect(weaponX,weaponY,weaponWidth,weaponHeight);
            nvgStrokeWidth(2);
            nvgStrokeColor(outlineColor);
            nvgStroke();
        end
		
        nvgBeginPath();
        nvgRect(weaponX,weaponY,weaponWidth*percentageAmmo,weaponHeight);
        nvgFillColor(backgroundColor);
        nvgFill();

        -- Icon
	    local iconRadius = weaponHeight * 0.40;
        local iconX = weaponX + (weaponHeight - iconRadius);
        local iconY = (weaponHeight / 2);
        local iconColor = color;

        if verticalRack == true then
            iconX = weaponX + iconRadius + 5;
            iconY = weaponY + (weaponHeight / 2);
        end

        if weaponIndex == player.weaponIndexSelected then 
			iconColor.r = lerp(iconColor.r, 255, player.weaponSelectionIntensity);
			iconColor.g = lerp(iconColor.g, 255, player.weaponSelectionIntensity);
			iconColor.b = lerp(iconColor.b, 255, player.weaponSelectionIntensity);
			iconColor.a = lerp(iconColor.a, 255, player.weaponSelectionIntensity);
		end
        
        local svgName = "internal/ui/icons/weapon"..weaponIndex;
		if (weaponIndex == 1) and (player.inventoryMelee ~= nil) then
			local def = inventoryDefinitions[player.inventoryMelee];
			if def ~= nil then
				svgName = def.asset;
			end
		end

		nvgFillColor(iconColor);
	    nvgSvg(svgName, iconX, iconY, iconRadius);

        -- Ammo
	    local ammoX = weaponX + (iconRadius) + (weaponWidth / 2);
        local ammoCount = player.weapons[weaponIndex].ammo;
	local weaponKey = FirstToUpper(bindReverseLookup("weapon " .. weaponIndex, "game"));

        if verticalRack == true then
            ammoX = weaponX + (weaponWidth / 2) + iconRadius;
        end

        if weaponIndex == 1 then ammoCount = "-" end

        nvgFontSize(30);
        --nvgFontFace("oswald-bold");
        nvgFontFace("TitilliumWeb-Bold");
	    nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_TOP);

	    nvgFontBlur(0);
	    nvgFillColor(Color(255,255,255));
	    nvgText(ammoX, weaponY, ammoCount);

        nvgFontSize(25);
        --nvgFontFace("oswald-bold");
        nvgFontFace("TitilliumWeb-Bold");
	    nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_BASELINE);

	    nvgFontBlur(0);
	    nvgFillColor(Color(255,255,255));
	    nvgText(weaponX+weaponWidth, weaponY+weaponHeight-(iconRadius/4), weaponKey);
        
        if verticalRack == true then
            weaponY = weaponY + weaponHeight + weaponSpacing;
        else
            weaponX = weaponX + weaponWidth + weaponSpacing;
        end
       
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function WeaponRack:drawOptions(x, y, intensity)
	local optargs = {};
	optargs.intensity = intensity;

	local user = self.userData;
	
	user.weaponRackVertical = ui2RowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Vertical Rack", user.weaponRackVertical, optargs);
	y = y + 60;

	saveUserData(user);
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function WeaponRack:getOptionsHeight()
	return 60; -- debug with: ui_menu_show_widget_properties_height 1
end
