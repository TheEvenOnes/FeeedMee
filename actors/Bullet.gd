extends Spatial

var velocity: Vector3
var ttl: float = 1.5

func _ready() -> void:
	$SFX.play(0.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	ttl -= delta
	if ttl < 0:
		poof()
		return

	for body in $Area.get_overlapping_bodies():
		if body.is_in_group('huntable'):
			if body.has_method('hurt'):
				body.hurt(27.0)
			poof()
			break

	global_transform.origin += velocity * delta
	#$AnimatedSprite3D.flip_h = velocity.x < 0

func poof() -> void:
	get_parent().remove_child($'.')
	queue_free()
