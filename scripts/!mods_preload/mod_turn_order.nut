::TurnOrderNumbers <- {
	ID = "mod_turn_order",
	Name = "Turn Order Numbers",
	Version = "1.0.2",
	NumbersColorPlayer = null,
	NumbersColorAllies = null,
	NumbersColorEnemies = null,
	NumbersColorHover = null,
	NumbersEnabledState = true,
	function ToggleNumbersState()
	{
		this.NumbersEnabledState = !this.NumbersEnabledState;
		this.Tactical.TurnSequenceBar.updateTurnOrderNumbers();
		this.Tactical.TurnSequenceBar.updateTurnBarNumbers();
	}
	function GetValueAsHexString(_array)
	{
		local asArray = split(_array, ",");
		local red = format("%x", asArray[0].tointeger());
		if (asArray[0].tointeger() < 10) red = "0" + red;
		local green = format("%x", asArray[1].tointeger());
		if (asArray[1].tointeger() < 10) green = "0" + green;
		local blue = format("%x", asArray[2].tointeger());
		if (asArray[2].tointeger() < 10) blue = "0" + blue;
		local opacity = asArray[3] == "0.0" ? "00" : format("%x", (asArray[3].tofloat() * 255).tointeger());
		return  red + green + blue + opacity;
	}
}
::mods_registerMod(::TurnOrderNumbers.ID, ::TurnOrderNumbers.Version)

