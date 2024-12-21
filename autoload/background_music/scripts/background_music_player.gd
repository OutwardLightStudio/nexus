extends Node

## Emitted when a new track starts playing
signal track_changed(track_title: String)

## Emitted when the playlist finishes and won't loop
signal playback_finished

## The playlist resource containing tracks to play
@export var playlist: BackgroundMusicPlaylist:
	set(value):
		playlist = value
		_validate_playlist()

## Whether to start playing automatically when ready
@export var autoplay: bool = true

var _current_track_index: int = -1
var _is_transitioning: bool = false
var _is_playing: bool = false
var _paused_position: float = 0.0

@onready var main_player: AudioStreamPlayer = $MainPlayer
@onready var crossfade_player: AudioStreamPlayer = $CrossfadePlayer

func _ready() -> void:
	if autoplay and _validate_playlist():
		play_track(0)

## Validates the current playlist configuration
func _validate_playlist() -> bool:
	if not playlist:
		push_warning("BackgroundMusicPlayer: No playlist assigned")
		return false
	if playlist.tracks.is_empty():
		push_warning("BackgroundMusicPlayer: Playlist is empty")
		return false
	if playlist.tracks.has(null):
		push_warning("BackgroundMusicPlayer: Playlist contains null tracks")
		return false
	return true

## Plays a track from the playlist by index
func play_track(index: int) -> bool:
	if not _validate_playlist() or index >= playlist.tracks.size():
		return false
		
	var track = playlist.tracks[index]
	_current_track_index = index
	_is_playing = true
	
	if playlist.crossfade_duration > 0.0:
		_start_crossfade(track)
	else:
		_play_track_immediate(track)
	
	track_changed.emit(track.title)
	return true

## Plays a track by its title
func play_track_by_name(track_name: String) -> bool:
	if not playlist:
		return false
		
	for index in playlist.tracks.size():
		if playlist.tracks[index].title == track_name:
			return play_track(index)
	return false

## Pauses the current track
func pause() -> void:
	if _is_playing:
		_paused_position = main_player.get_playback_position()
		main_player.stop()
		if _is_transitioning:
			crossfade_player.stop()
		_is_playing = false

## Resumes playback from the paused position
func resume() -> void:
	if not _is_playing and main_player.stream:
		main_player.play(_paused_position)
		if _is_transitioning:
			crossfade_player.play(_paused_position)
		_is_playing = true

## Stops playback completely
func stop() -> void:
	_is_playing = false
	_paused_position = 0.0
	main_player.stop()
	crossfade_player.stop()
	if _is_transitioning:
		_is_transitioning = false
		var tween = get_tree().create_tween()
		tween.tween_property(main_player, "volume_db", -80.0, 0.1)
		tween.tween_property(crossfade_player, "volume_db", -80.0, 0.1)

## Plays the next track in the playlist
func play_next() -> bool:
	if not _validate_playlist():
		return false
		
	var next_index = _current_track_index + 1
	if next_index >= playlist.tracks.size():
		if playlist.loop_playlist:
			next_index = 0
		else:
			playback_finished.emit()
			return false
			
	return play_track(next_index)

## Plays the previous track in the playlist
func play_previous() -> bool:
	if not _validate_playlist():
		return false
		
	var prev_index = _current_track_index - 1
	if prev_index < 0:
		if playlist.loop_playlist:
			prev_index = playlist.tracks.size() - 1
		else:
			return false
			
	return play_track(prev_index)

## Returns whether any track is currently playing
func is_playing() -> bool:
	return _is_playing

## Returns the name of the current track
func get_current_track_name() -> String:
	if _current_track_index >= 0 and _current_track_index < playlist.tracks.size():
		return playlist.tracks[_current_track_index].title
	return ""

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
