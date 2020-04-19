extends Node

class_name SoundFX

export (float) var playerWalkFreq = 0.3

var _playerWalking:bool
var _playerWalkingTime:float

# Called when the node enters the scene tree for the first time.
func _ready():
	_playerWalking = false
	_playerWalkingTime = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_playerWalkingPlay(delta)
	#_eatCow(delta)

func playerWalking(status:bool):
	if _playerWalking == status:
		return
	#print_debug("Player walking:", status)
	_playerWalking = status
	$WalkStep.stop()
	if _playerWalking:
		_playerWalkingTime = 0

func _playerWalkingPlay(delta):
	if !_playerWalking:
		return
	if _playerWalkingTime == 0:
		$WalkStep.play()
	_playerWalkingTime += delta
	if _playerWalkingTime > playerWalkFreq:
		_playerWalkingTime = 0
	
func _eatCow(delta):
	pass
