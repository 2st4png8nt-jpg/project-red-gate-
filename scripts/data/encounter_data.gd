extends Resource
class_name EncounterData
## A single-enemy battle definition. Multi-enemy encounters are a
## future extension (would grow `enemy_id` into an array) — not needed
## for the prototype. See AGENT_CONTRACTS.md.

@export var id: String = ""
@export var enemy_id: String = ""
@export var can_flee: bool = true
