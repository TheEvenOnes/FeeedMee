extends Node

class_name SoundFX

export (float) var playerWalkFreq = 0.3
export (float) var feedSoundsFreq = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	_playerWalking = false
	_playerWalkingTime = 0
	_nextFeedSnd = feedSoundsFreq
	$BGM.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_playerWalkingPlay(delta)
	_plantEatPlay(delta)
	_rndFeed(delta)

###############################################
# Player SFX

var _playerWalking:bool
var _playerWalkingTime:float

func playerWalking(status:bool):
	if _playerWalking == status:
		return
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

###############################################
# Plant SFX

var _plantEat:bool
var _plantEatTime:float

func plantEat(what:int):
	$Eating.stop()
	_plantEat = true
	_plantEatTime = 0

func _plantEatPlay(delta):
	if !_plantEat:
		return
	if _plantEatTime > 0.5 && !$Eating.playing:
		$Eating.play()
	if _plantEatTime > 0.6 && !$Eating.playing:
		_plantEat = false
	_plantEatTime+=delta

var _nextFeedSnd:float

func _rndFeed(delta):
	if _nextFeedSnd > 0:
		_nextFeedSnd -= delta
		if _nextFeedSnd < 0:
			_nextFeedSnd=0
		return

	_nextFeedSnd = feedSoundsFreq + rand_range(0, feedSoundsFreq / 2)
	if int(_nextFeedSnd) % 2 == 1:
		get_node('../TigerPlant/FeedMee').play()
	else:
		pass
		# get_node('../TigerPlant/ImHungry').play()
