package base;

import states.PlayState;
import sys.FileSystem;
import base.ScriptHandler.ForeverModule;

using StringTools;

typedef PlacedEvent =
{
	var timestamp:Float;
	var params:Array<Dynamic>;
	var eventName:String;
};

class Events
{
	public static var eventList:Array<String> = [];
	public static var loadedModules:Map<String, ForeverModule> = [];

	public static function obtainEvents()
	{
		loadedModules.clear();
		eventList = FileSystem.readDirectory('assets/events');
		if (eventList == null)
			eventList = [];
		if (eventList.length > 0)
		{
			for (i in 0...eventList.length)
			{
				eventList[i] = eventList[i].substring(0, eventList[i].indexOf('.', 0));
				loadedModules.set(eventList[i], ScriptHandler.loadModule('events/${eventList[i]}'));
			}
			eventList.sort(function(a, b) return Reflect.compare(a.toLowerCase(), b.toLowerCase()));
		}
		eventList.insert(0, '');
		//
	}

	public static function returnDescription(event:String):String
	{
		if (loadedModules.get(event) != null)
		{
			var module:ForeverModule = loadedModules.get(event);
			if (module.exists('returnDescription'))
				return module.get('returnDescription')();
		}
		return '';
	}
}
