extends RefCounted
class_name DungeonProfile
## Computed (not authored) generation parameters for a Gate combination
## that isn't a known/special row. Purely data — GeneratedDungeon.gd
## decides how to actually build a map from these numbers. See
## ARCHITECTURE.md Section 7a.

var origin_word: String
var tone_word: String
var sign_word: String
var level: int = 1
var floor_source_id: int = 0
var branch_tier: int = 0 # 0..3 — also picks map size (see GeneratedDungeon)
var loot_table_id: String = ""

# Origin -> which world_tileset.tres floor source is this dungeon's theme.
const ORIGIN_FLOOR_SOURCE := {
	"Cinder": 2, "Verdant": 3, "Drowned": 4, "Hollow": 5,
}
# Tone -> how many levels above the baseline this dungeon's enemies are.
const TONE_LEVEL_OFFSET := {
	"Silent": 0, "Broken": 1, "Forgotten": 2, "Undying": 3,
}
# Sign -> how many side branches the generated layout has (0..3).
const SIGN_BRANCH_TIER := {
	"Ember": 0, "Gale": 1, "Tide": 2, "Umbra": 3,
}

static func compute(origin: String, tone: String, sign: String) -> DungeonProfile:
	var profile := DungeonProfile.new()
	profile.origin_word = origin
	profile.tone_word = tone
	profile.sign_word = sign
	profile.level = 1 + TONE_LEVEL_OFFSET.get(tone, 0)
	profile.floor_source_id = ORIGIN_FLOOR_SOURCE.get(origin, 0)
	profile.branch_tier = SIGN_BRANCH_TIER.get(sign, 0)
	profile.loot_table_id = _loot_table_for_level(profile.level)
	return profile

static func _loot_table_for_level(level: int) -> String:
	if level <= 2:
		return "generated_low_loot"
	elif level == 3:
		return "generated_mid_loot"
	else:
		return "generated_high_loot"
