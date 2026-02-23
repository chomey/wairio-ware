extends MiniGameBase

## Number Crunch minigame.
## Stream of numbers shown, press space only when the number is prime.
## Race to 12 correct presses.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var status_label: Label = %StatusLabel
@onready var number_label: Label = %NumberLabel

const COMPLETION_TARGET: int = 12
const DISPLAY_TIME: float = 1.5  # Seconds each number is shown
const MIN_DISPLAY_TIME: float = 0.7

var _correct_count: int = 0
var _current_number: int = 0
var _display_timer: float = 0.0
var _pressed_this_number: bool = false
var _feedback_timer: float = 0.0
var _showing_feedback: bool = false


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	status_label.text = ""
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)
	number_label.text = ""


func _on_game_start() -> void:
	countdown_label.visible = false
	_correct_count = 0
	_pressed_this_number = false
	_showing_feedback = false
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)
	status_label.text = "Press SPACE when the number is PRIME!"
	_show_next_number()


func _on_game_end() -> void:
	status_label.text = "Time's up! Got " + str(_correct_count) + " correct!"
	submit_score(_correct_count)


func _process(delta: float) -> void:
	if not game_active:
		return

	if _showing_feedback:
		_feedback_timer -= delta
		if _feedback_timer <= 0.0:
			_showing_feedback = false
			_show_next_number()
		return

	_display_timer -= delta
	if _display_timer <= 0.0:
		# Time expired for this number
		if _is_prime(_current_number) and not _pressed_this_number:
			# Missed a prime
			_show_feedback("MISSED! " + str(_current_number) + " was prime!", Color(1.0, 0.5, 0.0))
		else:
			_show_next_number()


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _pressed_this_number or _showing_feedback:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
			_pressed_this_number = true
			if _is_prime(_current_number):
				_correct_count += 1
				score_label.text = "Correct: " + str(_correct_count) + " / " + str(COMPLETION_TARGET)
				if _correct_count >= COMPLETION_TARGET:
					status_label.text = "ALL PRIMES FOUND!"
					number_label.text = ""
					mark_completed(_correct_count)
					return
				_show_feedback("CORRECT! " + str(_current_number) + " is prime!", Color(0.2, 1.0, 0.2))
			else:
				_show_feedback("WRONG! " + str(_current_number) + " is NOT prime!", Color(1.0, 0.3, 0.3))


func _show_next_number() -> void:
	_current_number = _generate_number()
	_pressed_this_number = false
	_showing_feedback = false
	var progress: float = float(_correct_count) / float(COMPLETION_TARGET)
	_display_timer = lerpf(DISPLAY_TIME, MIN_DISPLAY_TIME, progress)
	number_label.text = str(_current_number)
	number_label.modulate = Color(1, 1, 1)


func _show_feedback(text: String, color: Color) -> void:
	_showing_feedback = true
	_feedback_timer = 0.4
	status_label.text = text
	number_label.modulate = color


func _generate_number() -> int:
	# Mix of primes and non-primes in range 2-99
	# Roughly 40% chance of prime for balanced gameplay
	if randf() < 0.4:
		var primes: Array[int] = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]
		return primes[randi() % primes.size()]
	else:
		# Pick a non-prime
		var composites: Array[int] = [4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 22, 24, 25, 26, 27, 28, 30, 32, 33, 34, 35, 36, 38, 39, 40, 42, 44, 45, 46, 48, 49, 50, 51, 52, 54, 55, 56, 57, 58, 60, 62, 63, 64, 65, 66, 68, 69, 70, 72, 74, 75, 76, 77, 78, 80, 81, 82, 84, 85, 86, 87, 88, 90, 91, 92, 93, 94, 95, 96, 98, 99]
		return composites[randi() % composites.size()]


func _is_prime(n: int) -> bool:
	if n < 2:
		return false
	if n < 4:
		return true
	if n % 2 == 0 or n % 3 == 0:
		return false
	var i: int = 5
	while i * i <= n:
		if n % i == 0 or n % (i + 2) == 0:
			return false
		i += 6
	return true


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
