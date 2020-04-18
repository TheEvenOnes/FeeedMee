tool
extends Area

export (Texture) var PROP_TEXTURE setget set_prop_texture, get_prop_texture

var _prop_texture = null
onready var mesh_instance = $MeshInstance

func _ready() -> void:
	if mesh_instance != null:
		mesh_instance.get_surface_material(0).albedo_texture = PROP_TEXTURE

func set_prop_texture(texture: Texture) -> void:
	_prop_texture = texture
	if mesh_instance != null and mesh_instance.get_surface_material_count() == 1:
		mesh_instance.get_surface_material(0).albedo_texture = PROP_TEXTURE

func get_prop_texture() -> Texture:
	return _prop_texture
