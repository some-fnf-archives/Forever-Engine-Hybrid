package base;

import AssetManager;
import Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.Note;
import funkin.Strumline;
import haxe.ds.StringMap;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import states.PlayState;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
 * Handles the Backend and Script interfaces of Forever Engine, as well as exceptions and crashes.
 */
class ScriptHandler
{
	/**
	 * Shorthand for exposure, specifically public exposure. 
	 * All scripts will be able to access these variables globally.
	 */
	public static var exp:StringMap<Dynamic>;

	public static var parser:Parser = new Parser();

	/**
	 * [Initializes the basis of the Scripting system]
	 */
	public static function initialize()
	{
		exp = new StringMap<Dynamic>();

		// Classes (Haxe)
		// /*
		exp.set("Sys", Sys);
		exp.set("Std", Std);
		exp.set("Math", Math);
		exp.set("StringTools", StringTools);

		// Classes (Flixel)
		exp.set("FlxG", FlxG);
		exp.set("FlxSprite", FlxSprite);
		exp.set("FlxMath", FlxMath);
		exp.set("FlxTween", FlxTween);
		exp.set("FlxEase", FlxEase);
		exp.set("FlxTimer", FlxTimer);

		// Classes (Forever)
		exp.set("Conductor", Conductor);
		exp.set("Note", Note);
		exp.set("Strumline", Strumline);
		exp.set("PlayState", PlayState);

		/**
			maybe changing this to a single function
			to allow people to only grab setting values @BeastlyGhost
		**/
		exp.set("Init", Init);

		//  */

		parser.allowTypes = true;
	}

	public static function loadModule(path:String, ?assetGroup:String, ?extraParams:StringMap<Dynamic>):ForeverModule
	{
		trace('Loading Module $path');
		var curModule:ForeverModule = null;
		var modulePath:String = AssetManager.getAsset(path, MODULE, assetGroup);
		if (FileSystem.exists(modulePath))
			curModule = new ForeverModule(parser.parseString(File.getContent(modulePath), modulePath), assetGroup, extraParams);
		return curModule;
	}
}

/**
 * The basic module class, for handling externalized scripts individually
 */
class ForeverModule
{
	public var interp:Interp;
	public var assetGroup:String;
	public var path:Paths; // the defined path
	public var alive:Bool = true;

	public function new(?contents:Expr, ?assetGroup:String, ?extraParams:StringMap<Dynamic>)
	{
		interp = new Interp();
		// Variable functionality
		for (i in ScriptHandler.exp.keys())
			interp.variables.set(i, ScriptHandler.exp.get(i));
		// Local Variable functionality
		if (extraParams != null)
		{
			for (i in extraParams.keys())
				interp.variables.set(i, extraParams.get(i));
		}
		// Asset functionality
		this.assetGroup = assetGroup;
		interp.variables.set('getAsset', getAsset);
		// define the current path (used within the script itself)
		var path = new LocalPath(assetGroup);
		interp.variables.set('Paths', path);
		interp.execute(contents);
	}

	/**
		* [Returns a field from the module]
			 * @param field 
			 * @return Dynamic
		return interp.variables.get(field)
	 */
	public function get(field:String):Dynamic
		return interp.variables.get(field);

	/**
	 * [Sets a field within the module to a new value]
	 * @param field 
	 * @param value 
	 * @return interp.variables.set(field, value)
	 */
	public function set(field:String, value:Dynamic)
		interp.variables.set(field, value);

	/**
		* [Checks the existence of a value or exposure within the module]
		* @param field 
		* @return Bool
				return interp.variables.exists(field)
	 */
	public function exists(field:String):Bool
		return interp.variables.exists(field);

	/**
	 * [Returns an asset from the local module path]
	 * @param directory The local directory of the requested asset 
	 * @param type The type of the requested asset
	 * @return returns the requested asset
	 */
	public function getAsset(directory:String, type:AssetType)
	{
		var path:String = AssetManager.getPath(directory, assetGroup, type);
		// trace('attempting path $path');
		if (FileSystem.exists(path))
			return AssetManager.getAsset(directory, type, assetGroup);
		else
		{
			trace('path failed');
			return AssetManager.getAsset(directory, type);
		}
	}
}
