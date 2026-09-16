extends CanvasLayer
# Battle command UI. Reads BattleManager's signals/fields and renders
# Controls; sends player choices back only through BattleManager's
# player_*() methods. Contains no combat math (Agent 2 owns that) — see
# ARCHITECTURE.md Section 6 / AGENT_CONTRACTS.md.
#
# Depth pass (post-Phase-6): fights are against a pack of 1-3 enemies.
# EnemyList shows one row per pack member; a TargetMenu submenu appears
# only when more than one enemy is alive and the player Attacks or uses
# a single_enemy Skill — with exactly one alive, targeting is automatic
# so a solo fight (most bosses) still takes zero extra clicks.

const UNIVERSAL_SKILL_IDS := ["ember_slash", "guard_break", "second_wind", "blazing_arc"]

@onready var battle_manager: Node = get_parent()
@onready var root: Control = $Root
@onready var hit_flash: ColorRect = $Root/HitFlash
@onready var enemy_list: VBoxContainer = $Root/EnemyList
@onready var player_hp_label: Label = $Root/PlayerPanel/PlayerHP
@onready var player_mp_label: Label = $Root/PlayerPanel/PlayerMP
@onready var message_label: Label = $Root/MessageLabel
@onready var command_menu: VBoxContainer = $Root/CommandMenu
@onready var skill_menu: VBoxContainer = $Root/SkillMenu
@onready var target_menu: VBoxContainer = $Root/TargetMenu
@onready var attack_button: Button = $Root/CommandMenu/AttackButton
@onready var skill_button: Button = $Root/CommandMenu/SkillButton
@onready var item_button: Button = $Root/CommandMenu/ItemButton
@onready var defend_button: Button = $Root/CommandMenu/DefendButton
@onready var run_button: Button = $Root/CommandMenu/RunButton
@onready var skill_back_button: Button = $Root/SkillMenu/BackButton
@onready var target_back_button: Button = $Root/TargetMenu/BackButton

var _pending_skill: SkillData = null # non-null while targeting for a Skill rather than a basic Attack

func _ready() -> void:
	var skill_ids := UNIVERSAL_SKILL_IDS.duplicate()
	var weapon: EquipmentData = battle_manager.player.equipped_weapon
	if weapon != null and weapon.granted_skill_id != "" and not skill_ids.has(weapon.granted_skill_id):
		skill_ids.append(weapon.granted_skill_id)
	for id in skill_ids:
		var skill: SkillData = DataLoader.load_resource("res://data/skills/%s.tres" % id)
		if skill == null:
			continue
		var btn := Button.new()
		btn.text = "%s (MP %d)" % [skill.display_name, skill.mp_cost]
		btn.pressed.connect(_on_skill_chosen.bind(skill))
		skill_menu.add_child(btn)
		skill_menu.move_child(skill_back_button, skill_menu.get_child_count() - 1)
	skill_menu.hide()
	target_menu.hide()

	attack_button.pressed.connect(_on_attack_pressed)
	skill_button.pressed.connect(_show_skill_menu)
	item_button.pressed.connect(func(): battle_manager.player_use_item())
	defend_button.pressed.connect(func(): battle_manager.player_defend())
	run_button.pressed.connect(func(): battle_manager.player_run())
	skill_back_button.pressed.connect(_hide_skill_menu)
	target_back_button.pressed.connect(_hide_target_menu)

	battle_manager.turn_state_changed.connect(_on_turn_state_changed)
	battle_manager.action_resolved.connect(_on_action_resolved)
	battle_manager.hp_mp_changed.connect(_refresh_stats)
	battle_manager.battle_won.connect(_on_battle_won)
	battle_manager.battle_lost.connect(_on_battle_lost)
	battle_manager.battle_fled.connect(_on_battle_fled)
	battle_manager.enemy_hit.connect(_on_enemy_hit)
	battle_manager.player_hit.connect(_on_player_hit)

	message_label.text = "%s appears!" % battle_manager.enemy_names_summary()
	_refresh_stats()

func _refresh_stats() -> void:
	for child in enemy_list.get_children():
		child.queue_free()
	for i in battle_manager.enemies.size():
		var enemy: EnemyData = battle_manager.enemies[i]
		var hp: int = battle_manager.enemy_hps[i]
		var label := Label.new()
		if hp <= 0:
			label.text = "%s — defeated" % enemy.display_name
			label.modulate = Color(0.55, 0.55, 0.55)
		else:
			var max_hp := EnemyScaler.max_hp(enemy, battle_manager.enemy_level)
			label.text = "%s  HP %d/%d" % [enemy.display_name, hp, max_hp]
		enemy_list.add_child(label)
	player_hp_label.text = "HP %d/%d" % [battle_manager.player.hp, StatsCalculator.effective_max_hp(battle_manager.player)]
	player_mp_label.text = "MP %d/%d" % [battle_manager.player.mp, StatsCalculator.effective_max_mp(battle_manager.player)]

