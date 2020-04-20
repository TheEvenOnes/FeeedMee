extends Spatial

onready var GUIOverlay: Control = $GUIOverlay

# ideally this should be a dict or an array, but eh, its a game jam game
export (Dictionary) var scores = {}

func _ready() -> void:
	if not scores.has('pig') or scores.has('pig') and scores['pig'] == -1:
		var control = $GUIOverlay/Scores/PigCounter
		control.get_parent().remove_child(control)
	if not scores.has('cow') or scores.has('cow') and scores['cow'] == -1:
		var control = $GUIOverlay/Scores/CowCounter
		control.get_parent().remove_child(control)
	if not scores.has('redneck') or scores.has('redneck') and scores['redneck'] == -1:
		var control = $GUIOverlay/Scores/RedneckCounter
		control.get_parent().remove_child(control)
	if not scores.has('joe') or scores.has('joe') and scores['joe'] == -1:
		var control = $GUIOverlay/Scores/JoeCounter
		control.get_parent().remove_child(control)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed('ui_cancel'):
		get_node('/root/Global').goto_scene('res://gui/menu_root.tscn')

func is_valid_key(key: String):
	return key == 'joe' || key == 'cow' || key == 'pig' || key == 'redneck'

func reduce_score(key: String):
	if scores.has(key):
		scores[key] = max(scores[key] - 1, 0)

func _process(_delta: float) -> void:
	var total = 0
	for key in scores:
		if is_valid_key(key):
			total += scores[key]

	# check for victory conditions
	if total == 0:
		# TODO: load victory scene
		# victory, move to next level
		print('win')
		Global.next_level()
		pass

	# check for loose conditions
	if scores['joe'] == 0 and total > 0:
		# TODO: load the loose animation
		# and go to main menu
		print('loose')
		Global.goto_menu()
		pass
