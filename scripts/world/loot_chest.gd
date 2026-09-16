extends Area2D
## A one-shot, visible loot source in the world (depth pass, post-Phase-6)
## — distinct from post-battle loot, which only ever comes from
## defeating enemies. Walking into an unopened chest rolls
## loot_table_id once and grants the result directly to the player.
## Chest loot tables are authored with drop_chance = 1.0 (see
## data/loot/*_chest_loot.tres) so a chest always yields something —
## an empty chest would undercut the point of adding visible loot.
## Does not persist across leaving and re-entering the map, matching
## every other trigger in the project (no encounter/chest state is
## saved to GameState).

@export var loot_table_id: String = ""

@onready var marker: ColorRect = $Marker
@onready var result_label: Label = $ResultLabel

var _opened := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	result_label.hide()

func _on_body_entered(body: Node) -> void:
	if _opened or loot_table_id == "" or not body.is_in_group("player"):
		return
	_opened = true
	marker.color = Color(0.35, 0.3, 0.22) # dim once opened, so a return trip reads as "already looted"
	var table: LootTableData = DataLoader.load_resource("res://data/loot/%s.tres" % loot_table_id)
	var item_id := LootRoller.roll(table)
	if item_id != "":
		var item: ItemData = DataLoader.load_resource("res://data/items/%s.tres" % item_id)
		if item != null:
			Inventory.add_item(GameState.player, item)
			result_label.text = "Found: %s!" % item.display_name
	else:
		result_label.text = "The chest is empty."
	result_label.show()
	Sfx.play("victory") # reuses the existing upbeat jingle rather than a 5th synthesized clip for one prop
