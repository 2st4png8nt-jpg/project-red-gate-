extends Node2D
class_name BattleManager
## Battle state machine. Owns all combat math and turn resolution — no
## UI code here (see ARCHITECTURE.md Section 6). One instance per
## Battle.tscn; not an autoload. UI drives it only through the
## player_*() methods and reads state only through the signals/fields
## below.

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
var enemy: EnemyData
var enemy_level: int = 1
var enemy_hp: int
var can_flee: bool = true
var player_defending: bool = false
var current_encounter: EncounterData # kept for loot_table_id_override — see _win()

# Enemy AI variety (Phase 6): normal enemies alternate basic
# attack/skill instead of always using their one skill; an enraged boss
# (see EnemyData.enrage_skill_id) overrides this once its HP threshold
# is crossed.
var enemy_turn_count: int = 0
var enemy_enraged: bool = false
var _just_enraged: bool = false

func _enter_tree() -> void:
	# Deliberately _enter_tree(), not _ready(): Godot calls _ready() on
	# children before their parent, so BattleUI (a child of this node)
	# would read `enemy`/`player` as still-null in its own _ready() if
	# start_battle() waited until this node's _ready(). _enter_tree()
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
	enemy = DataLoader.load_resource("res://data/enemies/%s.tres" % encounter.enemy_id)
	can_flee = encounter.can_flee
	enemy_level = maxi(1, encounter.level)
	player = GameState.player
	enemy_hp = EnemyScaler.max_hp(enemy, enemy_level)
	player_defending = false
	enemy_turn_count = 0
	enemy_enraged = false
	_just_enraged = false

	# Initiative: whoever is faster acts first; turns alternate normally
	# after that. Speed was previously decorative (turn order was
	# always player-first regardless of it) — see ARCHITECTURE.md
	# Section 6c. Enemy speed is deliberately unscaled by EnemyScaler.
	if enemy.speed > StatsCalculator.effective_speed(player):
		state = State.RESOLVING
		turn_state_changed.emit("resolving")
		action_resolved.emit("%s is faster and strikes first!" % enemy.display_name)
		await get_tree().create_timer(0.6).timeout
		_enemy_turn()
	else:
		state = State.PLAYER_INPUT
		turn_state_changed.emit("player_input")

func player_attack() -> void:
	if state != State.PLAYER_INPUT:
		return
	var dmg := CombatMath.mitigate(StatsCalculator.effective_attack(player), EnemyScaler.defense(enemy, enemy_level))
	dmg = _apply_weapon_family_bonus(dmg)
	enemy_hp = maxi(0, enemy_hp - dmg)
	action_resolved.emit("You attack for %d damage." % dmg)
	enemy_hit.emit(dmg)
	_after_player_action()

func player_use_skill(skill: SkillData) -> void:
	if state != State.PLAYER_INPUT:
		return
	if player.mp < skill.mp_cost:
		action_resolved.emit("Not enough MP for %s." % skill.display_name)
		return
	player.mp -= skill.mp_cost
	if skill.target_type == "self":
		var healed := skill.power
		player.hp = mini(StatsCalculator.effective_max_hp(player), player.hp + healed)
		action_resolved.emit("You use %s and recover %d HP." % [skill.display_name, healed])
	else:
		var power_stat := CombatMath.skill_power_stat(
			skill, StatsCalculator.effective_attack(player), StatsCalculator.effective_magic_power(player)
		)
		var dmg := CombatMath.mitigate(skill.power + power_stat, EnemyScaler.defense(enemy, enemy_level))
		dmg = _apply_weapon_family_bonus(dmg)
		enemy_hp = maxi(0, enemy_hp - dmg)
		action_resolved.emit("You use %s for %d damage." % [skill.display_name, dmg])
		enemy_hit.emit(dmg)
	hp_mp_changed.emit()
	_after_player_action()

