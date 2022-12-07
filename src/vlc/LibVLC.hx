package vlc;

#if !(desktop || android)
#error "The current target platform isn't supported by hxCodec. If you are targeting Windows/Mac/Linux/Android and you are getting this message, please contact us.";
#end
import cpp.Pointer;
import cpp.UInt8;

/**
 * ...
 * @author Tommy Svensson
 *
 * This class lets you to use the c++ code of libvlc as a extern class which you can use in HaxeFlixel.
 */
@:buildXml("<include name='${haxelib:hxCodec}/src/vlc/LibVLCBuild.xml' />")
@:include("LibVLC.cpp")
@:unreflective
@:keep
extern class LibVLC
{
	@:native("create")
	public static function create():Void;

	@:native("play")
	public static function play():Void;

	@:native("stop")
	public static function stop():Void;

	@:native("pause")
	public static function pause():Void;

	@:native("resume")
	public static function resume():Void;

	@:native("togglePause")
	public static function togglePause():Void;

	@:native("loadVideo")
	public static function loadVideo(path:String, loop:Bool, haccelerated:Bool):Void;

	@:native("getLength")
	public static function getLength():Float;

	@:native("getDuration")
	public static function getDuration():Float;

	@:native("getFPS")
	public static function getFPS():Float;

	@:native("getWidth")
	public static function getWidth():Int;

	@:native("getHeight")
	public static function getHeight():Int;

	@:native("isPlaying")
	public static function isPlaying():Bool;

	@:native("isSeekable")
	public static function isSeekable():Bool;

	@:native("isMediaPlayerAlive")
	public static function isMediaPlayerAlive():Bool;

	@:native("getLastError")
	public static function getLastError():String;

	@:native("setVolume")
	public static function setVolume(volume:Float):Void;

	@:native("getVolume")
	public static function getVolume():Float;

	@:native("setTime")
	public static function setTime(time:Int):Void;

	@:native("getTime")
	public static function getTime():Int;

	@:native("setPosition")
	public static function setPosition(pos:Float):Void;

	@:native("getPosition")
	public static function getPosition():Float;

	@:native("getPixelData")
	public static function getPixelData():Pointer<UInt8>;

	@:native("setFlag")
	public static function setFlag(flag:Int, value:Int):Void;

	@:native("getFlag")
	public static function getFlag(flag:Int):Int;
}
