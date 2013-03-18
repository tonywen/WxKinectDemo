package com.eventsManger
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class EventsManager extends EventDispatcher
	{
		public function EventsManager(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		private static var _instance : EventsManager;
		public static function get instance() : EventsManager
		{
			if(_instance == null)
				_instance= new EventsManager;
			return _instance;
		}
		
		public function dispatch(e : Event) : void
		{
			this.dispatchEvent(e);
		}
	}
}