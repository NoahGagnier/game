extends Node2D

const _TRACK_MAIN_MENU := 1
const _TRACK_GAMEPLAY := 2
const _TRACK_TREASURE := 3
const _TRACK_BOSS := 4
const _TRACK_CUTSCENE := 5

const FLOOR_CUTSCENE: PackedScene = preload("res://menus/floor_cutscene.tscn")

var floor_number: int = 1

@export var intro_fade_duration: float = 3.0

func _ready() -> void:
	add_to_group("game_controller")
	_music_play(_TRACK_GAMEPLAY)
	_connect_room_signals()
	_place_player_at_start()
	_fade_in_from_black(intro_fade_duration)

func _fade_in_from_black(duration: float) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 1)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	add_child(layer)
	var tween := create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, duration)
	await tween.finished
	layer.queue_free()

func _music() -> Node:
	return get_node_or_null("/root/MusicManager")

func _music_play(track: int) -> void:
	var m := _music()
	if m != null:
		m.call("play", track)

func _music_stop() -> void:
	var m := _music()
	if m != null:
		m.call("stop")

func _connect_room_signals() -> void:
	var generator := $Dungeon as DungeonGenerator
	if generator == null:
		return
	for child in generator.get_children():
		var room := child as Room
		if room == null:
			continue
		room.player_entered.connect(_on_player_entered_room)

func _place_player_at_start() -> void:
	var generator := $Dungeon as DungeonGenerator
	if generator == null:
		return
	for child in generator.get_children():
		var room := child as Room
		if room == null or room.room_type != Room.RoomType.START:
			continue
		var spawn := room.get_node_or_null("Spawns/PlayerSpawn") as Marker2D
		if spawn != null:
			$World/Player.global_position = spawn.global_position
			var cam := $RoomCamera as Node
			if cam != null and cam.has_method("snap_to_target"):
				cam.snap_to_target()
		return

func _on_player_entered_room(room: Room) -> void:
	match room.room_type:
		Room.RoomType.BOSS:
			_music_play(_TRACK_BOSS)
			var hud := get_node_or_null("HUD")
			if hud != null and hud.has_method("show_boss_bar"):
				hud.show_boss_bar()
		Room.RoomType.TREASURE:
			_music_play(_TRACK_TREASURE)
		Room.RoomType.START, Room.RoomType.NORMAL:
			_music_play(_TRACK_GAMEPLAY)

func _on_player_health_depleted() -> void:
	_music_stop()
	get_tree().change_scene_to_file("res://menus/game_over.tscn")

## Called by BossPortal via call_group when the player enters it.
## Plays the floor transition cutscene then rebuilds the dungeon.
func advance_floor() -> void:
	floor_number += 1
	var cutscene := FLOOR_CUTSCENE.instantiate()
	add_child(cutscene)
	cutscene.completed.connect(_on_floor_cutscene_done, CONNECT_ONE_SHOT)

func _on_floor_cutscene_done() -> void:
	# Reset the boss bar so it's ready for the next floor's boss.
	var hud_node := get_node_or_null("HUD")
	if hud_node != null:
		(hud_node as Node).set("_boss_connected", false)

	# Remove everything promoted to World except the player.
	# Remove from groups first so new rooms don't pick up stale references.
	var world := $World as Node2D
	if world != null:
		for child in world.get_children():
			if not child.is_in_group("player"):
				if child.is_in_group("enemies"):
					child.remove_from_group("enemies")
				child.queue_free()

	# Regenerate the dungeon layout.
	var generator := $Dungeon as DungeonGenerator
	if generator != null:
		generator.generate()

	# Reconnect room cleared/entered signals from the fresh rooms.
	_connect_room_signals()

	# Reset minimap so it doesn't reference freed room nodes.
	var minimap := get_node_or_null("HUD/Minimap")
	if minimap != null and minimap.has_method("reset"):
		minimap.reset()

	# Move player to the new start room, then remove the cutscene overlay.
	call_deferred("_place_player_at_start")
	_music_play(_TRACK_GAMEPLAY)

	# Clean up the cutscene node (screen is still black at this point from _finish).
	for child in get_children():
		if child.get_script() != null and child.get_script().resource_path.ends_with("floor_cutscene.gd"):
			child.queue_free()
