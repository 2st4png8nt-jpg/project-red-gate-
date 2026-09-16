extends Node
## Sfx — Autoload. Combat feedback sound (Phase 6 polish pass). Every
## clip is synthesized once at startup via ToneSynth rather than loaded
## from an audio file — see ARCHITECTURE.md Section 9. Call Sfx.play("name").

const CLIPS := {
	"hit": [[440.0, 0.05], [220.0, 0.06]],
	"victory": [[523.25, 0.12], [659.25, 0.12], [783.99, 0.22]],
	"defeat": [[392.0, 0.18], [329.63, 0.18], [261.63, 0.3]],
	"flee": [[330.0, 0.06], [494.0, 0.1]],
}
const PLAYER_POOL_SIZE := 4

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0

func _ready() -> void:
	for clip_name in CLIPS:
		_streams[clip_name] = ToneSynth.build(CLIPS[clip_name])
	for i in range(PLAYER_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

## Fire-and-forget; safe to call rapidly (round-robins a small player
## pool so overlapping calls, e.g. two hits in one turn, don't cut each
## other off).
func play(clip_name: String) -> void:
	if not _streams.has(clip_name):
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = _streams[clip_name]
	p.play()
