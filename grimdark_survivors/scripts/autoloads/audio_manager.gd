## AudioManager - Handles all audio playback, bus management, and pooling
## Provides easy-to-use interface for playing sounds and music
extends Node

# =============================================================================
# CONSTANTS
# =============================================================================

const SFX_POOL_SIZE: int = 32  # Number of pooled AudioStreamPlayers for SFX
const MUSIC_FADE_TIME: float = 1.0

enum AudioBus {
	MASTER,
	MUSIC,
	SFX,
	UI
}

const BUS_NAMES: Dictionary = {
	AudioBus.MASTER: "Master",
	AudioBus.MUSIC: "Music",
	AudioBus.SFX: "SFX",
	AudioBus.UI: "UI"
}

# =============================================================================
# NODES
# =============================================================================

var music_player: AudioStreamPlayer
var music_player_secondary: AudioStreamPlayer  # For crossfading
var sfx_pool: Array[AudioStreamPlayer] = []
var current_sfx_index: int = 0

# =============================================================================
# STATE
# =============================================================================

var current_music: String = ""
var music_tween: Tween = null
var is_fading: bool = false

# Preloaded sounds cache
var sound_cache: Dictionary = {}

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_setup_audio_buses()
	_create_music_players()
	_create_sfx_pool()
	_connect_signals()
	_apply_saved_volumes()
	print("[AudioManager] Initialized with %d SFX channels" % SFX_POOL_SIZE)


func _setup_audio_buses() -> void:
	# Audio buses should be set up in the project settings
	# This just verifies they exist
	for bus_name in BUS_NAMES.values():
		var bus_idx := AudioServer.get_bus_index(bus_name)
		if bus_idx == -1:
			push_warning("[AudioManager] Audio bus '%s' not found, using Master" % bus_name)


func _create_music_players() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.name = "MusicPlayer"
	add_child(music_player)

	music_player_secondary = AudioStreamPlayer.new()
	music_player_secondary.bus = "Music"
	music_player_secondary.name = "MusicPlayerSecondary"
	add_child(music_player_secondary)


func _create_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		player.name = "SFXPlayer_%d" % i
		add_child(player)
		sfx_pool.append(player)


func _connect_signals() -> void:
	EventBus.sfx_requested.connect(play_sfx)
	EventBus.music_requested.connect(play_music)
	EventBus.audio_stop_all.connect(stop_all)


func _apply_saved_volumes() -> void:
	set_bus_volume(AudioBus.MASTER, SaveManager.get_setting("master_volume"))
	set_bus_volume(AudioBus.MUSIC, SaveManager.get_setting("music_volume"))
	set_bus_volume(AudioBus.SFX, SaveManager.get_setting("sfx_volume"))

# =============================================================================
# SFX PLAYBACK
# =============================================================================

func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var stream := _get_sound(sfx_name)
	if stream == null:
		push_warning("[AudioManager] SFX not found: %s" % sfx_name)
		return

	var player := _get_available_sfx_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func play_sfx_at_position(sfx_name: String, _position: Vector2, volume_db: float = 0.0) -> void:
	# For 2D positional audio, you'd need AudioStreamPlayer2D
	# For now, just play it normally with slight volume adjustment based on distance
	play_sfx(sfx_name, volume_db)


func play_sfx_random_pitch(sfx_name: String, pitch_range: float = 0.1) -> void:
	var pitch := randf_range(1.0 - pitch_range, 1.0 + pitch_range)
	play_sfx(sfx_name, 0.0, pitch)


func _get_available_sfx_player() -> AudioStreamPlayer:
	# Round-robin through the pool
	var player := sfx_pool[current_sfx_index]
	current_sfx_index = (current_sfx_index + 1) % SFX_POOL_SIZE

	# If player is currently playing, stop it (oldest sound gets replaced)
	if player.playing:
		player.stop()

	return player

# =============================================================================
# MUSIC PLAYBACK
# =============================================================================

