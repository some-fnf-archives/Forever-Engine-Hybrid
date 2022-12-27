package;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;
import openfl.media.Sound;
import sys.FileSystem;
import sys.io.File;

@:enum abstract EngineImplementation(String) to String
{
	var FNF;
	var FNF_LEGACY;
	var FOREVER;
}

@:enum abstract AssetType(String) to String
{
	var IMAGE = 'image';
	var SPARROW = 'sparrow';
	var SOUND = 'sound';
	var MUSIC = 'music';
	var FONT = 'font';
	var DIRECTORY = 'directory';
	var MODULE = 'module';
	var JSON = 'json';
}

/*
 * This is the Asset Manager class, it manages the asset usage in the engine.
 * It's meant to both allow access to assets and at the same time manage and catalogue used assets.
 */
class AssetManager
{
	public static var keyedAssets:Map<String, Dynamic> = [];

	/**
	 * Returns an Asset based on the parameters and groups given.
	 * @param directory The asset directory, from within the assets folder (excluding 'assets/')
	 * @param group The asset group used to index the asset, like IMAGES or SONGS
	 * @return Dynamic
	 */
	public static function getAsset(directory:String, ?type:AssetType = DIRECTORY, ?group:String):Dynamic
	{
		var gottenPath = getPath(directory, group, type);
		switch (type)
		{
			case JSON:
				return File.getContent(gottenPath);
			case IMAGE:
				return returnGraphic(gottenPath, false);
			case SOUND | MUSIC:
				var soundMusic:String = getPath(directory, group, SOUND);
				return returnSound(soundMusic);
			case SPARROW:
				var graphicPath = getPath(directory, group, IMAGE);
				var graphic:FlxGraphic = returnGraphic(graphicPath, false);
				return FlxAtlasFrames.fromSparrow(graphic, File.getContent(gottenPath));
			default:
				return gottenPath;
		}
		trace('returning null for $gottenPath');
		return null;
	}

	/**
	 * Returns a graphic or image as a bitmap readable by the game. 
	 * 
	 * It is not recommended to use this function unless you want to access 
	 * a specific directory or access GPU resources as getAsset(directory, IMAGE); 
	 * already provides a similar function that takes into account packs.
	 * 
	 * @param key The asset directory in its entirety. 
	 * @param gpuRender If the image should be rendered by the GPU. (default is false)
	 */
	public static function returnGraphic(key:String, ?gpuRender:Bool = false)
	{
		if (FileSystem.exists(key))
		{
			if (!Paths.currentTrackedAssets.exists(key))
			{
				var bitmap = BitmapData.fromFile(key);
				var newGraphic:FlxGraphic;
				if (gpuRender)
				{
					var texture = FlxG.stage.context3D.createTexture(bitmap.width, bitmap.height, BGRA, true);
					texture.uploadFromBitmapData(bitmap);
					Paths.currentTrackedTextures.set(key, texture);
					bitmap.dispose();
					bitmap.disposeImage();
					bitmap = null;
					// trace('new texture $key, bitmap is $bitmap');
					newGraphic = FlxGraphic.fromBitmapData(BitmapData.fromTexture(texture), false, key, false);
				}
				else
				{
					newGraphic = FlxGraphic.fromBitmapData(bitmap, false, key, false);
					// trace('new bitmap $key, not textured');
				}
				newGraphic.persist = true;
				Paths.currentTrackedAssets.set(key, newGraphic);
			}
			// trace('graphic returning $key with gpu rendering $gpuRender');
			Paths.localTrackedAssets.push(key);
			return Paths.currentTrackedAssets.get(key);
		}
		trace('graphic returning null at $key with gpu rendering $gpuRender');
		return null;
	}

	/**
	 * [Returns a Sound when given a Key]
	 * @param key The asset directory in its entirety. 
	 */
	public static function returnSound(key:String)
	{
		if (FileSystem.exists(key))
		{
			if (!keyedAssets.exists(key))
			{
				keyedAssets.set(key, Sound.fromFile('./' + key));
				// trace('new sound $key');
			}
			trace('sound returning $key');
			return keyedAssets.get(key);
		}
		trace('sound returning null at $key');
		return null;
	}

	/**
	 * Returns the path for an asset with avaliabled keyed assets and paths. Alternatively use getAsset(directory, DIRECTORY);
	 * @param directory The asset directory, from within the assets folder (excluding 'assets/')
	 * @param group The asset group used to index the asset, like IMAGES or SONGS
	 * @return String
	 */
	public static function getPath(directory:String, group:String, ?type:AssetType = DIRECTORY):String
	{
		var pathBase:String = 'assets/';
		var directoryExtension:String = '$group/$directory';
		return filterExtensions('$pathBase$directoryExtension', type);
	}

	public static function filterExtensions(directory:String, type:String)
	{
		if (!FileSystem.exists(directory))
		{
			var extensions:Array<String> = [];
			switch (type)
			{
				case IMAGE:
					extensions = ['.png'];
				case JSON:
					extensions = ['.json'];
				case SPARROW:
					extensions = ['.xml'];
				case SOUND:
					extensions = ['.ogg', '.wav'];
				case FONT:
					extensions = ['.ttf', '.otf'];
				case MODULE:
					extensions = ['.hxs', '.hx'];
			}
			// trace(extensions);
			// apply the extension of the directory
			for (i in extensions)
			{
				var returnDirectory:String = '$directory$i';
				// trace('attempting directory $returnDirectory');
				if (FileSystem.exists(returnDirectory))
				{
					// trace('successful extension $i');
					return returnDirectory;
				}
			}
		}
		// trace('no extension needed, returning $directory');
		return directory;
	}
}
