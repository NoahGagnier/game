extends Node

# Broadcast signal that any system can connect to without needing a direct
# reference to the pickup or the HUD.
signal item_collected(pickup_name: String, description: String, icon: Texture2D)

func notify(pickup_name: String, description: String, icon: Texture2D) -> void:
	item_collected.emit(pickup_name, description, icon)
