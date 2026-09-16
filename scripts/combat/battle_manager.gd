extends Node2D
class_name BattleManager
## Battle state machine. Owns all combat math and turn resolution — no
## UI code here (see ARCHITECTURE.md Section 6). One instance per
## Battle.tscn; not an autoload. UI drives it only through the
## player_*() methods and reads state only through the signals/fields
## below.
##
## Depth pass (post-Phase-6): fights are against a *pack* of enemies
## (1 for bosses/minibosses, 2-3 for common encounters — see
## EncounterData.enemy_ids), not always exactly one. `enemies`/
## `enemy_hps` are parallel arrays indexed the same way throughout.

signal turn_state_changed(state_name: String) # "player_input" | "resolving" | "enemy_turn" | "won" | "lost" | "fled"
signal action_resolved(message: String)
signal hp_mp_changed
signal battle_won(xp: int, gold: int, leveled_up: bool, loot_item_name: String, clue_discovered: bool)
signal battle_lost
signal battle_fled
signal enemy_hit(damage: int) # Phase 6 — combat feedback (hit flash/shake); UI-only concern
signal player_hit(damage: int)

enum State { PLAYER_INPUT, RESOLVING, ENEMY_TURN, WON, LOST, FLED }

var state: State = State.PLAYER_INPUT
var player: PlayerData
var enemies: Array[EnemyData] = []
var enemy_hps: Array[int] = []
var enemy_level: int = 1
var can_flee: bool = true
var player_defending: bool = false
var current_encounter: EncounterData # kept for loot_table_id_override — see _win()

# Enemy AI variety (Phase 6, now per-pack-member): normal enemies
# alternate basic attack/skill instead of always using their one skill;
# an enraged boss (see EnemyData.enrage_skill_id) overrides this once
# its HP threshold is crossed. enemy_turn_count is shared across the
# whole pack (every living member alternates in lockstep) rather than
# tracked per enemy — simpler, and reads as intentional pack
# coordination rather than arbitrary.
var enemy_turn_count: int = 0
var enemy_enraged: Array[bool] = []
var _just_enraged: Array[bool] = []

func _enter_tree() -> void:
	# Deliberately _enter_tree(), not _ready(): Godot calls _ready() on
	# children before their parent, so BattleUI (a child of this node)
	# would read `enemies`/`player` as still-empty in its own _ready()
	# if start_battle() waited until this node's _ready(). _enter_tree()
	# fires top-down (parent before children), so state is guaranteed
	# ready before any child's _ready() runs.
	if GameState.pending_generated_encounter != null:
		var encounter := GameState.pending_generated_encounter
		GameState.pending_generated_encounter = null
		_start_with_encounter(encounter)
	else:
		start_battle(GameState.pending_encounter_id)

## File-based path (hand-authored data/encounters/*.tres rows).
func start_battle(encounter_id: String) -> void:
	var encounter: EncounterData = DataLoader.load_resource("res://data/encounters/%s.tres" % encounter_id)
	if encounter == null:
		push_error("BattleManager: unknown encounter id '%s'" % encounter_id)
		return
	_start_with_encounter(encounter)

## In-memory path (generated dungeons build an EncounterData at trigger
## time — see GeneratedEncounterTrigger — rather than authoring one row
## per possible Gate combination).
func _start_with_encounter(encounter: EncounterData) -> void:
	current_encounter = encounter
	enemies.clear()
	enemy_hps.clear()
	for enemy_id in encounter.enemy_ids:
		enemies.append(DataLoader.load_resource("res://data/enemies/%s.tres" % enemy_id))
	enemy_level = maxi(1, encounter.level)
	player = GameState.player
	for enemy in enemies:
		enemy_hps.append(EnemyScaler.max_hp(enemy, enemy_level))
	can_flee = encounter.can_flee
	player_defending = false
	enemy_turn_count = 0
	enemy_enraged = []
	_just_enraged = []
	for i in enemies.size():
		enemy_enraged.append(false)
		_just_enraged.append(false)

	# Initiative: the pack's fastest member vs the player's effective
	# Speed decides who opens; turns alternate normally after that.
	# Enemy speed is deliberately unscaled by EnemyScaler.
	var fastest_index := 0
	for i in enemies.size():
		if enemies[i].speed > enemies[fastest_index].speed:
			fastest_index = i
	if enemies[fastest_index].speed > StatsCalculator.effective_speed(player):
		state = State.RESOLVING
		turn_state_changed.emit("resolving")
		action_resolved.emit("%s is faster and strikes first!" % enemies[fastest_index].display_name)
		await get_tree().create_timer(0.6).timeout
		_enemy_turn()
	else:
		state = State.PLAYER_INPUT
		turn_state_changed.emit("player_input")

