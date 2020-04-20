tool
extends KinematicBody
class_name Villager

export (float) var HEALTH = 10.0
export (float) var MAX_HUNGER = 3.0
export (float) var MAX_TIRED = 3.0
export (float) var AI_DECISION_SPEED = 2.0

export (float) var GRAVITY = -24.8
export (float) var MAX_SPEED = 2.5
export (float) var ACCEL = 4
export (float) var DEACCEL = 16
export (float) var MAX_SLOPE_ANGLE = 30

# Define radii for the nudge-back shell.
export (float) var NUDGE_BACK_INNER = 1.5
export (float) var NUDGE_BACK_OUTER = 7

const BULLET_SPEED = 15.0

export (SpriteFrames) var SPRITE setget set_sprite, get_sprite

var _sprite = null
var velocity = Vector3()

onready var ray_cast = $RayCast
onready var collider = $CollisionShape
onready var sfx = $Walking
onready var huntable_scanner: Area = $HuntableScanner
onready var firing_range_scanner: Area = $FiringRangeScanner

var rng = RandomNumberGenerator.new()

enum VillagerState {
	Idle = 0,
	Firing = 1,
	Moving = 2,
	Held = 3,
	Thrown = 4,

	Hunting = 5,
	HuntingShoot = 6,
}

var state = VillagerState.Idle
var next_decision_in = AI_DECISION_SPEED
var hunger = 0.0
var tired = 0.0
var villager_direction = Vector3.ZERO
var throw_velocity = Vector3.ZERO
var hunt_target: Spatial = null
var hunt_shoot_dir: Vector3
var hunt_shoot_progress: float = 0
var hunt_shoot_shot: bool

# Villager stays around the spawn location.
var spawn_location: Vector3 = Vector3.ZERO

func _ready() -> void:
	rng.randomize()
	if has_node('AnimatedSprite3D'):
		$AnimatedSprite3D.frames = _sprite
	spawn_location = global_transform.origin

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
		$Walking.want_sound = false

func process_ai(delta: float) -> void:
	if not Engine.is_editor_hint():

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
						villager_direction = Vector3(x, 0.0, y).normalized()

						# There is a certain "nudge back" shell around the
						# spawn location of the villager.
						# Is the villager inside this  "nudge back" shell, or
						# even beyond it?
						var current_location: Vector3 = global_transform.origin
						if current_location.distance_to(spawn_location) > NUDGE_BACK_INNER:
							var nudge_strength = (current_location.distance_to(spawn_location) - NUDGE_BACK_INNER) / (NUDGE_BACK_OUTER - NUDGE_BACK_INNER)
							nudge_strength = clamp(nudge_strength, 0.0, 1.0)
							villager_direction = villager_direction.normalized().slerp(current_location.direction_to(spawn_location), nudge_strength)
							villager_direction = villager_direction.normalized()

						state = VillagerState.Moving

				# Note: state and hunt_target can be updated by evaluate_hunt
				# Evaluated even if the villager is not bored.
				villager_direction = evaluate_hunt(villager_direction)

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
				$Walking.want_sound = true

				if is_hungry():
					stop_moving()
					state = VillagerState.Firing
				elif is_tired():
					stop_moving()
					state = VillagerState.Idle

				# Note: state and hunt_target can be updated by evaluate_hunt
				# Evaluated even if the villager is not bored.
				villager_direction = evaluate_hunt(villager_direction)

			VillagerState.Held:
				play('walking')
				hunger = 0.0
				tired = 0.0
				honk()

			VillagerState.Hunting:
				play('walking')
				hunger = 0.0
				tired = 0.0
				villager_direction = global_transform.origin.direction_to(
					hunt_target.global_transform.origin)
				if not huntable_scanner.overlaps_body(hunt_target):
					#print("lost the target which was ", hunt_target)
					villager_direction = evaluate_hunt(villager_direction)
				else:
					#print("still overlaps")
					pass

				# confirm we still have a hunt_target
				if hunt_target != null:
					if firing_range_scanner.overlaps_body(hunt_target):
						#print("in firing range - distance is ", global_transform.origin.distance_to(
						#	hunt_target.global_transform.origin))
						state = VillagerState.HuntingShoot
						#hunt_shoot_dir = velocity.normalized()
						hunt_shoot_dir = global_transform.origin.direction_to(
							hunt_target.global_transform.origin)
						hunt_shoot_progress = 0.0
						hunt_shoot_shot = false
						stop_moving()
						$AnimatedSprite3D.flip_h = hunt_shoot_dir.x < 0
					else:
						#print("out of firing range - distance is ", global_transform.origin.distance_to(
						#	hunt_target.global_transform.origin))
						pass

			VillagerState.HuntingShoot:
				play('firing')
				hunt_shoot_progress += delta
				if hunt_shoot_progress > 0.4 and not hunt_shoot_shot: # 4th frame; 11 frames at 11 fps
					var bullet = load('res://actors/Bullet.tscn').instance()
					add_child(bullet)
					bullet.global_transform = Transform(
						hunt_shoot_dir,
						Vector3.UP,
						hunt_shoot_dir.cross(Vector3.UP),
						global_transform.origin)
					bullet.velocity = hunt_shoot_dir * BULLET_SPEED
					hunt_shoot_shot = true
					$AnimatedSprite3D.flip_h = hunt_shoot_dir.x < 0

				if hunt_shoot_progress > 1.0:
					# Switch us back to Hunting or to Moving or something.
					# We can easily get back to HuntingShoot from there.
					villager_direction = evaluate_hunt(villager_direction)
					

func process_movement(delta):
	if not Engine.is_editor_hint():
		villager_direction.y = 0

		if state == VillagerState.Held:
			velocity = Vector3.ZERO
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

		var horizontal_velocity: Vector3 = velocity
		horizontal_velocity.y = 0

		var target = villager_direction.normalized()
		target *= MAX_SPEED

		var acceleration
		if villager_direction.normalized().dot(horizontal_velocity) > 0:
				acceleration = ACCEL
		else:
				acceleration = DEACCEL

		horizontal_velocity = horizontal_velocity.move_toward(target, acceleration * delta)
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
	honk()

func stop_held(velocity: Vector3) -> void:
	throw_velocity = velocity
	ray_cast.enabled = true
	collider.disabled = false
	state = VillagerState.Thrown

# Chooses whether to begin a hunt, and updates object-level var 'state'.
#
# Updates hunt_target. May update hunt_target to null.
#
# Returns new movement direction for the villager if necessary.
func evaluate_hunt(villager_direction: Vector3) -> Vector3:
	var bodies = huntable_scanner.get_overlapping_bodies()
	var found: Node = null
	for body in bodies:
		if body.is_in_group('huntable'):
			found = body
			state = VillagerState.Hunting
			break

	if hunt_target == null and found != null:
		# found someone
		hunt_target = found
		honk()

	if found == null:
		hunt_target = null

	if hunt_target == null and (
		state == VillagerState.Hunting or state == VillagerState.HuntingShoot):
			# already was hunting, but lost the target
			state = VillagerState.Idle
			stop_moving()
			tired = MAX_TIRED
			hunger = 0.0

	return villager_direction

func honk() -> void:
	$Honk.play(2.0) # just 'get off my lawn' part
