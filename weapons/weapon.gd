class_name Weapon
extends Node2D

var player: Player

func bind_player(p: Player) -> void:
	player = p

func try_fire() -> bool:
	return false
