package funkin;

import AssetManager;
import base.Conductor;
import base.ForeverDependencies.ForeverSprite;
import base.ScriptHandler;
import flixel.FlxSprite;
import flixel.animation.FlxAnimationController;
import flixel.math.FlxPoint;
import haxe.Json;
import haxe.ds.StringMap;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class Character extends ForeverSprite
{
	public var cameraOffset:FlxPoint;
	public var characterOffset:FlxPoint;
	public var curCharacter:String;
	public var holdTimer:Float = 0;

	public var isPlayer:Bool = false;
	// might not be ideal. @BeastlyGhost
	public var isSpectator:Bool = false;
	public var adjustPos:Bool = true;

	public function new(x:Float = 0, y:Float = 0)
		super(x, y);

	public function setCharacter(x:Float, y:Float, ?character:String = 'bf', isPlayer:Bool = false):Character
	{
		this.isPlayer = isPlayer;
		isSpectator = character.startsWith('gf');
		curCharacter = character;
		antialiasing = true;

		cameraOffset = new FlxPoint(0, 0);
		characterOffset = new FlxPoint(0, 0);

		if (FileSystem.exists(AssetManager.getPath('$character', 'characters/$character', MODULE)))
		{
			var exposure:StringMap<Dynamic> = new StringMap<Dynamic>();
			exposure.set('character', this);
			var character:ForeverModule = ScriptHandler.loadModule(character, 'characters/$character', exposure);
			if (character.exists("loadAnimations"))
				character.get("loadAnimations")();
		}
		else
			trace('something went wrong');

		// reverse player flip
		if (isPlayer)
			flipX = !flipX;

		dance();

		setPosition(x, y);
		if (adjustPos)
		{
			this.x += characterOffset.x;
			this.y += (characterOffset.y - (frameHeight * scale.y));
		}
		return this;
	}

	override public function update(elapsed:Float)
	{
		// /*
		if (animation.curAnim != null)
		{
			if (!isPlayer)
			{
				if (animation.curAnim.name.startsWith('sing'))
					holdTimer += elapsed;
				if (holdTimer >= (Conductor.stepCrochet * 4) / 1000)
				{
					dance();
					holdTimer = 0;
				}
			}
			else
			{
				if (animation.curAnim.name.startsWith('sing'))
					holdTimer += elapsed;
				else
					holdTimer = 0;

				if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished)
					dance(true);
			}
		}
		// */
		super.update(elapsed);
	}

	public var danced:Bool = false;

	public function dance(?forced:Bool = false)
	{
		// Left / Right dancing, think Skid & Pump
		if (animation.getByName('danceLeft') != null && animation.getByName('danceRight') != null)
		{
			danced = !danced;
			if (danced)
				playAnim('danceRight', forced);
			else
				playAnim('danceLeft', forced);
		}
		else
			playAnim('idle', forced);
	}
}
