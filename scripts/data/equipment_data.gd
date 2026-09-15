extends ItemData
class_name EquipmentData
## Equipment schema. Combat/RPG systems read stat bonuses and the
## special_effect_id by id; this Resource holds no logic itself.

@export_enum("weapon", "armor", "accessory") var slot: String = "weapon"
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var magic_power_bonus: int = 0
@export var speed_bonus: int = 0
@export var max_hp_bonus: int = 0
@export var max_mp_bonus: int = 0
@export var special_effect_id: String = "" # reserved for future one-off/scripted effects
# Structured effects used by BattleManager directly (Phase 5) — common
# enough mechanics (Cindermourn's identity, GAME_DESIGN.md Section 10)
# to deserve real fields rather than a parsed special_effect_id string.
@export var bonus_damage_vs_family: String = "" # matches EnemyData.family; empty = no bonus
@export var bonus_damage_percent: float = 0.0 # e.g. 0.15 = +15% damage vs. that family
@export var mp_restore_on_kill: int = 0
# A weapon's "moveset" — an extra SkillData id only available in the
# Skill submenu while this piece is equipped, on top of the 3 universal
# skills every player always has. Empty = grants nothing (armor and
# accessories are never expected to set this, though the field isn't
# restricted to weapon-slot items).
@export var granted_skill_id: String = ""
