extends Resource
class_name ItemData
## Base schema for any inventory item. See AGENT_CONTRACTS.md.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_enum("common", "uncommon", "rare", "unique") var rarity: String = "common"
@export var level_requirement: int = 0
@export var value: int = 0
@export var source: String = ""
