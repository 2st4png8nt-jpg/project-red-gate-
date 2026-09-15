extends RefCounted
class_name EnemyScaler
## Scales an EnemyData's stats for a given encounter level, without
## mutating the shared cached EnemyData resource itself (DataLoader
## caches one instance per path, reused across every battle — mutating
## it in place would corrupt every other fight using that enemy).
## Speed is deliberately left unscaled; see ARCHITECTURE.md Section 7a.

static func scale_factor(level: int) -> float:
	return 1.0 + 0.35 * float(maxi(level, 1) - 1)

static func max_hp(enemy: EnemyData, level: int) -> int:
	return maxi(1, roundi(enemy.max_hp * scale_factor(level)))

static func attack(enemy: EnemyData, level: int) -> int:
	return maxi(1, roundi(enemy.attack * scale_factor(level)))

static func defense(enemy: EnemyData, level: int) -> int:
	return maxi(0, roundi(enemy.defense * scale_factor(level)))

static func magic_power(enemy: EnemyData, level: int) -> int:
	return maxi(0, roundi(enemy.magic_power * scale_factor(level)))

static func xp_reward(enemy: EnemyData, level: int) -> int:
	return maxi(1, roundi(enemy.xp_reward * scale_factor(level)))

static func gold_reward(enemy: EnemyData, level: int) -> int:
	return maxi(1, roundi(enemy.gold_reward * scale_factor(level)))