## Cindermourn-style equipment identity (GAME_DESIGN.md Section 10): a
## weapon can carry a flat damage percentage bonus against one specific
## enemy family, rather than just bigger raw stats.
func _apply_weapon_family_bonus(dmg: int) -> int:
	var weapon := player.equipped_weapon
	if weapon != null and weapon.bonus_damage_vs_family != "" and weapon.bonus_damage_vs_family == enemy.family:
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
		action_resolved.emit("The %s blocks your retreat!" % enemy.display_name)
		return
	state = State.FLED
	turn_state_changed.emit("fled")
	action_resolved.emit("You flee the battle.")
	battle_fled.emit()

func _after_player_action() -> void:
	if enemy_hp <= 0:
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

	var dmg: int
	var msg: String
	var player_defense := StatsCalculator.effective_defense(player)
	var skill_id := _choose_enemy_skill_id()
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

	if player_defending:
		dmg = dmg / 2
		msg += " (defended)"
	player_defending = false

	if _just_enraged:
		msg = "The %s's flames roar higher! " % enemy.display_name + msg
		_just_enraged = false

	player.hp = maxi(0, player.hp - dmg)
	action_resolved.emit(msg)
	player_hit.emit(dmg)
	hp_mp_changed.emit()

	if player.hp <= 0:
		_lose()
	else:
		state = State.PLAYER_INPUT
		turn_state_changed.emit("player_input")

## Every enemy alternates basic attack / its one skill rather than
## spamming the skill every turn (Phase 6 — AI variety). A boss with
## enrage_skill_id set overrides this permanently, always using that
## skill, once enemy_hp drops to or below enrage_threshold of max HP.
func _choose_enemy_skill_id() -> String:
	if enemy.enrage_skill_id != "":
		var max_hp := EnemyScaler.max_hp(enemy, enemy_level)
		if float(enemy_hp) / float(max_hp) <= enemy.enrage_threshold:
			if not enemy_enraged:
				enemy_enraged = true
				_just_enraged = true
			return enemy.enrage_skill_id
	if enemy.skill_ids.size() > 0 and enemy_turn_count % 2 == 0:
		return enemy.skill_ids[0]
	return ""

func _win() -> void:
	state = State.WON
	turn_state_changed.emit("won")
	var xp := EnemyScaler.xp_reward(enemy, enemy_level)
	var gold := EnemyScaler.gold_reward(enemy, enemy_level)
	player.gold += gold
	var leveled_up := Leveling.grant_xp(player, xp)

	var loot_item_name := ""
	var loot_table_id := enemy.loot_table_id
	if current_encounter != null and current_encounter.loot_table_id_override != "":
		loot_table_id = current_encounter.loot_table_id_override
	if loot_table_id != "":
		var table: LootTableData = DataLoader.load_resource("res://data/loot/%s.tres" % loot_table_id)
		var loot_id := LootRoller.roll(table)
		if loot_id != "":
			var item: ItemData = DataLoader.load_resource("res://data/items/%s.tres" % loot_id)
			if item != null:
				Inventory.add_item(player, item)
				loot_item_name = item.display_name

	var clue_discovered := false
	if enemy.gate_clue_id != "":
		GameState.discover_clue(enemy.gate_clue_id)
		clue_discovered = true

	var mp_restored := 0
	var weapon := player.equipped_weapon
	if weapon != null and weapon.mp_restore_on_kill > 0:
		var mp_before := player.mp
		player.mp = mini(StatsCalculator.effective_max_mp(player), player.mp + weapon.mp_restore_on_kill)
		mp_restored = player.mp - mp_before

	var victory_msg := "Victory! %s defeated." % enemy.display_name
	if loot_item_name != "":
		victory_msg += " You found %s!" % loot_item_name
	if clue_discovered:
		victory_msg += " A strange note falls from the wreckage..."
	if mp_restored > 0:
		victory_msg += " (+%d MP)" % mp_restored
	action_resolved.emit(victory_msg)
	battle_won.emit(xp, gold, leveled_up, loot_item_name, clue_discovered)

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
