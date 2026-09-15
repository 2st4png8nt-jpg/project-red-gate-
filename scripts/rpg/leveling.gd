extends RefCounted
class_name Leveling
## Minimal placeholder XP/level curve so the "win battle -> become
## stronger" loop is provable in Phase 2. Full progression balancing
## (equipment-driven power growth, stat tuning) is Phase 3/4 work — see
## AGENT_CONTRACTS.md and GAME_DESIGN.md Section 27 (balance principle:
## design -> implement -> play -> measure -> adjust, not spreadsheets
## up front).

static func xp_to_next_level(level: int) -> int:
	return level * 20

## Applies XP to player, looping through as many level-ups as the XP
## covers. Returns true if at least one level-up happened.
static func grant_xp(player: PlayerData, amount: int) -> bool:
	player.xp += amount
	var leveled_up := false
	while player.xp >= xp_to_next_level(player.level):
		player.xp -= xp_to_next_level(player.level)
		player.level += 1
		player.max_hp += 5
		player.max_mp += 2
		player.attack += 2
		player.defense += 1
		player.magic_power += 1
		player.speed += 1
		player.hp = player.max_hp
		player.mp = player.max_mp
		leveled_up = true
	return leveled_up
