extends Control

export (Texture) var IMAGE setget set_image, get_image
var _image: Texture

export (int) var NOMS_LEFT setget set_noms_left, get_noms_left
var _noms_left: int

export (String) var KEY

onready var scores = get_parent().get_parent().get_parent().scores

func _ready():
	if _noms_left == -1:
		hide()
	else:
		show()

func set_image(image: Texture) -> void:
	_image = image
	if has_node('TextureRect'):
		$TextureRect.texture = _image

func get_image() -> Texture:
	return _image

func set_noms_left(noms: int) -> void:
	_noms_left = max(noms, -1)
	if _noms_left == -1:
		hide()
	else:
		show()
	if has_node('Label'):
		$Label.text = 'x' + str(_noms_left)

func get_noms_left() -> int:
	return _noms_left

func _process(delta: float) -> void:
	if KEY != null and scores.has(KEY):
		set_noms_left(scores[KEY])
