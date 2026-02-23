extends MiniGameBase

## Arrow Storm minigame.
## Press matching arrow keys as prompts appear.
## Score = number of correct arrows pressed. Race to 20.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var arrow_label: Label = %ArrowLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel

const COMPLETION_TARGET: int = 20

var _correct_count: int = 0
var _current_direction: String = ""
var _waiting_for_input: bool = false

const DIRECTIONS: Array[String] = ["UP", "DOWN", "LEFT", "RIGHT"]
const ARROW_SYMBOLS: Dictionary = {
	"UP": "^",
	"DOWN": "v",
	"LEFT": "<",
	"RIGHT": ">",
}


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	arrow_label.text = ""
	feedback_label.text = ""
	score_label.text = "Arrows: 0 / " + str(COMPLETION_TARGET)


func _on_game_start() -> void:
	countdown_label.visible = false
	_correct_count = 0
	score_label.text = "Arrows: 0 / " + str(COMPLETION_TARGET)
	_pick_direction()


func _on_game_end() -> void:
	_waiting_for_input = false
	feedback_label.text = "Time's up! You hit " + str(_correct_count) + " arrows!"
	submit_score(_correct_count)


func _pick_direction() -> void:
	_current_direction = DIRECTIONS[randi_range(0, DIRECTIONS.size() - 1)]
	arrow_label.text = ARROW_SYMBOLS[_current_direction]
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

	var pressed_direction: String = ""
	if key_event.keycode == KEY_UP:
		pressed_direction = "UP"
	elif key_event.keycode == KEY_DOWN:
		pressed_direction = "DOWN"
	elif key_event.keycode == KEY_LEFT:
		pressed_direction = "LEFT"
	elif key_event.keycode == KEY_RIGHT:
		pressed_direction = "RIGHT"
	else:
		return

	_waiting_for_input = false
	get_viewport().set_input_as_handled()

	if pressed_direction == _current_direction:
		_correct_count += 1
		feedback_label.text = "Correct!"
		score_label.text = "Arrows: " + str(_correct_count) + " / " + str(COMPLETION_TARGET)
		if _correct_count >= COMPLETION_TARGET:
			mark_completed(_correct_count)
			return
	else:
		feedback_label.text = "Wrong! It was " + _current_direction

	_pick_direction()


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
