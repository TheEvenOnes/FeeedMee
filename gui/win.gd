extends Spatial

var timeout: float = 4.0
var next_scene: String

func _process(delta: float) -> void:
	timeout -= delta
	if timeout:
		Global.goto_loading_scene(next_scene)

func goto_scene(next_path):
	next_scene = next_path