func alive_enemy_indices() -> Array[int]:
	var result: Array[int] = []
	for i in enemy_hps.size():
		if enemy_hps[i] > 0:
			result.append(i)
	return result

func _valid_target(target_index: int) -> bool:
	return target_index >= 0 and target_index < enemy_hps.size() and enemy_hps[target_index] > 0

func player_attack(target_index: int) -> void:
	if state != State.PLAYER_INPUT or not _valid_target(target_index):
		return
	var target := enemies[target_index]
	var dmg := CombatMath.mitigate(StatsCalculator.effective_attack(player), EnemyScaler.defense(target, enemy_level))
	dmg = _apply_weapon_family_bonus(dmg, target)
	enemy_hps[target_index] = maxi(0, enemy_hps[target_index] - dmg)
	action_resolved.emit("You attack %s for %d damage." % [target.display_name, dmg])
	enemy_hit.emit(dmg)
	_after_player_action()

## target_index is ignored for "self" and "all_enemies" skills; required
## (and validated) for "single_enemy" ones.
func player_use_skill(skill: SkillData, target_index: int = -1) -> void:
	if state != State.PLAYER_INPUT:
		return
	if player.mp < skill.mp_cost:
		action_resolved.emit("Not enough MP for %s." % skill.display_name)
		return
	if skill.target_type == "single_enemy" and not _valid_target(target_index):
		return
	player.mp -= skill.mp_cost
	if skill.target_type == "self":
		var healed := skill.power
		player.hp = mini(StatsCalculator.effective_max_hp(player), player.hp + healed)
		action_resolved.emit("You use %s and recover %d HP." % [skill.display_name, healed])
	elif skill.target_type == "all_enemies":
		var power_stat := CombatMath.skill_power_stat(
			skill, StatsCalculator.effective_attack(player), StatsCalculator.effective_magic_power(player)
		)
		var total_dmg := 0
		for i in alive_enemy_indices():
			var dmg := CombatMath.mitigate(skill.power + power_stat, EnemyScaler.defense(enemies[i], enemy_level))
			dmg = _apply_weapon_family_bonus(dmg, enemies[i])
			enemy_hps[i] = maxi(0, enemy_hps[i] - dmg)
			total_dmg += dmg
		action_resolved.emit("You use %s, hitting the whole pack for %d total damage!" % [skill.display_name, total_dmg])
		enemy_hit.emit(total_dmg)
	else: # single_enemy
		var target := enemies[target_index]
		var power_stat := CombatMath.skill_power_stat(
			skill, StatsCalculator.effective_attack(player), StatsCalculator.effective_magic_power(player)
		)
		var dmg := CombatMath.mitigate(skill.power + power_stat, EnemyScaler.defense(target, enemy_level))
		dmg = _apply_weapon_family_bonus(dmg, target)
		enemy_hps[target_index] = maxi(0, enemy_hps[target_index] - dmg)
		action_resolved.emit("You use %s on %s for %d damage." % [skill.display_name, target.display_name, dmg])
		enemy_hit.emit(dmg)
	hp_mp_changed.emit()
	_after_player_action()

