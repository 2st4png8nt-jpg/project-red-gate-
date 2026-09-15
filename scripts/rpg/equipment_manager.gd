extends RefCounted
class_name EquipmentManager
## Equip/unequip a PlayerData's gear slots. Callers (InventoryUI, the
## Phase 4 loot flow) are responsible for moving the returned
## previously-equipped item into/out of `player.inventory` — this
## utility only touches the equipped_* slots and clamps hp/mp so a
## max_hp/max_mp swing never leaves current hp/mp above the new max.
##
## Callers are also responsible for checking can_equip() first: equip()
## trusts it was already checked and performs the swap unconditionally
## (same "utility does the mechanical part, caller owns the decision +
## any resulting inventory bookkeeping" split as the rest of this file).
## It does NOT return null to mean "rejected" — that would be
## indistinguishable from "nothing was equipped in that slot before,"
## and a caller that skipped the check would then wrongly treat a
## rejected equip as a successful one with no previous item to restore.

static func can_equip(player: PlayerData, item: EquipmentData) -> bool:
	return player.level >= item.level_requirement

static func equip(player: PlayerData, item: EquipmentData) -> EquipmentData:
	var previous: EquipmentData = null
	match item.slot:
		"weapon":
			previous = player.equipped_weapon
			player.equipped_weapon = item
		"armor":
			previous = player.equipped_armor
			player.equipped_armor = item
		"accessory":
			previous = player.equipped_accessory
			player.equipped_accessory = item
		_:
			push_warning("EquipmentManager: unknown slot '%s' on item '%s'" % [item.slot, item.id])
			return null
	_clamp_hp_mp(player)
	return previous

static func unequip(player: PlayerData, slot: String) -> EquipmentData:
	var previous: EquipmentData = null
	match slot:
		"weapon":
			previous = player.equipped_weapon
			player.equipped_weapon = null
		"armor":
			previous = player.equipped_armor
			player.equipped_armor = null
		"accessory":
			previous = player.equipped_accessory
			player.equipped_accessory = null
	_clamp_hp_mp(player)
	return previous

static func _clamp_hp_mp(player: PlayerData) -> void:
	player.hp = mini(player.hp, StatsCalculator.effective_max_hp(player))
	player.mp = mini(player.mp, StatsCalculator.effective_max_mp(player))
