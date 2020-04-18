extends Spatial

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed('ui_cancel'):
		get_tree().change_scene_to(load('res://gui/menu_root.tscn'))
