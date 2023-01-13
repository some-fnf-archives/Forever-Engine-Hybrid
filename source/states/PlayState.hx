package states;

import base.Events.PlacedEvent;
import AssetManager.EngineImplementation;
import base.*;
import base.*;
import base.Conductor.Highscore;
import base.Conductor.Timings;
import base.ForeverDependencies;
import base.ScriptHandler.ForeverModule;
import base.Song.SwagSong;
import base.dependency.MusicBeat.MusicBeatState;
import base.subState.*;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import funkin.*;
import funkin.Strumline;
import openfl.display.GraphicsShader;
import openfl.events.KeyboardEvent;
import openfl.filters.ShaderFilter;
import openfl.media.Sound;
import openfl.utils.Assets;
import states.charting.*;
import states.menus.*;
import states.subState.PauseSubState;
import sys.io.File;

using StringTools;

#if desktop
import base.dependency.Discord;
#end

class PlayState extends MusicBeatState
{
	public static var startTimer:FlxTimer;

	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 2;

	public static var songMusic:FlxSound;
	public static var vocals:FlxSound;

	public static var campaignScore:Int = 0;

	public static var dadOpponent:Character;
	public static var boyfriend:Character;
	public static var girlfriend:Character;

	public static var assetModifier:String = 'default';

	private var unspawnNotes:Array<Note> = [];
	private var allSicks:Bool = true;

	private var numberOfKeys:Int = 4;
	private var curSection:Int = 0;

	public static var songDetails:String = "";
	public static var detailsSub:String = "";
	public static var detailsPausedText:String = "";

	public var gfSpeed:Int = 1;

	public static var health:Float = 1; // mario
	public static var combo:Int = 0;
	public static var misses:Int = 0;
	public static var deaths:Int = 0;

	public var generatedMusic:Bool = false;

	private var startingSong:Bool = false;
	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var inCutscene:Bool = false;

	var canPause:Bool = true;

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	public static var camHUD:FlxCamera;
	public static var camGame:FlxCamera;
	public static var dialogueHUD:FlxCamera;

	public var camDisplaceX:Float = 0;
	public var camDisplaceY:Float = 0;

	public static var cameraSpeed:Float = 1;
	public static var defaultCamZoom:Float = 1.05;

	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject;

	public static var forceZoom:Array<Float>;

	public static var songScore:Int = 0;

	var storyDifficultyText:String = "";

	public static var iconRPC:String = "";
	public static var songLength:Float = 0;

	private var stageBuild:Stage;

	public static var uiHUD:UI;
	public static var daPixelZoom:Float = 6;

	// strumlines
	private var dadStrums:Strumline;
	private var boyfriendStrums:Strumline;

	public static var strumLines:FlxTypedGroup<Strumline>;

	public var judgementGroup:FlxTypedGroup<ForeverSprite>;
	public var comboGroup:FlxTypedGroup<ForeverSprite>;

	public static var playerStrumline:Int = 1;
	public static var instance:PlayState;

	public static var eventList:Array<PlacedEvent> = [];

	public var updateableScript:Array<ForeverModule> = [];

	// judgement customization
	public static var lockComboInHUD:Bool;
	public static var comboPosition:FlxPoint;

