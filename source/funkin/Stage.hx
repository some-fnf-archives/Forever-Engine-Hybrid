package funkin;

import base.ScriptHandler;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import haxe.ds.StringMap;
import states.PlayState;

class Stage extends FlxTypedGroup<FlxBasic>
{
	public var defaultCamZoom(never, set):Float;

	function set_defaultCamZoom(value:Float):Float
	{
		PlayState.defaultCamZoom = value;
		return value;
	}
	public var stageBuild:ForeverModule;
	public var foreground:FlxTypedGroup<FlxBasic>;

	public function new(stage:String, ?camPos:FlxPoint)
	{
		super();

		foreground = new FlxTypedGroup<FlxBasic>();

		var exposure:StringMap<Dynamic> = new StringMap<Dynamic>();
		exposure.set('add', add);
		exposure.set('stage', this);
		exposure.set('foreground', foreground);
		if (camPos != null)
			exposure.set('camPos', camPos);
		stageBuild = ScriptHandler.loadModule('$stage', 'stages/$stage', exposure);
		if (stageBuild.exists("onCreate"))
			stageBuild.get("onCreate")();
		trace('$stage loaded successfully');
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (stageBuild.exists("onUpdate"))
			stageBuild.get("onUpdate")(elapsed);
	}

	public function onStep(curStep:Int) {
		if (stageBuild.exists("onStep"))
			stageBuild.get("onStep")(curStep);
	}

	public function onBeat(curBeat:Int)
	{
		if (stageBuild.exists("onBeat"))
			stageBuild.get("onBeat")(curBeat);
	}

	public function dispatchEvent(myEvent:String)
	{
		if (stageBuild.exists("onEvent"))
			stageBuild.get("onEvent")(myEvent);
	}
}
