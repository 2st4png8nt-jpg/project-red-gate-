extends RefCounted
class_name GateResolver
## Resolves a 3-word Gate combination. Data-driven per CLAUDE.md Section
## 20 — the Red Gate's exact words and the catalogued "known" rows come
## from data/gates/, not hardcoded branches; only the priority order
## (special > known > generated > invalid) is code. See
## ARCHITECTURE.md Section 7.

enum ResultType { KNOWN, SPECIAL, GENERATED, INVALID }

static func resolve(origin: String, tone: String, sign: String) -> Dictionary:
	if not _is_valid_word(origin, "origin") or not _is_valid_word(tone, "tone") or not _is_valid_word(sign, "sign"):
		return {"type": ResultType.INVALID}

	var rows := DataLoader.load_all_in_dir("res://data/gates/combinations")
	for row in rows:
		var combo: GateCombinationData = row
		if combo.origin == origin and combo.tone == tone and combo.sign == sign:
			if combo.result_type == "special":
				return {"type": ResultType.SPECIAL, "destination_map_id": combo.destination_map_id}
			elif combo.result_type == "known":
				return {"type": ResultType.KNOWN, "destination_map_id": combo.destination_map_id}

	# Every other well-formed combination generates a dungeon — see
	# DungeonProfile and ARCHITECTURE.md Section 7a.
	var profile := DungeonProfile.compute(origin, tone, sign)
	return {"type": ResultType.GENERATED, "dungeon_profile": profile}

static func _is_valid_word(word: String, category: String) -> bool:
	var keywords := DataLoader.load_all_in_dir("res://data/gates/keywords")
	for row in keywords:
		var kw: GateKeywordData = row
		if kw.word == word and kw.category == category:
			return true
	return false
