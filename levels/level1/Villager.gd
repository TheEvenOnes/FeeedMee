tool
extends KinematicBody
class_name Villager

export (float) var HEALTH = 10.0
export (float) var MAX_HUNGER = 3.0
export (float) var MAX_TIRED = 3.0
export (float) var AI_DECISION_SPEED = 2.0

export (float) var GRAVITY = -24.8
export (float) var MAX_SPEED = 0.5
export (float) var ACCEL = 1
export (float) var DEACCEL = 16
export (float) var MAX_SLOPE_ANGLE = 30

export (SpriteFrames) var SPRITE setget set_sprite, get_sprite

var _sprite = null
var velocity = Vector3()
var direction = Vector3()

onready var ray_cast = $RayCast
onready var collider = $CollisionShape
onready var sfx = $Walking

var rng = RandomNumberGenerator.new()

enum VillagerState {
	Idle = 0,
	Firing = 1,
	Moving = 2,
	Held = 3,
	Thrown = 4
}

var state = VillagerState.Idle
var next_decision_in = AI_DECISION_SPEED
var hunger = 0.0
var tired = 0.0
var villager_direction = Vector3.ZERO
var throw_velocity = Vector3.ZERO

func _ready() -> void:
	rng.randomize()
	if has_node('AnimatedSprite3D'):
		$AnimatedSprite3D.frames = _sprite

func set_sprite(frames: SpriteFrames) -> void:
	_sprite = frames
	if has_node('AnimatedSprite3D'):
		$AnimatedSprite3D.frames = _sprite

func get_sprite() -> SpriteFrames:
	return _sprite

func _physics_process(delta: float) -> void:
	process_ai(delta)
	process_movement(delta)

func get_distance_to_bottom() -> float:
	if ray_cast != null:
		var collider = ray_cast.get_collider()
		if collider != null:
			return (global_transform.origin - ray_cast.get_collision_point()).length_squared()
	return 100.0

func play(animation: String) -> void:
	if has_node('AnimatedSprite3D') and $AnimatedSprite3D.animation != animation:
		$AnimatedSprite3D.animation = animation
		match animation:
			'idle': sfx.stop()
			'walking': sfx.play(0.0)
			'firing': sfx.stop()

func is_bored() -> bool:
	var bored = false
	if next_decision_in <= 0.0:
		if rng.randf() > 0.5:
			bored = true
		else:
			next_decision_in = AI_DECISION_SPEED
	return bored

func is_hungry() -> bool:
	return hunger >= MAX_HUNGER

func is_tired() -> bool:
	return tired >= MAX_TIRED

func stop_moving() -> void:
	if villager_direction.length_squared() > 0.01:
		villager_direction = Vector3.ZERO

func process_ai(delta: float) -> void:
	if not Engine.is_editor_hint():
		direction = Vector3()

		var movement_vector = Vector3.ZERO

		next_decision_in = clamp(next_decision_in - delta, 0.0, 1.0)
		match state:
			VillagerState.Idle:
				play('idle')
				# In idle, the animal gets hungry slower
				hunger = clamp(hunger + delta * 0.5, 0.0, MAX_HUNGER)
				# and rests faster
				tired = clamp(tired - delta * 2.0, 0.0, MAX_TIRED)
				if is_bored():
					if is_hungry():
						state = VillagerState.Firing
					elif not is_tired():
						var x = rng.randf() - 0.5
						x *= 2.0
						x = x if abs(x) > 0.1 else 0.1
						var y = rng.randf() - 0.5
						y *= 2.0
						y = y if abs(y) > 0.1 else 0.1
						villager_direction = Vector3(x, 0.0, y).normalized() * MAX_SPEED
						state = VillagerState.Moving

			VillagerState.Firing:
				play('firing')
				# In firing, the animal man fires
				hunger = clamp(hunger - delta, 0.0, MAX_HUNGER)
				# and gets tired slowly
				tired = clamp(tired - delta * 0.5, 0.0, MAX_TIRED)

				if is_tired() or hunger <= 0.0:
					state = VillagerState.Idle

			VillagerState.Moving:
				play('walking')
				# In moving, the animal man gets hungry for guns
				hunger = clamp(hunger + delta, 0.0, MAX_HUNGER)
				# and tired
				tired = clamp(tired + delta, 0.0, MAX_TIRED)

				if is_hungry():
					stop_moving()
					state = VillagerState.Firing
				elif is_tired():
					stop_moving()
					state = VillagerState.Idle

			VillagerState.Held:
				play('walking')
				hunger = 0.0
				tired = 0.0

		movement_vector = villager_direction
		velocity += movement_vector

		if state == VillagerState.Held:
			velocity = Vector3.ZERO

func process_movement(delta):
	if not Engine.is_editor_hint():
		direction.y = 0

		if state == VillagerState.Held:
			return

		if state == VillagerState.Thrown:
			throw_velocity.y += delta * GRAVITY
			throw_velocity = move_and_slide(throw_velocity, Vector3(0, 1, 0), true, 4, deg2rad(MAX_SLOPE_ANGLE))
			if is_on_floor():
				throw_velocity = Vector3.ZERO
				state = VillagerState.Idle
				velocity = Vector3.ZERO
			return

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

	if has_node('AnimatedSprite3D'):
		if abs(velocity.x) > 0.0001:
			$AnimatedSprite3D.flip_h = velocity.x < 0

func start_held() -> void:
	collider.disabled = true
	ray_cast.enabled = false
	state = VillagerState.Held

func stop_held(velocity: Vector3) -> void:
	throw_velocity = velocity
	ray_cast.enabled = true
	collider.disabled = false
	state = VillagerState.Thrown
