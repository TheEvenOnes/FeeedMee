extends Spatial

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed('ui_cancel'):
		get_node('/root/Global').goto_scene('res://gui/menu_root.tscn')
