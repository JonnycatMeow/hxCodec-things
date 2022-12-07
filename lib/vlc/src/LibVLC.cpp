#include <LibVLC.h>
#include <stdint.h>

static void *lock(void *data, void **p_pixels)
{
	t_ctx *ctx = (t_ctx*) data;
	*p_pixels = ctx->pixeldata;
	return NULL;
}

static void unlock(void *data, void *id, void *const *p_pixels)
{
	t_ctx *ctx = (t_ctx*) data;
}

static void display(void *data, void *id)
{
	t_ctx *ctx = (t_ctx*) data;
}

static unsigned format_setup(void **opaque, char *chroma, unsigned *width, unsigned *height, unsigned *pitches, unsigned *lines)
{
	struct ctx *callback = reinterpret_cast< struct ctx*> (*opaque);

	unsigned _w = (*width);
	unsigned _h = (*height);
	unsigned _pitch = _w * 4;
	unsigned _frame = _w *_h * 4;

	(*pitches) = _pitch;
	(*lines) = _h;

	memcpy(chroma, "RV32", 4);

	if (callback->pixeldata != 0)
		delete callback->pixeldata;

	callback->pixeldata = new unsigned char[_frame];
	return 1;
}

static void format_cleanup(void *opaque)
{
	// Sirox, same here. -jigsaw
}

void create()
{
	char const *argv[] = {
		"--drop-late-frames",
		"--ignore-config",
		"--intf", "dummy",
		"--no-disable-screensaver",
		"--no-snapshot-preview",
		"--no-stats",
		"--no-video-title-show",
		"--no-xlib",
		"--text-renderer", "dummy",
		#if DEBUG
		"--verbose=2",
		#endif
		"--quiet",
	};

	int argc = sizeof(argv) / sizeof(*argv);
	libVlcInstance = libvlc_new(argc, argv);
}

void play()
{
	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
		libvlc_media_player_play(libVlcMediaPlayer);
}

void stop()
{
	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
		libvlc_media_player_stop(libVlcMediaPlayer);
}

void pause()
{
	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
		libvlc_media_player_set_pause(libVlcMediaPlayer, 1);
}

void resume()
{
	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
		libvlc_media_player_set_pause(libVlcMediaPlayer, 0);
}

void togglePause()
{
	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
		libvlc_media_player_pause(libVlcMediaPlayer);
}

void loadVideo(const char *path, bool loop, bool haccelerated)
{
	libVlcMediaItem = libvlc_media_new_path(libVlcInstance, path);
	libVlcMediaPlayer = libvlc_media_player_new_from_media(libVlcMediaItem);

	libvlc_media_parse(libVlcMediaItem);

	if (loop)
	{
		#ifdef ANDROID
		libvlc_media_add_option(libVlcMediaItem, "input-repeat=65535");
		#else
		libvlc_media_add_option(libVlcMediaItem, "input-repeat=-1");
		#endif
	}
	else
		libvlc_media_add_option(libVlcMediaItem, "input-repeat=0");

	if (haccelerated)
	{
		libvlc_media_add_option(libVlcMediaItem, ":hwdec=vaapi");
		libvlc_media_add_option(libVlcMediaItem, ":ffmpeg-hw");
		libvlc_media_add_option(libVlcMediaItem, ":avcodec-hw=dxva2.lo");
		libvlc_media_add_option(libVlcMediaItem, ":avcodec-hw=any");
		libvlc_media_add_option(libVlcMediaItem, ":avcodec-hw=dxva2");
		libvlc_media_add_option(libVlcMediaItem, "--avcodec-hw=dxva2");
		libvlc_media_add_option(libVlcMediaItem, ":avcodec-hw=vaapi");
	}

	libvlc_media_release(libVlcMediaItem);

	ctx.pixeldata = 0;

	libvlc_video_set_format_callbacks(libVlcMediaPlayer, format_setup, format_cleanup);
	libvlc_video_set_callbacks(libVlcMediaPlayer, lock, unlock, display, &ctx);

	libVlcEventManager = libvlc_media_player_event_manager(libVlcMediaPlayer);

	libvlc_event_attach(libVlcEventManager, libvlc_MediaPlayerPlaying, callbacks, NULL);
	libvlc_event_attach(libVlcEventManager, libvlc_MediaPlayerStopped, callbacks, NULL);
	libvlc_event_attach(libVlcEventManager, libvlc_MediaPlayerEndReached, callbacks, NULL);
	libvlc_event_attach(libVlcEventManager, libvlc_MediaPlayerTimeChanged, callbacks, NULL);
	libvlc_event_attach(libVlcEventManager, libvlc_MediaPlayerPositionChanged, callbacks, NULL);
	libvlc_event_attach(libVlcEventManager, libvlc_MediaPlayerSeekableChanged, callbacks, NULL);
	libvlc_event_attach(libVlcEventManager, libvlc_MediaPlayerPlaying, callbacks, NULL);
	libvlc_event_attach(libVlcEventManager, libvlc_MediaPlayerEncounteredError, callbacks, NULL);
	libvlc_event_attach(libVlcEventManager, libvlc_MediaPlayerOpening, callbacks, NULL);
	libvlc_event_attach(libVlcEventManager, libvlc_MediaPlayerBuffering, callbacks, NULL);
	libvlc_event_attach(libVlcEventManager, libvlc_MediaPlayerForward, callbacks, NULL);
	libvlc_event_attach(libVlcEventManager, libvlc_MediaPlayerBackward, callbacks, NULL);

	libvlc_media_player_play(libVlcMediaPlayer);
}

