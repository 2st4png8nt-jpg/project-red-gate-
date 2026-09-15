extends Resource
class_name GateClueData
## Player-facing hint text for one GameState.known_gate_clues entry.
## GameState only ever stores an opaque id string; the Gate UI looks up
## display text through this. See GAME_DESIGN.md Section 8 (discovery
## sources) and Section 26 ("important discoveries should be
## understandable in retrospect" — hints should read as clues, not as
## the answer spelled out).

@export var id: String = ""
@export_multiline var hint_text: String = ""
