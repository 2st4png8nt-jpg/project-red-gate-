extends Resource
class_name MapData
## Map metadata schema consumed by SceneManager/GateResolver. See
## AGENT_CONTRACTS.md.

@export var id: String = ""
@export var display_name: String = ""
@export var is_special: bool = false
@export var encounter_table_id: String = ""
@export var scene_path: String = ""
