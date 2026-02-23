extends MiniGameBase

## Reaction Time minigame.
## After a random delay, a signal appears. Press spacebar as fast as possible.
## Score = 10000 - reaction_time_ms (higher = better). Early press = penalty score of 0.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var reaction_label: Label = %ReactionLabel
@onready var instruction_label: Label = %InstructionLabel

## Whether the "GO" signal has appeared
var _signal_shown: bool = false

## Whether the player has already reacted
var _has_reacted: bool = false

## Whether the player pressed too early
var _false_start: bool = false

## Time (msec) when the signal was shown
var _signal_time_msec: int = 0

## Reaction time in milliseconds
var _reaction_time_ms: int = 0

## Timer for the random delay before showing signal
var _delay_timer: Timer = null

## Number of rounds completed (best of 3)
var _attempts: int = 0

## Best reaction time across attempts (lowest ms)
var _best_time_ms: int = 99999


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	instruction_label.text = "Get ready..."
	reaction_label.text = ""

	_delay_timer = Timer.new()
	_delay_timer.one_shot = true
	_delay_timer.timeout.connect(_on_delay_timer_timeout)
	add_child(_delay_timer)


func _unhandled_input(event: InputEvent) -> void:
	if not game_active:
		return
	if _has_reacted or _false_start:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
			if not _signal_shown:
				# Pressed too early
				_false_start = true
				reaction_label.text = "TOO EARLY!"
				instruction_label.text = "Wait for the signal..."
				# Reset after a brief moment
				_start_new_attempt_delayed()
			else:
				# Valid reaction
				_has_reacted = true
				_reaction_time_ms = Time.get_ticks_msec() - _signal_time_msec
				if _reaction_time_ms < _best_time_ms:
					_best_time_ms = _reaction_time_ms
				_attempts += 1
				reaction_label.text = str(_reaction_time_ms) + " ms"
				instruction_label.text = "Best: " + str(_best_time_ms) + " ms (Attempt " + str(_attempts) + "/3)"
				if _attempts < 3:
					_start_new_attempt_delayed()
				else:
					instruction_label.text = "Done! Best: " + str(_best_time_ms) + " ms"


func _on_game_start() -> void:
	_attempts = 0
	_best_time_ms = 99999
	countdown_label.visible = false
	_begin_attempt()


func _on_game_end() -> void:
	_delay_timer.stop()
	var final_score: int = 0
	if _best_time_ms < 99999:
		final_score = maxi(0, 10000 - _best_time_ms)
	instruction_label.text = "Time's up! Best: " + str(_best_time_ms if _best_time_ms < 99999 else 0) + " ms"
	submit_score(final_score)


func _begin_attempt() -> void:
	_signal_shown = false
	_has_reacted = false
	_false_start = false
	_reaction_time_ms = 0
	reaction_label.text = ""
	instruction_label.text = "Wait for it..."

	# Random delay between 1.5 and 5.0 seconds
	var delay: float = randf_range(1.5, 5.0)
	# Clamp so it doesn't exceed remaining game time
	if _game_time_remaining < delay + 1.0:
		delay = maxf(0.5, _game_time_remaining - 1.0)
	_delay_timer.wait_time = delay
	_delay_timer.start()


func _on_delay_timer_timeout() -> void:
	if not game_active:
		return
	_signal_shown = true
	_signal_time_msec = Time.get_ticks_msec()
	reaction_label.text = ">>> PRESS SPACE! <<<"
	instruction_label.text = "NOW!"


func _start_new_attempt_delayed() -> void:
	# Brief pause before next attempt
	await get_tree().create_timer(1.0).timeout
	if game_active and _attempts < 3:
		_begin_attempt()


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
