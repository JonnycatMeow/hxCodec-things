#include "vlc/vlc.h"
#include "stdint.h"

struct libvlc_instance_t;
struct libvlc_media_t;
struct libvlc_media_player_t;

typedef struct ctx
{
	unsigned char *pixeldata;
	int flags[12] = { -1 };
} t_ctx;

t_ctx ctx;
libvlc_instance_t *libVlcInstance = nullptr;
libvlc_media_t *libVlcMediaItem = nullptr;
libvlc_media_player_t *libVlcMediaPlayer = nullptr;
libvlc_event_manager_t *libVlcEventManager = nullptr;
static void callbacks(const libvlc_event_t *event, void *self);
