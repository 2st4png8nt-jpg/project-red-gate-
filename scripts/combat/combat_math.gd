extends RefCounted
class_name CombatMath
## Shared damage-formula logic for BattleManager. See ARCHITECTURE.md
## Section 6c.
##
## Damage uses a diminishing-returns mitigation curve instead of flat
## `power - defense` subtraction: flat subtraction has an ugly cliff
## (once defense >= power, every hit floors to 1, so stacking defense
## past that point is worthless, and below it defense does nothing
## until it crosses the threshold). A percentage-based curve makes
## every point of defense worth something, without ever fully
## negating an attack.

const MITIGATION_K := 40.0 # defense == K gives 50% mitigation

static func mitigate(raw_power: int, defense: int) -> int:
	var mitigation := float(defense) / (float(defense) + MITIGATION_K)
	return maxi(1, roundi(raw_power * (1.0 - mitigation)))

## A skill's element decides which stat powers it: physical skills
## scale off Attack, everything else (ember, etc.) off Magic Power.
## Without this, a skill flagged element="physical" (Guard Break,
## Thorn Whip) was silently scaling off Magic Power like every other
## skill, which made the element field decorative.
static func skill_power_stat(skill: SkillData, attack_stat: int, magic_power_stat: int) -> int:
	if skill.element == "physical":
		return attack_stat
	return magic_power_stat
