package base;

import base.dependency.MusicBeat;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.FlxUIState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxGradient;

/**
 * A class that truncates/adds several functions and utilities
 * such as storing song time, simple depth sorting & offsetting functionality to the FlxSprite class
 */
class ForeverSprite extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var zDepth:Float = 0;
	public var currentTime:Float;

	public static inline function depthSorting(Order:Int, Obj1:ForeverSprite, Obj2:ForeverSprite)
	{
		if (Obj1.zDepth > Obj2.zDepth)
			return -Order;
		return Order;
	}

	public function resizeOffsets(?newScale:Float)
	{
		if (newScale == null)
			newScale = scale.x;
		for (i in animOffsets.keys())
			animOffsets[i] = [animOffsets[i][0] * newScale, animOffsets[i][1] * newScale];
	}

	public function new(?x:Float, ?y:Float)
	{
		super(x, y);
		animOffsets = new Map<String, Array<Dynamic>>();
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0):Void
		animOffsets[name] = [x, y];

	public function playAnim(AnimName:String, ?Force:Bool = false, ?Reversed:Bool = false, ?Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);
		centerOffsets();
		centerOrigin();

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
			offset.set(daOffset[0], daOffset[1]);
	}
}

class ForeverUIState extends FlxUIState
{
	override function create()
	{
		// state stuffs
		if (!FlxTransitionableState.skipNextTransOut)
			openSubState(new ForeverTransition(0.5, true));

		super.create();
	}
}

class ForeverTransition extends MusicBeatSubState
{
	public static var finishCallback:Void->Void;

	private var leTween:FlxTween = null;

	public static var nextCamera:FlxCamera;

	var isTransIn:Bool = false;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	public function new(duration:Float, isTransIn:Bool)
	{
		super();

		this.isTransIn = isTransIn;
		var width:Int = Std.int(FlxG.width);
		var height:Int = Std.int(FlxG.height);
		transGradient = FlxGradient.createGradientFlxSprite(width, height, (isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]));
		transGradient.scrollFactor.set();
		add(transGradient);

		transBlack = new FlxSprite().makeGraphic(width, height + 400, FlxColor.BLACK);
		transBlack.scrollFactor.set();
		add(transBlack);

		transGradient.x -= (width - FlxG.width) / 2;
		transBlack.x = transGradient.x;

		if (isTransIn)
		{
			transGradient.y = transBlack.y - transBlack.height;
			FlxTween.tween(transGradient, {y: transGradient.height + 50}, duration, {
				onComplete: function(twn:FlxTween)
				{
					close();
				},
				ease: FlxEase.linear
			});
		}
		else
		{
			transGradient.y = -transGradient.height;
			transBlack.y = transGradient.y - transBlack.height + 50;
			leTween = FlxTween.tween(transGradient, {y: transGradient.height + 50}, duration, {
				onComplete: function(twn:FlxTween)
				{
					if (finishCallback != null)
					{
						finishCallback();
					}
				},
				ease: FlxEase.linear
			});
		}
	}

	var camStarted:Bool = false;

	override function update(elapsed:Float)
	{
		if (isTransIn)
			transBlack.y = transGradient.y + transGradient.height;
		else
			transBlack.y = transGradient.y - transBlack.height;

		var camList = FlxG.cameras.list;
		camera = camList[camList.length - 1];
		transBlack.cameras = [camera];
		transGradient.cameras = [camera];

		super.update(elapsed);

		if (isTransIn)
			transBlack.y = transGradient.y + transGradient.height;
		else
			transBlack.y = transGradient.y - transBlack.height;
	}

	override function destroy()
	{
		if (leTween != null)
		{
			finishCallback();
			leTween.cancel();
		}
		super.destroy();
	}
}
