extends MiniGameBase

## Whack-a-Mole minigame.
## Colored squares pop up randomly in a 4x4 grid.
## Click them before they disappear. Race to 20 hits.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var status_label: Label = %StatusLabel
@onready var grid_container: GridContainer = %GridContainer

const COMPLETION_TARGET: int = 20
const GRID_SIZE: int = 4
const MOLE_SHOW_TIME: float = 1.2
const SPAWN_INTERVAL: float = 0.6
const MAX_ACTIVE: int = 3

var _score: int = 0
var _cells: Array[Button] = []
var _active_moles: Dictionary = {}  # cell_index -> time_remaining
var _spawn_timer: float = 0.0


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	status_label.text = ""
	score_label.text = "Whacked: 0 / " + str(COMPLETION_TARGET)
	_build_grid()


func _build_grid() -> void:
	for i: int in range(GRID_SIZE * GRID_SIZE):
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.text = ""
		btn.pressed.connect(_on_cell_pressed.bind(i))
		grid_container.add_child(btn)
		_cells.append(btn)
	_reset_all_cells()


func _reset_all_cells() -> void:
	for i: int in range(_cells.size()):
		_set_cell_inactive(i)


func _set_cell_inactive(index: int) -> void:
	var btn: Button = _cells[index]
	btn.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	btn.text = ""
	btn.modulate = Color(0.3, 0.3, 0.3, 1)


func _set_cell_active(index: int) -> void:
	var btn: Button = _cells[index]
	btn.text = "!"
	btn.modulate = Color(0.2, 0.8, 0.2, 1)


func _on_game_start() -> void:
	countdown_label.visible = false
	_score = 0
	_active_moles.clear()
	_spawn_timer = 0.0
	score_label.text = "Whacked: 0 / " + str(COMPLETION_TARGET)
	status_label.text = "Click the moles!"
	_reset_all_cells()
	_spawn_mole()


func _on_game_end() -> void:
	status_label.text = "Time's up! Whacked " + str(_score) + "!"
	_active_moles.clear()
	_reset_all_cells()
	submit_score(_score)


func _process(delta: float) -> void:
	if not game_active:
		return

	# Update mole timers
	var expired: Array[int] = []
	for idx: int in _active_moles:
		_active_moles[idx] = (_active_moles[idx] as float) - delta
		if (_active_moles[idx] as float) <= 0.0:
			expired.append(idx)

	for idx: int in expired:
		_active_moles.erase(idx)
		_set_cell_inactive(idx)

	# Spawn new moles
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL and _active_moles.size() < MAX_ACTIVE:
		_spawn_timer = 0.0
		_spawn_mole()


func _spawn_mole() -> void:
	# Find an inactive cell
	var inactive: Array[int] = []
	for i: int in range(_cells.size()):
		if not _active_moles.has(i):
			inactive.append(i)

	if inactive.is_empty():
		return

	var idx: int = inactive[randi_range(0, inactive.size() - 1)]
	_active_moles[idx] = MOLE_SHOW_TIME
	_set_cell_active(idx)


func _on_cell_pressed(index: int) -> void:
	if not game_active:
		return
	if not _active_moles.has(index):
		return

	_active_moles.erase(index)
	_set_cell_inactive(index)
	_score += 1
	score_label.text = "Whacked: " + str(_score) + " / " + str(COMPLETION_TARGET)

	if _score >= COMPLETION_TARGET:
		mark_completed(_score)
		return


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
