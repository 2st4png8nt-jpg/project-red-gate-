extends RefCounted
class_name Inventory
## Thin helpers over PlayerData.inventory (a flat Array[ItemData] — no
## stacking/counts in the prototype; duplicate purchases are separate
## entries, which is fine since ItemData/EquipmentData/ConsumableData
## resources are treated as shared, immutable templates and never
## mutated per-instance).

static func add_item(player: PlayerData, item: ItemData) -> void:
	player.inventory.append(item)

static func remove_item(player: PlayerData, item: ItemData) -> bool:
	var had_it := player.inventory.has(item)
	player.inventory.erase(item)
	return had_it

static func find_first_consumable(player: PlayerData) -> ConsumableData:
	for item in player.inventory:
		if item is ConsumableData:
			return item
	return null
