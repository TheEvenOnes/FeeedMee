extends KinematicBody

export (float) var GRAVITY = 9.81
var velocity = Vector3(0.0, 0.0, 0.0)

func _physics_process(delta: float) -> void:
	# fake gravity
	velocity += Vector3.DOWN * GRAVITY * delta

	var input_vector = Vector3.ZERO

	input_vector = Vector3(
		Input.get_action_strength('move_right') - Input.get_action_strength('move_left'),
		10.0 if Input.is_action_just_pressed('move_jump') else 0.0,
		Input.get_action_strength('move_up') - Input.get_action_strength('move_down')
	)

	velocity += input_vector

	move_and_slide(velocity, Vector3.UP, true)
