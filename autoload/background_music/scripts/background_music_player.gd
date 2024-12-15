extends Node

signal track_changed(track_title: String)
signal playback_finished

@export var playlist: BackgroundMusicPlaylist
@export var autoplay: bool = true

var _current_track_index: int = -1
var _is_transitioning: bool = false

@onready var main_player: AudioStreamPlayer = $MainPlayer
@onready var crossfade_player: AudioStreamPlayer = $CrossfadePlayer

func _ready() -> void:
	if autoplay and playlist and not playlist.tracks.is_empty():
		play_track(0)

func play_track(index: int) -> bool:
	if not playlist or index >= playlist.tracks.size():
		return false
		
	var track = playlist.tracks[index]
	_current_track_index = index
	
	if playlist.crossfade_duration > 0.0:
		_start_crossfade(track)
	else:
		_play_track_immediate(track)
	
	track_changed.emit(track.title)
	return true

func play_track_by_name(track_name: String) -> bool:
	if not playlist:
		return false
		
	for index in playlist.tracks.size():
		if playlist.tracks[index].title == track_name:
			return play_track(index)
	return false

func _play_track_immediate(track: BackgroundMusicTrack) -> void:
	main_player.stop()
	main_player.stream = track.audio_stream
	main_player.volume_db = track.volume_db
	main_player.pitch_scale = track.pitch_scale
	main_player.play()

func _start_crossfade(track: BackgroundMusicTrack) -> void:
	_is_transitioning = true
	
	crossfade_player.stop()
	crossfade_player.stream = track.audio_stream
	crossfade_player.volume_db = -80.0
	crossfade_player.pitch_scale = track.pitch_scale
	crossfade_player.play()
	
	var tween = create_tween()
	tween.parallel().tween_property(main_player, "volume_db", -80.0, playlist.crossfade_duration)
	tween.parallel().tween_property(crossfade_player, "volume_db", track.volume_db, playlist.crossfade_duration)
	tween.tween_callback(_finish_transition)

func _finish_transition() -> void:
	_is_transitioning = false
	main_player.stop()
	
	var temp_stream = main_player.stream
	var temp_volume = main_player.volume_db
	var temp_pitch = main_player.pitch_scale
	
	main_player.stream = crossfade_player.stream
	main_player.volume_db = crossfade_player.volume_db
	main_player.pitch_scale = crossfade_player.pitch_scale
	main_player.play(crossfade_player.get_playback_position())
	
	crossfade_player.stream = temp_stream
	crossfade_player.volume_db = temp_volume
	crossfade_player.pitch_scale = temp_pitch
	crossfade_player.stop()
