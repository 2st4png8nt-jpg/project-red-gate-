extends Resource
class_name GateCombinationData
## One catalogued Gate combination row — "known" (a fixed, hand-crafted
## normal destination) or "special" (the Red Gate). Every other
## well-formed combination is resolved procedurally by GateResolver
## (Phase 5) instead of needing a row here — see ARCHITECTURE.md
## Section 7/7a and AGENT_CONTRACTS.md.

@export var origin: String = ""
@export var tone: String = ""
@export var sign: String = ""
@export_enum("known", "special") var result_type: String = "known"
@export var destination_map_id: String = ""
