extends Area2D
## Like EncounterTrigger, but builds its EncounterData in memory instead
## of loading one from data/encounters/ — used by generated dungeons,
## where the enemy pool/level/loot table depend on the Gate words that
## produced this dungeon, not a pre-authored row (there could be up to
## dozens of word combinations; authoring a row per combination doesn't
## scale). See ARCHITECTURE.md Section 7a.

@export var enemy_ids: Array[String] = []
@export var level: int = 1
@export var can_flee: bool = true
@export var loot_table_id_override: String = ""

var _triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered or enemy_ids.is_empty() or not body.is_in_group("player"):
		return
	_triggered = true
	var encounter := EncounterData.new()
	encounter.id = "generated"
	encounter.enemy_id = enemy_ids[randi() % enemy_ids.size()]
	encounter.can_flee = can_flee
	encounter.level = level
	encounter.loot_table_id_override = loot_table_id_override
	SceneManager.go_to_generated_battle(encounter)
