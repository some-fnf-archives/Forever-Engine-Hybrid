package funkin;

import AssetManager;
import base.Conductor;
import base.ForeverDependencies;
import base.ScriptHandler;
import funkin.Strumline.ReceptorData;
import funkin.Strumline;
import haxe.Json;

class Note extends ForeverSprite
{
	public var noteData:Int;
	public var strumTime:Float;
	public var strumline:Int = 0;
	public var noteType:String = null;
	public var isSustain:Bool = false;
	public var isMine:Bool = false; // for mine notes / hurt notes
	//
	public var prevNote:Note;
	public var isSustainEnd:Bool = false;
	public var endHoldOffset:Float = Math.NEGATIVE_INFINITY;
	//
	public var noteHealth:Float = 1;
	public var ignoreNote:Bool = false;
	public var lowPriority:Bool = false;
	public var hitboxLength:Float = 1;

	public var parentNote:Note;
	public var childrenNotes:Array<Note> = [];

	// values
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public var useCustomSpeed:Bool = false;
	public var customNoteSpeed:Float;
	public var noteSpeed(default, set):Float;

	public function set_noteSpeed(value:Float):Float
	{
		if (noteSpeed != value)
		{
			noteSpeed = value;
			updateSustainScale();
		}
		return noteSpeed;
	}

	public var tooLate:Bool = false;
	public var canBeHit:Bool = false;
	public var wasGoodHit:Bool = false;

	public static var scriptCache:Map<String, ForeverModule> = [];
	public static var dataCache:Map<String, ReceptorData> = [];

	public var receptorData:ReceptorData;
	public var noteModule:ForeverModule;

	// used for keeping sustains sane for some reason, basically prevents bpm changes from messing with things - codist
	private var initialStepCrochet:Float = Conductor.stepCrochet;

	public function new(strumTime:Float, index:Int, noteType:String, strumline:Int, ?isSustain:Bool = false, ?prevNote:Note)
	{
		noteData = index;
		this.strumTime = strumTime;
		this.strumline = strumline;
		this.isSustain = isSustain;
		this.prevNote = prevNote;

		super();

		// determine parent note
		if (isSustain && prevNote != null)
		{
			parentNote = prevNote;
			while (parentNote.parentNote != null)
				parentNote = parentNote.parentNote;
			parentNote.childrenNotes.push(this);
		}
		else if (!isSustain)
			parentNote = null;

		loadNote(noteType);
	}

	public function loadNote(noteType:String)
	{
		if (this.noteType != noteType)
		{
			this.noteType = noteType;
			receptorData = returnNoteData(noteType);
			noteModule = returnNoteScript(noteType);

			// truncated loading functions by a ton
			noteModule.interp.variables.set('getNoteDirection', getNoteDirection);
			noteModule.interp.variables.set('getNoteColor', getNoteColor);

			var generationScript:String = isSustain ? 'generateSustain' : 'generateNote';
			if (noteModule.exists(generationScript))
				noteModule.get(generationScript)(this);
			else
			{
				this.destroy();
				return;
			}

			// set note data stuffs
			antialiasing = receptorData.antialiasing;
			setGraphicSize(Std.int(frameWidth * receptorData.size));
			updateHitbox();
		}
	}

	public function updateSustainScale()
	{
		if (isSustain)
		{
			alpha = 0.6;
			if (prevNote != null && prevNote.exists)
			{
				if (prevNote.isSustain)
				{
					// listen I dont know what i was doing but I was onto something
					prevNote.scale.y = (prevNote.width / prevNote.frameWidth) * ((initialStepCrochet / 100) * (1.07 / prevNote.receptorData.size)) * noteSpeed;
					prevNote.updateHitbox();
					offsetX = prevNote.offsetX;
				}
				else
					offsetX = ((prevNote.width / 2) - (width / 2));
			}
		}
	}

	public static function returnNoteData(noteType:String):ReceptorData
	{
		// load up the note data
		if (!dataCache.exists(noteType))
		{
			trace('setting note data $noteType');
			dataCache.set(noteType, cast Json.parse(AssetManager.getAsset(noteType, JSON, 'notetypes/$noteType')));
		}
		return dataCache.get(noteType);
	}

	public static function returnNoteScript(noteType:String):ForeverModule
	{
		// load up the note script
		if (!scriptCache.exists(noteType))
		{
			trace('setting note script $noteType');
			scriptCache.set(noteType, ScriptHandler.loadModule(noteType, 'notetypes/$noteType'));
		}
		return scriptCache.get(noteType);
	}

	public function getNoteDirection()
		return receptorData.actions[noteData];

	public function getNoteColor()
		return receptorData.colors[noteData];

	override public function update(elapsed:Float)
	{
		if (strumTime > (Conductor.songPosition - Timings.msThreshold * hitboxLength) //
			&& strumTime < (Conductor.songPosition + Timings.msThreshold * hitboxLength))
			canBeHit = true;
		else
			canBeHit = false;

		super.update(elapsed);

		if (noteModule.exists('onUpdate'))
			noteModule.get('onUpdate')(this);
	}

	public function noteHit()
	{
		if (noteModule.exists('onHit'))
			noteModule.get('onHit')(this);
	}

	public function noteMiss()
	{
		if (noteModule.exists('onMiss'))
			noteModule.get('onMiss')(this);
	}

	public function stepHit()
	{
		if (noteModule.exists('onStep'))
			noteModule.get('onStep')(this);
	}

	public function beatHit()
	{
		if (noteModule.exists('onBeat'))
			noteModule.get('onBeat')(this);
	}
}