func _on_attack_pressed() -> void:
	_pending_skill = null
	_start_targeting()

func _on_skill_chosen(skill: SkillData) -> void:
	_hide_skill_menu()
	if skill.target_type == "single_enemy":
		_pending_skill = skill
		_start_targeting()
	else:
		battle_manager.player_use_skill(skill)

## Auto-targets the lone survivor with zero extra clicks; only pauses
## for an explicit target pick when more than one enemy is alive.
func _start_targeting() -> void:
	var alive: Array[int] = battle_manager.alive_enemy_indices()
	if alive.size() <= 1:
		_confirm_target(alive[0] if alive.size() == 1 else -1)
		return
	command_menu.hide()
	for child in target_menu.get_children():
		if child != target_back_button:
			child.queue_free()
	for i in alive:
		var enemy: EnemyData = battle_manager.enemies[i]
		var btn := Button.new()
		btn.text = "%s (HP %d)" % [enemy.display_name, battle_manager.enemy_hps[i]]
		btn.pressed.connect(_confirm_target.bind(i))
		target_menu.add_child(btn)
		target_menu.move_child(target_back_button, target_menu.get_child_count() - 1)
	target_menu.show()

func _confirm_target(index: int) -> void:
	_hide_target_menu()
	if _pending_skill != null:
		var skill := _pending_skill
		_pending_skill = null
		battle_manager.player_use_skill(skill, index)
	else:
		battle_manager.player_attack(index)

func _show_skill_menu() -> void:
	command_menu.hide()
	skill_menu.show()

func _hide_skill_menu() -> void:
	skill_menu.hide()
	command_menu.show()

func _hide_target_menu() -> void:
	target_menu.hide()
	command_menu.show()
	_pending_skill = null

func _on_turn_state_changed(state_name: String) -> void:
	var can_act := state_name == "player_input"
	if not can_act:
		skill_menu.hide()
		target_menu.hide()
		command_menu.show()
	for child in command_menu.get_children():
		if child is Button:
			child.disabled = not can_act
	for child in skill_menu.get_children():
		if child is Button:
			child.disabled = not can_act
	for child in target_menu.get_children():
		if child is Button:
			child.disabled = not can_act
	_refresh_stats()

func _on_action_resolved(message: String) -> void:
	message_label.text = message

## Combat feedback polish (Phase 6): a quick tint + shake reacting to
## BattleManager's enemy_hit/player_hit signals. Pure presentation — no
## combat math lives here, only damage numbers already computed elsewhere.
func _on_enemy_hit(_damage: int) -> void:
	_flash(Color(1.0, 0.9, 0.6, 0.5))
	_shake(5.0)
	Sfx.play("hit")

func _on_player_hit(_damage: int) -> void:
	_flash(Color(0.9, 0.1, 0.1, 0.45))
	_shake(8.0)
	Sfx.play("hit")

func _flash(color: Color) -> void:
	hit_flash.color = color
	var tween := create_tween()
	tween.tween_property(hit_flash, "color:a", 0.0, 0.25)

func _shake(strength: float) -> void:
	var tween := create_tween()
	for i in range(4):
		var offset := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tween.tween_property(root, "position", offset, 0.04)
	tween.tween_property(root, "position", Vector2.ZERO, 0.04)

func _on_battle_won(xp: int, gold: int, leveled_up: bool, loot_item_name: String, clue_discovered: bool) -> void:
	command_menu.hide()
	skill_menu.hide()
	target_menu.hide()
	var extra := " You leveled up!" if leveled_up else ""
	var loot_text := " Found: %s!" % loot_item_name if loot_item_name != "" else ""
	var clue_text := " A note falls from the wreckage..." if clue_discovered else ""
	message_label.text = "Victory! +%d XP, +%d gold.%s%s%s" % [xp, gold, loot_text, clue_text, extra]
	Sfx.play("victory")
	await get_tree().create_timer(1.2).timeout
	SceneManager.go_to_current_map()

func _on_battle_lost() -> void:
	command_menu.hide()
	skill_menu.hide()
	target_menu.hide()
	message_label.text = "You were defeated... retreating to Waymark."
	Sfx.play("defeat")
	await get_tree().create_timer(1.2).timeout
	SceneManager.go_to_town()

func _on_battle_fled() -> void:
	command_menu.hide()
	skill_menu.hide()
	target_menu.hide()
	Sfx.play("flee")
	await get_tree().create_timer(0.6).timeout
	SceneManager.go_to_current_map()
