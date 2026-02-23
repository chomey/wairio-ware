extends MiniGameBase

## Countdown Catch minigame.
## Timer counts down from a random number (3-7 seconds).
## Press spacebar at exactly 0. Closest to zero scores best.
## Best of 5 attempts. Score = inverse of best error (higher = better).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var status_label: Label = %StatusLabel
@onready var countdown_display: Label = %CountdownDisplay
@onready var attempt_container: HBoxContainer = %AttemptContainer
@onready var best_label: Label = %BestLabel

const COMPLETION_TARGET: int = 5
const MAX_SCORE: int = 10000

var _attempt: int = 0
var _best_error_ms: int = MAX_SCORE  # Lower is better
var _counting_down: bool = false
var _countdown_time: float = 0.0
var _start_time: float = 0.0
var _pressed: bool = false
var _attempt_markers: Array[ColorRect] = []
var _pause_timer: float = 0.0
var _paused: bool = false


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	status_label.text = ""
	score_label.text = "Attempt: 0 / " + str(COMPLETION_TARGET)
	best_label.text = "Best: ---"
	countdown_display.text = ""
	_create_attempt_markers()


func _on_game_start() -> void:
	countdown_label.visible = false
	_attempt = 0
	_best_error_ms = MAX_SCORE
	_counting_down = false
	_pressed = false
	_paused = false
	score_label.text = "Attempt: 0 / " + str(COMPLETION_TARGET)
	best_label.text = "Best: ---"
	status_label.text = "Get ready..."
	_start_new_countdown()


func _on_game_end() -> void:
	# Score: higher is better. MAX_SCORE - best_error_ms, minimum 0
	var final_score: int = maxi(0, MAX_SCORE - _best_error_ms)
	status_label.text = "Time's up! Best: " + _format_error(_best_error_ms)
	submit_score(final_score)


func _process(delta: float) -> void:
	if not game_active:
		return

	if _paused:
		_pause_timer -= delta
		if _pause_timer <= 0.0:
			_paused = false
			if _attempt >= COMPLETION_TARGET:
				var final_score: int = maxi(0, MAX_SCORE - _best_error_ms)
				status_label.text = "All attempts done! Best: " + _format_error(_best_error_ms)
				mark_completed(final_score)
				return
			_start_new_countdown()
		return

	if _counting_down and not _pressed:
		_countdown_time -= delta
		if _countdown_time <= 0.0:
			# Player missed - went past zero
			_countdown_time = 0.0
			_counting_down = false
			_handle_press_result()
		else:
			_update_countdown_display()


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or not _counting_down or _pressed or _paused:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
			_pressed = true
			_handle_press_result()


func _handle_press_result() -> void:
	_counting_down = false
	_attempt += 1
	score_label.text = "Attempt: " + str(_attempt) + " / " + str(COMPLETION_TARGET)

	# Calculate error in milliseconds
	var error_ms: int = int(absf(_countdown_time) * 1000.0)

	# Update attempt marker
	if _attempt - 1 < _attempt_markers.size():
		if error_ms <= 50:
			_attempt_markers[_attempt - 1].color = Color(0.2, 1.0, 0.2, 1.0)  # Green - great
		elif error_ms <= 200:
			_attempt_markers[_attempt - 1].color = Color(1.0, 1.0, 0.2, 1.0)  # Yellow - ok
		else:
			_attempt_markers[_attempt - 1].color = Color(1.0, 0.3, 0.2, 1.0)  # Red - bad

	if error_ms < _best_error_ms:
		_best_error_ms = error_ms
		best_label.text = "Best: " + _format_error(_best_error_ms)

	if _countdown_time <= 0.0 and not _pressed:
		# Timer ran out - they missed completely
		countdown_display.text = "0.000"
		status_label.text = "TOO LATE! Off by " + _format_error(error_ms)
	elif error_ms == 0:
		countdown_display.text = "0.000"
		status_label.text = "PERFECT!"
	else:
		countdown_display.text = _format_time(_countdown_time)
		if error_ms <= 50:
			status_label.text = "GREAT! Off by " + _format_error(error_ms)
		elif error_ms <= 200:
			status_label.text = "OK! Off by " + _format_error(error_ms)
		else:
			status_label.text = "Off by " + _format_error(error_ms)

	# Brief pause before next attempt
	_paused = true
	_pause_timer = 1.0


func _start_new_countdown() -> void:
	_pressed = false
	_countdown_time = randf_range(3.0, 7.0)
	_start_time = _countdown_time
	_counting_down = true
	status_label.text = "Press SPACE at exactly 0!"
	_update_countdown_display()


func _update_countdown_display() -> void:
	countdown_display.text = _format_time(_countdown_time)
	# Color shifts from white to red as approaching zero
	var t: float = clampf(1.0 - _countdown_time / _start_time, 0.0, 1.0)
	countdown_display.modulate = Color(1.0, 1.0 - t * 0.7, 1.0 - t * 0.7, 1.0)


func _format_time(time_val: float) -> String:
	return "%.3f" % maxf(time_val, 0.0)


func _format_error(error_ms: int) -> String:
	if error_ms >= MAX_SCORE:
		return "---"
	if error_ms < 1000:
		return str(error_ms) + "ms"
	return "%.2f" % (float(error_ms) / 1000.0) + "s"


func _create_attempt_markers() -> void:
	_attempt_markers.clear()
	for child: Node in attempt_container.get_children():
		child.queue_free()
	for i: int in range(COMPLETION_TARGET):
		var marker: ColorRect = ColorRect.new()
		marker.custom_minimum_size = Vector2(40, 20)
		marker.color = Color(0.3, 0.3, 0.4, 1.0)
		attempt_container.add_child(marker)
		_attempt_markers.append(marker)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
