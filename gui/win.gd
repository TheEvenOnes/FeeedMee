extends Spatial

var timeout: float = 4.0
var next_scene: String

func _process(delta: float) -> void:
	timeout -= delta
	if timeout <= 0.0:
		Global.goto_loading_scene(next_scene)

func goto_scene(next_path):
	next_scene = next_path
