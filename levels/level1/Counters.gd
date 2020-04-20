tool
extends Control

export (Texture) var IMAGE setget set_image, get_image
var _image: Texture

export (int) var NOMS_LEFT setget set_noms_left, get_noms_left
var _noms_left: int

func set_image(image: Texture) -> void:
	_image = image
	if has_node('TextureRect'):
		$TextureRect.texture = _image

func get_image() -> Texture:
	return _image

func set_noms_left(noms: int) -> void:
	_noms_left = max(noms, 0)
	if has_node('Label'):
		$Label.text = 'x' + str(_noms_left)

func get_noms_left() -> int:
	return _noms_left

func _ready() -> void:
	pass # Replace with function body.

func decrement() -> void:
	set_noms_left(max(_noms_left - 1, 0))

func increment() -> void:
	set_noms_left(max(_noms_left + 1, 0))
