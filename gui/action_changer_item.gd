extends HBoxContainer

class_name ActionChangerItem

export (String) var action_name = "move_up"
export (String) var display_name = "Move up"

onready var display_name_label = $DisplayName
onready var action_1_label = $Action1
onready var action_2_label = $Action2

func binding_description(act: InputEvent) -> String:
	if act is InputEventJoypadButton:
		var actJB: InputEventJoypadButton = act
		return "joypad btn " + String(actJB.button_index)
	if act is InputEventJoypadMotion:
		var actJM: InputEventJoypadMotion = act
		return "joypad axis " + String(actJM.axis)
	if act is InputEventKey:
		return act.as_text()
	return "unsupported"

func _ready():
	display_name_label.text = display_name
	action_1_label.text = "-"
	action_2_label.text = "-"
	if len(InputMap.get_action_list(action_name)) > 0:
		var act = InputMap.get_action_list(action_name)[0]
		action_1_label.text = "[" + binding_description(act) + "]"
	if len(InputMap.get_action_list(action_name)) > 1:
		var act = InputMap.get_action_list(action_name)[1]
		action_2_label.text = "[" + binding_description(act) + "]"

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