func play_music(music_name: String, fade_time: float = MUSIC_FADE_TIME) -> void:
	if music_name == current_music:
		return

	var stream := _get_sound(music_name)
	if stream == null:
		push_warning("[AudioManager] Music not found: %s" % music_name)
		return

	current_music = music_name

	if fade_time > 0.0 and music_player.playing:
		_crossfade_music(stream, fade_time)
	else:
		music_player.stream = stream
		music_player.volume_db = 0.0
		music_player.play()


func _crossfade_music(new_stream: AudioStream, fade_time: float) -> void:
	if music_tween:
		music_tween.kill()

	# Swap players for crossfade
	var temp := music_player
	music_player = music_player_secondary
	music_player_secondary = temp

	# Setup new music
	music_player.stream = new_stream
	music_player.volume_db = -80.0
	music_player.play()

	# Create crossfade tween
	music_tween = create_tween()
	music_tween.set_parallel(true)
	music_tween.tween_property(music_player, "volume_db", 0.0, fade_time)
	music_tween.tween_property(music_player_secondary, "volume_db", -80.0, fade_time)
	music_tween.chain().tween_callback(music_player_secondary.stop)


func stop_music(fade_time: float = MUSIC_FADE_TIME) -> void:
	current_music = ""

	if fade_time > 0.0:
		if music_tween:
			music_tween.kill()
		music_tween = create_tween()
		music_tween.tween_property(music_player, "volume_db", -80.0, fade_time)
		music_tween.tween_callback(music_player.stop)
	else:
		music_player.stop()


func pause_music() -> void:
	music_player.stream_paused = true


func resume_music() -> void:
	music_player.stream_paused = false


func is_music_playing() -> bool:
	return music_player.playing

# =============================================================================
# BUS VOLUME CONTROL
# =============================================================================

func set_bus_volume(bus: AudioBus, volume: float) -> void:
	var bus_name: String = BUS_NAMES.get(bus, "Master")
	var bus_idx := AudioServer.get_bus_index(bus_name)

	if bus_idx == -1:
		bus_idx = 0  # Fallback to Master

	# Convert linear (0-1) to decibels
	var volume_db := linear_to_db(clamp(volume, 0.0, 1.0))
	AudioServer.set_bus_volume_db(bus_idx, volume_db)


func get_bus_volume(bus: AudioBus) -> float:
	var bus_name: String = BUS_NAMES.get(bus, "Master")
	var bus_idx := AudioServer.get_bus_index(bus_name)

	if bus_idx == -1:
		bus_idx = 0

	return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))


func set_bus_muted(bus: AudioBus, muted: bool) -> void:
	var bus_name: String = BUS_NAMES.get(bus, "Master")
	var bus_idx := AudioServer.get_bus_index(bus_name)

	if bus_idx == -1:
		bus_idx = 0

	AudioServer.set_bus_mute(bus_idx, muted)

# =============================================================================
# SOUND CACHING
# =============================================================================

func _get_sound(sound_name: String) -> AudioStream:
	# Check cache first
	if sound_name in sound_cache:
		return sound_cache[sound_name]

	# Try to load from various locations
	var paths := [
		"res://assets/audio/sfx/%s.wav" % sound_name,
		"res://assets/audio/sfx/%s.ogg" % sound_name,
		"res://assets/audio/sfx/%s.mp3" % sound_name,
		"res://assets/audio/music/%s.ogg" % sound_name,
		"res://assets/audio/music/%s.mp3" % sound_name,
		"res://assets/audio/ui/%s.wav" % sound_name,
		"res://assets/audio/ui/%s.ogg" % sound_name,
	]

	for path in paths:
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			if stream:
				sound_cache[sound_name] = stream
				return stream

	return null


func preload_sounds(sound_names: Array[String]) -> void:
	for sound_name in sound_names:
		_get_sound(sound_name)


func clear_sound_cache() -> void:
	sound_cache.clear()

# =============================================================================
# UTILITY
# =============================================================================

func stop_all() -> void:
	stop_music(0.0)
	for player in sfx_pool:
		player.stop()


func stop_all_sfx() -> void:
	for player in sfx_pool:
		player.stop()


func get_active_sfx_count() -> int:
	var count := 0
	for player in sfx_pool:
		if player.playing:
			count += 1
	return count