float getLength()
{
	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
		return libvlc_media_player_get_length(libVlcMediaPlayer);
	else
		return 0;
}

float getDuration()
{
	if (libVlcMediaItem != NULL && libVlcMediaItem != nullptr)
		return libvlc_media_get_duration(libVlcMediaItem);
	else
		return 0;
}

float getFPS()
{
	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
		return libvlc_media_player_get_fps(libVlcMediaPlayer);
	else
		return 0;
}

int getWidth()
{
	unsigned int width;
	unsigned int height;

	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
	{
		libvlc_video_get_size(libVlcMediaPlayer, 0, &width, &height);
		return width;
	}
	else
		return 0;
}

int getHeight()
{
	unsigned int width;
	unsigned int height;

	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
	{
		libvlc_video_get_size(libVlcMediaPlayer, 0, &width, &height);
		return height;
	}
	else
		return 0;
}

bool isMediaPlayerAlive()
{
	return libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr;
}

bool isMediaItemAlive()
{
	return libVlcMediaItem != NULL && libVlcMediaItem != nullptr;
}

bool isPlaying()
{
	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
		return libvlc_media_player_is_playing(libVlcMediaPlayer);
	else
		return false;
}

bool isSeekable()
{
	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
		return libvlc_media_player_is_seekable(libVlcMediaPlayer);
	else
		return false;
}

const char *getLastError()
{
	return libvlc_errmsg();
}

void setVolume(float volume)
{
	if (volume > 100)
		volume = 100.0;

	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
		libvlc_audio_set_volume(libVlcMediaPlayer, volume);
}

float getVolume()
{
	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
		return libvlc_audio_get_volume(libVlcMediaPlayer);
	else
		return 0;
}

void setTime(int time)
{
	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
		libvlc_media_player_set_time(libVlcMediaPlayer, time);
}

int getTime()
{
	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
		return libvlc_media_player_get_time(libVlcMediaPlayer);
	else
		return 0;
}

void setPosition(float pos)
{
	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
		libvlc_media_player_set_position(libVlcMediaPlayer, pos);
}

float getPosition()
{
	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
		return libvlc_media_player_get_position(libVlcMediaPlayer);
	else
		return 0;
}

uint8_t* getPixelData()
{
	return ctx.pixeldata;
}

int getFlag(int flag)
{
	return ctx.flags[flag];
}

void setFlag(int flag, int value)
{
	ctx.flags[flag] = value;
}

void callbacks(const libvlc_event_t *event, void *ptr)
{
	struct ctx *callback = reinterpret_cast< struct ctx*> (*ptr);

	switch (event->type)
	{
		case libvlc_MediaPlayerPlaying:
			callback->flags[1] = 1;
			break;
		case libvlc_MediaPlayerStopped:
			callback->flags[2] = 1;
			break;
		case libvlc_MediaPlayerEndReached:
			callback->flags[3] = 1;
			break;
		case libvlc_MediaPlayerTimeChanged:
			callback->flags[4] = event->u.media_player_time_changed.new_time;
			break;
		case libvlc_MediaPlayerPositionChanged:
			callback->flags[5] = event->u.media_player_position_changed.new_position;
			break;
		case libvlc_MediaPlayerSeekableChanged:
			callback->flags[6] = event->u.media_player_seekable_changed.new_seekable;
			break;
		case libvlc_MediaPlayerEncounteredError:
			callback->flags[7] = 1;
			break;
		case libvlc_MediaPlayerOpening:
			callback->flags[8] = 1;
			break;
		case libvlc_MediaPlayerBuffering:
			callback->flags[9] = 1;
			break;
		case libvlc_MediaPlayerForward:
			callback->flags[10] = 1;
			break;
		case libvlc_MediaPlayerBackward:
			callback->flags[11] = 1;
			break;
		default:
			break;
	}
}
