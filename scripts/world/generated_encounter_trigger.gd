extends Area2D
## Like EncounterTrigger, but builds its EncounterData in memory instead
## of loading one from data/encounters/ — used by generated dungeons,
## where the enemy pool/level/loot table depend on the Gate words that
## produced this dungeon, not a pre-authored row (there could be up to
## dozens of word combinations; authoring a row per combination doesn't
## scale). See ARCHITECTURE.md Section 7a.
##
## Depth pass (post-Phase-6): each trigger now spawns a *pack* —
## pack_size_min..pack_size_max enemies (with repetition) drawn from
## enemy_pool — instead of always exactly one.

@export var enemy_pool: Array[String] = []
@export var level: int = 1
@export var can_flee: bool = true
@export var loot_table_id_override: String = ""
@export var pack_size_min: int = 2
@export var pack_size_max: int = 3

var _triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered or enemy_pool.is_empty() or not body.is_in_group("player"):
		return
	_triggered = true
	var encounter := EncounterData.new()
	encounter.id = "generated"
	var pack_size := randi_range(pack_size_min, pack_size_max)
	var chosen: Array[String] = []
	for i in range(pack_size):
		chosen.append(enemy_pool[randi() % enemy_pool.size()])
	encounter.enemy_ids = chosen
	encounter.can_flee = can_flee
	encounter.level = level
	encounter.loot_table_id_override = loot_table_id_override
	SceneManager.go_to_generated_battle(encounter)
