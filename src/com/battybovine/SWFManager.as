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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import mx.controls.SWFLoader;
	
	/**
	 * ...
	 * @author Jamie Greunbaum
	 */
	public class SWFManager extends EventDispatcher
	{
		
		private var loadedSWF:SWFLoader = null;
		private var swfcontroller:MovieClip = new MovieClip();
		
		private function beginLoadingSWF(filepath:String):void {
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadSWF);
			var fLoader:ForcibleLoader = new ForcibleLoader(loader);
			fLoader.load(new URLRequest(filepath));
			seekbar.addEventListener(Event.CHANGE, seekbarChange);
			seekbar.enabled = true;
		}
		private function loadSWF(e:Event):void {
			loadedSWF.width = e.currentTarget.width;
			loadedSWF.height = e.currentTarget.height;
			loadedSWF.source = e.currentTarget.content;
			
			//trace("Loaded SWF container size: " + loadedSWF.width + ", " + loadedSWF.height);
			//trace("Loaded SWF source size:    " + loadedSWF.source.width + ", " + loadedSWF.source.height);
			//trace("Loaded SWF source scale:   " + loadedSWF.source.scaleX + ", " + loadedSWF.source.scaleY);
			
			swfcontroller = e.currentTarget.content as MovieClip;
			swfcontroller.addEventListener(Event.ADDED_TO_STAGE,updateCapturedImage);
			swfcontroller.gotoAndStop(1);
			
			seekbar.maximum = swfcontroller.totalFrames;
		}
		private function updateCapturedImage():void {
			capturedImage.source = captureSWFFrame(capturedImage.width, capturedImage.height);
		}
		private function captureSWFFrame(capturewidth:int, captureheight:int, aspect:int = 1):Bitmap {
			var fitaspect:Boolean = true;
			var aspectcrop:Boolean = false;
			switch(aspect) {
				case 0:
					// letterboxing/pillarboxing
					fitaspect = false;
					aspectcrop = false;
					break;
				case 2:
					// cropping
					fitaspect = true;
					aspectcrop = true;
					break;
			}
			
			var scalex:Number = 1;
			var scaley:Number = 1;
			
			if(!fitaspect || aspectcrop) {
				// Calculate the desired scale of our image based on the dimension that is proportionally larger than the desired output resolution
				scalex = scaley = (((loadedSWF.height * capturewidth) / captureheight) >= loadedSWF.width)
					? (capturewidth / loadedSWF.width)
					: (captureheight / loadedSWF.height);
			} else {
				// Scale each side of the SWF to match the dimensions of our output image
				scalex = capturewidth / loadedSWF.width;
				scaley = captureheight / loadedSWF.height;
			}
			
			// Create a new bitmap containing a scaled version of our SWF
			var bd:BitmapData = new BitmapData(loadedSWF.width*scalex, loadedSWF.height*scaley, true);
			var scalematrix:Matrix = new Matrix(scalex, 0, 0, scaley);
			bd.draw(loadedSWF, scalematrix);
			
			var bm:Bitmap = null;
			// Crop it down if we were asked to
			if(fitaspect && aspectcrop) {
				var crop:Rectangle = new Rectangle(((loadedSWF.width * scalex) - capturewidth) / 2, ((loadedSWF.height * scalex) - captureheight) / 2, capturewidth, captureheight);
				var bdcrop:BitmapData = new BitmapData(crop.width, crop.height, true);
				bdcrop.copyPixels(bd, crop, new Point(0, 0));
				bm = new Bitmap(bdcrop);
			} else {
				bm = new Bitmap(bd);
			}
			
			if (bm == null) {
				trace("Bitmap is null somehow.");
				return null;
			}
			
			return bm;
		}
		
		private function beginUnloadingSWF():void {
			loadedSWF.unloadAndStop(true);
			capturedImage.unloadAndStop(true);
			seekbar.enabled = false;
			seekbar.removeEventListener(Event.CHANGE, seekbarChange);
			seekbar.maximum = 1;
		}
		
	}
	
}