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
import flash.events.IEventDispatcher;
import flash.utils.ByteArray;

/**
 *  The IThreadedImageEncoder interface defines the interface
 *  that image encoders implement to take BitmapData objects,
 *  or ByteArrays containing raw ARGB pixels, as input
 *  and convert them to popular image formats such as PNG or JPEG.
 *  With threads. Kind of.
 * 
 *  @see PNGThreadedEncoder
 *  @see JPEGThreadedEncoder
 *  @see TGAThreadedEncoder
 */
public interface IThreadedImageEncoder extends IEventDispatcher
{
	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------

	//----------------------------------
	//  contentType
	//----------------------------------

    /**
     *  The MIME type for the image format that this encoder produces.
     */
    function get contentType():String;

	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------

    /**
     *  Encodes a BitmapData object as a ByteArray.
     *
     *  @param bitmapData The input BitmapData object.
     *
     *  @returns A ByteArray object containing encoded image data. 
     */
    function encode(bitmapData:BitmapData):void;

    /**
     *  Encodes a ByteArray object containing raw pixels
	 *  in 32-bit ARGB (Alpha, Red, Green, Blue) format
	 *  as a new ByteArray object containing encoded image data.
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
     *  @param transparent If <code>false</code>,
	 *  alpha channel information is ignored.
     *
     *  @returns A ByteArray object containing encoded image data.
     */
    function encodeByteArray(byteArray:ByteArray, width:int, height:int,
							 transparent:Boolean = true):void;
	
	function writeHeader(e:Event = null):void;
	function writeDataLoop(e:Event = null):void;
	function writeFooter(e:Event = null):void;
	function getEncodedImage():ByteArray;
	
	function setFilePath(file:String):void;
	function getFilePath():String;
	
	function setFrameRate(value:int):void;
	function getFrameRate():int;
	function setAffinity(value:Number):void;
	function getAffinity():Number;
	
	function finish():void;
	function stop():void;
}

}