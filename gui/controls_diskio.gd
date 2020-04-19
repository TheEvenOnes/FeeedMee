extends Spatial

class_name ControlsDiskIO

const INPUT_ACTIONS = [ "move_up", "move_down", "move_left", "move_right", "move_jump", "player_action"]
const CONFIG_FILE = "user://input.cfg"

func reset_config(config: ConfigFile) -> void:
	config.set_value("input", "move_up", "[{\"kind\":\"key\",\"scancode\":\"W\"},{\"axis\":\"1\",\"dir\":\"-1\",\"kind\":\"joypad_motion\"}]")
	config.set_value("input", "move_down", "[{\"kind\":\"key\",\"scancode\":\"S\"},{\"axis\":\"1\",\"dir\":\"1\",\"kind\":\"joypad_motion\"}]")
	config.set_value("input", "move_left", "[{\"kind\":\"key\",\"scancode\":\"A\"},{\"axis\":\"0\",\"dir\":\"-1\",\"kind\":\"joypad_motion\"}]")
	config.set_value("input", "move_right", "[{\"kind\":\"key\",\"scancode\":\"D\"},{\"axis\":\"0\",\"dir\":\"1\",\"kind\":\"joypad_motion\"}]")
	config.set_value("input", "move_jump", "[{\"button\":\"0\",\"kind\":\"joypad_button\"},{\"kind\":\"key\",\"scancode\":\"Space\"}]")
	config.set_value("input", "player_action", "[{\"kind\":\"key\",\"scancode\":\"Enter\"},{\"button\":\"2\",\"kind\":\"joypad_button\"}]")

func save_config(config: ConfigFile) -> void:
	if !config:
		config = ConfigFile.new()
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

func load_config() -> ConfigFile:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE)
	if err: # Assuming that file is missing, generate default config
		print("generating default config file because loading failed: ", err)
		reset_config(config)
		err = null

	# ConfigFile was properly loaded or generated from reset; initialize InputMap
	if !err:
		process_config(config)

	return config

func process_config(config: ConfigFile) -> void:
	for action_name in config.get_section_keys("input"):
		InputMap.action_erase_events(action_name)
		var jsn: String = config.get_value("input", action_name)
		print("for action ", action_name, " loading ", jsn)
		for enc in parse_json(jsn):
			var act = dict_to_action(enc)
			InputMap.action_add_event(action_name, act)
