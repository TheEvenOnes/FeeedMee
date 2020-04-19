extends Node2D

var current_scene = null
var next_scene: String = ""

func _ready():
	# https://docs.godotengine.org/en/3.0/getting_started/step_by_step/singletons_autoload.html
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() -1)

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
