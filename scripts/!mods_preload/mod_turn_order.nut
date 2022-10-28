::TurnOrderNumbers <- {
	ID = "mod_turn_order",
	Name = "Turn Order Numbers",
	Version = "1.0.4",
	NumbersColorPlayer = null,
	NumbersColorAllies = null,
	NumbersColorEnemies = null,
	NumbersColorHover = null,
	function UpdateNumbers(_ = null)
	{
		if (this.Tactical.isVisible())
			this.Tactical.TurnSequenceBar.updateTurnOrderNumbers();
	}
	function getNumbersEnabledState()
	{
		return this.Mod.ModSettings.getSetting("EnabledState").getValue();
	}
	function GetValueAsHexString(_array)
	{
		local asArray = split(_array, ",");
		local red = format("%x", asArray[0].tointeger());
		local green = format("%x", asArray[1].tointeger());
		local blue = format("%x", asArray[2].tointeger());
		local opacity = format("%x", (asArray[3].tofloat() * 255).tointeger());
		if (red.len() == 1) red = "0" + red;
		if (green.len() == 1) green = "0" + green;
		if (blue.len() == 1) blue = "0" + blue;
		if (opacity.len() == 1) opacity = "0" + opacity;
		return  red + green + blue + opacity;
	}
}
::mods_registerMod(::TurnOrderNumbers.ID, ::TurnOrderNumbers.Version)

