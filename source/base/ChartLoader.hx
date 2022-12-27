package base;

import base.ScriptHandler.ForeverModule;
import base.Events.PlacedEvent;
import states.PlayState;
import base.Song;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.*;

/**
	This is the chartloader class. it loads in charts, but also exports charts, the chart parameters are based on the type of chart, 
	say the base game type loads the base game's charts, the forever chart type loads a custom forever structure chart with custom features,
	and so on. This class will handle both saving and loading of charts with useful features and scripts that will make things much easier
	to handle and load, as well as much more modular!
**/
class ChartLoader
{
	// hopefully this makes it easier for people to load and save chart features and such, y'know the deal lol
	public static function generateChartType(songData:SwagSong, ?typeOfChart:String = "FNF"):Dynamic
	{
		var unspawnNotes:Array<Note> = [];
		var noteData:Array<SwagSection>;

		noteData = songData.notes;
		switch (typeOfChart)
		{
			default:
				for (section in noteData)
				{
					var coolSection:Int = Std.int(section.lengthInSteps / 4);

					for (songNotes in section.sectionNotes)
					{
						if (songNotes[1] != -1)
						{
							var daStrumTime:Float = #if !neko songNotes[0] - Init.trueSettings['Offset'] /* - | late, + | early */ #else songNotes[0] #end;
							var daNoteData:Int = Std.int(songNotes[1] % 4);
							var daNoteType:String = 'default';

							// convert "Hurt Note"s to "Mine"s
							if (songNotes.length > 2)
							{
								if (Std.isOfType(songNotes[3], String))
								{
									switch (songNotes[3])
									{
										case "Hurt Note":
											songNotes[3] = 'mine';
										default:
											songNotes[3] = 'default';
									}
									daNoteType = songNotes[3];
								}
							}

							/**
								for Cubii, I don't know whether notetypes work or not
								so it's good to test the before anything

								psych conversion SHOULD work for mines though
								@BeastlyGhost
							**/

							// check the base section
							var gottaHitNote:Bool = section.mustHitSection;

							// if the note is on the other side, flip the base section of the note
							if (songNotes[1] > 3)
								gottaHitNote = !section.mustHitSection;

							// define the note that comes before (previous note)
							var oldNote:Note;
							if (unspawnNotes.length > 0)
								oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
							else // if it exists, that is
								oldNote = null;

							// create the new note
							var swagNote:Note = new Note(daStrumTime, daNoteData, daNoteType, gottaHitNote ? 1 : 0, false);
							unspawnNotes.push(swagNote);

							if (songNotes[2] > 0)
							{
								var susLength:Float = (songNotes[2] / Conductor.stepCrochet) + 1;
								for (susNote in 0...Math.floor(susLength))
								{
									oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
									var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, daNoteType,
										gottaHitNote ? 1 : 0, true, oldNote);
									if (susNote == susLength - 1)
										sustainNote.isSustainEnd = true;
									unspawnNotes.push(sustainNote);
								}
							}
						}
						else
							pushEvent(songNotes, PlayState.eventList);
					}
				}

			case 'event':
				var eventList:Array<PlacedEvent> = [];
				for (section in noteData)
				{
					for (songNotes in section.sectionNotes)
						pushEvent(songNotes, eventList);
				}
				return eventList;
		}

		return unspawnNotes;
	}

	public static function pushEvent(note:Array<Dynamic>, myEventList:Array<PlacedEvent>)
	{
		var daStrumTime:Float = note[0] - Init.trueSettings['Offset']; // - | late, + | early
		// event notes
		if (Events.eventList.contains(note[2]))
		{
			var mySelectedEvent:String = Events.eventList[Events.eventList.indexOf(note[2])];
			if (mySelectedEvent != null)
			{
				// /*
				var module:ForeverModule = Events.loadedModules.get(note[2]);
				var delay:Float = 0;
				if (module.exists("returnDelay"))
					delay = module.get("returnDelay")();
				//
				var myEvent:PlacedEvent = {
					timestamp: daStrumTime + (delay * Conductor.stepCrochet),
					params: [note[3], note[4]],
					eventName: note[2],
				};
				//
				if (module.exists("initFunction"))
					module.get("initFunction")(myEvent.params);
				// */
				myEventList.push(myEvent);
			}
		}
		//
	}
}
