extends HBoxContainer

class_name GenericItemRow, "res://icon.png"

func get_column_count() -> int:
	return 1

func get_column(idx: int) -> Control:
	match idx:
		0:
			var r: Control
			r = get_child(0)
			return r
	return null

func activate() -> void:
	print("<activate unimplemented>")
