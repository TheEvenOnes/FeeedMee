extends Control

# https://docs.godotengine.org/en/3.0/tutorials/io/background_loading.html

var loader
var wait_frames
var time_max = 100 # msec
var current_scene

onready var progressbar: ProgressBar = $Panel/ProgressBar

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() -1)
	print("ya ready")

func goto_scene(path): # game requests to switch to this scene
	print("loading.goto_scene(", path, ")")
	loader = ResourceLoader.load_interactive(path)
	if loader == null: # check for errors
		#show_error()
		print("there was an error loading...")
		return
	set_process(true)
	print("loading.goto_scene: set_process(true)")

	# FIXME: this is not necessary in our setup with async switch to loading
	# scene and then having loading scene go onwards.
	# Where would this be required? Presumably if main menu had its own loading?
	#current_scene.queue_free() # get rid of the old scene

	# start your "loading..." animation
	#get_node("animation").play("loading")

	wait_frames = 1


func _enter_tree() -> void:
	print('tree is entered')
func _exit_tree() -> void:
	print('tree is exited')

func _process(time):
	print("-")
	if loader == null:
		# no need to process anymore
		if wait_frames == 0: # wait for a few frames before removing overlay
			set_process(false)
			current_scene.queue_free()
		else:
			wait_frames -= 1
		return

	print("test waitframe")
	if wait_frames > 0: # wait for frames to let the "loading" animation to show up
		wait_frames -= 1
		return

	var t = OS.get_ticks_msec()
	while OS.get_ticks_msec() < t + time_max: # use "time_max" to control how much time we block this thread

		# poll your loader
		var err = loader.poll()

		if err == ERR_FILE_EOF: # load finished
			var resource = loader.get_resource()
			loader = null
			print('load finished')
			set_new_scene(resource)
			break
		elif err == OK:
			update_progress()
		else: # error during loading
			#show_error()
			print("there was an error loading")
			loader = null
			break

func update_progress():
	#var progress = float(loader.get_stage()) / loader.get_stage_count()
	# update your progress bar?
	#progressbar.set_progress(progress)
	progressbar.set_max(loader.get_stage_count()-1)
	progressbar.set_value(loader.get_stage())


	# or update a progress animation?
	#var len = get_node("animation").get_current_animation_length()

	# call this on a paused animation. use "true" as the second parameter to force the animation to update
	#get_node("animation").seek(progress * len, true)

func set_new_scene(scene_resource):
	wait_frames = 1
	call_deferred('set_new_scene_deferred', scene_resource)
	
func set_new_scene_deferred(scene_resource):
	print('setting new scene')
	var new_scene = scene_resource.instance()
	get_node("/root").add_child(new_scene)
	$'/root/Global'.current_scene = new_scene
