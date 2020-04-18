extends Spatial

const INPUT_ACTIONS = [ "move_up", "move_down", "move_left", "move_right", "move_jump", "player_action"]
const CONFIG_FILE = "user://input.cfg"

func save_config() -> void:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE)
	if err:
		print("Error code when loading config file: ", err, " (continuing anyway)")

	for action_name in INPUT_ACTIONS:
		save_action_to_config(config, action_name)

	config.save(CONFIG_FILE)

func action_to_dict(act: InputEvent) -> Dictionary:
	var enc: Dictionary = {}
	if act is InputEventKey:
		var evt: InputEventKey = act
		enc["kind"] = "key"
		enc["scancode"] = OS.get_scancode_string(evt.scancode)
	elif act is InputEventJoypadMotion:
		var evt: InputEventJoypadMotion = act
		enc["kind"] = "joypad_motion"
		enc["axis"] = String(evt.axis)
		if evt.axis_value < 0:
			enc["dir"] = "-1"
		else:
			enc["dir"] = "1"
	elif act is InputEventJoypadButton:
		var evt: InputEventJoypadButton = act
		enc["kind"] = "joypad_button"
		enc["button"] = String(evt.button_index)
	return enc

func dict_to_action(enc: Dictionary) -> InputEvent:
	var act: InputEvent
	match enc["kind"]:
		"key":
			var scancode = OS.find_scancode_from_string(enc["scancode"])
			# Create a new event object based on the saved scancode
			var event = InputEventKey.new()
			event.scancode = scancode
			act = event
			print("providing key action ", scancode)
		"joypad_motion":
			var axis = int(enc["axis"])
			var dir = int(enc["dir"])
			var event = InputEventJoypadMotion.new()
			event.axis = axis
			event.axis_value = dir
			act = event
			print("providing joypad motion action ", axis, " ", dir)
		"joypad_button":
			var button = int(enc["button"])
			var event = InputEventJoypadButton.new()
			event.button_index = button
			act = event
			print("providing joypad button action ", button)
	return act

func save_action_to_config(config: ConfigFile, action_name: String) -> void:
	var enc: Array = []
	for act in InputMap.get_action_list(action_name):
		enc.append(action_to_dict(act))

	#save_to_config("input", action_name, to_json(enc))
	config.set_value("input", action_name, to_json(enc))

func _ready() -> void:
	load_config()

# Load/save code heavily inspired by "Input Mapping GUI demo"

# Load/save input mapping to a config file
# Changes done while testing the demo will be persistent, saved to CONFIG_FILE

func load_config():
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE)
	if err: # Assuming that file is missing, generate default config
		print("generating default config file because loading failed: ", err)
		save_config()
	else: # ConfigFile was properly loaded, initialize InputMap
		for action_name in config.get_section_keys("input"):
			
			InputMap.action_erase_events(action_name)
			var jsn: String = config.get_value("input", action_name)
			print("for action ", action_name, " loading ", jsn)
			for enc in parse_json(jsn):
				var act = dict_to_action(enc)
				InputMap.action_add_event(action_name, act)
			
#			# Get the key scancode corresponding to the saved human-readable string
#			var scancode = OS.find_scancode_from_string(config.get_value("input", action_name))
#			# Create a new event object based on the saved scancode
#			var event = InputEventKey.new()
#			event.scancode = scancode
#			# Replace old action (key) events by the new one
#			for old_event in InputMap.get_action_list(action_name):
#				if old_event is InputEventKey:
#					InputMap.action_erase_event(action_name, old_event)
#			InputMap.action_add_event(action_name, event)

#
#func save_to_config(section, key, value):
#	"""Helper function to redefine a parameter in the settings file"""
#	var config = ConfigFile.new()
#	var err = config.load(CONFIG_FILE)
#	if err:
#		print("Error code when loading config file: ", err)
#	else:
#		config.set_value(section, key, value)
#		config.save(CONFIG_FILE)

