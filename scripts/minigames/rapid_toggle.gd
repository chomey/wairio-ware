extends MiniGameBase

## Rapid Toggle minigame.
## A 4x4 grid of dark squares. Clicking a cell toggles it and its
## orthogonal neighbors (Lights Out style). Light all 16 to clear the round.
## Each cleared round generates a new puzzle.
## Race to clear 3 puzzles.
## Score = number of puzzles cleared within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var toggle_grid: GridContainer = %ToggleGrid

const COMPLETION_TARGET: int = 3
const GRID_COLS: int = 4
const GRID_ROWS: int = 4
const GRID_SIZE: int = GRID_COLS * GRID_ROWS
const CELL_SIZE: Vector2 = Vector2(70, 70)

const COLOR_OFF: Color = Color(0.15, 0.15, 0.2)
const COLOR_ON: Color = Color(0.3, 0.85, 0.9)

var _score: int = 0
var _cells: Array[bool] = []


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	instruction_label.text = "Get ready..."
	_update_score_display()
	toggle_grid.columns = GRID_COLS


func _on_game_start() -> void:
	_score = 0
	_update_score_display()
	instruction_label.text = "CLICK TO TOGGLE! LIGHT ALL CELLS!"
	countdown_label.visible = false
	_generate_puzzle()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_score)


func _generate_puzzle() -> void:
	_cells.clear()
	for i: int in range(GRID_SIZE):
		_cells.append(false)

	# Randomly toggle 4-8 cells (using toggle logic) to create a solvable puzzle
	var toggle_count: int = 4 + randi() % 5
	var indices: Array[int] = []
	for i: int in range(GRID_SIZE):
		indices.append(i)
	indices.shuffle()
	for i: int in range(toggle_count):
		_apply_toggle(indices[i])

	# If all cells ended up lit, toggle one more to ensure puzzle isn't already solved
	if _check_all_lit():
		_apply_toggle(randi() % GRID_SIZE)

	_rebuild_grid()


func _apply_toggle(index: int) -> void:
	var row: int = index / GRID_COLS
	var col: int = index % GRID_COLS

	_cells[index] = not _cells[index]

	# Toggle up
	if row > 0:
		_cells[index - GRID_COLS] = not _cells[index - GRID_COLS]
	# Toggle down
	if row < GRID_ROWS - 1:
		_cells[index + GRID_COLS] = not _cells[index + GRID_COLS]
	# Toggle left
	if col > 0:
		_cells[index - 1] = not _cells[index - 1]
	# Toggle right
	if col < GRID_COLS - 1:
		_cells[index + 1] = not _cells[index + 1]


func _check_all_lit() -> bool:
	for state: bool in _cells:
		if not state:
			return false
	return true


func _rebuild_grid() -> void:
	for child: Node in toggle_grid.get_children():
		child.queue_free()

	for i: int in range(GRID_SIZE):
		var btn: Button = Button.new()
		btn.custom_minimum_size = CELL_SIZE
		_apply_cell_style(btn, i)
		var idx: int = i
		btn.pressed.connect(_on_cell_clicked.bind(idx))
		toggle_grid.add_child(btn)


func _apply_cell_style(btn: Button, index: int) -> void:
	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	if _cells[index]:
		stylebox.bg_color = COLOR_ON
	else:
		stylebox.bg_color = COLOR_OFF
	stylebox.corner_radius_top_left = 4
	stylebox.corner_radius_top_right = 4
	stylebox.corner_radius_bottom_left = 4
	stylebox.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", stylebox)
	btn.add_theme_stylebox_override("hover", stylebox)
	btn.add_theme_stylebox_override("pressed", stylebox)
	btn.add_theme_stylebox_override("focus", stylebox)


func _on_cell_clicked(index: int) -> void:
	if not game_active:
		return

	_apply_toggle(index)
	_update_all_cell_styles()

	if _check_all_lit():
		_score += 1
		_update_score_display()
		if _score >= COMPLETION_TARGET:
			mark_completed(_score)
			return
		_generate_puzzle()


func _update_all_cell_styles() -> void:
	var buttons: Array[Node] = toggle_grid.get_children()
	for i: int in range(buttons.size()):
		var btn: Button = buttons[i] as Button
		if btn != null:
			_apply_cell_style(btn, i)


func _update_score_display() -> void:
	score_label.text = "Solved: " + str(_score) + " / " + str(COMPLETION_TARGET)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
