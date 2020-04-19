extends AudioStreamPlayer

export (float) var FREQUENCY = 1.0

var timer = 0.0

func _process(delta: float) -> void:
	if playing:
		timer += delta
		if timer > 1.0 / max(FREQUENCY, 0.1):
			timer = 0.0
			play(0.0)
