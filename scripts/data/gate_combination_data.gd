extends Resource
class_name GateCombinationData
## One catalogued Gate combination row. Combinations not present in the
## table resolve to "unknown" at runtime; malformed input resolves to
## "invalid". Neither of those two is ever stored as a row. See
## ARCHITECTURE.md Section 7 and AGENT_CONTRACTS.md.

@export var origin: String = ""
@export var tone: String = ""
@export var sign: String = ""
@export_enum("known", "special", "locked") var result_type: String = "known"
@export var destination_map_id: String = ""
