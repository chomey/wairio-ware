extends MiniGameBase

## Morse Decode minigame.
## Morse patterns (dots and dashes) are shown. Type the matching letter.
## Score = number of letters decoded. Race to 10.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var morse_label: Label = %MorseLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel
@onready var hint_label: Label = %HintLabel

const COMPLETION_TARGET: int = 10

var _decoded_count: int = 0
var _current_letter: String = ""
var _current_morse: String = ""
var _waiting_for_input: bool = false

const MORSE_CODE: Dictionary = {
	"A": ".-",
	"B": "-...",
	"C": "-.-.",
	"D": "-..",
	"E": ".",
	"F": "..-.",
	"G": "--.",
	"H": "....",
	"I": "..",
	"J": ".---",
	"K": "-.-",
	"L": ".-..",
	"M": "--",
	"N": "-.",
	"O": "---",
	"P": ".--.",
	"Q": "--.-",
	"R": ".-.",
	"S": "...",
	"T": "-",
	"U": "..-",
	"V": "...-",
	"W": ".--",
	"X": "-..-",
	"Y": "-.--",
	"Z": "--.."
}

const LETTERS: Array[String] = [
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
	morse_label.text = ""
	feedback_label.text = ""
	hint_label.text = "dot = .   dash = -"
	score_label.text = "Decoded: 0 / " + str(COMPLETION_TARGET)


func _on_game_start() -> void:
	countdown_label.visible = false
	_decoded_count = 0
	score_label.text = "Decoded: 0 / " + str(COMPLETION_TARGET)
	_generate_morse()


func _on_game_end() -> void:
	_waiting_for_input = false
	feedback_label.text = "Time's up! You decoded " + str(_decoded_count) + " letters!"
	submit_score(_decoded_count)


func _generate_morse() -> void:
	_current_letter = LETTERS[randi_range(0, LETTERS.size() - 1)]
	_current_morse = MORSE_CODE[_current_letter]
	# Display morse with visual spacing for readability
	var display: String = ""
	for i: int in range(_current_morse.length()):
		if i > 0:
			display += "  "
		var ch: String = _current_morse[i]
		if ch == ".":
			display += "DOT"
		else:
			display += "DASH"
	morse_label.text = _current_morse + "\n" + display
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

	var pressed_letter: String = ""
	if key_event.keycode >= KEY_A and key_event.keycode <= KEY_Z:
		pressed_letter = char(key_event.keycode - KEY_A + 65)
	else:
		return

	get_viewport().set_input_as_handled()

	if pressed_letter == _current_letter:
		_waiting_for_input = false
		_decoded_count += 1
		score_label.text = "Decoded: " + str(_decoded_count) + " / " + str(COMPLETION_TARGET)
		feedback_label.text = "Correct! " + _current_morse + " = " + _current_letter
		if _decoded_count >= COMPLETION_TARGET:
			mark_completed(_decoded_count)
			return
		_generate_morse()
	else:
		feedback_label.text = "Wrong! Try again. (Not " + pressed_letter + ")"


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
