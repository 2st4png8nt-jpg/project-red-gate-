extends RefCounted
class_name ToneSynth
## Tiny procedural-audio helper (Phase 6 polish pass). Synthesizes short
## sine-wave jingles as an in-memory AudioStreamWAV so combat SFX exist
## without needing any external audio asset — this sandbox has no way
## to source or license real sound files. See ARCHITECTURE.md Section 9.
## Swapping in real audio later just means replacing a build() call
## with a preloaded AudioStream resource; nothing else changes.

const MIX_RATE := 22050

## notes: Array of [frequency_hz: float, duration_sec: float] pairs,
## played back to back. A frequency of 0 is a silent rest.
static func build(notes: Array) -> AudioStreamWAV:
	var samples := PackedByteArray()
	for note in notes:
		var freq: float = note[0]
		var duration: float = note[1]
		var sample_count := int(MIX_RATE * duration)
		for i in range(sample_count):
			var t := float(i) / MIX_RATE
			var envelope := 1.0 - float(i) / float(sample_count) # linear fade-out avoids a click at the note's end
			var value := 0.0
			if freq > 0.0:
				value = sin(TAU * freq * t) * envelope
			var sample := int(clampf(value, -1.0, 1.0) * 32767.0)
			samples.append(sample & 0xFF)
			samples.append((sample >> 8) & 0xFF)
	var stream := AudioStreamWAV.new()
	stream.data = samples
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	return stream
