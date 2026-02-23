extends MiniGameBase

## Digit Span minigame.
## Increasing sequences of digits are shown, then player types them back.
## Starts with length 2, grows by 1 each round. Race to recall length 9.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var status_label: Label = %StatusLabel
@onready var digit_display: Label = %DigitDisplay
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel
@onready var input_field: LineEdit = %InputField

const COMPLETION_TARGET: int = 9
const STARTING_LENGTH: int = 2
const FLASH_TIME: float = 0.6
const PAUSE_TIME: float = 0.2

var _current_length: int = STARTING_LENGTH
var _current_sequence: Array[int] = []
var _phase: String = "waiting"  # "waiting", "showing", "input"
var _show_index: int = 0
var _flash_timer: Timer = null
var _pause_timer: Timer = null


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	status_label.text = ""
	feedback_label.text = ""
	digit_display.text = ""
	score_label.text = "Length: 0 / " + str(COMPLETION_TARGET)
	input_field.visible = false
	input_field.text_submitted.connect(_on_input_submitted)

	_flash_timer = Timer.new()
	_flash_timer.wait_time = FLASH_TIME
	_flash_timer.one_shot = true
	_flash_timer.timeout.connect(_on_flash_timer_timeout)
	add_child(_flash_timer)

	_pause_timer = Timer.new()
	_pause_timer.wait_time = PAUSE_TIME
	_pause_timer.one_shot = true
	_pause_timer.timeout.connect(_on_pause_timer_timeout)
	add_child(_pause_timer)


func _on_game_start() -> void:
	countdown_label.visible = false
	_current_length = STARTING_LENGTH
	score_label.text = "Length: 0 / " + str(COMPLETION_TARGET)
	_generate_and_show_sequence()


func _on_game_end() -> void:
	_phase = "waiting"
	input_field.visible = false
	var best: int = _current_length - STARTING_LENGTH
	feedback_label.text = "Time's up! Reached length " + str(_current_length - 1) + "!"
	submit_score(best)


func _generate_and_show_sequence() -> void:
	_current_sequence.clear()
	for i: int in range(_current_length):
		_current_sequence.append(randi_range(0, 9))
	_phase = "showing"
	_show_index = 0
	status_label.text = "Memorize the digits!"
	feedback_label.text = ""
	digit_display.text = ""
	input_field.visible = false
	_show_next_digit()


func _show_next_digit() -> void:
	if _show_index >= _current_sequence.size():
		# Done showing, switch to input
		digit_display.text = ""
		_phase = "input"
		status_label.text = "Type the sequence!"
		input_field.visible = true
		input_field.text = ""
		input_field.grab_focus()
		return

	digit_display.text = str(_current_sequence[_show_index])
	_flash_timer.start()


func _on_flash_timer_timeout() -> void:
	digit_display.text = ""
	_show_index += 1
	_pause_timer.start()


func _on_pause_timer_timeout() -> void:
	if _phase == "showing" and game_active:
		_show_next_digit()


func _on_input_submitted(text: String) -> void:
	if not game_active or _phase != "input":
		return

	var expected: String = ""
	for d: int in _current_sequence:
		expected += str(d)

	var answer: String = text.strip_edges()
	if answer == expected:
		var reached: int = _current_length - STARTING_LENGTH + 1
		score_label.text = "Length: " + str(reached) + " / " + str(COMPLETION_TARGET)
		feedback_label.text = "Correct! Length " + str(_current_length) + " done!"

		if reached >= COMPLETION_TARGET:
			mark_completed(reached)
			return

		_current_length += 1
		_phase = "waiting"
		input_field.visible = false
		await get_tree().create_timer(0.5).timeout
		if game_active:
			_generate_and_show_sequence()
	else:
		feedback_label.text = "Wrong! Was: " + expected
		input_field.text = ""
		input_field.grab_focus()
		# Retry same length with new sequence
		_phase = "waiting"
		input_field.visible = false
		await get_tree().create_timer(0.8).timeout
		if game_active:
			_generate_and_show_sequence()


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
