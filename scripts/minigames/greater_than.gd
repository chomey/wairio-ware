extends MiniGameBase

## Greater Than minigame.
## Two numbers flash, press left or right arrow for the larger one.
## Score = number of correct presses. Race to 15.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var left_number_label: Label = %LeftNumberLabel
@onready var right_number_label: Label = %RightNumberLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel

const COMPLETION_TARGET: int = 15

var _correct_count: int = 0
var _left_number: int = 0
var _right_number: int = 0
var _waiting_for_input: bool = false


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	left_number_label.text = ""
	right_number_label.text = ""
	feedback_label.text = ""
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)


func _on_game_start() -> void:
	countdown_label.visible = false
	_correct_count = 0
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)
	_pick_numbers()


func _on_game_end() -> void:
	_waiting_for_input = false
	feedback_label.text = "Time's up! You got " + str(_correct_count) + " correct!"
	submit_score(_correct_count)


func _pick_numbers() -> void:
	_left_number = randi_range(1, 99)
	_right_number = randi_range(1, 99)
	# Ensure they are different so there's always a correct answer
	while _right_number == _left_number:
		_right_number = randi_range(1, 99)
	left_number_label.text = str(_left_number)
	right_number_label.text = str(_right_number)
	feedback_label.text = ""
	_waiting_for_input = true


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or not _waiting_for_input:
		return

	if not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var chose_left: bool = false
	var chose_right: bool = false
	if key_event.keycode == KEY_LEFT:
		chose_left = true
	elif key_event.keycode == KEY_RIGHT:
		chose_right = true
	else:
		return

	_waiting_for_input = false
	get_viewport().set_input_as_handled()

	var correct: bool = false
	if chose_left and _left_number > _right_number:
		correct = true
	elif chose_right and _right_number > _left_number:
		correct = true

	if correct:
		_correct_count += 1
		feedback_label.text = "Correct!"
		score_label.text = "Correct: " + str(_correct_count) + " / " + str(COMPLETION_TARGET)
		if _correct_count >= COMPLETION_TARGET:
			mark_completed(_correct_count)
			return
	else:
		var larger_side: String = "LEFT" if _left_number > _right_number else "RIGHT"
		feedback_label.text = "Wrong! " + larger_side + " was bigger"

	_pick_numbers()


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
