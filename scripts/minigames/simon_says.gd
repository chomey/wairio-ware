extends MiniGameBase

## Simon Says minigame.
## Colored panels flash in a sequence. Repeat the sequence using arrow keys.
## Each round adds one more step. Race to complete 10 rounds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var status_label: Label = %StatusLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel
@onready var panel_up: ColorRect = %PanelUp
@onready var panel_down: ColorRect = %PanelDown
@onready var panel_left: ColorRect = %PanelLeft
@onready var panel_right: ColorRect = %PanelRight

const COMPLETION_TARGET: int = 10
const STARTING_LENGTH: int = 2
const FLASH_TIME: float = 0.5
const PAUSE_TIME: float = 0.25

const DIRECTIONS: Array[String] = ["UP", "DOWN", "LEFT", "RIGHT"]

const DIM_COLORS: Dictionary = {
	"UP": Color(0.2, 0.2, 0.5, 1),
	"DOWN": Color(0.2, 0.5, 0.2, 1),
	"LEFT": Color(0.5, 0.2, 0.2, 1),
	"RIGHT": Color(0.5, 0.5, 0.2, 1),
}

const BRIGHT_COLORS: Dictionary = {
	"UP": Color(0.4, 0.4, 1.0, 1),
	"DOWN": Color(0.4, 1.0, 0.4, 1),
	"LEFT": Color(1.0, 0.4, 0.4, 1),
	"RIGHT": Color(1.0, 1.0, 0.4, 1),
}

var _sequences_completed: int = 0
var _current_sequence: Array[String] = []
var _player_input_index: int = 0
var _phase: String = "waiting"  # "waiting", "showing", "input"
var _show_index: int = 0
var _flash_timer: Timer = null
var _pause_timer: Timer = null
var _input_flash_timer: Timer = null


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	status_label.text = ""
	feedback_label.text = ""
	score_label.text = "Rounds: 0 / " + str(COMPLETION_TARGET)
	_dim_all_panels()

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

	_input_flash_timer = Timer.new()
	_input_flash_timer.wait_time = 0.2
	_input_flash_timer.one_shot = true
	_input_flash_timer.timeout.connect(_dim_all_panels)
	add_child(_input_flash_timer)


func _on_game_start() -> void:
	countdown_label.visible = false
	_sequences_completed = 0
	score_label.text = "Rounds: 0 / " + str(COMPLETION_TARGET)
	_generate_and_show_sequence()


func _on_game_end() -> void:
	_phase = "waiting"
	feedback_label.text = "Time's up! " + str(_sequences_completed) + " rounds completed!"
	submit_score(_sequences_completed)


func _dim_all_panels() -> void:
	panel_up.color = DIM_COLORS["UP"]
	panel_down.color = DIM_COLORS["DOWN"]
	panel_left.color = DIM_COLORS["LEFT"]
	panel_right.color = DIM_COLORS["RIGHT"]


func _flash_panel(direction: String) -> void:
	_dim_all_panels()
	var panel: ColorRect = _get_panel(direction)
	panel.color = BRIGHT_COLORS[direction]


func _get_panel(direction: String) -> ColorRect:
	match direction:
		"UP":
			return panel_up
		"DOWN":
			return panel_down
		"LEFT":
			return panel_left
		"RIGHT":
			return panel_right
	return panel_up


func _generate_and_show_sequence() -> void:
	var length: int = STARTING_LENGTH + _sequences_completed
	_current_sequence.clear()
	for i: int in range(length):
		_current_sequence.append(DIRECTIONS[randi_range(0, DIRECTIONS.size() - 1)])
	_player_input_index = 0
	_phase = "showing"
	_show_index = 0
	status_label.text = "Watch the pattern!"
	feedback_label.text = ""
	_dim_all_panels()
	_show_next_panel()


func _show_next_panel() -> void:
	if _show_index >= _current_sequence.size():
		_dim_all_panels()
		_phase = "input"
		_player_input_index = 0
		status_label.text = "Your turn! Repeat with arrow keys."
		return

	_flash_panel(_current_sequence[_show_index])
	_flash_timer.start()


func _on_flash_timer_timeout() -> void:
	_dim_all_panels()
	_show_index += 1
	_pause_timer.start()


func _on_pause_timer_timeout() -> void:
	if _phase == "showing" and game_active:
		_show_next_panel()


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

	# Flash the pressed panel briefly
	_flash_panel(pressed_direction)
	_input_flash_timer.start()

	var expected: String = _current_sequence[_player_input_index]
	if pressed_direction == expected:
		_player_input_index += 1
		feedback_label.text = str(_player_input_index) + " / " + str(_current_sequence.size())

		if _player_input_index >= _current_sequence.size():
			_sequences_completed += 1
			score_label.text = "Rounds: " + str(_sequences_completed) + " / " + str(COMPLETION_TARGET)
			feedback_label.text = "Round complete!"

			if _sequences_completed >= COMPLETION_TARGET:
				mark_completed(_sequences_completed)
				return

			_phase = "waiting"
			await get_tree().create_timer(0.5).timeout
			if game_active:
				_generate_and_show_sequence()
	else:
		feedback_label.text = "Wrong! Sequence reset."
		_player_input_index = 0


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
