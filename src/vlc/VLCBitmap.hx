package vlc;

#if !(desktop || android)
#error "The current target platform isn't supported by hxCodec. If you're targeting Windows/Mac/Linux/Android and getting this message, please contact us.";
#end
import cpp.NativeArray;
import cpp.UInt8;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.PixelSnapping;
import openfl.display3D.textures.RectangleTexture;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.utils.ByteArray;
import haxe.io.Bytes;
import vlc.LibVLC;

/**
 * ...
 * @author Tommy Svensson
 *
 * This class lets you to use `LibVLC` as a bitmap then you can displaylist along other items.
 */
class VLCBitmap extends Bitmap
{
	public var videoFramerate:Int = 60;
	public var videoHeight(get, never):Int;
	public var videoWidth(get, never):Int;
	public var volume(default, set):Float;

	private var bufferMemory:Array<UInt8> = [];
	private var texture:RectangleTexture;
	private var _width:Null<Float>;
	private var _height:Null<Float>;

	public var initComplete:Bool = false;
	public var onReady:Void->Void = null;
	public var onPlay:Void->Void = null;
	public var onStop:Void->Void = null;
	public var onPause:Void->Void = null;
	public var onResume:Void->Void = null;
	public var onBuffer:Void->Void = null;
	public var onOpening:Void->Void = null;
	public var onComplete:Void->Void = null;
	public var onError:String->Void = null;
	public var onTimeChanged:Int->Void = null;
	public var onPositionChanged:Int->Void = null;
	public var onSeekableChanged:Int->Void = null;
	public var onForward:Void->Void = null;
	public var onBackward:Void->Void = null;

	public function new():Void
	{
		super(bitmapData, PixelSnapping.AUTO, true);

		LibVLC.create();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	/**
		Loads and plays the video file..

		@param	path	The video path (the location of the video in the files).
		@param	loop	If you want to loop the video.
		@param	haccelerated	If you want to have hardware acceleration enabled for the video.
	**/
	public function loadVideo(path:String = null, loop:Bool = false, haccelerated:Bool = true):Void
	{
		if (path != null)
		{
			#if HXC_DEBUG_TRACE
			trace("Video path: " + path);
			#end

			LibVLC.loadVideo(path, loop, haccelerated);
		}
	}

	/**
		Plays the video.
	**/
	public function play():Void
	{
		if (LibVLC.isMediaPlayerAlive())
			LibVLC.play();	
	}

	/**
		Stops the video.
	**/
	public function stop():Void
	{
		if (LibVLC.isMediaPlayerAlive())
			LibVLC.stop();
	}

	/**
		Pauses the video.
	**/
	public function pause():Void
	{
		if (LibVLC.isMediaPlayerAlive())
		{
			LibVLC.pause();

			if (onPause != null)
				onPause();
		}
	}

	/**
		Resumes the video.
	**/
	public function resume():Void
	{
		if (LibVLC.isMediaPlayerAlive())
		{
			LibVLC.resume();

			if (onResume != null)
				onResume();
		}
	}

	/**
		Pauses / Resumes the video.
	**/
	public function togglePause():Void
	{
		if (LibVLC.isMediaPlayerAlive())
			LibVLC.togglePause();
	}

	/**
		Seeking the procent of the video.

		@param	seekProcen  The procent you want to seek the video.
	**/
	public function seek(seekProcent:Float):Void
	{
		if (LibVLC.isMediaPlayerAlive() && LibVLC.isSeekable())
			LibVLC.setPosition(seekProcent);
	}

	/**
		Setting the time of the video.

		@param	time The video time you want to set.
	**/
	public function setTime(time:Int):Void
	{
		if (LibVLC.isMediaPlayerAlive())
			LibVLC.setTime(time);
	}

	/**
		Returns the time of the video.
	**/
	public function getTime():Int
	{
		if (LibVLC.isMediaPlayerAlive())
			return LibVLC.getTime();
		else
			return 0;
	}

	/**
		Setting the volume of the video.

		@param	vol	 The video volume you want to set.
	**/
	public function setVolume(vol:Float):Void
	{
		if (LibVLC.isMediaPlayerAlive())
			LibVLC.setVolume(vol * 100);
	}

	/**
		Returns the volume of the video.
	**/
	public function getVolume():Float
	{
		if (LibVLC.isMediaPlayerAlive())
			return LibVLC.getVolume();
		else
			return 0;
	}

	/**
		Sets the Framerate of the video.

		@param	fps	 The video FPS you want to set.
	**/
	public function setVideoFramerate(fps:Int):Void
	{
		videoFramerate = fps;
	}

	/**
		Returns the Framerate of the video.
	**/
	public function getVideoFramerate():Int
	{
		return videoFramerate;
	}

	/**
		Returns the duration of the video.
	**/
	public function getDuration():Float
	{
		if (LibVLC.isMediaPlayerAlive())
			return LibVLC.getDuration();
		else
			return 0;
	}

	/**
		Returns the frames per second of the video.
	**/
	public function getFPS():Float
	{
		if (LibVLC.isMediaPlayerAlive())
			return LibVLC.getFPS();
		else
			return 0;
	}

	/**
		Returns the length of the video.
	**/
	public function getLength():Float
	{
		if (LibVLC.isMediaPlayerAlive())
			return LibVLC.getLength();
		else
			return 0;
	}

	private function checkFlags():Void
	{
		if (LibVLC.getFlag(1) == 1)
		{
			LibVLC.setFlag(1, -1);
			if (onPlay != null)
				onPlay();
		}
		if (LibVLC.getFlag(2) == 1)
		{
			LibVLC.setFlag(2, -1);
			if (onStop != null)
				onStop();
		}
		if (LibVLC.getFlag(3) == 1)
		{
			LibVLC.setFlag(3, -1);

			#if HXC_DEBUG_TRACE
			trace("The Video got done!");
			#end

			if (onComplete != null)
				onComplete();
		}
		if (LibVLC.getFlag(4) != -1)
		{
			var newTime:Int = LibVLC.getFlag(4);

			#if HXC_DEBUG_TRACE
			trace("video time now is: " + newTime);
			#end

			if (onTimeChanged != null)
				onTimeChanged(newTime);
		}
		if (LibVLC.getFlag(5) != -1)
		{
			var newPos:Int = LibVLC.getFlag(5);

			#if HXC_DEBUG_TRACE
			trace("the position of the video now is: " + newPos);
			#end

			if (onPositionChanged != null)
				onPositionChanged(newPos);
		}
		if (LibVLC.getFlag(6) != -1)
		{
			var newPos:Int = LibVLC.getFlag(6);

			#if HXC_DEBUG_TRACE
			trace("the seeked pos of the video now is: " + newPos);
			#end

			if (onSeekableChanged != null)
				onSeekableChanged(newPos);
		}
		if (LibVLC.getFlag(7) == 1)
		{
			LibVLC.setFlag(7, -1);
			if (onError != null)
				onError(LibVLC.getLastError());
		}
		if (LibVLC.getFlag(8) == 1)
		{
			LibVLC.setFlag(8, -1);

			if (!initComplete)
				videoInitComplete();

			if (onOpening != null)
				onOpening();
		}
		if (LibVLC.getFlag(9) == 1)
		{
			LibVLC.setFlag(9, -1);
			if (onBuffer != null)
				onBuffer();
		}
		if (LibVLC.getFlag(10) == 1)
		{
			LibVLC.setFlag(10, -1);
			if (onForward != null)
				onForward();
		}
		if (LibVLC.getFlag(11) == 1)
		{
			LibVLC.setFlag(11, -1);
			if (onBackward != null)
				onBackward();
		}
	}

	private function videoInitComplete():Void
	{
		if (texture != null)
			texture.dispose();

		texture = Lib.current.stage.context3D.createRectangleTexture(LibVLC.getWidth(), LibVLC.getHeight(), BGRA, true);

		if (bitmapData != null)
			bitmapData.dispose();

		bitmapData = BitmapData.fromTexture(texture);

		if (bufferMemory.length > 0)
			bufferMemory = [];

		if (_width != null)
			width = _width;
		else
			width = LibVLC.getWidth();

		if (_height != null)
			height = _height;
		else
			height = LibVLC.getHeight();

		initComplete = true;

		if (onReady != null)
			onReady();

		#if HXC_DEBUG_TRACE
		trace("Video Loaded!");
		#end
	}

	private function init(?e:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE)) removeEventListener(Event.ADDED_TO_STAGE, init);

		stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	private var currentTime:Float = 0;
	private function onEnterFrame(?e:Event):Void
	{
		checkFlags();

		// LibVLC.getPixelData() sometimes is null and the app hangs ...
		if ((LibVLC.isPlaying() && initComplete) && LibVLC.getPixelData() != null)
		{
			var time:Int = Lib.getTimer();
			var elements:Int = LibVLC.getWidth() * LibVLC.getHeight() * 4;
			renderToTexture(time - currentTime, elements);			
		}
	}

	private function renderToTexture(deltaTime:Float, elementsCount:Int):Void
	{
		if (deltaTime > (1000 / videoFramerate))
		{
			currentTime = deltaTime;

			#if HXC_DEBUG_TRACE
			trace("Rendering...");
			#end

			NativeArray.setUnmanagedData(bufferMemory, LibVLC.getPixelData(), elementsCount);

			if (texture != null && (bufferMemory != null && bufferMemory.length > 0))
			{
				var bytes:ByteArray = Bytes.ofData(cast(bufferMemory));
				if (bytes.length >= elementsCount)
					texture.uploadFromByteArray(Bytes.ofData(cast(bufferMemory)), 0);
			}
		}
	}

	/**
		Dispose the whole bitmap.
	**/
	public function dispose():Void
	{
		#if HXC_DEBUG_TRACE
		trace("Disposing the bitmap!");
		#end

		if (LibVLC.isPlaying())
			LibVLC.stop();

		if (stage.hasEventListener(Event.ENTER_FRAME))
			stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);

		if (texture != null)
		{
			texture.dispose();
			texture = null;
		}

		if (bitmapData != null)
		{
			bitmapData.dispose();
			bitmapData = null;
		}

		if (bufferMemory.length > 0)
			bufferMemory = [];

		initComplete = false;

		onReady = null;
		onComplete = null;
		onPause = null;
		onOpening = null;
		onPlay = null;
		onResume = null;
		onStop = null;
		onBuffer = null;
		onTimeChanged = null;
		onPositionChanged = null;
		onSeekableChanged = null;
		onForward = null;
		onBackward = null;
		onError = null;

		#if HXC_DEBUG_TRACE
		trace("Disposing Done!");
		#end
	}

	@:noCompletion private function get_videoHeight():Int
	{
		if (initComplete)
			return LibVLC.getHeight();

		return 0;
	}

	@:noCompletion private function get_videoWidth():Int
	{
		if (initComplete)
			return LibVLC.getWidth();

		return 0;
	}

	private override function get_width():Float
	{
		return _width;
	}

	private override function set_width(value:Float):Float
	{
		_width = value;
		return super.set_width(value);
	}

	private override function get_height():Float
	{
		return _height;
	}

	private override function set_height(value:Float):Float
	{
		_height = value;
		return super.set_height(value);
	}

	private function set_volume(value:Float):Float
	{
		setVolume(value);
		return volume = value;
	}
}
