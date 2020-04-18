extends KinematicBody

export (float) var GRAVITY = -24.8
export (float) var MAX_SPEED = 9
export (float) var JUMP_SPEED = 8
export (float) var ACCEL = 4.5
export (float) var DEACCEL = 16
export (float) var MAX_SLOPE_ANGLE = 30

var velocity = Vector3()
var direction = Vector3()

onready var ray_cast = $RayCast
onready var sprite = $AnimatedSprite3D

func _physics_process(delta: float) -> void:
		process_input(delta)
		process_movement(delta)

func get_distance_to_bottom() -> float:
	if ray_cast != null:
		var collider = ray_cast.get_collider()
		if collider != null:
			return (global_transform.origin - ray_cast.get_collision_point()).length_squared()
	return 100.0

func process_input(delta: float) -> void:
		direction = Vector3()

		var input_movement_vector = Vector3()

		input_movement_vector.z += Input.get_action_strength('move_down')
		input_movement_vector.z -= Input.get_action_strength('move_up')
		input_movement_vector.x -= Input.get_action_strength('move_left')
		input_movement_vector.x += Input.get_action_strength('move_right')

		var can_jump = false
		var dist = get_distance_to_bottom()
		if dist < 0.1:
			can_jump = true

		if is_on_floor() or can_jump:
				if Input.is_action_just_pressed('move_jump'):
						velocity.y = JUMP_SPEED

		velocity += input_movement_vector

func process_movement(delta):
		direction.y = 0

		if not is_on_floor():
			velocity.y += delta * GRAVITY

		var horizontal_velocity = velocity
		horizontal_velocity.y = 0

		var target = direction
		target *= MAX_SPEED

		var acceleration
		if direction.dot(horizontal_velocity) > 0:
				acceleration = ACCEL
		else:
				acceleration = DEACCEL

		horizontal_velocity = horizontal_velocity.linear_interpolate(target, acceleration * delta)
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z
		velocity = move_and_slide(velocity, Vector3(0, 1, 0), true, 4, deg2rad(MAX_SLOPE_ANGLE))

		if velocity.length_squared() > 0.1:
			sprite.animation = 'walking'
		else:
			sprite.animation = 'idle'

		sprite.flip_h = velocity.x < 0
