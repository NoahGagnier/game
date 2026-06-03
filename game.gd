extends Node2D

const _TRACK_MAIN_MENU := 1
const _TRACK_GAMEPLAY := 2
const _TRACK_TREASURE := 3
const _TRACK_BOSS := 4
const _TRACK_CUTSCENE := 5

var floor_number: int = 1

func _ready() -> void:
	add_to_group("game_controller")
	_music_play(_TRACK_GAMEPLAY)
	_connect_room_signals()
	_place_player_at_start()

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
		Room.RoomType.TREASURE:
			_music_play(_TRACK_TREASURE)
		Room.RoomType.START, Room.RoomType.NORMAL:
			_music_play(_TRACK_GAMEPLAY)

func _on_player_health_depleted() -> void:
	_music_stop()
	get_tree().change_scene_to_file("res://menus/game_over.tscn")

## Called by BossPortal via call_group when the player enters it.
func advance_floor() -> void:
	floor_number += 1
	_music_play(_TRACK_GAMEPLAY)

	# Remove everything promoted to World except the player.
	var world := $World as Node2D
	if world != null:
		for child in world.get_children():
			if not child.is_in_group("player"):
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

	# Move player to the new start room after rooms are ready.
	call_deferred("_place_player_at_start")
