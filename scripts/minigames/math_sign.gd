extends MiniGameBase

## Math Sign minigame.
## Equation missing an operator (+, -, *, /), press the correct key.
## Race to 12 correct. Score = number of correct answers.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var equation_label: Label = %EquationLabel
@onready var hint_label: Label = %HintLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel

const COMPLETION_TARGET: int = 12
const OPERATORS: Array[String] = ["+", "-", "*", "/"]

var _left: int = 0
var _right: int = 0
var _correct_op: String = ""
var _result: int = 0
var _correct_count: int = 0


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	equation_label.text = ""
	hint_label.text = "Press +  -  *  /"
	feedback_label.text = ""
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)


func _on_game_start() -> void:
	countdown_label.visible = false
	_correct_count = 0
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)
	_generate_equation()


func _on_game_end() -> void:
	feedback_label.text = "Time's up! You got " + str(_correct_count) + " correct!"
	submit_score(_correct_count)


func _generate_equation() -> void:
	_correct_op = OPERATORS[randi_range(0, OPERATORS.size() - 1)]

	match _correct_op:
		"+":
			_left = randi_range(1, 50)
			_right = randi_range(1, 50)
			_result = _left + _right
		"-":
			_left = randi_range(10, 50)
			_right = randi_range(1, _left)
			_result = _left - _right
		"*":
			_left = randi_range(2, 12)
			_right = randi_range(2, 12)
			_result = _left * _right
		"/":
			_right = randi_range(2, 10)
			_result = randi_range(1, 10)
			_left = _right * _result

	equation_label.text = str(_left) + "  ?  " + str(_right) + "  =  " + str(_result)
	feedback_label.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if not game_active:
		return
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var pressed_op: String = ""
	match key_event.keycode:
		KEY_EQUAL:
			# + is Shift+= on most keyboards
			if key_event.shift_pressed:
				pressed_op = "+"
		KEY_KP_ADD:
			pressed_op = "+"
		KEY_MINUS:
			pressed_op = "-"
		KEY_KP_SUBTRACT:
			pressed_op = "-"
		KEY_8:
			if key_event.shift_pressed:
				pressed_op = "*"
		KEY_KP_MULTIPLY:
			pressed_op = "*"
		KEY_SLASH:
			pressed_op = "/"
		KEY_KP_DIVIDE:
			pressed_op = "/"

	if pressed_op.is_empty():
		return

	get_viewport().set_input_as_handled()

	if pressed_op == _correct_op:
		_correct_count += 1
		feedback_label.text = "Correct! " + str(_left) + " " + _correct_op + " " + str(_right) + " = " + str(_result)
		score_label.text = "Correct: " + str(_correct_count) + " / " + str(COMPLETION_TARGET)
		if _correct_count >= COMPLETION_TARGET:
			mark_completed(_correct_count)
			return
		_generate_equation()
	else:
		feedback_label.text = "Wrong! It was: " + _correct_op


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
