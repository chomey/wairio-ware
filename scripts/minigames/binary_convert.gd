extends MiniGameBase

## Binary Convert minigame.
## A decimal number is shown, player types its binary representation.
## Race to 8 correct conversions. Score = number of correct conversions.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var decimal_label: Label = %DecimalLabel
@onready var hint_label: Label = %HintLabel
@onready var answer_input: LineEdit = %AnswerInput
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel

const COMPLETION_TARGET: int = 8

var _correct_count: int = 0
var _current_number: int = 0


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	answer_input.text_submitted.connect(_on_answer_submitted)
	decimal_label.text = ""
	hint_label.text = ""
	feedback_label.text = ""
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)
	answer_input.editable = false
	answer_input.placeholder_text = "Type binary + Enter"


func _on_game_start() -> void:
	countdown_label.visible = false
	_correct_count = 0
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)
	answer_input.editable = true
	answer_input.grab_focus()
	_generate_number()


func _on_game_end() -> void:
	answer_input.editable = false
	feedback_label.text = "Time's up! You got " + str(_correct_count) + " correct!"
	submit_score(_correct_count)


func _generate_number() -> void:
	# Numbers from 1 to 31 (5-bit range, reasonable difficulty)
	_current_number = randi_range(1, 31)
	decimal_label.text = "Decimal: " + str(_current_number)
	hint_label.text = "Type the binary representation"
	answer_input.text = ""
	answer_input.grab_focus()


func _decimal_to_binary(value: int) -> String:
	if value == 0:
		return "0"
	var result: String = ""
	var n: int = value
	while n > 0:
		result = str(n % 2) + result
		n = n / 2
	return result


func _on_answer_submitted(text: String) -> void:
	if not game_active:
		return

	var stripped: String = text.strip_edges()
	if stripped.is_empty():
		return

	var expected: String = _decimal_to_binary(_current_number)

	# Strip leading zeros from player answer for comparison
	var player_answer: String = stripped.lstrip("0")
	if player_answer.is_empty():
		player_answer = "0"

	if player_answer == expected:
		_correct_count += 1
		feedback_label.text = "Correct! " + str(_current_number) + " = " + expected
		score_label.text = "Correct: " + str(_correct_count) + " / " + str(COMPLETION_TARGET)
		if _correct_count >= COMPLETION_TARGET:
			mark_completed(_correct_count)
			return
		_generate_number()
	else:
		feedback_label.text = "Wrong! " + str(_current_number) + " = " + expected
		_generate_number()


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
