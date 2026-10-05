extends CanvasLayer
## Minimal Phase 3 HUD: player HP/SP bars + a target info panel.
## Target HP is read directly off the targeted Enemy each frame rather
## than via a signal — simplest option until enemies need to broadcast
## their own HP changes for some other reason.

@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPLabel
@onready var sp_bar: ProgressBar = $SPBar
@onready var sp_label: Label = $SPLabel
@onready var target_panel: Control = $TargetPanel
@onready var target_name_label: Label = $TargetPanel/TargetName
@onready var target_hp_bar: ProgressBar = $TargetPanel/TargetHPBar

var _current_target: Node = null

func _ready() -> void:
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.player_sp_changed.connect(_on_player_sp_changed)
	EventBus.target_changed.connect(_on_target_changed)
	target_panel.visible = false
	if GameState.player_character != null:
		_on_player_hp_changed(GameState.player_hp, GameState.player_character.max_hp)
		_on_player_sp_changed(GameState.player_sp, GameState.player_character.max_sp)

func _process(_delta: float) -> void:
	if _current_target == null:
		return
	if not is_instance_valid(_current_target):
		_on_target_changed(null)
		return
	target_hp_bar.max_value = _current_target.enemy_data.max_hp
	target_hp_bar.value = _current_target.hp

func _on_player_hp_changed(current: int, max_value: int) -> void:
	hp_bar.max_value = max_value
	hp_bar.value = current
	hp_label.text = "HP %d/%d" % [current, max_value]

func _on_player_sp_changed(current: int, max_value: int) -> void:
	sp_bar.max_value = max_value
	sp_bar.value = current
	sp_label.text = "SP %d/%d" % [current, max_value]

func _on_target_changed(target: Node) -> void:
	_current_target = target
	target_panel.visible = target != null
	if target != null and "enemy_data" in target:
		target_name_label.text = target.enemy_data.display_name
