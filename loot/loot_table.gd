class_name LootTable
extends Resource

# A reusable loot definition. Multiple chests (or other lootable objects) can
# share the same LootTable resource. To change drop rates everywhere a table
# is used, edit the .tres file once.
#
# How to add a new item:
#   1. Make the item scene (e.g. coin.tscn) with a Node2D root.
#   2. Create a new LootEntry .tres in loot/entries/ pointing at that scene.
#   3. Open the LootTable .tres you want it to drop from (e.g.
#      loot/tables/standard_chest.tres) and add the entry to `entries`.
#   4. Tweak its `weight` (relative chance vs other entries in the table).

@export var entries: Array[LootEntry] = []

# How many items to pick (with replacement) per loot roll.
@export var picks: int = 1


func roll() -> Array[LootEntry]:
	var result: Array[LootEntry] = []
	if picks <= 0:
		return result

	var total := 0.0
	for e in entries:
		if e != null and e.weight > 0.0:
			total += e.weight
	if total <= 0.0:
		return result

	for i in range(picks):
		var chosen := _pick_weighted(total)
		if chosen != null:
			result.append(chosen)
	return result


func _pick_weighted(total: float) -> LootEntry:
	var roll_value := randf() * total
	var acc := 0.0
	for e in entries:
		if e == null or e.weight <= 0.0:
			continue
		acc += e.weight
		if roll_value <= acc:
			return e
	return null
