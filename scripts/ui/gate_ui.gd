extends CanvasLayer
# Gate combination interface — the payoff of Phase 5. Reads the keyword
# pool from data/gates/keywords/ (data-driven, not hardcoded) and lets
# the player pick one word per category, then resolves via GateResolver.
# Contains no dungeon-generation logic itself — see ARCHITECTURE.md
# Section 7/7a.

@onready var origin_option: OptionButton = $Root/OriginOption
@onready var tone_option: OptionButton = $Root/ToneOption
@onready var sign_option: OptionButton = $Root/SignOption
@onready var open_button: Button = $Root/OpenButton
@onready var close_button: Button = $Root/CloseButton
@onready var message_label: Label = $Root/MessageLabel
@onready var clues_label: Label = $Root/CluesLabel

func _ready() -> void:
	_populate_option(origin_option, "origin")
	_populate_option(tone_option, "tone")
	_populate_option(sign_option, "sign")
	open_button.pressed.connect(_on_open_pressed)
	close_button.pressed.connect(func(): hide())
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		message_label.text = "Choose a word for each — Origin, Tone, Sign — and open the Gate."
		_refresh_clues()

func _populate_option(option: OptionButton, category: String) -> void:
	option.clear()
	option.add_item("— choose —")
	var keywords := DataLoader.load_all_in_dir("res://data/gates/keywords")
	for row in keywords:
		var kw: GateKeywordData = row
		if kw.category == category:
			option.add_item(kw.word)

func _refresh_clues() -> void:
	if GameState.known_gate_clues.is_empty():
		clues_label.text = "Clues discovered: none yet."
		return
	var lines: Array[String] = []
	for clue_id in GameState.known_gate_clues:
		var clue: GateClueData = DataLoader.load_resource("res://data/gates/clues/%s.tres" % clue_id)
		lines.append(clue.hint_text if clue != null else clue_id)
	clues_label.text = "Clues discovered:\n" + "\n".join(lines)

func _on_open_pressed() -> void:
	if origin_option.selected <= 0 or tone_option.selected <= 0 or sign_option.selected <= 0:
		message_label.text = "Choose all three words first."
		return
	var origin := origin_option.get_item_text(origin_option.selected)
	var tone := tone_option.get_item_text(tone_option.selected)
	var sign := sign_option.get_item_text(sign_option.selected)
	var result := GateResolver.resolve(origin, tone, sign)
	match result.type:
		GateResolver.ResultType.INVALID:
			message_label.text = "Nothing happens. The Gate stays dark."
		GateResolver.ResultType.KNOWN:
			message_label.text = "The Gate recognizes the words... it opens."
			_depart(result.destination_map_id)
		GateResolver.ResultType.SPECIAL:
			message_label.text = "The arch does not glow amber. It turns RED."
			_depart(result.destination_map_id)
		GateResolver.ResultType.GENERATED:
			message_label.text = "The Gate hums and opens onto somewhere new..."
			_depart_generated(result.dungeon_profile)

func _depart(destination_map_id: String) -> void:
	await get_tree().create_timer(0.8).timeout
	hide()
	SceneManager.go_to_map(destination_map_id)

func _depart_generated(profile: DungeonProfile) -> void:
	await get_tree().create_timer(0.8).timeout
	hide()
	SceneManager.go_to_generated_dungeon(profile)
