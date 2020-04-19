extends Spatial

onready var GUIOverlay: Control = $GUIOverlay

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed('ui_cancel'):
		get_node('/root/Global').goto_scene('res://gui/menu_root.tscn')

	if Input.is_action_just_pressed('ui_page_down'): # REMOVE ME, sample
		var global = get_node('/root/Global')

		var current: int = global.achieved('first_piggy')
		current += 1
		global.achieve('first_piggy', current)
