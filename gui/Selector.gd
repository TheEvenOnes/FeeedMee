extends Control

export (float) var SCALE_X = 1.0
export (float) var SCALE_Y = 1.0

onready var selected = $Selected

onready var start = $Start
onready var options = $Options
onready var exit = $Exit

onready var all_options = [start, options, exit]

enum Item {
	START = 0,
	OPTIONS = 1,
	EXIT = 2
}

var current = 0
var target = 0

onready var l = get_current().margin_left
onready var t = get_current().margin_top
onready var r = get_current().margin_right
onready var b = get_current().margin_bottom

const MENU_OPTIONS = preload("res://gui/menu_options.tscn")

func _ready() -> void:
	selected.clear_points()
	selected.add_point(Vector2(l - SCALE_X, b + SCALE_Y))
	selected.add_point(Vector2(l - SCALE_X, t - SCALE_Y))
	selected.add_point(Vector2(r + SCALE_X, t - SCALE_Y))
	selected.add_point(Vector2(r + SCALE_X, b + SCALE_Y))
	selected.add_point(Vector2(l - SCALE_X, b + SCALE_Y))
	selected.add_point(Vector2(l - SCALE_X, t + SCALE_Y))

func _input(event: InputEvent) -> void:
	if target < 0:
		target += len(all_options)
	if event.is_action_pressed('ui_down') or event.is_action_pressed('ui_focus_next'):
		target = (target + 1) % len(all_options)
	if event.is_action_pressed('ui_up') or event.is_action_pressed('ui_focus_prev'):
		target = (target - 1) % len(all_options)
	if event.is_action_pressed('ui_accept') or event.is_action_pressed('ui_select'):
		# replace_by does the wrong thing, seemingly.
		#
		# Instead, we create the replacement scene, teach it what to replace
		# itself with when the scene is closed (i.e. "us"), add it, and remove
		# ourselves.
		match target:
			Item.START:
				Global.next_level()
				return
			Item.OPTIONS:
				# TODO: should this be instantiated only once and reused?
				var inst := MENU_OPTIONS.instance()
				inst.main_menu = get_node(".")
				get_parent().add_child(inst)
				get_parent().remove_child(get_node("."))
				return
			Item.EXIT:
				get_tree().quit(0)

func _exit_tree() -> void:
	print('main menu selector: exiting tree')

func _process(delta: float) -> void:
	l = lerp(l, get_target().margin_left, 0.2)
	t = lerp(t, get_target().margin_top, 0.2)
	r = lerp(r, get_target().margin_right, 0.2)
	b = lerp(b, get_target().margin_bottom, 0.2)

	selected.set_point_position(0, Vector2(l - SCALE_X, b + SCALE_Y))
	selected.set_point_position(1, Vector2(l - SCALE_X, t - SCALE_Y))
	selected.set_point_position(2, Vector2(r + SCALE_X, t - SCALE_Y))
	selected.set_point_position(3, Vector2(r + SCALE_X, b + SCALE_Y))
	selected.set_point_position(4, Vector2(l - SCALE_X, b + SCALE_Y))
	selected.set_point_position(5, Vector2(l - SCALE_X, t - SCALE_Y))

	if (
		abs(l - get_target().margin_left) < 0.001 and
		abs(r - get_target().margin_right) < 0.001 and
		abs(t - get_target().margin_top) < 0.001 and
		abs(b - get_target().margin_bottom) < 0.001
	):
		current = target

func get_current():
	return all_options[current]

func get_target():
	return all_options[target]