::mods_queue(::TurnOrderNumbers.ID, "mod_msu,>mod_autopilot", function()
{
	::TurnOrderNumbers.Mod <- ::MSU.Class.Mod(::TurnOrderNumbers.ID, ::TurnOrderNumbers.Version, ::TurnOrderNumbers.Name);
	local generalPage = ::TurnOrderNumbers.Mod.ModSettings.addPage("General");

	// To enable and disable the numbers I use the setting itself with a further keybind
	local enabledSetting = generalPage.addBooleanSetting("EnabledState", true, "Enable or disable numbers");
	enabledSetting.addCallback(::TurnOrderNumbers.UpdateNumbers);

	::TurnOrderNumbers.Mod.Keybinds.addSQKeybind("ToggleNumbers", "n", ::MSU.Key.State.Tactical, function(){
		local setting = ::TurnOrderNumbers.Mod.ModSettings.getSetting("EnabledState");
		setting.set(!setting.getValue(), true, false, false);
		::TurnOrderNumbers.UpdateNumbers();
	}, "Enable or disable turn order numbers.", ::MSU.Key.KeyState.Release);


	local playerColor = "221,162,31,1.0";
	local allyColor = "221,162,31,1.0";
	local enemyColor =  "248,120,31,1.0";
	local hoverColor = "255,0,0,1.0";
	local colorCallback = function(_newVal)
	{
		::TurnOrderNumbers[this.getID()] = this.createColor(::TurnOrderNumbers.GetValueAsHexString(_newVal));
		::TurnOrderNumbers.UpdateNumbers();
	}

	local playerColorSetting = generalPage.addColorPickerSetting("NumbersColorPlayer", playerColor, "Color of player numbers");
	playerColorSetting.addCallback(colorCallback);
	::TurnOrderNumbers.NumbersColorPlayer = this.createColor(::TurnOrderNumbers.GetValueAsHexString(playerColor));

	local allyColorSetting = generalPage.addColorPickerSetting("NumbersColorAllies", allyColor, "Color of ally numbers");
	allyColorSetting.addCallback(colorCallback);
	::TurnOrderNumbers.NumbersColorAllies = this.createColor(::TurnOrderNumbers.GetValueAsHexString(allyColor));

	local enemyColorSetting = generalPage.addColorPickerSetting("NumbersColorEnemies", enemyColor, "Color of enemy numbers");
	enemyColorSetting.addCallback(colorCallback);
	::TurnOrderNumbers.NumbersColorEnemies = this.createColor(::TurnOrderNumbers.GetValueAsHexString(enemyColor));

	local scaleNumbersSetting = generalPage.addBooleanSetting("ScaleNumbers", true, "Increase size of lower numbers");
	scaleNumbersSetting.setDescription("Smaller numbers will be bigger than bigger numbers to increase visibility of those entities who will act soon.");
	scaleNumbersSetting.addCallback(function(_){
		if (this.Tactical.isVisible())
		{
			this.Tactical.TurnSequenceBar.updateTurnOrderNumbers();
		}
	});

	generalPage.addDivider("1");
	local hoverNumberSetting = generalPage.addBooleanSetting("HoverNumbers", true, "Color lower numbers on hover");
	hoverNumberSetting.setDescription("When hovering over an entity, the number of entities acting after it will be colored differently.")

	local hoverColorSetting = generalPage.addColorPickerSetting("NumbersColorHover", hoverColor, "Hover color");
	hoverColorSetting.setDescription("When hovering over an entity, this is the color of the entities acting after it.");
	hoverColorSetting.addCallback(colorCallback);

	local fontSizeSetting = generalPage.addRangeSetting("NumbersFontSize", 100, 1, 200, 1, "Font Size", "Increase or reduce font size of the numbers, in %.");


	::TurnOrderNumbers.NumbersColorHover = this.createColor(::TurnOrderNumbers.GetValueAsHexString(hoverColor));


	::mods_hookNewObject("ui/screens/tactical/modules/turn_sequence_bar/turn_sequence_bar", function(o)
	{
		o.updateTurnOrderNumbers <- function()
		{
			local hoveredEntityTurns = this.Tooltip.m.CurrentHoveredEntityId != null ?  this.Tactical.TurnSequenceBar.getTurnsUntilActive(this.Tooltip.m.CurrentHoveredEntityId) : null;

			foreach(entity in this.getAllEntities())
			{
				if (!entity.hasSprite("number_left"))
				{
					entity.addSprite("number_left");
					entity.getSprite("number_left").Scale = 0.3;
					entity.setSpriteOffset("number_left", this.createVec(-10, 70))
				}

				if (!entity.hasSprite("number_right"))
				{
					entity.addSprite("number_right");
					entity.getSprite("number_right").Scale = 0.3;
				}
				if (!entity.hasSprite("number_asterisk"))
				{
					entity.addSprite("number_asterisk");
					entity.getSprite("number_asterisk").setBrush("turnnumber_asterisk");
					entity.getSprite("number_asterisk").Scale = 0.3;
				}
				entity.getSprite("number_left").Visible = false;
				entity.getSprite("number_right").Visible = false;
				entity.getSprite("number_asterisk").Visible = false;
				entity.setSpriteColorization("number_left", true);
				entity.setSpriteColorization("number_right", true);
				entity.setSpriteColorization("number_asterisk", true);
				entity.setSpriteRenderToTexture("number_left", false);
				entity.setSpriteRenderToTexture("number_right", false);
				entity.setSpriteRenderToTexture("number_asterisk", false);

			}

			if (::TurnOrderNumbers.getNumbersEnabledState() == false)
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
				local asterisk = entity.getSprite("number_asterisk");

				local idxAsString = altIdx.tostring();
				local left = altIdx > 9 ? idxAsString[0] : null;
				local right = altIdx > 9 ? idxAsString[1] : idxAsString[0];


				if (entity.m.IsWaitActionSpent)
				{
					asterisk.Color = color;
					asterisk.Visible = true;
				}

				if (left != null)
				{
					leftSprite.setBrush(format("turnnumber_number_%s", left.tochar()));
					leftSprite.Color = color;
					leftSprite.Visible = true;
					entity.setSpriteOffset("number_right", this.createVec(10, 70))
					entity.setSpriteOffset("number_asterisk", this.createVec(28, 70))
				}
				else
				{
					entity.setSpriteOffset("number_right", this.createVec(0, 70))
					entity.setSpriteOffset("number_asterisk", this.createVec(18, 70))
				}
				rightSprite.setBrush(format("turnnumber_number_%s", right.tochar()));
				rightSprite.Color = color;
				rightSprite.Visible = true;


				// decreasing scale
				local scale = 0.3;
				if (::TurnOrderNumbers.Mod.ModSettings.getSetting("ScaleNumbers").getValue())
					scale = ::Math.maxf(0.25, 0.4 - (0.01*altIdx));

				scale *= (::TurnOrderNumbers.Mod.ModSettings.getSetting("NumbersFontSize").getValue() * 0.01);
				rightSprite.Scale = scale;
				leftSprite.Scale = scale;
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

	::mods_hookExactClass("states/tactical_state", function(o)
	{
		local onBattleEnded = o.onBattleEnded;
		o.onBattleEnded = function()
		{
			foreach(entity in this.World.getPlayerRoster().getAll())
			{
				entity.removeSprite("number_left");
				entity.removeSprite("number_right");
			}
			return onBattleEnded();
		}

		local turnsequencebar_onEntityMouseEnter = o.turnsequencebar_onEntityMouseEnter;
		o.turnsequencebar_onEntityMouseEnter = function(_entity)
		{
			if (_entity != null && _entity.isAlive())
			{
				_entity.getSprite("number_left").Visible = false;
				_entity.getSprite("number_right").Visible = false;
			}
			return turnsequencebar_onEntityMouseEnter(_entity);
		}

		local turnsequencebar_onEntityMouseLeave = o.turnsequencebar_onEntityMouseLeave;
		o.turnsequencebar_onEntityMouseLeave = function(_entity)
		{
			if (_entity != null && _entity.isAlive())
			{
				local turns = this.Tactical.TurnSequenceBar.getTurnsUntilActive(_entity.getID());
				if (turns > 10)
					_entity.getSprite("number_left").Visible = true;
				_entity.getSprite("number_right").Visible = true;
			}
			return turnsequencebar_onEntityMouseLeave(_entity);
		}
	})
})

