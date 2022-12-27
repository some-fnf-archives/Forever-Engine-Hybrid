package states.subState;

import base.Conductor.BPMChangeEvent;
import base.Conductor;
import base.dependency.MusicBeat.MusicBeatSubState;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;
import funkin.Character;
import states.*;
import states.menus.*;

class GameOverSubstate extends MusicBeatSubState
{
	//
	var bf:Character;
	var camFollow:FlxObject;
	var soundMusic:FlxSound;
	var soundConfirm:FlxSound;

	public function new(x:Float, y:Float)
	{
		var daBf:String = '';
		switch (PlayState.boyfriend.curCharacter)
		{
			case 'bf-pixel':
				daBf = 'bf-pixel-dead';
			default:
				daBf = 'bf-dead';
		}

		super();

		Conductor.songPosition = 0;

		// preload music and sounds
		if (soundMusic == null)
		{
			soundMusic = new FlxSound().loadEmbedded(AssetManager.getAsset('gameOver', MUSIC, 'music/${PlayState.assetModifier}'));
			FlxG.sound.list.add(soundMusic);
		}

		if (soundConfirm == null)
		{
			soundConfirm = new FlxSound().loadEmbedded(AssetManager.getAsset('gameOverEnd', SOUND, 'music/${PlayState.assetModifier}'));
			FlxG.sound.list.add(soundConfirm);
		}

		bf = new Character();
		bf.setCharacter(x, y + PlayState.boyfriend.height, daBf);
		add(bf);

		PlayState.boyfriend.destroy();

		camFollow = new FlxObject(bf.getGraphicMidpoint().x + 20, bf.getGraphicMidpoint().y - 40, 1, 1);
		add(camFollow);

		Conductor.changeBPM(100);

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		if (bf.animation.getByName('firstDeath') != null)
			bf.playAnim('firstDeath');
	}

	var playDeathMusic:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT)
			endBullshit();

		if (controls.BACK)
		{
			playDeathMusic = false;
			soundMusic.stop();
			soundConfirm.stop();
			PlayState.deaths = 0;

			if (PlayState.isStoryMode)
				Main.switchState(this, new StoryMenuState());
			else
				Main.switchState(this, new FreeplayState());
		}

		if (bf.animation.curAnim.name == 'firstDeath')
		{
			if (bf.animation.curAnim.curFrame == 12)
				FlxG.camera.follow(camFollow, LOCKON, 0.01);

			if (bf.animation.curAnim.finished)
			{
				if (bf.animation.getByName('deathLoop') != null)
					bf.playAnim('deathLoop');
				playDeathMusic = true;
			}
		}

		if (playDeathMusic)
		{
			if (soundMusic != null && !soundMusic.playing)
				soundMusic.play();
		}
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			playDeathMusic = false;
			if (bf.animation.getByName('deathConfirm') != null)
				bf.playAnim('deathConfirm', true);
			soundMusic.stop();
			soundConfirm.play();
			soundConfirm.persist = true;
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 1, false, function()
				{
					Main.switchState(this, new PlayState());
				});
			});
			//
		}
	}
}
