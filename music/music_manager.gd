extends Node

## Global music manager — add as an autoload named "MusicManager".
## Place audio files in res://music/ and assign them in the inspector
## on the MusicManager node in your autoload scene, or just drop them
## here as preloads once you have the files imported.

enum Track {
	NONE,
	MAIN_MENU,
	GAMEPLAY,
	TREASURE,
	BOSS,
	CUTSCENE,
}

@export var main_menu_stream: AudioStream
@export var gameplay_stream: AudioStream = preload("res://music/main-theme-final.ogg")
@export var treasure_stream: AudioStream = preload("res://music/treasure-final.ogg")
@export var boss_stream: AudioStream
@export var cutscene_stream: AudioStream

@export var music_bus_name: StringName = &"Music"
@export var sfx_bus_name: StringName = &"SFX"

@export var crossfade_duration: float = 1.5
@export var volume_db: float = 0.0

var _current_track: Track = Track.NONE
var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer
var _tween: Tween

func _ready() -> void:
	_player_a = AudioStreamPlayer.new()
	_player_b = AudioStreamPlayer.new()
	var bus := music_bus_name
	if AudioServer.get_bus_index(String(bus)) == -1:
		bus = &"Master"
	for p in [_player_a, _player_b]:
		p.bus = String(bus)
		p.volume_db = -80.0
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
	_active_player = _player_a

func play(track: Track, force_restart: bool = false) -> void:
	if track == _current_track and not force_restart:
		return
	_current_track = track
	var stream := _stream_for(track)
	if stream == null:
		stop()
		return
	_crossfade_to(stream)

func stop() -> void:
	_current_track = Track.NONE
	_fade_out(_active_player)

func pause_music() -> void:
	_active_player.stream_paused = true

func resume_music() -> void:
	_active_player.stream_paused = false

func _stream_for(track: Track) -> AudioStream:
	match track:
		Track.MAIN_MENU:  return main_menu_stream
		Track.GAMEPLAY:   return gameplay_stream
		Track.TREASURE:   return treasure_stream
		Track.BOSS:       return boss_stream
		Track.CUTSCENE:   return cutscene_stream
	return null

func _crossfade_to(stream: AudioStream) -> void:
	if _tween != null:
		_tween.kill()

	var outgoing := _active_player
	var incoming := _player_b if _active_player == _player_a else _player_a
	_active_player = incoming

	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()

	_tween = create_tween().set_parallel(true)
	_tween.tween_property(incoming, "volume_db", volume_db, crossfade_duration)
	_tween.tween_property(outgoing, "volume_db", -80.0, crossfade_duration)
	await _tween.finished
	if outgoing.volume_db <= -79.0:
		outgoing.stop()

func _fade_out(player: AudioStreamPlayer) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(player, "volume_db", -80.0, crossfade_duration)
	await _tween.finished
	player.stop()
