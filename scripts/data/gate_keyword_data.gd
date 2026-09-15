extends Resource
class_name GateKeywordData
## One Gate keyword and its category. See GAME_DESIGN.md Section 6.

@export var word: String = ""
@export_enum("origin", "tone", "sign") var category: String = "origin"
