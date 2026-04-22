extends Node2D

func _ready() -> void:
	_place_player_at_start()

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
			$Player.global_position = spawn.global_position
			var cam := $RoomCamera as Node
			if cam != null and cam.has_method("snap_to_target"):
				cam.snap_to_target()
		return

func _on_player_health_depleted() -> void:
	%GameOver.visible = true
	get_tree().paused = true
