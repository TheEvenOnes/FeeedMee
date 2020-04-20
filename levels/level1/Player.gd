extends KinematicBody

export (float) var GRAVITY = -24.8
export (float) var MAX_SPEED = 9
export (float) var JUMP_SPEED = 8
export (float) var ACCEL = 4.5
export (float) var DEACCEL = 16
export (float) var MAX_SLOPE_ANGLE = 30

var velocity = Vector3()
var direction = Vector3()

var health_now: float = 100.0
var health_max: float = 100.0

onready var ray_cast = $RayCast
onready var sprite = $AnimatedSprite3D
onready var holdable_scanner = $Area
onready var hold_mount = $HoldMount
onready var sfx = get_node("../SFX")
onready var health_bar = get_node("../GUIOverlay/HealthBar")

enum PlayerState {
	Idle = 0,
	Holding = 1,
}

var held_object = null # : Animal = null
var hold_cooldown = 0.0
var state = PlayerState.Idle

func _physics_process(delta: float) -> void:
		process_input(delta)
		process_movement(delta)
		process_held_object(delta)

		health_bar.max_value = health_max
		health_bar.value = health_now

func hurt(amount: float) -> void:
	health_now -= amount
	$PlayerHurt.play()
	if health_now < 0:
		die()

func die() -> void:
	Global.goto_menu()

func get_distance_to_bottom() -> float:
	if ray_cast != null:
		var collider = ray_cast.get_collider()
		if collider != null:
			return (global_transform.origin - ray_cast.get_collision_point()).length_squared()
	return 100.0

func process_input(_delta: float) -> void:
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
			sfx.playerWalking(true)
		else:
			sprite.animation = 'idle'
			sfx.playerWalking(false)

		sprite.flip_h = velocity.x < 0

func process_held_object(delta) -> void:
	hold_cooldown = max(hold_cooldown - delta, 0.0)
	if state == PlayerState.Idle:
		if hold_cooldown > 0.0:
			return
		var bodies = holdable_scanner.get_overlapping_bodies()
		if len(bodies) > 0:
			if Input.is_action_just_pressed('player_action'):
				var holdable = []
				for body in bodies:
					if body.is_in_group('holdable'):
						holdable.push_back(body)
					if len(holdable) > 0:
						holdable.sort_custom(self, 'sorter')
						#var fst: Animal = holdable[0] # or villager... :)
						var fst = holdable[0]
						fst.start_held()
						fst.get_parent().remove_child(fst)
						hold_mount.add_child(fst)
						fst.transform.origin = Vector3.ZERO
						state = PlayerState.Holding
						held_object = fst
						if held_object.has_method('honk'):
							held_object.honk()
						break
	elif state == PlayerState.Holding:
		if Input.is_action_just_pressed('player_action'):
			hold_cooldown = 0.2
			hold_mount.remove_child(held_object)
			var animals = get_node('../Animals')
			animals.add_child(held_object)
			var throw_velocity
			if velocity.length_squared() < 0.1:
				throw_velocity = Vector3(0.0, 3.0, -1.0).normalized() * 3.0
			else:
				throw_velocity = Vector3(velocity.x, 3.0, velocity.z).normalized() * 6.0
			held_object.stop_held(throw_velocity)
			held_object.global_transform.origin = hold_mount.global_transform.origin
			if held_object.has_method('honk'):
				held_object.honk()
			held_object = null
			state = PlayerState.Idle

func sorter(a: Spatial, b: Spatial) -> bool:
	var la = global_transform.origin.distance_to(a.global_transform.origin)
	var lb = global_transform.origin.distance_to(b.global_transform.origin)
	return la > lb