	override public function create()
	{
		super.create();
		instance = this;

		Events.obtainEvents();

		// reset any values and variables that are static
		songScore = 0;
		combo = 0;
		health = 1;
		misses = 0;

		lockComboInHUD = false;

		defaultCamZoom = 1.05;
		cameraSpeed = 1;
		forceZoom = [0, 0, 0, 0];

		Timings.callAccuracy();

		assetModifier = 'default';

		// stop any existing music tracks playing
		resetMusic();
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// create the game camera
		camGame = new FlxCamera();

		// create the hud camera (separate so the hud stays on screen)
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		//create the dialogue camera
		dialogueHUD = new FlxCamera();
		dialogueHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(dialogueHUD, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		// default song
		if (SONG == null)
			SONG = Song.loadFromJson('test', 'test');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		curStage = "stage";
		if (SONG.stage != null)
			curStage = SONG.stage;

		judgementGroup = new FlxTypedGroup<ForeverSprite>();
		comboGroup = new FlxTypedGroup<ForeverSprite>();

		comboPosition = new FlxPoint(0, 0);

		displayRating('sick', false, true);
		popUpCombo(true);

		dadOpponent = new Character().setCharacter(50, 850, SONG.player2);
		boyfriend = new Character().setCharacter(750, 850, SONG.player1, true);
		girlfriend = new Character().setCharacter(300, 750, SONG.gfVersion);

		// set the camera position to the center of the stage
		var camPos:FlxPoint = new FlxPoint(((dadOpponent.x + dadOpponent.width / 2) + (boyfriend.x + boyfriend.width / 2)) / 2,
			((dadOpponent.y + dadOpponent.height / 2) + (boyfriend.y + boyfriend.height / 2)) / 2);

		stageBuild = new Stage(curStage, camPos);
		add(stageBuild);

		if (SONG.assetModifier != null && SONG.assetModifier.length > 1)
			assetModifier = SONG.assetModifier;

		if (dadOpponent.isSpectator)
			dadOpponent.setPosition(girlfriend.x, girlfriend.y);
		else if (stageBuild.addGirlfriend)
			add(girlfriend);

		add(stageBuild.layers);

		add(dadOpponent);
		add(boyfriend);

		add(stageBuild.foreground);

		// set song position before beginning
		Conductor.songPosition = -(Conductor.crochet * 4);

		// strum setup
		strumLines = new FlxTypedGroup<Strumline>();
		strumLines.cameras = [camHUD];

		// generate the song
		generateSong(SONG.song);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(camPos.x, camPos.y);

		add(camFollow);
		add(camFollowPos);

		// actually set the camera up
		camGame.follow(camFollowPos, LOCKON, 1);
		camGame.zoom = defaultCamZoom;
		camGame.focusOn(camFollowPos.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		// initialize ui elements
		startingSong = true;
		startedCountdown = true;

		var separation:Float = FlxG.width / 4;
		// dad
		dadStrums = new Strumline((FlxG.width / 2) - separation, (Init.trueSettings.get('Downscroll') ? FlxG.height - FlxG.height / 6 : FlxG.height / 6),
			'default', true, false, [dadOpponent], [dadOpponent]);
		dadStrums.visible = !Init.trueSettings.get('Centered Notefield');
		boyfriendStrums = new Strumline((FlxG.width / 2) + (!Init.trueSettings.get('Centered Notefield') ? separation : 0),
			(Init.trueSettings.get('Downscroll') ? FlxG.height - FlxG.height / 6 : FlxG.height / 6), 'default', false, true, [boyfriend], [boyfriend]);

		strumLines.add(dadStrums);
		strumLines.add(boyfriendStrums);
		add(strumLines);

		uiHUD = new UI();
		add(uiHUD);
		uiHUD.cameras = [camHUD];
		//

		if (lockComboInHUD)
		{
			judgementGroup.cameras = [camHUD];
			comboGroup.cameras = [camHUD];
		}

		add(judgementGroup);
		add(comboGroup);

		//
		controls.setKeyboardScheme(None, false);
		keysArray = [
			copyKey(Init.gameControls.get('LEFT')[0]),
			copyKey(Init.gameControls.get('DOWN')[0]),
			copyKey(Init.gameControls.get('UP')[0]),
			copyKey(Init.gameControls.get('RIGHT')[0])
		];

		if (!Init.trueSettings.get('Controller Mode'))
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		songCutscene(false);

		Paths.clearUnusedMemory();
	}

	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}

	var keysArray:Array<Dynamic>;

	public function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if ((key >= 0)
			&& !boyfriendStrums.autoplay
			&& (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || Init.trueSettings.get('Controller Mode'))
			&& (FlxG.keys.enabled && !paused && (FlxG.state.active || FlxG.state.persistentUpdate)))
		{
			if (generatedMusic)
			{
				// var previousTime:Float = Conductor.songPosition;
				// Conductor.songPosition = songMusic.time;

				var possibleNoteList:Array<Note> = [];
				var pressedNotes:Array<Note> = [];

				boyfriendStrums.allNotes.forEachAlive(function(daNote:Note)
				{
					if ((daNote.noteData == key) && daNote.canBeHit && !daNote.isSustain && !daNote.tooLate && !daNote.wasGoodHit)
						possibleNoteList.push(daNote);
				});
				possibleNoteList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				// if there is a list of notes that exists for that control
				if (possibleNoteList.length > 0)
				{
					var eligable = true;
					var firstNote = true;
					// loop through the possible notes
					for (coolNote in possibleNoteList)
					{
						for (noteDouble in pressedNotes)
						{
							if (Math.abs(noteDouble.strumTime - coolNote.strumTime) < 10)
								firstNote = false;
							else
								eligable = false;
						}

						if (eligable)
						{
							goodNoteHit(coolNote, boyfriendStrums.singingList, boyfriendStrums, firstNote); // then hit the note
							pressedNotes.push(coolNote);
						}
						// end of this little check
					}
					//
				}
				else // else just call bad notes
					if (!Init.trueSettings.get('Ghost Tapping'))
						missNoteCheck(true, boyfriendStrums.receptors.members[key], boyfriendStrums.singingList, true);
				// Conductor.songPosition = previousTime;
			}

			if (boyfriendStrums.receptors.members[key] != null
				&& boyfriendStrums.receptors.members[key].animation.curAnim.name != 'confirm')
				boyfriendStrums.receptors.members[key].playAnim('pressed');
		}
	}

