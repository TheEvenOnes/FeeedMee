tool
extends KinematicBody

export (float) var AI_DECISION_SPEED = 2.0

export (bool) var SKIP_HUNGER = false
export (bool) var FLIP_SPRITE setget set_flip, get_flip
var _flip = false

var velocity = Vector3()
var direction = Vector3()

onready var ray_cast = $RayCast
onready var collider = $CollisionShape
onready var sfx = $Devouring
onready var food_scanner = $FoodScanner

var rng = RandomNumberGenerator.new()

enum TigerPlantState {
	IDLE = 0,
	DEVOURING = 1,
}

var state = TigerPlantState.IDLE
var next_decision_in = AI_DECISION_SPEED
var feeding_on = null

func _ready() -> void:
	rng.randomize()
	set_flip(_flip)

func set_flip(flip: bool) -> void:
	_flip = flip
	if has_node('AnimatedSprite3D'):
		$AnimatedSprite3D.flip_h = _flip

func get_flip() -> bool:
	return _flip

func _physics_process(delta: float) -> void:
	process_ai(delta)

func play(animation: String) -> void:
	if has_node('AnimatedSprite3D') and $AnimatedSprite3D.animation != animation:
		$AnimatedSprite3D.animation = animation
		match animation:
			'idle': sfx.stop()
			'munching': sfx.play()

func process_ai(delta: float) -> void:
	if not Engine.is_editor_hint():

		next_decision_in = clamp(next_decision_in - delta, 0.0, 0.5)
		if next_decision_in <= 0.0:
			next_decision_in = 1.0
			match state:
				TigerPlantState.IDLE:
					var bodies = food_scanner.get_overlapping_bodies()
					if len(bodies) > 0:
						var food = []
						for body in bodies:
							if body.is_in_group('food'):
								food.push_back(body)
						if len(food) > 0:
							food.sort_custom(self, 'sorter')
							feeding_on = food[0]
							state = TigerPlantState.DEVOURING
					play('idle')

				TigerPlantState.DEVOURING:
					play('munching')
					if has_node('AnimatedSprite3D'):
						print($AnimatedSprite3D.animation)
						# var anim_frames = $AnimatedSprite3D.frames.get_frame_count('munching')
						var curr_frame = $AnimatedSprite3D.frame
						if $AnimatedSprite3D.animation == 'munching' and curr_frame >= 3:
							if feeding_on != null:
								print(feeding_on.global_transform.origin.distance_to(global_transform.origin))
								if feeding_on.global_transform.origin.distance_to(global_transform.origin) < 1.5:
									# update score
									var level = get_parent()
									if feeding_on.is_in_group('cow'):
										level.reduce_score('cow')
									elif feeding_on.is_in_group('pig'):
										level.reduce_score('pig')
									elif feeding_on.is_in_group('redneck'):
										level.reduce_score('redneck')
									elif feeding_on.is_in_group('joe'):
										level.reduce_score('joe')
									feeding_on.get_parent().remove_child(feeding_on)
									feeding_on.queue_free()
								feeding_on = null
								# TODO: put gibbs here
								# TODO: handle player specially
							state = TigerPlantState.IDLE

func sorter(a: Spatial, b: Spatial) -> bool:
	var la = global_transform.origin.distance_to(a.global_transform.origin)
	var lb = global_transform.origin.distance_to(b.global_transform.origin)
	return la > lb

