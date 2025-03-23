extends GutTest

var BackgroundMusicPlayer = load("res://autoload/background_music/scripts/background_music_player.gd")
var player: Node
var test_playlist: BackgroundMusicPlaylist
var test_track1: BackgroundMusicTrack
var test_track2: BackgroundMusicTrack

func before_each():
	player = BackgroundMusicPlayer.new()
	add_child_autoqfree(player)
	
	# Create test audio players
	var main_player = AudioStreamPlayer.new()
	main_player.name = "MainPlayer"
	player.add_child(main_player)
	
	var crossfade_player = AudioStreamPlayer.new()
	crossfade_player.name = "CrossfadePlayer"
	player.add_child(crossfade_player)
	
	# Wait for ready to complete node setup
	await player.ready
	
	# Setup test tracks and playlist
	test_track1 = BackgroundMusicTrack.new()
	test_track1.title = "Test Track 1"
	test_track1.audio_stream = AudioStreamWAV.new()
	test_track1.volume_db = -10.0
	test_track1.pitch_scale = 1.0
	
	test_track2 = BackgroundMusicTrack.new()
	test_track2.title = "Test Track 2"
	test_track2.audio_stream = AudioStreamWAV.new()
	test_track2.volume_db = -8.0
	test_track2.pitch_scale = 1.2
	
	test_playlist = BackgroundMusicPlaylist.new()
	test_playlist.tracks = [test_track1, test_track2]
	test_playlist.crossfade_duration = 1.0
	test_playlist.loop_playlist = true

func test_playlist_validation():
	assert_false(player._validate_playlist(), "Should fail with no playlist")
	
	player.playlist = BackgroundMusicPlaylist.new()
	assert_false(player._validate_playlist(), "Should fail with empty playlist")
	
	player.playlist = test_playlist
	assert_true(player._validate_playlist(), "Should pass with valid playlist")

func test_play_track():
	player.playlist = test_playlist
	assert_true(player.play_track(0), "Should successfully play first track")
	assert_eq(player.get_current_track_name(), "Test Track 1", "Should be playing first track")
	
	assert_false(player.play_track(99), "Should fail with invalid track index")

func test_play_track_by_name():
	player.playlist = test_playlist
	assert_true(player.play_track_by_name("Test Track 2"), "Should find and play track by name")
	assert_eq(player.get_current_track_name(), "Test Track 2", "Should be playing correct track")
	
	assert_false(player.play_track_by_name("Non-existent Track"), "Should fail with invalid track name")

func test_pause_resume():
	player.playlist = test_playlist
	player.play_track(0)
	
	player.pause()
	assert_false(player.is_playing(), "Should not be playing when paused")
	
	player.resume()
	assert_true(player.is_playing(), "Should be playing after resume")

func test_stop():
	player.playlist = test_playlist
	player.play_track(0)
	
	player.stop()
	assert_false(player.is_playing(), "Should not be playing when stopped")
	assert_eq(player._paused_position, 0.0, "Paused position should be reset")

func test_track_navigation():
	player.playlist = test_playlist
	player.play_track(0)
	
	assert_true(player.play_next(), "Should successfully play next track")
	assert_eq(player.get_current_track_name(), "Test Track 2", "Should be playing second track")
	
	assert_true(player.play_next(), "Should loop back to first track")
	assert_eq(player.get_current_track_name(), "Test Track 1", "Should be playing first track after loop")
	
	assert_true(player.play_previous(), "Should successfully play previous track")
	assert_eq(player.get_current_track_name(), "Test Track 2", "Should be playing second track")

func test_track_changed_signal():
	player.playlist = test_playlist
	watch_signals(player)
	
	player.play_track(0)
	assert_signal_emitted_with_parameters(player, "track_changed", ["Test Track 1"])
	
	player.play_track(1)
	assert_signal_emitted_with_parameters(player, "track_changed", ["Test Track 2"])

func test_playback_finished_signal():
	test_playlist.loop_playlist = false
	player.playlist = test_playlist
	watch_signals(player)
	
	player.play_track(1)  # Play last track
	player.play_next()    # Try to play past the end
	assert_signal_emitted(player, "playback_finished")

func test_crossfade():
	player.playlist = test_playlist
	player.play_track(0)
	
	# Test with crossfade enabled
	assert_eq(test_playlist.crossfade_duration, 1.0, "Crossfade duration should be set")
	player.play_track(1)
	assert_true(player._is_transitioning, "Should be in transition state during crossfade")
	
	# Test with crossfade disabled
	test_playlist.crossfade_duration = 0.0
	player.play_track(0)
	assert_false(player._is_transitioning, "Should not transition when crossfade is disabled")

func test_crossfade_interruption():
	player.playlist = test_playlist
	player.play_track(0)
	
	# Start crossfade
	player.play_track(1)
	assert_true(player._is_transitioning, "Should start transitioning")
	
	# Interrupt with stop
	player.stop()
	assert_false(player._is_transitioning, "Should not be transitioning after stop")
	assert_false(player.is_playing(), "Should not be playing after stop")
	
	# Test volume reset
	assert_eq(player.get_node("MainPlayer").volume_db, -80.0, "Main player volume should be muted")
	assert_eq(player.get_node("CrossfadePlayer").volume_db, -80.0, "Crossfade player volume should be muted")