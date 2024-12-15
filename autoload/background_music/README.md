# Background Music Controller

A background music management system for Godot 4.x games that provides seamless music playback across scene transitions with support for playlists, crossfading, and dynamic track switching.

## Installation

1. Create an `autoload` directory in your project root if it doesn't already exist.

2. Copy the `background_music` directory into your project's `autoload` folder, maintaining this structure:
```
autoload/
└── background_music/
	├── resources/
	│   ├── track.gd
	│   ├── playlist.gd
	│   └── default_playlist.tres
	├── scenes/
	│   └── background_music_player.tscn
	└── scripts/
		└── background_music_player.gd
```

3. In your Project Settings, add the BackgroundMusic autoload:
   - Open Project → Project Settings
   - Navigate to the AutoLoad tab
   - Click the folder icon and select `autoload/background_music/scenes/background_music_player.tscn`
   - Set the Node Name as "BackgroundMusic"
   - Click "Add" to register the autoload

## Creating a Music Playlist

1. Create track resources:
   - Right-click in the FileSystem panel
   - Select New Resource
   - Choose "BackgroundMusicTrack"
   - Configure the track:
	 - Set the AudioStream to your music file
	 - Enter a title for the track
	 - Adjust volume and pitch if needed
	 - Save the track resource

2. Create a playlist:
   - Right-click in the FileSystem panel
   - Select New Resource
   - Choose "BackgroundMusicPlaylist"
   - Add your track resources to the tracks array
   - Configure playlist settings:
	 - Loop playlist: Enable to repeat the playlist
	 - Shuffle mode: Enable for random playback
	 - Crossfade duration: Set the transition time between tracks
   - Save the playlist resource

3. Assign the playlist:
   - Select the BackgroundMusic node in the Scene tab
   - In the Inspector, drag your playlist resource into the "Playlist" property

## Using the Background Music System

### Basic Playback Control

Play a specific track by name:
```gdscript
BackgroundMusic.play_track_by_name("level_theme")
```

Control playback:
```gdscript
BackgroundMusic.pause()
BackgroundMusic.resume()
BackgroundMusic.stop()
```

Navigate playlist:
```gdscript
BackgroundMusic.play_next()
BackgroundMusic.play_previous()
```

### Advanced Features

Fade control:
```gdscript
# Fade out current track
BackgroundMusic.fade_out(2.0)  # Duration in seconds

# Fade in current track
BackgroundMusic.fade_in(2.0)

# Crossfade to a different track
BackgroundMusic.fade_to_track("boss_theme", 2.0)
```

Volume control:
```gdscript
BackgroundMusic.set_volume(-10.0)  # Volume in decibels
```

### Track Change Notifications

Listen for track changes:
```gdscript
func _ready():
	BackgroundMusic.track_changed.connect(_on_track_changed)

func _on_track_changed(track_title: String):
	print("Now playing: ", track_title)
```

## Example Integration

Here's how to use the background music system in a level:

```gdscript
extends Node

func _ready():
	# Start playing the level music
	BackgroundMusic.play_track_by_name("level_theme")

func _on_boss_battle_start():
	# Smoothly transition to boss music
	BackgroundMusic.fade_to_track("boss_theme", 2.0)

func _on_boss_battle_end():
	# Return to level music
	BackgroundMusic.fade_to_track("level_theme", 1.0)
```

## Best Practices

1. Always use track names rather than indices for reliability.

2. Implement proper error handling when playing tracks:
```gdscript
if not BackgroundMusic.play_track_by_name("track_name"):
	push_error("Failed to play track: track_name")
```

3. Consider using constants for track names to avoid typos:
```gdscript
const TRACK_NAMES = {
	LEVEL = "level_theme",
	BOSS = "boss_theme",
	VICTORY = "victory_theme"
}
```

4. Use appropriate fade durations for smooth transitions:
   - Quick transitions (0.5-1.0 seconds) for sudden events
   - Longer transitions (2.0-3.0 seconds) for mood changes

## Troubleshooting

Common issues and solutions:

1. Music stops between scenes
   - Verify the BackgroundMusic autoload is properly configured
   - Check that the scene transition isn't freeing the autoload

2. Tracks won't play
   - Confirm audio files are properly imported
   - Verify track names match exactly
   - Check the audio bus setup in Project Settings

3. Crossfading isn't smooth
   - Ensure crossfade_duration is greater than 0.0
   - Verify both AudioStreamPlayer nodes are on the same bus
   - Check that the audio files are properly formatted

## Support

For issues, questions, or contributions, please file an issue in the project repository.
