/* 
 * Copyright (c) 2012 Jamie Greunbaum
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 * 
 */

package com.battybovine
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	/**
	 * ...
	 * @author Jamie Greunbaum
	 */
	public class PreferencesManager extends EventDispatcher
	{
		
		public static const LOADED:String = "prefsLoaded";
		public static const SAVED:String = "prefsSaved";
		public static const OUTPUTDIRECTORY_CHANGED:String = "prefsOutputDirectoryChanged";
		public static const OUTPUTRESOLUTION_CHANGED:String = "prefsOutputResolutionChanged";
		public static const OUTPUTFORMAT_CHANGED:String = "prefsOutputFormatChanged";
		public static const OUTPUTQUALITY_CHANGED:String = "prefsOutputQualityChanged";
		public static const ASPECT_CHANGED:String = "prefsAspectChanged";
		
		private var outputdirectory:String = null;
		private var outputresolution:String = null;
		private var outputformat:int = -1;
		private var outputquality:int = -1;
		private var aspect:String = null;
		
		public function load():void {
			trace("Loading preferences...");
			
			var prefsfile:File = File.applicationStorageDirectory.resolvePath("Preferences.sol");
			if (prefsfile.exists) {
				var prefsstream:FileStream = new FileStream();
				prefsstream.open(prefsfile, FileMode.READ);
				outputdirectory = prefsstream.readUTF();
				outputresolution = prefsstream.readUTF();
				outputformat = prefsstream.readInt();
				outputquality = prefsstream.readInt();
				aspect = prefsstream.readUTF();
				prefsstream.close();
			
				trace("Load complete");
				dispatchEvent(new Event(LOADED));
			}
			
			/* Encrypted Local Store code
			//if (EncryptedLocalStore.getItem("outputdirectory"))
				//outputdirectory.text = EncryptedLocalStore.getItem("outputdirectory").readUTF();
			//if (EncryptedLocalStore.getItem("outputresolution"))
				//outputresolution.text = EncryptedLocalStore.getItem("outputresolution").readUTF();
			//if (EncryptedLocalStore.getItem("outputformat")) {
				//outputformat.selectedIndex = parseInt(EncryptedLocalStore.getItem("outputformat").readUTF());
				//outputformat.dispatchEvent(new ListEvent("change"));
			//}
			//if (EncryptedLocalStore.getItem("outputquality"))
				//outputquality.value = parseInt(EncryptedLocalStore.getItem("outputquality").readUTF());
			//if (EncryptedLocalStore.getItem("aspect"))
				//aspect.selectedIndex = parseInt(EncryptedLocalStore.getItem("aspect").readUTF());
			*/
		}
		
		public function save():void {
			trace("Saving preferences...");
			
			var prefsfile:File = File.applicationStorageDirectory.resolvePath("Preferences.sol");
			if (prefsfile.exists)	prefsfile.deleteFile();
			
			var prefsstream:FileStream = new FileStream();
			prefsstream.open(prefsfile, FileMode.WRITE);
			prefsstream.writeUTF(outputdirectory);
			prefsstream.writeUTF(outputresolution);
			prefsstream.writeInt(outputformat);
			prefsstream.writeInt(outputquality);
			prefsstream.writeUTF(aspect);
			prefsstream.close();
			
			/* Encrypted Local Store code
			//var outputdirectorybytes:ByteArray = new ByteArray();	outputdirectorybytes.writeUTF(outputdirectory.text);
			//var outputresolutionbytes:ByteArray = new ByteArray();	outputresolutionbytes.writeUTF(outputresolution.text);
			//var outputformatbytes:ByteArray = new ByteArray();	outputdirectorybytes.writeUTF(outputformat.selectedIndex.toString());
			//var outputqualitybytes:ByteArray = new ByteArray();	outputdirectorybytes.writeUTF(outputquality.value.toString());
			//var aspectbytes:ByteArray = new ByteArray();	outputdirectorybytes.writeUTF(aspect.selectedIndex.toString());
			//
			//EncryptedLocalStore.setItem("outputdirectory", outputdirectorybytes);
			//EncryptedLocalStore.setItem("outputresolution", outputresolutionbytes);
			//EncryptedLocalStore.setItem("outputformat", outputformatbytes);
			//EncryptedLocalStore.setItem("outputquality", outputqualitybytes);
			//EncryptedLocalStore.setItem("aspect", aspectbytes);
			*/
			
			trace("Save complete");
			dispatchEvent(new Event(SAVED));
		}
		
		
		
		public function setOutputDirectory(i:String):void {
			outputdirectory = i;
			dispatchEvent(new Event(OUTPUTDIRECTORY_CHANGED));
		}
		
		public function setOutputResolution(i:String):void {
			outputresolution = i;
			dispatchEvent(new Event(OUTPUTRESOLUTION_CHANGED));
		}
		
		public function setOutputFormat(i:int):void {
			outputformat = i;
			dispatchEvent(new Event(OUTPUTFORMAT_CHANGED));
		}
		
		public function setOutputQuality(i:int):void {
			outputquality = i;
			dispatchEvent(new Event(OUTPUTQUALITY_CHANGED));
		}
		
		public function setAspect(i:String):void {
			aspect = i;
			dispatchEvent(new Event(ASPECT_CHANGED));
		}
		
		
		
		public function getOutputDirectory():String {
			return outputdirectory;
		}
		
		public function getOutputResolution():String {
			return outputresolution;
		}
		public function getOutputWidth():int {
			return outputresolution.match(/(\d+)[x×]\d+/)[1];
		}
		public function getOutputHeight():int {
			return outputresolution.match(/\d+[x×](\d+)/)[1];
		}
		
		public function getOutputFormat():int {
			return outputformat;
		}
		
		public function getOutputQuality():int {
			return outputquality;
		}
		
		public function getAspect():String {
			return aspect;
		}
		
		
		
		public function preferencesLoaded():Boolean {
			return (outputdirectory!=null && outputresolution!=null && outputformat>=0 && outputquality>=0 && aspect!=null);
		}
	
	}
}