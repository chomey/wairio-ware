extends MiniGameBase

## Speed Spell minigame.
## Single letters displayed one at a time, type the matching key as fast as possible.
## Score = number of correct letters typed. Race to 25.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var letter_label: Label = %LetterLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel

const COMPLETION_TARGET: int = 25

var _correct_count: int = 0
var _current_letter: String = ""
var _waiting_for_input: bool = false

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
	letter_label.text = ""
	feedback_label.text = ""
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)


func _on_game_start() -> void:
	countdown_label.visible = false
	_correct_count = 0
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)
	_pick_letter()


func _on_game_end() -> void:
	_waiting_for_input = false
	feedback_label.text = "Time's up! You got " + str(_correct_count) + " correct!"
	submit_score(_correct_count)


func _pick_letter() -> void:
	_current_letter = LETTERS[randi_range(0, LETTERS.size() - 1)]
	letter_label.text = _current_letter
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

	# Convert keycode to letter string
	var pressed_letter: String = ""
	if key_event.keycode >= KEY_A and key_event.keycode <= KEY_Z:
		pressed_letter = char(key_event.keycode - KEY_A + 65)
	else:
		return

	_waiting_for_input = false
	get_viewport().set_input_as_handled()

	if pressed_letter == _current_letter:
		_correct_count += 1
		feedback_label.text = "Correct!"
		score_label.text = "Correct: " + str(_correct_count) + " / " + str(COMPLETION_TARGET)
		if _correct_count >= COMPLETION_TARGET:
			mark_completed(_correct_count)
			return
	else:
		feedback_label.text = "Wrong! It was " + _current_letter

	_pick_letter()


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
