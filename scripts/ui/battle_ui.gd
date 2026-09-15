extends CanvasLayer
# Battle command UI. Reads BattleManager's signals/fields and renders
# Controls; sends player choices back only through BattleManager's
# player_*() methods. Contains no combat math (Agent 2 owns that) — see
# ARCHITECTURE.md Section 6 / AGENT_CONTRACTS.md.

const SKILL_IDS := ["ember_slash", "guard_break", "second_wind"]

@onready var battle_manager: Node = get_parent()
@onready var enemy_name_label: Label = $Root/EnemyPanel/EnemyName
@onready var enemy_hp_label: Label = $Root/EnemyPanel/EnemyHP
@onready var player_hp_label: Label = $Root/PlayerPanel/PlayerHP
@onready var player_mp_label: Label = $Root/PlayerPanel/PlayerMP
@onready var message_label: Label = $Root/MessageLabel
@onready var command_menu: VBoxContainer = $Root/CommandMenu
@onready var skill_menu: VBoxContainer = $Root/SkillMenu
@onready var attack_button: Button = $Root/CommandMenu/AttackButton
@onready var skill_button: Button = $Root/CommandMenu/SkillButton
@onready var item_button: Button = $Root/CommandMenu/ItemButton
@onready var defend_button: Button = $Root/CommandMenu/DefendButton
@onready var run_button: Button = $Root/CommandMenu/RunButton
@onready var skill_back_button: Button = $Root/SkillMenu/BackButton

func _ready() -> void:
	for id in SKILL_IDS:
		var skill: SkillData = DataLoader.load_resource("res://data/skills/%s.tres" % id)
		if skill == null:
			continue
		var btn := Button.new()
		btn.text = "%s (MP %d)" % [skill.display_name, skill.mp_cost]
		btn.pressed.connect(_on_skill_chosen.bind(skill))
		skill_menu.add_child(btn)
		skill_menu.move_child(skill_back_button, skill_menu.get_child_count() - 1)
	skill_menu.hide()

	attack_button.pressed.connect(func(): battle_manager.player_attack())
	skill_button.pressed.connect(_show_skill_menu)
	item_button.pressed.connect(func(): battle_manager.player_use_item())
	defend_button.pressed.connect(func(): battle_manager.player_defend())
	run_button.pressed.connect(func(): battle_manager.player_run())
	skill_back_button.pressed.connect(_hide_skill_menu)

	battle_manager.turn_state_changed.connect(_on_turn_state_changed)
	battle_manager.action_resolved.connect(_on_action_resolved)
	battle_manager.hp_mp_changed.connect(_refresh_stats)
	battle_manager.battle_won.connect(_on_battle_won)
	battle_manager.battle_lost.connect(_on_battle_lost)
	battle_manager.battle_fled.connect(_on_battle_fled)

	enemy_name_label.text = battle_manager.enemy.display_name
	message_label.text = "A wild %s appears!" % battle_manager.enemy.display_name
	_refresh_stats()

func _refresh_stats() -> void:
	enemy_hp_label.text = "HP %d/%d" % [battle_manager.enemy_hp, battle_manager.enemy.max_hp]
	player_hp_label.text = "HP %d/%d" % [battle_manager.player.hp, StatsCalculator.effective_max_hp(battle_manager.player)]
	player_mp_label.text = "MP %d/%d" % [battle_manager.player.mp, StatsCalculator.effective_max_mp(battle_manager.player)]

func _on_skill_chosen(skill: SkillData) -> void:
	_hide_skill_menu()
	battle_manager.player_use_skill(skill)

func _show_skill_menu() -> void:
	command_menu.hide()
	skill_menu.show()

func _hide_skill_menu() -> void:
	skill_menu.hide()
	command_menu.show()

func _on_turn_state_changed(state_name: String) -> void:
	var can_act := state_name == "player_input"
	if not can_act:
		skill_menu.hide()
		command_menu.show()
	for child in command_menu.get_children():
		if child is Button:
			child.disabled = not can_act
	for child in skill_menu.get_children():
		if child is Button:
			child.disabled = not can_act
	_refresh_stats()

func _on_action_resolved(message: String) -> void:
	message_label.text = message

func _on_battle_won(xp: int, gold: int, leveled_up: bool) -> void:
	command_menu.hide()
	skill_menu.hide()
	var extra := " You leveled up!" if leveled_up else ""
	message_label.text = "Victory! +%d XP, +%d gold.%s" % [xp, gold, extra]
	await get_tree().create_timer(1.2).timeout
	SceneManager.go_to_map(GameState.current_map_id)

func _on_battle_lost() -> void:
	command_menu.hide()
	skill_menu.hide()
	message_label.text = "You were defeated... retreating to Waymark."
	await get_tree().create_timer(1.2).timeout
	SceneManager.go_to_town()

func _on_battle_fled() -> void:
	command_menu.hide()
	skill_menu.hide()
	await get_tree().create_timer(0.6).timeout
	SceneManager.go_to_map(GameState.current_map_id)
