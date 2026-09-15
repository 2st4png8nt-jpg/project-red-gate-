extends CanvasLayer
# Waymark shop screen. Which items are for sale is data (an exported
# id list set on the scene instance in Town.tscn), not hardcoded logic
# — see AGENT_CONTRACTS.md.

@export var item_ids: Array[String] = []

@onready var gold_label: Label = $Root/GoldLabel
@onready var items_list: VBoxContainer = $Root/ItemsList
@onready var message_label: Label = $Root/MessageLabel
@onready var leave_button: Button = $Root/LeaveButton

func _ready() -> void:
	leave_button.pressed.connect(func(): hide())
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		refresh()

func refresh() -> void:
	gold_label.text = "Gold: %d" % GameState.player.gold
	message_label.text = ""
	for child in items_list.get_children():
		child.queue_free()
	for id in item_ids:
		var item: ItemData = DataLoader.load_resource("res://data/items/%s.tres" % id)
		if item == null:
			continue
		var row := HBoxContainer.new()
		var text := Label.new()
		text.text = "%s - %d gold" % [item.display_name, item.value]
		row.add_child(text)
		var btn := Button.new()
		btn.text = "Buy"
		btn.pressed.connect(_on_buy_pressed.bind(item))
		row.add_child(btn)
		items_list.add_child(row)

func _on_buy_pressed(item: ItemData) -> void:
	if GameState.player.gold < item.value:
		message_label.text = "Not enough gold."
		return
	GameState.player.gold -= item.value
	Inventory.add_item(GameState.player, item)
	message_label.text = "Bought %s." % item.display_name
	refresh()
