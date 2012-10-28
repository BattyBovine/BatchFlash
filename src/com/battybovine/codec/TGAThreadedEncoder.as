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

package com.battybovine.codec
{

import flash.display.BitmapData;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.TimerEvent;
import flash.utils.Endian;
import flash.utils.ByteArray;
import flash.utils.Timer;
import flash.utils.getTimer;

/**
 *  The TGAEncoder class converts raw bitmap images into encoded
 *  images using Truevision TARGA (TGA) lossless compression.
 *
 *  <p>For the PNG specification, see http://www.w3.org/TR/PNG/</p>.
 *  
 *  @langversion 3.0
 *  @playerversion Flash 9
 *  @playerversion AIR 1.1
 *  @productversion Flex 3
 */
public class TGAThreadedEncoder extends EventDispatcher implements IThreadedImageEncoder
{
    //--------------------------------------------------------------------------
	//
	//  Class constants
	//
	//--------------------------------------------------------------------------

    /**
     *  @private
	 *  The MIME type for a TGA image.
     */
    private static const CONTENT_TYPE:String = "image/x-tga";
	
	private var rleEncoding:Boolean;
	private var loopFrameRate:int = 30;
	private var loopAffinity:Number = 0.85;
	
	private var encodefile:String;
	private var bitmapDataToEncode:BitmapData;
	private var byteArrayToEncode:ByteArray;
	private var width:int = 0;
	private var height:int = 0;
	private var transparent:Boolean = true;
	private var imgdata:ByteArray;
	private var tga:ByteArray;
	
	private var loopTimer:Timer;
	private var row:int = 0;

	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------

    /**
     *  Constructor.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public function TGAThreadedEncoder(rle:Boolean = false)
    {
		super();
		
		rleEncoding = rle;
	}
    
	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------

	//----------------------------------
	//  contentType
	//----------------------------------

    /**
     *  The MIME type for the TGA encoded image.
     *  The value is <code>"image/x-tga"</code>.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public function get contentType():String
    {
        return CONTENT_TYPE;
    }

	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------

    /**
     *  Converts the pixels of a BitmapData object
	 *  to a TGA-encoded ByteArray object.
     *
     *  @param bitmapData The input BitmapData object.
     *
     *  @return Returns a ByteArray object containing TGA-encoded image data.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public function encode(bitmapData:BitmapData):void
    {
        bitmapDataToEncode = bitmapData;
		width = bitmapData.width;
		height = bitmapData.height;
		transparent = bitmapData.transparent;
		
		dispatchEvent(new Event(ThreadedEncoderEvent.START_ENCODE));
    }

    /**
     *  Converts a ByteArray object containing raw pixels
	 *  in 32-bit ARGB (Alpha, Red, Green, Blue) format
	 *  to a new PNG-encoded ByteArray object.
	 *  The original ByteArray is left unchanged.
     *
     *  @param byteArray The input ByteArray object containing raw pixels.
	 *  This ByteArray should contain
	 *  <code>4 * width * height</code> bytes.
	 *  Each pixel is represented by 4 bytes, in the order ARGB.
	 *  The first four bytes represent the top-left pixel of the image.
	 *  The next four bytes represent the pixel to its right, etc.
	 *  Each row follows the previous one without any padding.
     *
     *  @param width The width of the input image, in pixels.
     *
     *  @param height The height of the input image, in pixels.
     *
     *  @param transparent If <code>false</code>, alpha channel information
	 *  is ignored but you still must represent each pixel 
     *  as four bytes in ARGB format.
     *
     *  @return Returns a ByteArray object containing PNG-encoded image data. 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public function encodeByteArray(byteArray:ByteArray, width:int, height:int, transparent:Boolean = true):void
    {
        byteArrayToEncode = byteArray;
		width = width;
		height = height;
		transparent = transparent;
		
		byteArrayToEncode.position = 0;
		
		dispatchEvent(new Event(ThreadedEncoderEvent.START_ENCODE));
    }
	
	public function writeHeader(e:Event = null):void
	{
		imgdata = new ByteArray();
		imgdata.endian = Endian.LITTLE_ENDIAN;
		
     	// Create output byte array
        tga = new ByteArray();

        // Write TGA header
        tga.writeBytes(createHeader(width, height));
		
		row = height-1;
		
		dispatchEvent(new Event(ThreadedEncoderEvent.HEADER_WRITTEN));
	}
	
	public function writeDataLoop(e:Event = null):void
	{
		// Set a timer such that the write loop runs as long as a frame at the given
		// frame rate, accounting for the fact that 20 milliseconds is the shortest
		// safe timer frequency
		loopTimer = new Timer(Math.max(20, 1000 / loopFrameRate), loopFrameRate);
		loopTimer.addEventListener(TimerEvent.TIMER, writeDataChunk);
		loopTimer.addEventListener(TimerEvent.TIMER_COMPLETE, endWriteDataLoopEventHandler);
		loopTimer.start();
	}
    public function writeDataChunk(e:Event = null):void
	{
		var startTime:int = getTimer();
		var endTime:int = startTime;
		
		if (row < 0) {
			if(loopTimer) {
				loopTimer.removeEventListener(TimerEvent.TIMER, writeDataChunk);
				loopTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, endWriteDataLoopEventHandler);
				loopTimer.stop();
				loopTimer = null;
			}
			
			if(rleEncoding) {
				var compressStartTime:int = getTimer();
				tga.writeBytes(runLengthEncoder(imgdata));
				var compressEndTime:int = getTimer();
				trace("Compression took " + ((compressEndTime-compressStartTime) / 1000).toString() + " seconds.");
			} else {
				tga.writeBytes(imgdata);
			}
			
			dispatchEvent(new Event(ThreadedEncoderEvent.COMPLETE_DATA_WRITTEN));
		} else {
			// Run the loop while the number of milliseconds is less than a frame, accounting for the requested CPU idle
			while(((endTime-startTime) < ((1000 / loopFrameRate) * (loopAffinity / 100)))) {
				var pixel:uint;
				for (var x:int = 0; x < width; x++) {
					if (!transparent) {
						if (bitmapDataToEncode)
							pixel = bitmapDataToEncode.getPixel(x, row);
						else
							pixel = byteArrayToEncode.readUnsignedInt();
					} else {
						if (bitmapDataToEncode)
							pixel = bitmapDataToEncode.getPixel32(x, row);
						else
							pixel = byteArrayToEncode.readUnsignedInt();
					}
					
					imgdata.writeInt(pixel);
				}
				row--;
				if (row < 0) {
					break;
				}
				
				endTime += (getTimer()-endTime);
			}
		}
	}
	private function endWriteDataLoopEventHandler(e:TimerEvent = null):void {
		if(loopTimer) {
			loopTimer.removeEventListener(TimerEvent.TIMER, writeDataChunk);
			loopTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, endWriteDataLoopEventHandler);
			loopTimer.stop();
			loopTimer = null;
		}
		dispatchEvent(new Event(ThreadedEncoderEvent.DATA_CHUNK_WRITTEN));
	}
	
	public function writeFooter(e:Event = null):void
	{
        tga.position = 0;
		
		dispatchEvent(new Event(ThreadedEncoderEvent.FOOTER_WRITTEN));
	}
	
	private function createHeader(w:int, h:int):ByteArray {
        var HEAD:ByteArray = new ByteArray();
		HEAD.endian = Endian.LITTLE_ENDIAN;
		
		HEAD.writeByte(0);	// No Image ID field
		HEAD.writeByte(0);	// No colour map
		HEAD.writeByte(2);	// RLE true colour
		HEAD.writeShort(0);	// No colour map offset
		HEAD.writeShort(0);	// No colour map length
		HEAD.writeByte(0);	// No colour map entry
		
		HEAD.writeShort(0);	// X origin at 0
		HEAD.writeShort(0);	// Y origin at 0
		
		HEAD.writeShort(w);	// Image width
		HEAD.writeShort(h);	// Image height
		
		HEAD.writeByte(32);	// RGBA image (32bpp)
		HEAD.writeByte(8);	// 8 attribute bits per pixel
		
        return HEAD;
	}
	
	private function runLengthEncoder(data:ByteArray):ByteArray {
		var compressedData:ByteArray = new ByteArray();
		
		var rawbytes:ByteArray = new ByteArray();	// Contains all bytes from this cycle that will not be run-length encoded
		rawbytes.endian = Endian.LITTLE_ENDIAN;
		var rlebytes:ByteArray = new ByteArray();	// Contains all bytes from this cycle that will be run-length encoded
		rlebytes.endian = Endian.LITTLE_ENDIAN;
		
		var cmpbyte:uint = data.readUnsignedInt();
		var rawmode:Boolean = true;
		while (data.bytesAvailable) {
			var curbyte:uint = cmpbyte;
			cmpbyte = data.readUnsignedInt();
			
			if (curbyte == cmpbyte) {
				if (rawmode && rawbytes.length) {
					compressedData.writeBytes(rawPacket(rawbytes));
					rawbytes.clear();
				}
				rlebytes.writeUnsignedInt(curbyte);
			} else {
				if (!rawmode && rlebytes.length) {
					compressedData.writeBytes(rlePacket(rlebytes));
					rlebytes.clear();
				}
				rawbytes.writeUnsignedInt(curbyte);
			}
			
			if (rlebytes.length == (127*4)) {
				compressedData.writeBytes(rlePacket(rlebytes));
				rlebytes.clear();
			}
			if (rawbytes.length == (127*4)) {
				compressedData.writeBytes(rawPacket(rawbytes));
				rawbytes.clear();
			}
		}
		compressedData.position = 0;
		
		return compressedData;
	}
	private function rawPacket(raw:ByteArray):ByteArray {
		var out:ByteArray = new ByteArray();
		
		out.writeByte(raw.length & 0x7F);
		out.writeBytes(raw);
		return out;
	}
	private function rlePacket(rle:ByteArray):ByteArray {
		var out:ByteArray = new ByteArray();
		out.writeByte(rle.length & 0xFF);
		out.writeBytes(rle);
		return out;
	}
	
	public function getEncodedImage():ByteArray
	{
		return tga;
	}
	
	public function setFilePath(file:String):void
	{
		encodefile = file;
	}
	
	public function getFilePath():String
	{
		return encodefile;
	}
	
	
	
	public function setFrameRate(value:int):void
	{
		loopFrameRate = Math.round(Math.max(0,Math.min(value,60))) as int;
	}
	
	public function getFrameRate():int
	{
		return loopFrameRate;
	}
	
	public function setAffinity(value:Number):void
	{
		loopAffinity = Math.max(1,Math.min(value,100));
	}
	
	public function getAffinity():Number
	{
		return loopAffinity;
	}
	
	
	
	public function finish():void
	{
		dispatchEvent(new Event(ThreadedEncoderEvent.ENCODE_COMPLETE));
	}
	public function stop():void
	{
		dispatchEvent(new Event(ThreadedEncoderEvent.ENCODE_CANCELLED));
	}
}

}