::mods_queue(::TurnOrderNumbers.ID, "mod_msu", function()
{
	::TurnOrderNumbers.Mod <- ::MSU.Class.Mod(::TurnOrderNumbers.ID, ::TurnOrderNumbers.Version, ::TurnOrderNumbers.Name);
	::TurnOrderNumbers.Mod.Keybinds.addSQKeybind("ToggleNumbers", "n", ::MSU.Key.State.Tactical, function(){
		::TurnOrderNumbers.ToggleNumbersState();
	}, "Enable or disable turn order numbers.");

	local callback = function(_newVal)
	{
		::TurnOrderNumbers[this.getID()] = this.createColor(::TurnOrderNumbers.GetValueAsHexString(_newVal));
		if (this.Tactical.isVisible())
		{
			this.Tactical.TurnSequenceBar.updateTurnOrderNumbers();
			this.Tactical.TurnSequenceBar.updateTurnBarNumbers();
		}
	}
	local generalPage = ::TurnOrderNumbers.Mod.ModSettings.addPage("General");
	local playerColor = "221,162,31,1.0";
	local allyColor = "221,162,31,1.0";
	local enemyColor =  "248,120,31,1.0";
	local hoverColor = "255,0,0,1.0";

	local playerColorSetting = generalPage.addColorPickerSetting("NumbersColorPlayer", playerColor, "Color of player numbers");
	playerColorSetting.addCallback(callback);
	::TurnOrderNumbers.NumbersColorPlayer = this.createColor(::TurnOrderNumbers.GetValueAsHexString(playerColor));

	local allyColorSetting = generalPage.addColorPickerSetting("NumbersColorAllies", allyColor, "Color of ally numbers");
	allyColorSetting.addCallback(callback);
	::TurnOrderNumbers.NumbersColorAllies = this.createColor(::TurnOrderNumbers.GetValueAsHexString(allyColor));

	local enemyColorSetting = generalPage.addColorPickerSetting("NumbersColorEnemies", enemyColor, "Color of enemy numbers");
	enemyColorSetting.addCallback(callback);
	::TurnOrderNumbers.NumbersColorEnemies = this.createColor(::TurnOrderNumbers.GetValueAsHexString(enemyColor));

	local scaleNumbersSetting = generalPage.addBooleanSetting("ScaleNumbers", true, "Increase size of lower numbers");
	scaleNumbersSetting.setDescription("Smaller numbers will be bigger than bigger numbers to increase visibility of those entities who will act soon.");
	scaleNumbersSetting.addCallback(function(_){
		if (this.Tactical.isVisible())
		{
			this.Tactical.TurnSequenceBar.updateTurnOrderNumbers();
			this.Tactical.TurnSequenceBar.updateTurnBarNumbers();
		}
	});

	generalPage.addDivider("1");
	local hoverNumberSetting = generalPage.addBooleanSetting("HoverNumbers", true, "Only show lower numbers on hover");
	hoverNumberSetting.setDescription("When hovering over an entity, only those other entities who will act before it will have a number over their heads.")

	local hoverColorSetting = generalPage.addColorPickerSetting("NumbersColorHover", hoverColor, "Hover color.");
	hoverColorSetting.setDescription("When hovering over an entity, this is the color of the entities coming after it.");
	hoverColorSetting.addCallback(callback);
	::TurnOrderNumbers.NumbersColorHover = this.createColor(::TurnOrderNumbers.GetValueAsHexString(hoverColor));


	::mods_hookExactClass("ui/screens/tactical/modules/turn_sequence_bar/turn_sequence_bar", function(o)
	{
		o.updateTurnOrderNumbers <- function()
		{
			local hoveredEntityTurns = this.Tooltip.m.CurrentHoveredEntityId != null ?  this.Tactical.TurnSequenceBar.getTurnsUntilActive(this.Tooltip.m.CurrentHoveredEntityId) : null;

			foreach(entity in this.getAllEntities())
			{
				if (!entity.hasSprite("number_left"))
				{
					entity.addSprite("number_left");
					entity.setSpriteOffset("number_left", this.createVec(-10, 70))
					entity.getSprite("number_left").Scale = 0.3;

				}

				if (!entity.hasSprite("number_right"))
				{
					entity.addSprite("number_right");
					entity.setSpriteOffset("number_right", this.createVec(10, 70))
					entity.getSprite("number_right").Scale = 0.3;
				}
				entity.getSprite("number_left").Visible = false;
				entity.getSprite("number_right").Visible = false;
				entity.setSpriteColorization("number_left", true);
				entity.setSpriteColorization("number_right", true);

			}

			if (::TurnOrderNumbers.NumbersEnabledState == false)
				return;

			foreach(idx, entity in this.getCurrentEntities())
			{
				local altIdx = idx > 99 ? 99 : idx;
				if (altIdx == 0)
					continue


				local color = ::TurnOrderNumbers.NumbersColorEnemies;
				if (hoveredEntityTurns != null && altIdx > hoveredEntityTurns && ::TurnOrderNumbers.Mod.ModSettings.getSetting("HoverNumbers").getValue())
					color = ::TurnOrderNumbers.NumbersColorHover;
				else if (entity.isPlayerControlled())
					color = ::TurnOrderNumbers.NumbersColorPlayer;
				else if (entity.isAlliedWithPlayer())
					color = ::TurnOrderNumbers.NumbersColorAllies;

				local leftSprite = entity.getSprite("number_left");
				local rightSprite = entity.getSprite("number_right");

				local idxAsString = altIdx.tostring();
				local left = altIdx > 9 ? idxAsString[0] : null;
				local right = altIdx > 9 ? idxAsString[1] : idxAsString[0];


				if (left != null)
				{
					leftSprite.setBrush(format("turnnumber_number_%s", left.tochar()));
					leftSprite.Color = color;
					leftSprite.Visible = true;
				}
				rightSprite.setBrush(format("turnnumber_number_%s", right.tochar()));
				rightSprite.Color = color;
				rightSprite.Visible = true;

				// decreasing scale
				local scale = 0.3;
				if (::TurnOrderNumbers.Mod.ModSettings.getSetting("ScaleNumbers").getValue())
					scale = ::Math.maxf(0.25, 0.4 - (0.01*altIdx));
				rightSprite.Scale = scale;
				leftSprite.Scale = scale;
			}
		}

		o.updateTurnBarNumbers <- function()
		{
			foreach(entity in this.getAllEntities())
			{
				entity.setDirty(true);
			}
		}

		local initNextTurn = o.initNextTurn;
		o.initNextTurn = function(_force = false)
		{
			initNextTurn(_force);
			this.updateTurnOrderNumbers();
		}
	})

	::mods_hookNewObject("ui/screens/tooltip/modules/tooltip", function(o)
	{
		local mouseEnterTile = o.mouseEnterTile;
		o.mouseEnterTile = function(_x, _y, _entityId = null)
		{
			mouseEnterTile(_x, _y, _entityId);
			if (this.Tactical.isVisible() && ::TurnOrderNumbers.Mod.ModSettings.getSetting("HoverNumbers").getValue())
				this.Tactical.TurnSequenceBar.updateTurnOrderNumbers();
		}
	})
})

