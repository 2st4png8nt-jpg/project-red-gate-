extends CanvasLayer
# Inventory/Equipment screen. Reads GameState.player directly (there is
# only ever one local player) and mutates it only through
# Inventory/EquipmentManager helpers — no equip/stat math lives here,
# including the Phase 4 comparison text (_format_comparison reads
# EquipmentData bonus fields directly rather than computing damage or
# anything StatsCalculator-shaped).

# (label, EquipmentData bonus field) pairs shown in the comparison text.
const COMPARISON_FIELDS := [
	["ATK", "attack_bonus"], ["DEF", "defense_bonus"], ["MAG", "magic_power_bonus"],
	["SPD", "speed_bonus"], ["HP", "max_hp_bonus"], ["MP", "max_mp_bonus"],
]

@onready var stats_label: Label = $Root/StatsLabel
@onready var equipped_list: VBoxContainer = $Root/EquippedList
@onready var items_list: VBoxContainer = $Root/ItemsList
@onready var message_label: Label = $Root/MessageLabel
@onready var close_button: Button = $Root/CloseButton

func _ready() -> void:
	close_button.pressed.connect(func(): hide())
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		message_label.text = ""
		refresh()

func refresh() -> void:
	var player := GameState.player
	stats_label.text = "ATK %d  DEF %d  MAG %d  SPD %d   HP %d/%d  MP %d/%d  Gold %d" % [
		StatsCalculator.effective_attack(player), StatsCalculator.effective_defense(player),
		StatsCalculator.effective_magic_power(player), StatsCalculator.effective_speed(player),
		player.hp, StatsCalculator.effective_max_hp(player),
		player.mp, StatsCalculator.effective_max_mp(player),
		player.gold,
	]

	for child in equipped_list.get_children():
		child.queue_free()
	_add_equipped_row("Weapon", player.equipped_weapon, "weapon")
	_add_equipped_row("Armor", player.equipped_armor, "armor")
	_add_equipped_row("Accessory", player.equipped_accessory, "accessory")

	for child in items_list.get_children():
		child.queue_free()
	for item in player.inventory:
		_add_item_row(item)

func _add_equipped_row(slot_label: String, item: EquipmentData, slot: String) -> void:
	var row := HBoxContainer.new()
	var text := Label.new()
	text.text = "%s: %s" % [slot_label, item.display_name if item != null else "(none)"]
	row.add_child(text)
	if item != null:
		var btn := Button.new()
		btn.text = "Unequip"
		btn.pressed.connect(_on_unequip_pressed.bind(slot))
		row.add_child(btn)
	equipped_list.add_child(row)

func _add_item_row(item: ItemData) -> void:
	var row := HBoxContainer.new()
	var text := Label.new()
	if item is EquipmentData:
		text.text = "%s (%s %s, req. Lv%d) — %s" % [
			item.display_name, item.rarity, item.slot, item.level_requirement, _format_comparison(item)
		]
	elif item is ConsumableData:
		text.text = "%s (heals %d HP, %d MP)" % [item.display_name, item.heal_hp, item.heal_mp]
	else:
		text.text = item.display_name
	row.add_child(text)
	if item is EquipmentData:
		var btn := Button.new()
		btn.text = "Equip"
		btn.disabled = not EquipmentManager.can_equip(GameState.player, item)
		btn.pressed.connect(_on_equip_pressed.bind(item))
		row.add_child(btn)
	items_list.add_child(row)

## Textual before/after preview vs. whatever currently occupies this
## item's slot — e.g. "ATK+8, HP+5" or "(no change)". Godot's Resource
## exposes @export fields through get(), so this works for any bonus
## field without a match statement per stat.
func _format_comparison(item: EquipmentData) -> String:
	var current: EquipmentData = null
	match item.slot:
		"weapon":
			current = GameState.player.equipped_weapon
		"armor":
			current = GameState.player.equipped_armor
		"accessory":
			current = GameState.player.equipped_accessory
	var deltas: Array[String] = []
	for pair in COMPARISON_FIELDS:
		var label: String = pair[0]
		var field: String = pair[1]
		var new_val: int = item.get(field)
		var cur_val: int = 0 if current == null else current.get(field)
		var delta := new_val - cur_val
		if delta != 0:
			deltas.append("%s%+d" % [label, delta])
	if deltas.is_empty():
		return "(no change)"
	return "vs. equipped: " + ", ".join(deltas)

func _on_equip_pressed(item: EquipmentData) -> void:
	# The Equip button is already disabled when this would fail (see
	# _add_item_row), but check again here rather than trust that alone
	# — cheap, and avoids ever silently eating an item on a stale button.
	if not EquipmentManager.can_equip(GameState.player, item):
		message_label.text = "Requires level %d (you are %d)." % [item.level_requirement, GameState.player.level]
		return
	var previous := EquipmentManager.equip(GameState.player, item)
	Inventory.remove_item(GameState.player, item)
	if previous != null:
		Inventory.add_item(GameState.player, previous)
	message_label.text = ""
	refresh()

func _on_unequip_pressed(slot: String) -> void:
	var removed := EquipmentManager.unequip(GameState.player, slot)
	if removed != null:
		Inventory.add_item(GameState.player, removed)
	refresh()
