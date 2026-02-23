extends Node

class_name MiniGameBase

## Base class for all minigames.
## Provides countdown timer (3s), game timer (10s), score submission,
## and virtual hooks _on_game_start() and _on_game_end().

signal countdown_tick(seconds_left: int)
signal countdown_finished()
signal game_timer_tick(seconds_left: float)
signal game_timer_finished()

const COUNTDOWN_DURATION: int = 3
const GAME_DURATION: float = 10.0

## Whether the game is currently in the playable phase
var game_active: bool = false

## Whether the countdown is running
var _countdown_active: bool = false

## Countdown seconds remaining
var _countdown_remaining: int = COUNTDOWN_DURATION

## Game time remaining
var _game_time_remaining: float = GAME_DURATION

## Whether this player has already submitted a score
var _score_submitted: bool = false

## Timer nodes
var _countdown_timer: Timer = null
var _game_timer: Timer = null


func _ready() -> void:
	_setup_timers()
	# Auto-start countdown when scene loads
	start_countdown()


func _setup_timers() -> void:
	_countdown_timer = Timer.new()
	_countdown_timer.wait_time = 1.0
	_countdown_timer.one_shot = false
	_countdown_timer.timeout.connect(_on_countdown_timer_timeout)
	add_child(_countdown_timer)

	_game_timer = Timer.new()
	_game_timer.wait_time = 0.1
	_game_timer.one_shot = false
	_game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(_game_timer)


## Start the 3-second countdown
func start_countdown() -> void:
	_countdown_active = true
	_countdown_remaining = COUNTDOWN_DURATION
	game_active = false
	_score_submitted = false
	countdown_tick.emit(_countdown_remaining)
	_countdown_timer.start()


func _on_countdown_timer_timeout() -> void:
	_countdown_remaining -= 1
	countdown_tick.emit(_countdown_remaining)

	if _countdown_remaining <= 0:
		_countdown_timer.stop()
		_countdown_active = false
		countdown_finished.emit()
		_start_game()


## Begin the playable game phase
func _start_game() -> void:
	game_active = true
	_game_time_remaining = GAME_DURATION
	game_timer_tick.emit(_game_time_remaining)
	_game_timer.start()
	_on_game_start()


func _on_game_timer_timeout() -> void:
	_game_time_remaining -= 0.1
	game_timer_tick.emit(_game_time_remaining)

	if _game_time_remaining <= 0.0:
		_game_timer.stop()
		game_active = false
		game_timer_finished.emit()
		_end_game()


## End the game phase
func _end_game() -> void:
	game_active = false
	_on_game_end()


## Virtual hook: called when the playable phase begins (after countdown)
## Override in subclasses.
func _on_game_start() -> void:
	pass


## Virtual hook: called when the game timer expires.
## Override in subclasses to submit score.
func _on_game_end() -> void:
	pass


## Submit this player's score to the server via GameManager.
## Each player submits their own score; the server collects them.
func submit_score(raw_score: int) -> void:
	if _score_submitted:
		return
	_score_submitted = true

	var my_id: int = multiplayer.get_unique_id()
	_submit_score_to_server.rpc_id(1, my_id, raw_score)


@rpc("any_peer", "reliable")
func _submit_score_to_server(peer_id: int, raw_score: int) -> void:
	if not multiplayer.is_server():
		return
	GameManager.submit_player_score(peer_id, raw_score)


## Get the remaining game time (for UI display)
func get_time_remaining() -> float:
	return _game_time_remaining


## Check if countdown is active (for UI display)
func is_countdown_active() -> bool:
	return _countdown_active
