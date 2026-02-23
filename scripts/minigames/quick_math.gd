extends MiniGameBase

## Quick Math minigame.
## Solve as many simple arithmetic problems as possible in 10 seconds.
## Score = number of correct answers.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var problem_label: Label = %ProblemLabel
@onready var answer_input: LineEdit = %AnswerInput
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel

## Current correct answer
var _correct_answer: int = 0

## Number of correct answers
var _correct_count: int = 0

## Number of problems shown
var _problems_shown: int = 0


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	answer_input.text_submitted.connect(_on_answer_submitted)
	problem_label.text = ""
	feedback_label.text = ""
	score_label.text = "Correct: 0"
	answer_input.editable = false
	answer_input.placeholder_text = "Type answer + Enter"


func _on_game_start() -> void:
	countdown_label.visible = false
	_correct_count = 0
	_problems_shown = 0
	score_label.text = "Correct: 0"
	answer_input.editable = true
	answer_input.grab_focus()
	_generate_problem()


func _on_game_end() -> void:
	answer_input.editable = false
	feedback_label.text = "Time's up! You got " + str(_correct_count) + " correct!"
	submit_score(_correct_count)


func _generate_problem() -> void:
	_problems_shown += 1
	var op: int = randi_range(0, 2)
	var a: int = 0
	var b: int = 0

	if op == 0:
		# Addition
		a = randi_range(1, 50)
		b = randi_range(1, 50)
		_correct_answer = a + b
		problem_label.text = str(a) + " + " + str(b) + " = ?"
	elif op == 1:
		# Subtraction (ensure non-negative result)
		a = randi_range(10, 50)
		b = randi_range(1, a)
		_correct_answer = a - b
		problem_label.text = str(a) + " - " + str(b) + " = ?"
	else:
		# Multiplication
		a = randi_range(2, 12)
		b = randi_range(2, 12)
		_correct_answer = a * b
		problem_label.text = str(a) + " x " + str(b) + " = ?"

	answer_input.text = ""
	answer_input.grab_focus()


func _on_answer_submitted(text: String) -> void:
	if not game_active:
		return

	var stripped: String = text.strip_edges()
	if stripped.is_empty():
		return

	if stripped.is_valid_int() and stripped.to_int() == _correct_answer:
		_correct_count += 1
		feedback_label.text = "Correct!"
		score_label.text = "Correct: " + str(_correct_count)
	else:
		feedback_label.text = "Wrong! Answer: " + str(_correct_answer)

	_generate_problem()


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
