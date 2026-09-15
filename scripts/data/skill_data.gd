extends Resource
class_name SkillData
## Player/enemy skill schema. See AGENT_CONTRACTS.md.

@export var id: String = ""
@export var display_name: String = ""
@export var mp_cost: int = 0
@export var power: int = 0
@export_enum("single_enemy", "self", "all_enemies") var target_type: String = "single_enemy"
@export var element: String = "physical"
