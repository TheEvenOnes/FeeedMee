extends VBoxContainer

onready var selected = $Selected
onready var selected_ani = $Selected/AnimationPlayer
onready var instruction = $Instruction

export (Vector2) var extra_margin := Vector2.ZERO

var selected_col: int = 0
var selected_row: int = 0

var main_menu: Control  # set by menu.tscn when switching to this scene

var items: Array
var current_rect: Rect2
var current_item: ActionChangerItem  # TODO: may be something else

enum SelectionState {
	SELECTING,
	REBINDING,
}

var selection_state

# Returns the rectangle for the selectable object at coordinates (col, row).
#
# 'row' refers to a particular item out of array 'items'; 'col' refers to
# selectable columns inside that row.
func grid_rect(col: int, row: int) -> Rect2:
	var item: ActionChangerItem = items[row]
	var cntrl: Control = item.get_column(col)
	return Rect2(
		cntrl.get_global_rect().position - cntrl.get_parent().get_parent().get_global_rect().position,
		cntrl.get_global_rect().size)

# Updates drawable Line2D 'selected', which shows to the user which item has
# been selected.
func update_selected(rect: Rect2) -> void:
	var l = rect.position.x - extra_margin.x
	var r = rect.end.x + extra_margin.x
	var t = rect.end.y + extra_margin.y
	var b = rect.position.y - extra_margin.y
	
	selected.set_point_position(0, Vector2(l, t))
	selected.set_point_position(1, Vector2(r, t))
	selected.set_point_position(2, Vector2(r, b))
	selected.set_point_position(3, Vector2(l, b))
	selected.set_point_position(4, Vector2(l, t))
	selected.set_point_position(5, Vector2(r, t)) # deals with the problem in the corner, closing the loop

func _ready() -> void:
	for child in get_children():
		if child is ActionChangerItem:
			items.append(child)

	selected.clear_points()
	selected.add_point(Vector2.ZERO)
	selected.add_point(Vector2.ZERO)
	selected.add_point(Vector2.ZERO)
	selected.add_point(Vector2.ZERO)
	selected.add_point(Vector2.ZERO)
	selected.add_point(Vector2.ZERO)

	selected_ani.current_animation = "sz"
	selection_state = SelectionState.SELECTING

func _input(event: InputEvent) -> void:
	if selection_state == SelectionState.REBINDING:
		if event.is_action_pressed("ui_cancel"):
			selection_state = SelectionState.SELECTING
			return

	if event.is_action_pressed("ui_cancel"):
		get_parent().add_child(main_menu)
		get_parent().remove_child(get_node("."))

	#################
	# handle arrows
	if event.is_action_pressed("ui_up"):
		selected_row -= 1
	if event.is_action_pressed("ui_down"):
		selected_row += 1
	if event.is_action_pressed("ui_left"):
		selected_col -= 1
	if event.is_action_pressed("ui_right"):
		selected_col += 1

	# clear values based on arrows
	if selected_row < 0:
		selected_row += len(items)
	selected_row %= len(items)
	current_item = items[selected_row]

	if current_item:
		if current_item.get_column_count() < 1:
			# Let's not have modulo operator complain about zeroes.
			selected_col = 0
		else:
			if selected_col < 0:
				selected_col += current_item.get_column_count() 
			selected_col %= current_item.get_column_count()

	#################
	# handle ui_focus_{next,prev}
	#
	# these will nudge selection values into valid ranges themselves
	if event.is_action_pressed("ui_focus_next"):
		selected_col += 1
		if selected_col >= items[selected_row].get_column_count():
			selected_col = 0
			selected_row += 1
			selected_row %= len(items)
	if event.is_action_pressed("ui_focus_prev"):
		selected_col -= 1
		if selected_col < 0:
			selected_row -= 1
			if selected_row < 0:
				selected_row = len(items)-1
			selected_col = items[selected_row].get_column_count()-1


	##################
	# handle accept/select
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		selection_state = SelectionState.REBINDING

	match selection_state:
		SelectionState.SELECTING:
			selected_ani.current_animation = "sz"
			instruction.text = "choose options to rebind, or esc to exit"
		SelectionState.REBINDING:
			selected_ani.current_animation = "active"
			instruction.text = "press key to rebind, backspace to clear, esc to cancel"

func _process(delta: float):
	# Find out the desired rect. Use move_toward to update both position and
	# end of the rect (its two opposing corners).
	var new_rect = grid_rect(selected_col, selected_row)
	if current_rect.get_area() < 0.001:
		current_rect = new_rect
	else:
		current_rect.position = current_rect.position.move_toward(new_rect.position, delta * 200)
		current_rect.end = current_rect.end.move_toward(new_rect.end, delta * 200)

	update_selected(current_rect)
