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
	if Input.is_action_just_pressed('ui_down'):
		target = (target + 1) % len(all_options)
	if Input.is_action_just_pressed('ui_up'):
		target = (target - 1) % len(all_options)
	if Input.is_action_just_pressed('ui_accept'):
		match target:
			Item.OPTIONS:
				get_node(".").replace_by(MENU_OPTIONS.instance())

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
