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
@export var special_effect_id: String = ""
