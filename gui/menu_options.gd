extends VBoxContainer

onready var selected = $Selected

var selected_col: int = 0
var selected_row: int = 0

var main_menu: Control  # set by menu.tscn when switching to this scene

var items: Array
var current_rect: Rect2
var current_item: ActionChangerItem  # TODO: may be something else

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
	selected.set_point_position(0, rect.position)
	selected.set_point_position(1, rect.position + Vector2(0, rect.size.y))
	selected.set_point_position(2, rect.end)
	selected.set_point_position(3, rect.end - Vector2(0, rect.size.y))
	selected.set_point_position(4, rect.position)
	selected.set_point_position(5, rect.position + Vector2(0, rect.size.y)) # deals with the problem in the corner, closing the loop

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

	current_rect = grid_rect(selected_col, selected_row)
	update_selected(current_rect)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_parent().add_child(main_menu)
		get_parent().remove_child(get_node("."))
	if event.is_action_pressed("ui_up"):
		selected_row -= 1
	if event.is_action_pressed("ui_down"):
		selected_row += 1
	if event.is_action_pressed("ui_left"):
		selected_col -= 1
	if event.is_action_pressed("ui_right"):
		selected_col += 1

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

func _process(delta: float):
	# Find out the desired rect. Use move_toward to update both position and
	# end of the rect (its two opposing corners).
	var new_rect = grid_rect(selected_col, selected_row)
	current_rect.position = current_rect.position.move_toward(new_rect.position, delta * 500)
	current_rect.end = current_rect.end.move_toward(new_rect.end, delta * 500)

	update_selected(current_rect)
