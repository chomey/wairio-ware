extends MiniGameBase

## Bomb Defuse minigame.
## A key sequence is displayed. Press each key in order to defuse the bomb.
## Score = number of bombs defused. Race to 6.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var sequence_label: Label = %SequenceLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel
@onready var bomb_label: Label = %BombLabel

const COMPLETION_TARGET: int = 6
const MIN_SEQ_LENGTH: int = 3
const MAX_SEQ_LENGTH: int = 6

var _bombs_defused: int = 0
var _current_sequence: Array[String] = []
var _current_index: int = 0
var _waiting_for_input: bool = false

const KEYS: Array[String] = [
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
	"K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
	"U", "V", "W", "X", "Y", "Z"
]


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	sequence_label.text = ""
	feedback_label.text = ""
	score_label.text = "Defused: 0 / " + str(COMPLETION_TARGET)
	bomb_label.text = ""


func _on_game_start() -> void:
	countdown_label.visible = false
	_bombs_defused = 0
	score_label.text = "Defused: 0 / " + str(COMPLETION_TARGET)
	_generate_bomb()


func _on_game_end() -> void:
	_waiting_for_input = false
	feedback_label.text = "Time's up! You defused " + str(_bombs_defused) + " bombs!"
	submit_score(_bombs_defused)


func _generate_bomb() -> void:
	_current_sequence.clear()
	var seq_length: int = randi_range(MIN_SEQ_LENGTH, MAX_SEQ_LENGTH)
	for i: int in range(seq_length):
		_current_sequence.append(KEYS[randi_range(0, KEYS.size() - 1)])
	_current_index = 0
	_update_sequence_display()
	feedback_label.text = ""
	bomb_label.text = "BOMB #" + str(_bombs_defused + 1)
	_waiting_for_input = true


func _update_sequence_display() -> void:
	var display: String = ""
	for i: int in range(_current_sequence.size()):
		if i > 0:
			display += "  "
		if i < _current_index:
			display += "[" + _current_sequence[i] + "]"
		elif i == _current_index:
			display += ">" + _current_sequence[i] + "<"
		else:
			display += _current_sequence[i]
	sequence_label.text = display


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or not _waiting_for_input:
		return

	if not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var pressed_letter: String = ""
	if key_event.keycode >= KEY_A and key_event.keycode <= KEY_Z:
		pressed_letter = char(key_event.keycode - KEY_A + 65)
	else:
		return

	get_viewport().set_input_as_handled()

	var expected: String = _current_sequence[_current_index]
	if pressed_letter == expected:
		_current_index += 1
		_update_sequence_display()
		if _current_index >= _current_sequence.size():
			_waiting_for_input = false
			_bombs_defused += 1
			score_label.text = "Defused: " + str(_bombs_defused) + " / " + str(COMPLETION_TARGET)
			feedback_label.text = "DEFUSED!"
			if _bombs_defused >= COMPLETION_TARGET:
				mark_completed(_bombs_defused)
				return
			_generate_bomb()
	else:
		# Wrong key - reset this bomb's sequence
		_current_index = 0
		_update_sequence_display()
		feedback_label.text = "Wrong! Expected " + expected + " - start over!"


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