## Cindermourn-style equipment identity (GAME_DESIGN.md Section 10): a
## weapon can carry a flat damage percentage bonus against one specific
## enemy family, rather than just bigger raw stats.
func _apply_weapon_family_bonus(dmg: int, target: EnemyData) -> int:
	var weapon := player.equipped_weapon
	if weapon != null and weapon.bonus_damage_vs_family != "" and weapon.bonus_damage_vs_family == target.family:
		return maxi(1, roundi(dmg * (1.0 + weapon.bonus_damage_percent)))
	return dmg

func player_use_item() -> void:
	if state != State.PLAYER_INPUT:
		return
	var consumable := Inventory.find_first_consumable(player)
	if consumable == null:
		action_resolved.emit("No items to use.")
		return
	Inventory.remove_item(player, consumable)
	player.hp = mini(StatsCalculator.effective_max_hp(player), player.hp + consumable.heal_hp)
	player.mp = mini(StatsCalculator.effective_max_mp(player), player.mp + consumable.heal_mp)
	action_resolved.emit("You use %s. +%d HP, +%d MP." % [consumable.display_name, consumable.heal_hp, consumable.heal_mp])
	hp_mp_changed.emit()
	_after_player_action()

func player_defend() -> void:
	if state != State.PLAYER_INPUT:
		return
	player_defending = true
	action_resolved.emit("You brace for the next attack.")
	_after_player_action()

func player_run() -> void:
	if state != State.PLAYER_INPUT:
		return
	if not can_flee:
		action_resolved.emit("%s blocks your retreat!" % enemy_names_summary())
		return
	state = State.FLED
	turn_state_changed.emit("fled")
	action_resolved.emit("You flee the battle.")
	battle_fled.emit()

func _after_player_action() -> void:
	if alive_enemy_indices().is_empty():
		_win()
		return
	state = State.RESOLVING
	turn_state_changed.emit("resolving")
	await get_tree().create_timer(0.6).timeout
	_enemy_turn()

func _enemy_turn() -> void:
	state = State.ENEMY_TURN
	turn_state_changed.emit("enemy_turn")
	enemy_turn_count += 1

	var player_defense := StatsCalculator.effective_defense(player)
	for i in alive_enemy_indices():
		var enemy := enemies[i]
		var dmg: int
		var msg: String
		var skill_id := _choose_enemy_skill_id(i)
		if skill_id != "":
			var skill: SkillData = DataLoader.load_resource("res://data/skills/%s.tres" % skill_id)
			var power_stat := CombatMath.skill_power_stat(
				skill, EnemyScaler.attack(enemy, enemy_level), EnemyScaler.magic_power(enemy, enemy_level)
			)
			dmg = CombatMath.mitigate(skill.power + power_stat, player_defense)
			msg = "%s uses %s for %d damage!" % [enemy.display_name, skill.display_name, dmg]
		else:
			dmg = CombatMath.mitigate(EnemyScaler.attack(enemy, enemy_level), player_defense)
			msg = "%s attacks for %d damage!" % [enemy.display_name, dmg]

		dmg = CombatMath.pack_scale(dmg, enemies.size())

		if player_defending:
			dmg = dmg / 2
			msg += " (defended)"

		if _just_enraged[i]:
			msg = "The %s's flames roar higher! " % enemy.display_name + msg
			_just_enraged[i] = false

		player.hp = maxi(0, player.hp - dmg)
		action_resolved.emit(msg)
		player_hit.emit(dmg)
		hp_mp_changed.emit()

		if player.hp <= 0:
			_lose()
			return
		if alive_enemy_indices().size() > 1:
			await get_tree().create_timer(0.5).timeout # let each pack member's hit read individually

	player_defending = false
	state = State.PLAYER_INPUT
	turn_state_changed.emit("player_input")

