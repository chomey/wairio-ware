extends MiniGameBase

## Copy Cat minigame.
## Watch a sequence of arrows, then reproduce it.
## Each successful sequence adds one more arrow.
## Score = number of sequences completed. Race to 5.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var sequence_label: Label = %SequenceLabel
@onready var status_label: Label = %StatusLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel
@onready var input_label: Label = %InputLabel

const COMPLETION_TARGET: int = 5
const STARTING_LENGTH: int = 2
const FLASH_TIME: float = 0.6
const PAUSE_TIME: float = 0.3

const DIRECTIONS: Array[String] = ["UP", "DOWN", "LEFT", "RIGHT"]
const ARROW_SYMBOLS: Dictionary = {
	"UP": "^",
	"DOWN": "v",
	"LEFT": "<",
	"RIGHT": ">",
}

var _sequences_completed: int = 0
var _current_sequence: Array[String] = []
var _player_input_index: int = 0
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
	sequence_label.text = ""
	status_label.text = ""
	feedback_label.text = ""
	input_label.text = ""
	score_label.text = "Sequences: 0 / " + str(COMPLETION_TARGET)

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
	_sequences_completed = 0
	score_label.text = "Sequences: 0 / " + str(COMPLETION_TARGET)
	_generate_and_show_sequence()


func _on_game_end() -> void:
	_phase = "waiting"
	feedback_label.text = "Time's up! You completed " + str(_sequences_completed) + " sequences!"
	submit_score(_sequences_completed)


func _generate_and_show_sequence() -> void:
	var length: int = STARTING_LENGTH + _sequences_completed
	_current_sequence.clear()
	for i: int in range(length):
		_current_sequence.append(DIRECTIONS[randi_range(0, DIRECTIONS.size() - 1)])
	_player_input_index = 0
	_phase = "showing"
	_show_index = 0
	status_label.text = "Watch carefully!"
	sequence_label.text = ""
	input_label.text = ""
	feedback_label.text = ""
	_show_next_arrow()


func _show_next_arrow() -> void:
	if _show_index >= _current_sequence.size():
		# Done showing, switch to input phase
		_phase = "input"
		_player_input_index = 0
		sequence_label.text = "? ? ?"
		status_label.text = "Your turn! Repeat the sequence."
		input_label.text = ""
		return

	sequence_label.text = ARROW_SYMBOLS[_current_sequence[_show_index]]
	_flash_timer.start()


func _on_flash_timer_timeout() -> void:
	sequence_label.text = ""
	_show_index += 1
	_pause_timer.start()


func _on_pause_timer_timeout() -> void:
	if _phase == "showing" and game_active:
		_show_next_arrow()


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _phase != "input":
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

	get_viewport().set_input_as_handled()

	var expected: String = _current_sequence[_player_input_index]
	if pressed_direction == expected:
		_player_input_index += 1
		# Build display of progress
		var progress: String = ""
		for i: int in range(_player_input_index):
			if progress.length() > 0:
				progress += " "
			progress += ARROW_SYMBOLS[_current_sequence[i]]
		input_label.text = progress
		feedback_label.text = "Correct!"

		if _player_input_index >= _current_sequence.size():
			# Sequence complete
			_sequences_completed += 1
			score_label.text = "Sequences: " + str(_sequences_completed) + " / " + str(COMPLETION_TARGET)
			feedback_label.text = "Sequence complete!"

			if _sequences_completed >= COMPLETION_TARGET:
				mark_completed(_sequences_completed)
				return

			# Short delay then next sequence
			_phase = "waiting"
			await get_tree().create_timer(0.5).timeout
			if game_active:
				_generate_and_show_sequence()
	else:
		feedback_label.text = "Wrong! Expected " + ARROW_SYMBOLS[expected] + ". Try again!"
		# Reset input for this sequence
		_player_input_index = 0
		input_label.text = ""


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
