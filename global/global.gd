extends Node2D

var current_scene = null
var next_scene: String = ""

var _next_level = 0

export (Array) var level_order = [
	'res://levels/level1/Level0.tscn',
	'res://levels/level1/Level1.tscn',
	'res://levels/level1/Level3.tscn'
]

func _ready():
	# https://docs.godotengine.org/en/3.0/getting_started/step_by_step/singletons_autoload.html
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() -1)

func next_level():
	if _next_level >= len(level_order):
		# victory, got to main menu
		_next_level = 0
		goto_loading_scene('res://gui/menu_root.tscn')
	else:
		goto_loading_scene(level_order[_next_level])
		_next_level += 1

func goto_menu():
	_next_level = 0
	goto_loading_scene('res://gui/menu_root.tscn')

func goto_scene(path):
	# https://docs.godotengine.org/en/3.0/getting_started/step_by_step/singletons_autoload.html
	# This function will usually be called from a signal callback,
	# or some other function from the running scene.
	# Deleting the current scene at this point might be
	# a bad idea, because it may be inside of a callback or function of it.
	# The worst case will be a crash or unexpected behavior.

	# The way around this is deferring the load to a later time, when
	# it is ensured that no code from the current scene is running:

	next_scene = ""
	call_deferred("_deferred_goto_scene", path)

func goto_loading_scene(next_path):
	# This allows switching through the loading scene securely.
	next_scene = next_path
	call_deferred("_deferred_goto_scene", "res://gui/loading.tscn")

func goto_win_scene(next_path):
	# This allows switching through the win scene securely.
	next_scene = next_path
	call_deferred("_deferred_goto_scene", "res://gui/win.tscn")

func goto_loss_scene():
	# This allows switching through the win scene securely.
	next_scene = "res://gui/menu_root.tscn"
	call_deferred("_deferred_goto_scene", "res://gui/loss.tscn")

func _deferred_goto_scene(path):
	# https://docs.godotengine.org/en/3.0/getting_started/step_by_step/singletons_autoload.html
	# Immediately free the current scene,
	# there is no risk here.
	current_scene.free()

	# Load new scene.
	var s = ResourceLoader.load(path)

	# Instance the new scene.
	current_scene = s.instance()

	print('-> adding new scene to tree and making it current')
	# Add it to the active scene, as child of root.
	get_tree().get_root().add_child(current_scene)

	print('-> setting scene')
	# Optional, to make it compatible with the SceneTree.change_scene() API.
	get_tree().set_current_scene(current_scene)

	if next_scene != "":
		# If we are going through the loading scene, let's tell it where to go
		# next.
		print('-> telling loading scene about next scene')
		current_scene.call_deferred('goto_scene', next_scene)
		print('-> done telling loading scene about next scene')

const Achievements: Dictionary = {
	'first_pig': {
		'sort_id': 0, # Unused; would be used in GUI for achievements
		'id': 'first_pig',
		'name': 'Deliverance!',
		'desc': 'Deliver the first piggy',
		'req': 1,
		'show_every': 1,
	},
	'first_cow': {
		'sort_id': 1, # Unused; would be used in GUI for achievements
		'id': 'first_cow',
		'name': 'Beefy stuff',
		'desc': 'Deliver the first cow',
		'req': 1,
		'show_every': 1,
	},
	'first_villager': {
		'sort_id': 2, # Unused; would be used in GUI for achievements
		'id': 'first_villager',
		'name': 'Human sacrifice',
		'desc': 'Provide a human sacrifice',
		'req': 1,
		'show_every': 1,
	},
	'first_joe': {
		'sort_id': 3, # Unused; would be used in GUI for achievements
		'id': 'first_joe',
		'name': 'Selflessness',
		'desc': 'Provide Joe as sustenance',
		'req': 1,
		'show_every': 1,
	},
	
	'pigs_10': {
		'sort_id': 4, # Unused; would be used in GUI for achievements
		'id': 'pigs_10',
		'name': "Porkin' around",
		'desc': 'Provide 10 piggies',
		'req': 10,
		'show_every': 2,
	},
	'cows_10': {
		'sort_id': 5, # Unused; would be used in GUI for achievements
		'id': 'cows_10',
		'name': 'No missteak',
		'desc': 'Deliver 10 cows',
		'req': 10,
		'show_every': 2,
	},
	'villagers_10': {
		'sort_id': 6, # Unused; would be used in GUI for achievements
		'id': 'villagers_10',
		'name': 'Collective sacrifice',
		'desc': '10x glory to the plant',
		'req': 10,
		'show_every': 2,
	},
	'joes_10': {
		'sort_id': 7, # Unused; would be used in GUI for achievements
		'id': 'joes_10',
		'name': 'Heroism',
		'desc': 'Joe is a treasure, 10x',
		'req': 10,
		'show_every': 2,
	},
}

func achieved(id: String) -> int:
	var ach: Dictionary = Achievements[id]
	var f: ConfigFile = ConfigFile.new()
	var err = f.load('user://achievements.cfg')
	if err != null:
		# Errors are actually meant to be acceptable.
		# Default values are set in get_value() calls.
		pass
	var complete_count: int = int(f.get_value('progress', id, '0'))
	return complete_count

func achieve(id: String, complete_count: int) -> void:
	var ach: Dictionary = Achievements[id]

	var f: ConfigFile = ConfigFile.new()
	var err = f.load('user://achievements.cfg')
	if err != null:
		# Errors are actually meant to be acceptable.
		# Default values are set in get_value() calls.
		pass

	var old_complete_count: int = int(f.get_value('progress', id, '0'))
	if old_complete_count == ach['req']:
		# Completed previously. There's no further chance of achieving this.
		return

	if complete_count < old_complete_count:
		# We can't go back.
		return

	# Update the saved value.
	f.set_value('progress', id, String(complete_count))

	# Is it complete yet?
	if complete_count == ach['req']:
		show_achievement(ach['name'], ach['desc'], complete_count, ach['req'])

	# When did we last show this?
	var last_shown_at_count: int = int(f.get_value('last_show_count', id, '-1'))
	if int(int(last_shown_at_count) / int(ach['show_every'])) != int((complete_count) / (ach['show_every'])):
		f.set_value('last_show_count', id, String(complete_count))
		show_achievement(ach['name'], ach['desc'], complete_count, ach['req'])
	f.save('user://achievements.cfg')

func show_achievement(text: String, desc: String, got: int, req: int):
	if current_scene.get_node('GUIOverlay') == null:
		print('no gui overlay, cannot show achievement')
		return
	var achievement_panel: AchievementPanel
	achievement_panel = load('res://gui/achievement_panel.tscn').instance()
	achievement_panel.text = text
	achievement_panel.desc = desc
	if got != req:
		achievement_panel.title = 'Progress: ' + String(got) + ' / ' + String(req)
	current_scene.get_node('GUIOverlay').add_child(achievement_panel)
