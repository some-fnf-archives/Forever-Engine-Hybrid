package funkin.menu;

import base.ForeverDependencies;

using StringTools;

class Checkmark extends ForeverSprite
{
	public function new(x:Float, y:Float)
	{
		super(x, y);
		frames = Paths.getSparrowAtlas('ui/default/checkboxThingie');
		antialiasing = true;

		animation.addByPrefix('false finished', 'uncheckFinished');
		animation.addByPrefix('false', 'uncheck', 12, false);
		animation.addByPrefix('true finished', 'checkFinished');
		animation.addByPrefix('true', 'check', 12, false);

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();

		///*
		var offsetByX = 45;
		var offsetByY = 5;
		addOffset('false', offsetByX, offsetByY);
		addOffset('true', offsetByX, offsetByY);
		addOffset('true finished', offsetByX, offsetByY);
		addOffset('false finished', offsetByX, offsetByY);
		// */
	}

	override public function update(elapsed:Float)
	{
		if (animation != null)
		{
			if ((animation.finished) && (animation.curAnim.name == 'true'))
				playAnim('true finished');
			if ((animation.finished) && (animation.curAnim.name == 'false'))
				playAnim('false finished');
		}

		super.update(elapsed);
	}
}