## Every enemy alternates basic attack / its one skill rather than
## spamming the skill every turn (Phase 6 — AI variety), in lockstep
## across the whole pack via the shared enemy_turn_count. A boss with
## enrage_skill_id set overrides this permanently for itself, always
## using that skill, once its own HP drops to or below enrage_threshold.
func _choose_enemy_skill_id(index: int) -> String:
	var enemy := enemies[index]
	if enemy.enrage_skill_id != "":
		var max_hp := EnemyScaler.max_hp(enemy, enemy_level)
		if float(enemy_hps[index]) / float(max_hp) <= enemy.enrage_threshold:
			if not enemy_enraged[index]:
				enemy_enraged[index] = true
				_just_enraged[index] = true
			return enemy.enrage_skill_id
	# Offset by pack index so a multi-enemy pack staggers its
	# attack/skill alternation instead of every member upgrading to
	# its (usually stronger) skill on the same synchronized turn —
	# found via a pack self-test dealing a sudden lethal spike every
	# other turn when all members attacked in lockstep. A solo enemy
	# (index 0) is completely unaffected: (n + 0) % 2 == n % 2.
	if enemy.skill_ids.size() > 0 and (enemy_turn_count + index) % 2 == 0:
		return enemy.skill_ids[0]
	return ""

## Human-readable pack summary for messages, e.g. "Ember Wisp x2, Bramble
## Husk" — collapses duplicate pack members instead of repeating a name.
func enemy_names_summary() -> String:
	var counts: Dictionary = {}
	var order: Array[String] = []
	for enemy in enemies:
		if not counts.has(enemy.display_name):
			counts[enemy.display_name] = 0
			order.append(enemy.display_name)
		counts[enemy.display_name] += 1
	var parts: Array[String] = []
	for display_name in order:
		if counts[display_name] > 1:
			parts.append("%s x%d" % [display_name, counts[display_name]])
		else:
			parts.append(display_name)
	return ", ".join(parts)

func _win() -> void:
	state = State.WON
	turn_state_changed.emit("won")
	var total_xp := 0
	var total_gold := 0
	for enemy in enemies:
		total_xp += EnemyScaler.xp_reward(enemy, enemy_level)
		total_gold += EnemyScaler.gold_reward(enemy, enemy_level)
	player.gold += total_gold
	var leveled_up := Leveling.grant_xp(player, total_xp)

	var loot_item_name := ""
	var loot_table_id := ""
	if current_encounter != null and current_encounter.loot_table_id_override != "":
		loot_table_id = current_encounter.loot_table_id_override
	else:
		for enemy in enemies:
			if enemy.loot_table_id != "":
				loot_table_id = enemy.loot_table_id
				break
	if loot_table_id != "":
		var table: LootTableData = DataLoader.load_resource("res://data/loot/%s.tres" % loot_table_id)
		var loot_id := LootRoller.roll(table)
		if loot_id != "":
			var item: ItemData = DataLoader.load_resource("res://data/items/%s.tres" % loot_id)
			if item != null:
				Inventory.add_item(player, item)
				loot_item_name = item.display_name

	var clue_discovered := false
	for enemy in enemies:
		if enemy.gate_clue_id != "":
			GameState.discover_clue(enemy.gate_clue_id)
			clue_discovered = true

	var mp_restored := 0
	var weapon := player.equipped_weapon
	if weapon != null and weapon.mp_restore_on_kill > 0:
		var mp_before := player.mp
		player.mp = mini(StatsCalculator.effective_max_mp(player), player.mp + weapon.mp_restore_on_kill * enemies.size())
		mp_restored = player.mp - mp_before

	var victory_msg := "Victory! %s defeated." % enemy_names_summary()
	if loot_item_name != "":
		victory_msg += " You found %s!" % loot_item_name
	if clue_discovered:
		victory_msg += " A strange note falls from the wreckage..."
	if mp_restored > 0:
		victory_msg += " (+%d MP)" % mp_restored
	action_resolved.emit(victory_msg)
	battle_won.emit(total_xp, total_gold, leveled_up, loot_item_name, clue_discovered)

func _lose() -> void:
	state = State.LOST
	turn_state_changed.emit("lost")
	# No real defeat penalty in the prototype yet — full heal and send
	# the player back to Waymark rather than soft-locking a solo
	# playtester. A real game-over/consequence system is later polish.
	player.hp = StatsCalculator.effective_max_hp(player)
	player.mp = StatsCalculator.effective_max_mp(player)
	action_resolved.emit("You were defeated...")
	battle_lost.emit()
