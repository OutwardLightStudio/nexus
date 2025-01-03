@tool
class_name BackgroundMusicPlaylist
extends Resource

@export var tracks: Array[BackgroundMusicTrack]
@export var loop_playlist: bool = true
@export var shuffle_mode: bool = false
@export var crossfade_duration: float = 1.0
@export var default_volume_db: float = 0.0

func _get_resource_name() -> String:
	return "Background Music Playlist"