	public function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (FlxG.keys.enabled && !paused && (FlxG.state.active || FlxG.state.persistentUpdate))
		{
			// receptor reset
			if (key >= 0 && boyfriendStrums.receptors.members[key] != null)
				boyfriendStrums.receptors.members[key].playAnim('static');
		}
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
						return i;
				}
			}
		}
		return -1;
	}

	override public function destroy()
	{
		if (!Init.trueSettings.get('Controller Mode'))
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		super.destroy();
	}

	var staticDisplace:Int = 0;

	var lastSection:Int = 0;

	public var camZooming:Bool = true;
	public var hudCameraZoom:Float = 1;
	public var gameBump:Float = 0;
	public var hudBump:Float = 0;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		for (i in updateableScript)
		{
			if (i.alive && i.exists('onUpdate'))
			{
				i.get('onUpdate')(elapsed);
			}
			else
				updateableScript.splice(updateableScript.indexOf(i), 1);
		}

		if (health > 2)
			health = 2;

		if (!inCutscene)
		{
			// pause the game if the game is allowed to pause and enter is pressed
			if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
				pauseGame();

			// make sure you're not cheating lol
			if (!isStoryMode)
			{
				// charting state (more on that later)
				if ((FlxG.keys.justPressed.SEVEN) && (!startingSong))
				{
					resetMusic();
					Main.switchState(this, new ChartingState());
				}

				if ((FlxG.keys.justPressed.SIX))
					boyfriendStrums.autoplay = !boyfriendStrums.autoplay;
			}

			///*
			if (startingSong)
			{
				if (startedCountdown)
				{
					Conductor.songPosition += elapsed * 1000;
					if (Conductor.songPosition >= 0)
						startSong();
				}
			}
			else
			{
				Conductor.songPosition += elapsed * 1000;

				if (!paused)
				{
					songTime += FlxG.game.ticks - previousFrameTime;
					previousFrameTime = FlxG.game.ticks;

					// Interpolation type beat
					if (Conductor.lastSongPos != Conductor.songPosition)
					{
						songTime = (songTime + Conductor.songPosition) / 2;
						Conductor.lastSongPos = Conductor.songPosition;
						// Conductor.songPosition += FlxG.elapsed * 1000;
						// trace('MISSED FRAME');
					}
				}
			}
			// */

			if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
			{
				if (!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
				{
					var char = dadOpponent;

					var getCenterX = char.getMidpoint().x + 100;
					var getCenterY = char.getMidpoint().y - 100;
					camFollow.setPosition(getCenterX + camDisplaceX + char.cameraOffset.x, getCenterY + camDisplaceY + char.cameraOffset.y);
				}
				else
				{
					var char = boyfriend;

					var getCenterX = char.getMidpoint().x - 100;
					var getCenterY = char.getMidpoint().y - 100;
					camFollow.setPosition(getCenterX + camDisplaceX - char.cameraOffset.x, getCenterY + camDisplaceY + char.cameraOffset.y);
				}

				var curSection = Std.int(curStep / 16);
				if (curSection != lastSection)
				{
					// section reset stuff
					var lastMustHit:Bool = PlayState.SONG.notes[lastSection].mustHitSection;
					if (PlayState.SONG.notes[curSection].mustHitSection != lastMustHit)
					{
						camDisplaceX = 0;
						camDisplaceY = 0;
					}
					lastSection = Std.int(curStep / 16);
				}
			}

			var lerpVal:Float = (elapsed * 2.4) * cameraSpeed;
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

			// handle the camera zooming
			camGame.zoom = defaultCamZoom + gameBump;
			camHUD.zoom = hudCameraZoom + hudBump;
			// /*
			if (camZooming)
			{
				var easeLerp = 1 - (elapsed * 3.125);
				gameBump = FlxMath.lerp(0, gameBump, easeLerp);
				hudBump = FlxMath.lerp(0, hudBump, easeLerp);
			}
			// */

			// RESET = Quick Game Over Screen
			if (controls.RESET && !Init.trueSettings.get("Disable Reset Button") && !startingSong && !isStoryMode)
				health = 0;

			if (health <= 0 && startedCountdown)
			{
				paused = true;
				// startTimer.active = false;
				persistentUpdate = false;
				persistentDraw = false;

				resetMusic();

				deaths += 1;

				openSubState(new states.subState.GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				FlxG.sound.play(AssetManager.getAsset('fnf_loss_sfx', SOUND, 'sounds/${PlayState.assetModifier}'));

				#if DISCORD_RPC
				Discord.changePresence("Game Over - " + songDetails, detailsSub, iconRPC);
				#end
			}

			// spawn in the notes from the array
			while ((unspawnNotes[0] != null) && ((unspawnNotes[0].strumTime - Conductor.songPosition) < 3500))
			{
				var unspawnNote:Note = unspawnNotes[0];
				if (unspawnNote != null)
				{
					var strumline:Strumline = strumLines.members[unspawnNote.strumline];
					if (strumline != null)
						strumline.add(unspawnNote);
				}
				unspawnNotes.splice(unspawnNotes.indexOf(unspawnNote), 1);
			}

			if (eventList.length > 0)
			{
				// /*
				for (i in 0...eventList.length)
				{
					if (eventList[i] != null && Conductor.songPosition >= eventList[i].timestamp)
					{
						// /*
						var module:ForeverModule = Events.loadedModules.get(eventList[i].eventName);
						if (module.exists("eventFunction"))
							module.get("eventFunction")(eventList[i].params);
						stageBuild.dispatchEvent(eventList[i].eventName);
						if (module.exists("onUpdate"))
							updateableScript.push(module);
						// */
						trace(eventList.splice(i, 1));
					}
				}
				// */
			}

			noteCalls();

			if (Init.trueSettings.get('Controller Mode'))
				controllerInput();
		}
	}

	// maybe theres a better place to put this, idk -saw
	function controllerInput()
	{
		var justPressArray:Array<Bool> = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];

		var justReleaseArray:Array<Bool> = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];

		if (justPressArray.contains(true))
		{
			for (i in 0...justPressArray.length)
			{
				if (justPressArray[i])
					onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
			}
		}

		if (justReleaseArray.contains(true))
		{
			for (i in 0...justReleaseArray.length)
			{
				if (justReleaseArray[i])
					onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
			}
		}
	}

	function noteCalls()
	{
		// reset strums
		for (strumline in strumLines)
		{
			// handle strumline stuffs
			for (receptor in strumline.receptors)
			{
				if (strumline.autoplay)
					if (receptor.animation.finished)
						receptor.playAnim('static');
			}
		}

		// if the song is generated
		if (generatedMusic && startedCountdown)
		{
			for (strumline in strumLines)
			{
				// set the notes x and y
				var downscrollMultiplier = 1;
				if (Init.trueSettings.get('Downscroll'))
					downscrollMultiplier = -1;

				strumline.allNotes.forEachAlive(function(daNote:Note)
				{
					// update position
					var baseY = strumline.receptors.members[Math.floor(daNote.noteData)].y;
					var baseX = strumline.receptors.members[Math.floor(daNote.noteData)].x;

					if (daNote.useCustomSpeed)
						daNote.noteSpeed = daNote.customNoteSpeed;
					else
						daNote.noteSpeed = Math.abs(SONG.speed);

					daNote.x = baseX + daNote.offsetX;
					daNote.y = baseY + daNote.offsetY + (downscrollMultiplier * -((Conductor.songPosition - daNote.strumTime) * (0.45 * daNote.noteSpeed)));
					var center:Float = baseY + (daNote.receptorData.separation / 2);
					if (daNote.isSustain)
					{
						// note placement
						daNote.y += ((daNote.receptorData.separation / 2) * downscrollMultiplier);

						// note clipping
						if (downscrollMultiplier < 0)
						{
							if (daNote.isSustainEnd)
							{
								if (daNote.endHoldOffset == Math.NEGATIVE_INFINITY)
									daNote.endHoldOffset = Math.ceil(daNote.prevNote.y - (daNote.y + daNote.height)) + 1.5;
								daNote.y += daNote.endHoldOffset;
							}

							daNote.flipY = true;
							if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
								&& (strumline.autoplay || (daNote.wasGoodHit || (daNote.prevNote != null && daNote.prevNote.wasGoodHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = (center - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;
								daNote.clipRect = swagRect;
							}
						}
						else if (downscrollMultiplier > 0)
						{
							if (daNote.y + daNote.offset.y * daNote.scale.y <= center
								&& (strumline.autoplay || (daNote.wasGoodHit || (daNote.prevNote != null && daNote.prevNote.wasGoodHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;
								daNote.clipRect = swagRect;
							}
						}
					}
					// hell breaks loose here, we're using nested scripts!
					mainControls(daNote, strumline.singingList, strumline, strumline.autoplay);

					// check where the note is and make sure it is either active or inactive
					if (daNote.y > FlxG.height)
					{
						daNote.active = false;
						daNote.visible = false;
					}
					else
					{
						daNote.visible = true;
						daNote.active = true;
					}

					if (!daNote.tooLate && daNote.strumTime < Conductor.songPosition - (Timings.msThreshold) && !daNote.wasGoodHit)
					{
						if (daNote.strumline == playerStrumline)
						{
							if (!daNote.isSustain)
							{
								daNote.tooLate = true;
								for (note in daNote.childrenNotes)
									note.tooLate = true;
								daNote.noteMiss();

								if (daNote.ignoreNote)
									return;

								vocals.volume = 0;
								missNoteCheck((Init.trueSettings.get('Ghost Tapping')) ? true : false, strumline.receptors.members[daNote.noteData],
									boyfriendStrums.singingList, true);
								// ambiguous name
								Timings.updateAccuracy(0);
							}
							else if (daNote.isSustain)
							{
								if (daNote.parentNote != null)
								{
									var parentNote = daNote.parentNote;
									if (!parentNote.tooLate)
									{
										var breakFromLate:Bool = false;
										for (note in parentNote.childrenNotes)
										{
											trace('hold amount ${parentNote.childrenNotes.length}, note is late?' + note.tooLate + ', ' + breakFromLate);
											if (note.tooLate && !note.wasGoodHit)
												breakFromLate = true;
										}
										if (!breakFromLate)
										{
											missNoteCheck((Init.trueSettings.get('Ghost Tapping')) ? true : false,
												strumline.receptors.members[daNote.noteData], boyfriendStrums.singingList, true);
											for (note in parentNote.childrenNotes)
												note.tooLate = true;
										}
										//
									}
									//
								}
							}
						}
					}

					// if the note is off screen (above)
					if ((((!Init.trueSettings.get('Downscroll')) && (daNote.y < -daNote.height))
						|| ((Init.trueSettings.get('Downscroll')) && (daNote.y > (FlxG.height + daNote.height))))
						&& (daNote.tooLate || daNote.wasGoodHit))
						destroyNote(strumline, daNote);
				});

				// unoptimised asf camera control based on strums
				strumCameraRoll(strumline.receptors, (strumline == boyfriendStrums));
			}
		}

		// reset bf's animation
		var holdControls:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		if ((boyfriend != null && boyfriend.animation != null)
			&& (boyfriend.holdTimer > Conductor.stepCrochet * (4 / 1000) && (!holdControls.contains(true) || boyfriendStrums.autoplay)))
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();
		}
	}

	function destroyNote(strumline:Strumline, daNote:Note)
		strumline.remove(daNote, true);

	function goodNoteHit(coolNote:Note, characters:Array<Character>, characterStrums:Strumline, ?canDisplayJudgement:Bool = true)
	{
		if (!coolNote.wasGoodHit)
		{
			coolNote.wasGoodHit = true;
			vocals.volume = 1;

			for (character in characters)
				characterPlayAnimation(coolNote, character);
			if (characterStrums.receptors.members[coolNote.noteData] != null)
				characterStrums.receptors.members[coolNote.noteData].playAnim('confirm', true);

			// special thanks to sam, they gave me the original system which kinda inspired my idea for this new one
			if (canDisplayJudgement)
			{
				// get the note ms timing
				var noteDiff:Float = Math.abs(coolNote.strumTime - Conductor.songPosition);
				// get the timing
				var ratingTiming:Bool;
				if (coolNote.strumTime < Conductor.songPosition)
					ratingTiming = true;
				else
					ratingTiming = false;

				// loop through all avaliable judgements
				var foundRating:String = 'miss';
				var lowestThreshold:Float = Math.POSITIVE_INFINITY;
				for (myRating in Timings.judgementsMap.keys())
				{
					var myThreshold:Float = Timings.judgementsMap.get(myRating)[1];
					if (noteDiff <= myThreshold && (myThreshold < lowestThreshold))
					{
						foundRating = myRating;
						lowestThreshold = myThreshold;
					}
				}

				if (!coolNote.isSustain)
				{
					increaseCombo(foundRating, characterStrums.receptors.members[coolNote.noteData], characters);
					popUpScore(foundRating, ratingTiming, characterStrums, coolNote);
					if (coolNote.childrenNotes.length > 0)
						Timings.notesHit++;
					healthCall(Timings.judgementsMap.get(foundRating)[3]);
				}
				else if (coolNote.isSustain)
				{
					// call updated accuracy stuffs
					if (coolNote.parentNote != null)
					{
						Timings.updateAccuracy(100, true, coolNote.parentNote.childrenNotes.length);
						healthCall(100 / coolNote.parentNote.childrenNotes.length);
					}
				}
			}

			if (!coolNote.isSustain)
				destroyNote(characterStrums, coolNote);
			//
		}
	}

	function missNoteCheck(?includeAnimation:Bool = false, receptor:Receptor, characters:Array<Character>, popMiss:Bool = false, lockMiss:Bool = false)
	{
		if (includeAnimation)
		{
			var stringDirection:String = receptor.getNoteDirection();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			for (character in characters)
				character.playAnim('sing' + stringDirection.toUpperCase() + 'miss', lockMiss);
		}
		decreaseCombo(popMiss);

		//
	}

	function characterPlayAnimation(coolNote:Note, character:Character)
	{
		// alright so we determine which animation needs to play
		// get alt strings and stuffs
		var stringArrow:String = '';
		var altString:String = '';

		var baseString = 'sing' + coolNote.getNoteDirection().toUpperCase();

		stringArrow = baseString + altString;
		// if (coolNote.foreverMods.get('string')[0] != "")
		//	stringArrow = coolNote.noteString;

		character.playAnim(stringArrow, true);
		character.holdTimer = 0;
	}

	private function mainControls(daNote:Note, characters:Array<Character>, strumline:Strumline, autoplay:Bool):Void
	{
		var notesPressedAutoplay = [];

		// here I'll set up the autoplay functions
		if (autoplay)
		{
			// check if the note was a good hit
			if (daNote.strumTime <= Conductor.songPosition)
			{
				// kill the note, then remove it from the array
				var canDisplayJudgement = false;
				if (strumline.displayJudgement)
				{
					canDisplayJudgement = true;
					for (noteDouble in notesPressedAutoplay)
					{
						if (noteDouble.noteData == daNote.noteData)
							canDisplayJudgement = false;
						//
					}
					notesPressedAutoplay.push(daNote);
				}
				goodNoteHit(daNote, characters, strumline, canDisplayJudgement);
			}
			//
		}

		var holdControls:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		if (!autoplay)
		{
			// check if anything is held
			if (holdControls.contains(true))
			{
				// check notes that are alive
				strumline.allNotes.forEachAlive(function(coolNote:Note)
				{
					if ((coolNote.parentNote != null && coolNote.parentNote.wasGoodHit)
						&& coolNote.canBeHit
						&& coolNote.strumline == playerStrumline
						&& !coolNote.tooLate
						&& coolNote.isSustain
						&& holdControls[coolNote.noteData])
						goodNoteHit(coolNote, characters, strumline);
				});
			}
		}
	}

	private function strumCameraRoll(cStrum:FlxTypedSpriteGroup<Receptor>, mustHit:Bool)
	{
		if (!Init.trueSettings.get('No Camera Note Movement'))
		{
			var camDisplaceExtend:Float = 15 / defaultCamZoom;
			if (PlayState.SONG.notes[Std.int(curStep / 16)] != null)
			{
				if ((PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && mustHit)
					|| (!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && !mustHit))
				{
					camDisplaceX = 0;
					if (cStrum.members[0].animation.curAnim.name == 'confirm')
						camDisplaceX -= camDisplaceExtend;
					if (cStrum.members[3].animation.curAnim.name == 'confirm')
						camDisplaceX += camDisplaceExtend;

					camDisplaceY = 0;
					if (cStrum.members[1].animation.curAnim.name == 'confirm')
						camDisplaceY += camDisplaceExtend;
					if (cStrum.members[2].animation.curAnim.name == 'confirm')
						camDisplaceY -= camDisplaceExtend;
				}
			}
		}
		//
	}

	public function pauseGame()
	{
		// pause discord rpc
		updateRPC(true);

		// pause game
		paused = true;

		// update drawing stuffs
		persistentUpdate = false;
		persistentDraw = true;

		// open pause substate
		openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
	}

	override public function onFocus():Void
	{
		if (!paused)
			updateRPC(false);
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		if (canPause && !paused && !Init.trueSettings.get('Auto Pause'))
			pauseGame();
		super.onFocusLost();
	}

	public static function updateRPC(pausedRPC:Bool)
	{
		#if DISCORD_RPC
		var displayRPC:String = (pausedRPC) ? detailsPausedText : songDetails;

		if (health > 0)
		{
			if (Conductor.songPosition > 0 && !pausedRPC)
				Discord.changePresence(displayRPC, detailsSub, iconRPC, true, songLength - Conductor.songPosition);
			else
				Discord.changePresence(displayRPC, detailsSub, iconRPC);
		}
		#end
	}

	function popUpScore(baseRating:String, timing:Bool, strumline:Strumline, coolNote:Note)
	{
		// set up the rating
		var score:Int = 50;

		// notesplashes
		if (baseRating == "sick")
			// create the note splash if you hit a sick
			generateNoteSplash(strumline, coolNote.noteType, coolNote.noteData);
		else
			// if it isn't a sick, and you had a sick combo, then it becomes not sick :(
			if (allSicks)
				allSicks = false;

		displayRating(baseRating, timing);
		Timings.updateAccuracy(Timings.judgementsMap.get(baseRating)[3]);
		score = Std.int(Timings.judgementsMap.get(baseRating)[2]);

		songScore += score;

		popUpCombo();
	}

	public function generateNoteSplash(strumline:Strumline, noteType:String, noteData:Int):ForeverSprite
	{
		var noteModule:ForeverModule = Note.returnNoteScript(noteType);
		if (strumline.noteSplashes != null && noteModule.exists("generateSplash"))
		{
			var splashNote:ForeverSprite = strumline.noteSplashes.recycle(ForeverSprite, function()
			{
				var splashNote:ForeverSprite = new ForeverSprite();
				return splashNote;
			});
			//
			splashNote.alpha = 1;
			splashNote.visible = true;
			splashNote.scale.set(1, 1);
			splashNote.x = strumline.receptors.members[noteData].x;
			splashNote.y = strumline.receptors.members[noteData].y;
			//
			noteModule.get("generateSplash")(splashNote, noteData);
			if (splashNote.animation != null)
			{
				splashNote.animation.finishCallback = function(name:String)
				{
					splashNote.kill();
				}
			}
			splashNote.zDepth = -Conductor.songPosition;
			strumline.noteSplashes.sort(ForeverSprite.depthSorting, FlxSort.DESCENDING);
			return splashNote;
		}
		return null;
	}

	private var createdColor = FlxColor.fromRGB(204, 66, 66);

	private var lastJudgement:ForeverSprite;

	function popUpCombo(?cache:Bool = false)
	{
		// combo
		var comboString:String = Std.string(combo);
		// determine negative combo
		var negative = false;
		if ((comboString.startsWith('-')) || (combo == 0))
			negative = true;

		// display combo
		var stringArray:Array<String> = comboString.split("");
		for (i in 0...stringArray.length)
		{
			var combo:ForeverSprite = comboGroup.recycle(ForeverSprite, function()
			{
				var newCombo:ForeverSprite = new ForeverSprite();
				newCombo.loadGraphic(AssetManager.getAsset('ui/$assetModifier/combo_numbers', IMAGE, 'images'), true, 100, 140);
				newCombo.animation.add('-', [0]);
				for (i in 0...10)
					newCombo.animation.add('$i', [i + 1]);
				for (i in 0...10)
					newCombo.animation.add('$i-perfect', [i + 12]);
				return newCombo;
			});
			combo.alpha = 1;
			if (cache)
				combo.alpha = 0;
			combo.zDepth = -Conductor.songPosition;
			combo.animation.play(stringArray[i]);
			if (Timings.smallestRating == 'sick')
				combo.animation.play(stringArray[i] + '-perfect');
			combo.antialiasing = true;
			combo.setGraphicSize(Std.int(combo.frameWidth * 0.5));

			combo.color = FlxColor.WHITE;
			if (negative)
				combo.color = FlxColor.fromRGB(204, 66, 66);

			combo.acceleration.y = lastJudgement.acceleration.y - FlxG.random.int(100, 200);
			combo.velocity.y = -FlxG.random.int(140, 160);
			combo.velocity.x = FlxG.random.float(-5, 5);

			combo.x = lastJudgement.x + (lastJudgement.width * (1 / 2)) + (43 * i);
			combo.y = lastJudgement.y + lastJudgement.height / 2;

			FlxTween.tween(combo, {alpha: 0}, (Conductor.stepCrochet * 2) / 1000, {
				onComplete: function(tween:FlxTween)
				{
					combo.kill();
				},
				startDelay: (Conductor.crochet) / 1000
			});
		}
		comboGroup.sort(ForeverSprite.depthSorting, FlxSort.DESCENDING);
	}

	function decreaseCombo(?popMiss:Bool = false)
	{
		if (combo > 0)
			combo = 0; // bitch lmao
		else
			combo--;

		// misses
		songScore -= 10;
		misses++;

		// display negative combo
		if (popMiss)
		{
			// doesnt matter miss ratings dont have timings
			displayRating("miss", true);
			healthCall(Timings.judgementsMap.get("miss")[3]);
		}
		popUpCombo();

		// gotta do it manually here lol
		Timings.updateFCDisplay();
	}

	function increaseCombo(?baseRating:String, ?receptor:Receptor, ?characters:Array<Character>)
	{
		// trolled this can actually decrease your combo if you get a bad/shit/miss
		if (baseRating != null)
		{
			if (Timings.judgementsMap.get(baseRating)[3] > 0)
			{
				if (combo < 0)
					combo = 0;
				combo += 1;
			}
			else
				missNoteCheck(true, receptor, characters, false, true);
		}
	}

	public function displayRating(daRating:String, late:Bool, ?cache:Bool = false)
	{
		var curJudgement:ForeverSprite = judgementGroup.recycle(ForeverSprite, function()
		{
			var newJudgement:ForeverSprite = new ForeverSprite();
			newJudgement.loadGraphic(AssetManager.getAsset('ui/$assetModifier/judgements', IMAGE, 'images'), true, 500, 163);
			newJudgement.animation.add('sick-perfect', [0]);
			for (i in Timings.judgementsMap.keys())
			{
				for (j in 0...2)
					newJudgement.animation.add(i + (j == 1 ? '-late' : '-early'), [(Std.int(Timings.judgementsMap[i][0]) * 2) + (j == 1 ? 1 : 0) + 2]);
			}
			//
			return newJudgement;
		});
		curJudgement.alpha = cache ? 0 : 1;

		curJudgement.zDepth = -Conductor.songPosition;
		curJudgement.screenCenter();
		curJudgement.animation.play(daRating + (late ? '-late' : '-early'));
		if (Timings.smallestRating == 'sick' && daRating == 'sick')
			curJudgement.animation.play('sick-perfect');
		curJudgement.antialiasing = true;
		curJudgement.setGraphicSize(Std.int(curJudgement.frameWidth * 0.7));

		curJudgement.x += comboPosition.x;
		curJudgement.y += comboPosition.y;

		curJudgement.acceleration.y = 550;
		curJudgement.velocity.y = -FlxG.random.int(140, 175);
		curJudgement.velocity.x = -FlxG.random.int(0, 10);

		FlxTween.tween(curJudgement, {alpha: 0}, (Conductor.stepCrochet) / 1000, {
			onComplete: function(tween:FlxTween)
			{
				curJudgement.kill();
			},
			startDelay: ((Conductor.crochet + Conductor.stepCrochet * 2) / 1000)
		});
		judgementGroup.sort(ForeverSprite.depthSorting, FlxSort.DESCENDING);

		if (!cache)
		{
			Timings.gottenJudgements.set(daRating, Timings.gottenJudgements.get(daRating) + 1);
			if (Timings.smallestRating != daRating)
			{
				if (Timings.judgementsMap.get(Timings.smallestRating)[0] < Timings.judgementsMap.get(daRating)[0])
					Timings.smallestRating = daRating;
			}
		}
		lastJudgement = curJudgement;
	}

	function healthCall(?ratingMultiplier:Float = 0)
	{
		// health += 0.012;
		var healthBase:Float = 0.06;
		health += (healthBase * (ratingMultiplier / 100));
	}

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused)
		{
			songMusic.play();
			songMusic.onComplete = endSong;
			vocals.play();

			resyncVocals();

			#if desktop
			// Song duration in a float, useful for the time left feature
			songLength = songMusic.length;

			// Updating Discord Rich Presence (with Time Left)
			updateRPC(false);
			#end
		}
	}

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		songDetails = CoolUtil.dashToSpace(SONG.song) + ' - ' + CoolUtil.difficultyFromNumber(storyDifficulty);

		// String for when the game is paused
		detailsPausedText = "Paused - " + songDetails;

		// set details for song stuffs
		detailsSub = "";

		// Updating Discord Rich Presence.
		updateRPC(false);

		songMusic = new FlxSound().loadEmbedded(Paths.inst(SONG.song), false, true);

		vocals = new FlxSound();
		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(SONG.song), false, true);

		FlxG.sound.list.add(songMusic);
		FlxG.sound.list.add(vocals);

		unspawnNotes = ChartLoader.generateChartType(SONG, "FNF");
		if (sys.FileSystem.exists(Paths.songJson(SONG.song.toLowerCase(), 'events')))
		{
			trace('events found');
			var eventJson:SwagSong = Song.loadFromJson('events', SONG.song.toLowerCase());
			if (eventJson != null)
				eventList = ChartLoader.generateChartType(eventJson, 'event');
		}
		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function resyncVocals():Void
	{
		trace('resyncing vocal time ${vocals.time}');
		songMusic.pause();
		vocals.pause();
		Conductor.songPosition = songMusic.time;
		vocals.time = Conductor.songPosition;
		songMusic.play();
		vocals.play();
		trace('new vocal time ${Conductor.songPosition}');
	}

	override function stepHit()
	{
		super.stepHit();
		///*
		if (songMusic.time >= Conductor.songPosition + 20 || songMusic.time <= Conductor.songPosition - 20)
			resyncVocals();
		//*/

		stageBuild.onStep(curStep);
	}

	private function charactersDance(curBeat:Int)
	{
		// /*
		for (strumline in strumLines)
		{
			for (character in strumline.characterList)
			{
				if ((character != null
					&& character.animation.curAnim.name.startsWith("idle")
					|| character.animation.curAnim.name.startsWith("dance")
					&& !character.animation.curAnim.name.startsWith("sing"))
					&& (curBeat % 2 == 0))
					character.dance();
			}
		}

		if (girlfriend != null)
		{
			if ((girlfriend.animation.curAnim.name.startsWith("idle")
				|| girlfriend.animation.curAnim.name.startsWith("dance")
				&& !girlfriend.animation.curAnim.name.startsWith("sing"))
				&& (curBeat % gfSpeed == 0))
				girlfriend.dance();
		}
		//  */
	}

	override function beatHit()
	{
		super.beatHit();

		if (!Init.trueSettings.get('Reduced Movements'))
			cameraZoom();

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
		}

		uiHUD.beatHit();
		stageBuild.onBeat(curBeat);
		charactersDance(curBeat);
	}

	public function cameraZoom()
	{
		//
		if (camZooming)
		{
			if (gameBump < 0.35 && curBeat % 4 == 0)
			{
				// trace('bump');
				gameBump += 0.015;
				hudBump += 0.05;
			}
		}
	}

	public static function resetMusic()
	{
		// simply stated, resets the playstate's music for other states and substates
		if (songMusic != null)
			songMusic.stop();

		if (vocals != null)
			vocals.stop();
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			// trace('null song');
			if (songMusic != null)
			{
				//	trace('nulled song');
				songMusic.pause();
				vocals.pause();
				//	trace('nulled song finished');
			}

			// trace('ui shit break');
			if ((startTimer != null) && (!startTimer.finished))
				startTimer.active = false;
		}

		// trace('open substate');
		super.openSubState(SubState);
		// trace('open substate end ');
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (songMusic != null && !startingSong)
				resyncVocals();

			if ((startTimer != null) && (!startTimer.finished))
				startTimer.active = true;
			paused = false;

			///*
			updateRPC(false);
			// */
		}

		super.closeSubState();
	}

	/*
		Extra functions and stuffs
	 */
	/// song end function at the end of the playstate lmao ironic I guess
	private var endSongEvent:Bool = false;

	function endSong():Void
	{
		canPause = false;
		songMusic.volume = 0;
		vocals.volume = 0;
		if (SONG.validScore)
			Highscore.saveScore(SONG.song, songScore, storyDifficulty);

		deaths = 0;

		if (isStoryMode)
		{
			// set the campaign's score higher
			campaignScore += songScore;

			// remove a song from the story playlist
			storyPlaylist.remove(storyPlaylist[0]);

			// check if there aren't any songs left
			if ((storyPlaylist.length <= 0) && (!endSongEvent))
			{
				// play menu music
				CoolUtil.resetMenuMusic();

				// set up transitions
				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				// change to the menu state
				Main.switchState(this, new StoryMenuState());

				// save the week's score if the score is valid
				if (SONG.validScore)
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);

				// flush the save
				FlxG.save.flush();
			}
			else
				songCutscene(true);
		}
		else {
			songCutscene(true);
		}
		//
	}

	private function finishSongSequence()
	{
		if (!isStoryMode)
		{
			Main.switchState(this, new FreeplayState());
		}
		else
		{
			var difficulty:String = '-' + CoolUtil.difficultyFromNumber(storyDifficulty).toLowerCase();
			difficulty = difficulty.replace('-normal', '');

			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;

			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
			CoolUtil.killMusic([songMusic, vocals]);

			// deliberately did not use the main.switchstate as to not unload the assets
			FlxG.switchState(new PlayState());
		}
	}

	public function songCutscene(atTheEnd:Bool = false)
	{
		inCutscene = true;
		uiHUD.alpha = 0;
		for (strumline in strumLines)
		{
			for (i in 0...strumline.receptors.members.length)
				strumline.receptors.members[i].alpha = 0;
		}

		var funcToCall:String = atTheEnd ? 'songEnding' : 'songIntro';

		switch (PlayState.SONG.song.toLowerCase())
		{
			default:
				// why did i name it the same thing bru
				// this was confusing sorry shubs :sob: @BeastlyGhost
				if (stageBuild.stageModule.exists(funcToCall))
					stageBuild.stageModule.get(funcToCall)();
				else
				{
					if (atTheEnd)
						finishSongSequence();
					else
						startCountdown();
				}
		}
		//
	}

	public var displayCountdown:Bool = true;

	private function startCountdown():Void
	{
		inCutscene = false;
		Conductor.songPosition = -(Conductor.crochet * 5);

		camHUD.visible = true;
		// summon the notes
		for (strumline in strumLines)
		{
			for (i in 0...strumline.receptors.members.length)
			{
				var toAlpha:Float = strumline.receptors.members[i].tweenAlpha;
				var startY:Float = strumline.receptors.members[i].y;
				strumline.receptors.members[i].y -= 32;
				FlxTween.tween(strumline.receptors.members[i], {y: startY, alpha: toAlpha}, (Conductor.crochet * 4) / 1000,
					{ease: FlxEase.circOut, startDelay: (Conductor.crochet / 1000) + ((Conductor.stepCrochet / 1000) * i)});
			}
		}

		FlxTween.tween(uiHUD, {alpha: 1}, (Conductor.crochet * 2) / 1000, {startDelay: (Conductor.crochet / 1000)});

		// overengineering by definition but fuck you
		if (displayCountdown)
		{
			var introArray:Array<FlxGraphic> = [];
			var soundsArray:Array<Sound> = [];
			var introName:Array<String> = ['ready', 'set', 'go'];
			var soundNames:Array<String> = ['intro3', 'intro2', 'intro1', 'introGo'];
			for (intro in introName)
				introArray.push(AssetManager.getAsset('ui/$assetModifier/$intro', IMAGE, 'images'));
			for (sound in soundNames)
				soundsArray.push(AssetManager.returnSound('assets/sounds/$assetModifier/$sound.ogg'));

			var countdown:Int = -1;
			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (countdown >= 0 && countdown < introArray.length)
				{
					var introSprite:FlxSprite = new FlxSprite().loadGraphic(introArray[countdown]);
					introSprite.scrollFactor.set();
					introSprite.updateHitbox();
					introSprite.antialiasing = true;

					introSprite.screenCenter();
					add(introSprite);
					FlxTween.tween(introSprite, {y: introSprite.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							introSprite.destroy();
						}
					});
				}
				countdown++;

				FlxG.sound.play(soundsArray[countdown], 0.6);
				charactersDance(curBeat);
			}, 5);
		}
	}

	override function add(Object:FlxBasic):FlxBasic
	{
		if (Init.trueSettings.get('Disable Antialiasing') && Std.isOfType(Object, FlxSprite))
			cast(Object, FlxSprite).antialiasing = false;
		return super.add(Object);
	}
}
