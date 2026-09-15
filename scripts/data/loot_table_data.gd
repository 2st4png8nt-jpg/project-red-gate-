extends Resource
class_name LootTableData
## A weighted loot table. `item_ids` and `weights` are parallel arrays
## (kept flat rather than an array of a nested LootEntry resource, so a
## table is easy to hand-author as a single .tres — see AGENT_CONTRACTS.md).
## Referenced by EnemyData.loot_table_id.

@export var id: String = ""
@export var drop_chance: float = 1.0 # 0..1: probability anything drops at all
@export var item_ids: Array[String] = []
@export var weights: Array[int] = [] # parallel to item_ids
