extends CanvasLayer
# Inventory/Equipment screen. Reads GameState.player directly (there is
# only ever one local player) and mutates it only through
# Inventory/EquipmentManager helpers — no equip/stat math lives here.
# Equipment *comparison* (before/after preview) is Phase 4 — this is
# just equip/unequip.

@onready var stats_label: Label = $Root/StatsLabel
@onready var equipped_list: VBoxContainer = $Root/EquippedList
@onready var items_list: VBoxContainer = $Root/ItemsList
@onready var close_button: Button = $Root/CloseButton

func _ready() -> void:
	close_button.pressed.connect(func(): hide())
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
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
		text.text = "%s (%s %s)" % [item.display_name, item.rarity, item.slot]
	elif item is ConsumableData:
		text.text = "%s (heals %d HP, %d MP)" % [item.display_name, item.heal_hp, item.heal_mp]
	else:
		text.text = item.display_name
	row.add_child(text)
	if item is EquipmentData:
		var btn := Button.new()
		btn.text = "Equip"
		btn.pressed.connect(_on_equip_pressed.bind(item))
		row.add_child(btn)
	items_list.add_child(row)

func _on_equip_pressed(item: EquipmentData) -> void:
	var previous := EquipmentManager.equip(GameState.player, item)
	Inventory.remove_item(GameState.player, item)
	if previous != null:
		Inventory.add_item(GameState.player, previous)
	refresh()

func _on_unequip_pressed(slot: String) -> void:
	var removed := EquipmentManager.unequip(GameState.player, slot)
	if removed != null:
		Inventory.add_item(GameState.player, removed)
	refresh()
