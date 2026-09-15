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
signal battle_won(xp: int, gold: int, leveled_up: bool)
signal battle_lost
signal battle_fled

enum State { PLAYER_INPUT, RESOLVING, ENEMY_TURN, WON, LOST, FLED }

var state: State = State.PLAYER_INPUT
var player: PlayerData
var enemy: EnemyData
var enemy_hp: int
var can_flee: bool = true
var player_defending: bool = false

func _enter_tree() -> void:
	# Deliberately _enter_tree(), not _ready(): Godot calls _ready() on
	# children before their parent, so BattleUI (a child of this node)
	# would read `enemy`/`player` as still-null in its own _ready() if
	# start_battle() waited until this node's _ready(). _enter_tree()
	# fires top-down (parent before children), so state is guaranteed
	# ready before any child's _ready() runs.
	start_battle(GameState.pending_encounter_id)

func start_battle(encounter_id: String) -> void:
	var encounter: EncounterData = DataLoader.load_resource("res://data/encounters/%s.tres" % encounter_id)
	if encounter == null:
		push_error("BattleManager: unknown encounter id '%s'" % encounter_id)
		return
	enemy = DataLoader.load_resource("res://data/enemies/%s.tres" % encounter.enemy_id)
	can_flee = encounter.can_flee
	player = GameState.player
	enemy_hp = enemy.max_hp
	player_defending = false
	state = State.PLAYER_INPUT
	turn_state_changed.emit("player_input")

func player_attack() -> void:
	if state != State.PLAYER_INPUT:
		return
	var dmg := maxi(1, StatsCalculator.effective_attack(player) - enemy.defense)
	enemy_hp = maxi(0, enemy_hp - dmg)
	action_resolved.emit("You attack for %d damage." % dmg)
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
		var dmg := maxi(1, skill.power + StatsCalculator.effective_magic_power(player) - enemy.defense)
		enemy_hp = maxi(0, enemy_hp - dmg)
		action_resolved.emit("You use %s for %d damage." % [skill.display_name, dmg])
	hp_mp_changed.emit()
	_after_player_action()

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

	var dmg: int
	var msg: String
	var player_defense := StatsCalculator.effective_defense(player)
	if enemy.skill_ids.size() > 0:
		var skill: SkillData = DataLoader.load_resource("res://data/skills/%s.tres" % enemy.skill_ids[0])
		dmg = maxi(1, skill.power + enemy.magic_power - player_defense)
		msg = "%s uses %s for %d damage!" % [enemy.display_name, skill.display_name, dmg]
	else:
		dmg = maxi(1, enemy.attack - player_defense)
		msg = "%s attacks for %d damage!" % [enemy.display_name, dmg]

	if player_defending:
		dmg = dmg / 2
		msg += " (defended)"
	player_defending = false

	player.hp = maxi(0, player.hp - dmg)
	action_resolved.emit(msg)
	hp_mp_changed.emit()

	if player.hp <= 0:
		_lose()
	else:
		state = State.PLAYER_INPUT
		turn_state_changed.emit("player_input")

func _win() -> void:
	state = State.WON
	turn_state_changed.emit("won")
	var xp := enemy.xp_reward
	var gold := enemy.gold_reward
	player.gold += gold
	var leveled_up := Leveling.grant_xp(player, xp)
	action_resolved.emit("Victory! %s defeated." % enemy.display_name)
	battle_won.emit(xp, gold, leveled_up)

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
