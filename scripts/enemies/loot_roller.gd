extends RefCounted
class_name LootRoller
## Rolls a LootTableData: first a drop_chance check, then a
## weight-proportional pick among item_ids. Returns "" if nothing
## dropped (either the table is empty, the drop_chance roll failed, or
## all weights are zero).

static func roll(table: LootTableData) -> String:
	if table == null or table.item_ids.is_empty():
		return ""
	if randf() > table.drop_chance:
		return ""

	var total_weight := 0
	for w in table.weights:
		total_weight += w
	if total_weight <= 0:
		return ""

	var pick := randi_range(1, total_weight)
	var cumulative := 0
	for i in table.item_ids.size():
		cumulative += table.weights[i]
		if pick <= cumulative:
			return table.item_ids[i]
	return ""
