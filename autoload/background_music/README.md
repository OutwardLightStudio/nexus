# Background Music Controller for Godot 4.x

A robust yet simple background music management system for Godot 4.x games. This controller handles one of the most challenging aspects of game audio - maintaining smooth, continuous background music across scene transitions while providing powerful features like crossfading and dynamic track switching.

## Key Features

The system provides essential music management capabilities while maintaining simplicity:

- Seamless playback across scene transitions using Godot's autoload system
- Smart playlist management with looping and shuffle options
- Smooth crossfading between tracks with configurable duration
- Resource-based configuration that integrates naturally with the Godot editor
- Type-safe GDScript implementation with proper error handling
- Memory-efficient design using audio streaming

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

### Audio Bus Setup

The background music system requires proper audio bus configuration:

1. Open Project → Project Settings → Audio
2. Check the default audio bus is configured, e.g. `res://default_bus_layout.tres`
3. Create or open the `res://default_bus_layout.tres`
   - to create a new one, click the "Audio" button at the bottom of the window and then click "Create". Save with the default name "default_bus_layout.tres" in the project root directory.
4. Create a "Music" bus if you don't already have one
   - to create a new bus, click the "Add Bus" button in the Audio section
5. Configure the bus settings:
   - Volume: Start with -3dB to leave headroom
   - Effects: Consider adding a limiter to prevent clipping
   
This setup ensures optimal audio quality and prevents common issues with volume management.

## Creating a Music Playlist

### Audio File Preparation

When preparing your music files, consider these important factors:

1. Use consistent sample rates across your music files (44.1kHz recommended)
2. Ensure files are properly looped if they need to loop
3. Consider using OGG format for good compression while maintaining quality
4. Store audio files in a dedicated music directory within your project

### Resource Creation

1. Edit the `BackgroundMusicPlayer` scene
2. under `Playlist`, add a new `BackgroundMusicPlaylist` resource
3. add tracks to the playlist by clicking the `+ Add Element` button
4. for each track, add a new `BackgroundMusicTrack` resource
5. configure the AudioStream property with the corresponding music file, Title, volume dB, Pitch Scale, and Loop as desired

## Using the Background Music System

### Basic Playback Control

```gdscript
# Play a specific track
BackgroundMusic.play_track_by_name("level_theme")

# Basic playback controls
BackgroundMusic.pause()
BackgroundMusic.resume()
BackgroundMusic.stop()

# Navigate playlist
BackgroundMusic.play_next()
BackgroundMusic.play_previous()
```

### Track Change Notifications

```gdscript
func _ready() -> void:
	BackgroundMusic.track_changed.connect(_on_track_changed)

func _on_track_changed(track_title: String) -> void:
	print("Now playing: ", track_title)
```

## Performance Considerations

The background music system is designed to be lightweight, but keep these points in mind:

1. Memory Usage
   - Audio streams are loaded on demand
   - Use appropriate compression settings in your audio files
   - Consider using the `load_step` property for large music files

2. CPU Impact
   - Crossfading temporarily uses two audio streams
   - The default 1-second crossfade duration works well on most systems
   - Increase crossfade duration gradually if needed, monitoring performance

3. Scene Transitions
   - The autoload system keeps memory usage consistent
   - No additional loading occurs during scene changes
   - Track changes are thread-safe and won't cause stuttering

## Support

For issues, questions, or contributions, please visit our repository at [repository URL]. We welcome bug reports, feature requests, and pull requests that align with our goal of maintaining a simple yet powerful background music system.

## License

This project is released under the MIT License. See the LICENSE file for details.
