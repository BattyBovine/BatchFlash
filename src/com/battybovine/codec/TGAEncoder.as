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

import flash.utils.Endian;
import mx.graphics.codec.IImageEncoder;
import flash.display.BitmapData;
import flash.utils.ByteArray;

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
public class TGAEncoder implements IImageEncoder
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
    public function TGAEncoder(rle:Boolean = false)
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
    public function encode(bitmapData:BitmapData):ByteArray
    {
        return internalEncode(bitmapData, bitmapData.width, bitmapData.height, bitmapData.transparent);
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
    public function encodeByteArray(byteArray:ByteArray, width:int, height:int, transparent:Boolean = true):ByteArray
    {
        return internalEncode(byteArray, width, height, transparent);
    }

    /**
	 *  @private
	 */
	private function internalEncode(source:Object, width:int, height:int, transparent:Boolean = true):ByteArray
    {
     	// The source is either a BitmapData or a ByteArray.
    	var sourceBitmapData:BitmapData = source as BitmapData;
    	var sourceByteArray:ByteArray = source as ByteArray;
    	
    	if (sourceByteArray)	sourceByteArray.position = 0;
    	
        // Create output byte array
        var tga:ByteArray = new ByteArray();

        // Write TGA header
        tga.writeBytes(createHeader(width, height));
		
		// Write TGA image data
		var imgdata:ByteArray = new ByteArray();
		imgdata.endian = Endian.LITTLE_ENDIAN;
		var pixel:uint;
		for (var y:int = height-1; y >= 0; y--) {
			for (var x:int = 0; x < width; x++) {
				if (sourceBitmapData)
					pixel = sourceBitmapData.getPixel32(x, y);
				else
					pixel = sourceByteArray.readUnsignedInt();
				
				imgdata.writeInt(pixel);
			}
		}
		if(rleEncoding)
			tga.writeBytes(runLengthEncoder(imgdata));
		else
			tga.writeBytes(imgdata);
		
        tga.position = 0;
        return tga;
    }
	
	private function createHeader(w:int, h:int):ByteArray {
        var HEAD:ByteArray = new ByteArray();
		HEAD.endian = Endian.LITTLE_ENDIAN;
		
		//var id:String = "Batty Bovine Productions, LLC";
		
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
		
		//HEAD.writeMultiByte(id,"iso-8859-1");	// Image ID
		
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
}

}
