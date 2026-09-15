extends RefCounted
class_name StatsCalculator
## Computes a player's effective (base + equipment) stats. PlayerData
## stores only base stats (set by leveling); equipment bonuses are
## applied here rather than by mutating PlayerData on equip/unequip —
## that would need perfectly symmetric add-on-equip/subtract-on-unequip
## bookkeeping, which is exactly the kind of thing that quietly drifts
## out of sync. Combat and UI should read stats through this, not
## PlayerData's raw fields, whenever equipment could matter.

static func effective_max_hp(player: PlayerData) -> int:
	var total := player.max_hp
	for piece in _equipped_pieces(player):
		total += piece.max_hp_bonus
	return total

static func effective_max_mp(player: PlayerData) -> int:
	var total := player.max_mp
	for piece in _equipped_pieces(player):
		total += piece.max_mp_bonus
	return total

static func effective_attack(player: PlayerData) -> int:
	var total := player.attack
	for piece in _equipped_pieces(player):
		total += piece.attack_bonus
	return total

static func effective_defense(player: PlayerData) -> int:
	var total := player.defense
	for piece in _equipped_pieces(player):
		total += piece.defense_bonus
	return total

static func effective_magic_power(player: PlayerData) -> int:
	var total := player.magic_power
	for piece in _equipped_pieces(player):
		total += piece.magic_power_bonus
	return total

static func effective_speed(player: PlayerData) -> int:
	var total := player.speed
	for piece in _equipped_pieces(player):
		total += piece.speed_bonus
	return total

static func _equipped_pieces(player: PlayerData) -> Array[EquipmentData]:
	var pieces: Array[EquipmentData] = []
	if player.equipped_weapon != null:
		pieces.append(player.equipped_weapon)
	if player.equipped_armor != null:
		pieces.append(player.equipped_armor)
	if player.equipped_accessory != null:
		pieces.append(player.equipped_accessory)
	return pieces
