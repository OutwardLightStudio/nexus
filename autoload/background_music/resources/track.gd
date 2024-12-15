@tool
class_name BackgroundMusicTrack
extends Resource

@export var audio_stream: AudioStream
@export var title: String
@export var volume_db: float = 0.0
@export var pitch_scale: float = 1.0
@export var loop: bool = true

func _get_resource_name() -> String:
    return title if title else "Background Music Track"
