tool
extends Spatial

export (Texture) var PROP_TEXTURE setget set_prop_texture, get_prop_texture

var _prop_texture = null

func _ready() -> void:
	if has_node('MeshInstance'):
		$MeshInstance.get_surface_material(0).albedo_texture = _prop_texture

func set_prop_texture(texture: Texture) -> void:
	_prop_texture = texture
	if has_node('MeshInstance'):
		$MeshInstance.get_surface_material(0).albedo_texture = _prop_texture

func get_prop_texture() -> Texture:
	return _prop_texture
