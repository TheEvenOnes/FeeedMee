extends Control

class_name AchievementPanel

var progress: float
var title: String
var text: String
var desc: String

func _enter_tree() -> void:
	update_position()
	if title != '':
		$PopupPanel/Title.text = title
	if text != '':
		$PopupPanel/Name.text = text
		$PopupPanel/Desc.text = desc

func _exit_tree() -> void:
	queue_free()

func _process(delta: float) -> void:
	if progress < 0:
		return
	if progress >= 1:
		get_parent().remove_child(get_node('.'))
		return
	progress += delta * 0.25
	update_position()

func update_position() -> void:
	var progress_off_y: float
	var edge: float = 0.05
	if progress < edge:
		progress_off_y = get_rect().size.y * progress / edge
	elif progress > 1.0-edge:
		progress_off_y = clamp(get_rect().size.y * ((1.0-progress) / edge), 0.0, get_rect().size.y)
	else:
		progress_off_y = get_rect().size.y

	get_node(".").set_position(
		Vector2(
			get_parent().get_rect().size.x / 2 - get_rect().size.x / 2,
			get_parent().get_rect().size.y - progress_off_y))
