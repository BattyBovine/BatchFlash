////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2007 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package com.battybovine.codec
{

import flash.display.BitmapData;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.TimerEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;
import flash.utils.Timer;
import flash.utils.getTimer;

/**
 *  The PNGEncoder class converts raw bitmap images into encoded
 *  images using Portable Network Graphics (PNG) lossless compression.
 *
 *  <p>For the PNG specification, see http://www.w3.org/TR/PNG/</p>.
 *  
 *  @langversion 3.0
 *  @playerversion Flash 9
 *  @playerversion AIR 1.1
 *  @productversion Flex 3
 */
public class PNGThreadedEncoder extends EventDispatcher implements IThreadedImageEncoder
{
	//--------------------------------------------------------------------------
	//
	//  Class constants
	//
	//--------------------------------------------------------------------------

    /**
     *  @private
	 *  The MIME type for a PNG image.
     */
    private static const CONTENT_TYPE:String = "image/png";

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
    public function PNGThreadedEncoder()
    {
    	super();
		
		initializeCRCTable();
	}

	//--------------------------------------------------------------------------
	//
	//  Variables
	//
	//--------------------------------------------------------------------------

    /**
     *  @private
	 *  Used for computing the cyclic redundancy checksum
	 *  at the end of each chunk.
     */
    private var crcTable:Array;
	
	private var loopTimer:Timer;
	private var loopFrameRate:int = 30;
	private var loopAffinity:Number = 0.85;
	
	private var encodefile:String;
	private var bitmapDataToEncode:BitmapData;
	private var byteArrayToEncode:ByteArray;
	private var width:int = 0;
	private var height:int = 0;
	private var transparent:Boolean = true;
	private var IHDR:ByteArray;
	private var IDAT:ByteArray = new ByteArray();
	private var row:int = 0;
	private var pngdata:ByteArray;
	
	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------

	//----------------------------------
	//  contentType
	//----------------------------------

    /**
     *  The MIME type for the PNG encoded image.
     *  The value is <code>"image/png"</code>.
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
	 *  to a PNG-encoded ByteArray object.
     *
     *  @param bitmapData The input BitmapData object.
     *
     *  @return Returns a ByteArray object containing PNG-encoded image data.
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
    public function encodeByteArray(byteArray:ByteArray, width:int, height:int,
									transparent:Boolean = true):void
    {
		byteArrayToEncode = byteArray;
		width = width;
		height = height;
		transparent = transparent;
		
		byteArrayToEncode.position = 0;
		
		dispatchEvent(new Event(ThreadedEncoderEvent.START_ENCODE));
    }

    /**
	 *  @private
	 */
	private function initializeCRCTable():void
	{
		crcTable = [];

        for (var n:uint = 0; n < 256; n++)
        {
            var c:uint = n;
            for (var k:uint = 0; k < 8; k++)
            {
                if (c & 1)
                    c = uint(uint(0xedb88320) ^ uint(c >>> 1));
				else
                    c = uint(c >>> 1);
             }
            crcTable[n] = c;
        }
	}
	
	public function writeHeader(e:Event = null):void
	{
		// Create output byte array
        pngdata = new ByteArray();

        // Write PNG signature
        pngdata.writeUnsignedInt(0x89504E47);
        pngdata.writeUnsignedInt(0x0D0A1A0A);

        // Build IHDR chunk
        IHDR = new ByteArray();
        IHDR.writeInt(width);
        IHDR.writeInt(height);
		IHDR.writeByte(8); // bit depth per channel
		IHDR.writeByte(6); // color type: RGBA
		IHDR.writeByte(0); // compression method
		IHDR.writeByte(0); // filter method
        IHDR.writeByte(0); // interlace method
        writeChunk(pngdata, 0x49484452, IHDR);
		
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
    private function writeDataChunk(e:Event = null):void
	{
		var startTime:int = getTimer();
		var endTime:int = startTime;
		
		if (row >= height) {
			if(loopTimer) {
				loopTimer.removeEventListener(TimerEvent.TIMER, writeDataChunk);
				loopTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, endWriteDataLoopEventHandler);
				loopTimer.stop();
				loopTimer = null;
			}
			
			var compressStartTime:int = getTimer();
			IDAT.compress();
			writeChunk(pngdata, 0x49444154, IDAT);
			var compressEndTime:int = getTimer();
			trace("Compression took " + ((compressEndTime-compressStartTime) / 1000).toString() + " seconds.");
			
			dispatchEvent(new Event(ThreadedEncoderEvent.COMPLETE_DATA_WRITTEN));
		} else {
			// Run the loop while the number of milliseconds is less than a frame, accounting for the requested CPU idle
			while(((endTime-startTime) < ((1000 / loopFrameRate) * (loopAffinity / 100)))) {
				IDAT.writeByte(0); // no filter
				
				var x:int;
				var pixel:uint;
				
				if (!transparent)
				{
					for (x = 0; x < width; x++)
					{
						if (bitmapDataToEncode)
							pixel = bitmapDataToEncode.getPixel(x, row);
						else
							pixel = byteArrayToEncode.readUnsignedInt();

						IDAT.writeUnsignedInt(uint(((pixel & 0xFFFFFF) << 8) | 0xFF));
					}
				}
				else
				{
					for (x = 0; x < width; x++)
					{
						if (bitmapDataToEncode)
							pixel = bitmapDataToEncode.getPixel32(x, row);
						else
							pixel = byteArrayToEncode.readUnsignedInt();

						IDAT.writeUnsignedInt(uint(((pixel & 0xFFFFFF) << 8) |
													(pixel >>> 24)));
					}
				}
				row++;
				if (row >= height) {
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
		// Build IEND chunk
        writeChunk(pngdata, 0x49454E44, null);

        // return PNG
        pngdata.position = 0;
		
		dispatchEvent(new Event(ThreadedEncoderEvent.FOOTER_WRITTEN));
	}
	
	

    /**
	 *  @private
	 */
	private function writeChunk(png:ByteArray, type:uint, data:ByteArray):void
    {
        // Write length of data.
        var len:uint = 0;
        if (data)
            len = data.length;
		png.writeUnsignedInt(len);
        
		// Write chunk type.
		var typePos:uint = png.position;
		png.writeUnsignedInt(type);
        
		// Write data.
		if (data)
            png.writeBytes(data);

        // Write CRC of chunk type and data.
		var crcPos:uint = png.position;
        png.position = typePos;
        var crc:uint = 0xFFFFFFFF;
        for (var i:uint = typePos; i < crcPos; i++)
        {
            crc = uint(crcTable[(crc ^ png.readUnsignedByte()) & uint(0xFF)] ^
					   uint(crc >>> 8));
        }
        crc = uint(crc ^ uint(0xFFFFFFFF));
        png.position = crcPos;
        png.writeUnsignedInt(crc);
    }
	
	public function getEncodedImage():ByteArray
	{
		return pngdata;
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
		loopAffinity = Math.max(0,Math.min(value,100));
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
		if(loopTimer) {
			loopTimer.removeEventListener(TimerEvent.TIMER, writeDataChunk);
			loopTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, endWriteDataLoopEventHandler);
			loopTimer.stop();
		}
		dispatchEvent(new Event(ThreadedEncoderEvent.ENCODE_CANCELLED));
	}
}

}