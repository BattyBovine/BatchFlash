package com.battybovine.codec 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Jamie Greunbaum
	 */
	public class ThreadedEncoderEvent extends Event 
	{
		
		public function ThreadedEncoderEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) 
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			return new ThreadedEncoderEvent(type, bubbles, cancelable);
		}
		
		override public function toString():String
		{
			return formatToString("ThreadedEncoderEvent", "type", "bubbles", "cancelable", "eventPhase");
		}
		
		
		
		public static const START_ENCODE:String = "StartEncode";
		public static const HEADER_WRITTEN:String = "HeaderWritten";
		public static const DATA_CHUNK_WRITTEN:String = "DataChunkWritten";
		public static const COMPLETE_DATA_WRITTEN:String = "CompleteDataWritten";
		public static const FOOTER_WRITTEN:String = "FooterWritten";
		public static const ENCODE_COMPLETE:String = "EncodeComplete";
		public static const ENCODE_CANCELLED:String = "EncodeCancelled";
	}

}