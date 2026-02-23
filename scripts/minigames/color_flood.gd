extends MiniGameBase

## Color Flood minigame.
## Fill a grid by selecting colors to expand from the top-left corner.
## All connected same-color cells from the origin adopt the new color.
## Race to clear 5 boards (make entire grid one color).
## Score = number of boards cleared within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var grid_container: GridContainer = %GridContainer
@onready var color_buttons_container: HBoxContainer = %ColorButtonsContainer
@onready var moves_label: Label = %MovesLabel

const COMPLETION_TARGET: int = 5
const GRID_COLS: int = 8
const GRID_ROWS: int = 8
const GRID_SIZE: int = GRID_COLS * GRID_ROWS
const NUM_COLORS: int = 5

const FLOOD_COLORS: Array[Color] = [
	Color(0.9, 0.2, 0.2),   # Red
	Color(0.2, 0.7, 0.2),   # Green
	Color(0.2, 0.4, 0.9),   # Blue
	Color(0.9, 0.8, 0.1),   # Yellow
	Color(0.8, 0.3, 0.8),   # Purple
]

const COLOR_NAMES: Array[String] = ["R", "G", "B", "Y", "P"]

var _score: int = 0
var _moves: int = 0
## Grid state: array of color indices (0 to NUM_COLORS-1)
var _grid: Array[int] = []
## Color buttons
var _color_btns: Array[Button] = []


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	instruction_label.text = "Get ready..."
	_update_score_display()
	grid_container.columns = GRID_COLS
	_create_color_buttons()


func _on_game_start() -> void:
	_score = 0
	_update_score_display()
	instruction_label.text = "Pick colors to flood from top-left!"
	countdown_label.visible = false
	_generate_board()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_score)


func _create_color_buttons() -> void:
	_color_btns.clear()
	for i: int in range(NUM_COLORS):
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(60, 50)
		btn.text = COLOR_NAMES[i]
		var stylebox: StyleBoxFlat = StyleBoxFlat.new()
		stylebox.bg_color = FLOOD_COLORS[i]
		stylebox.corner_radius_top_left = 6
		stylebox.corner_radius_top_right = 6
		stylebox.corner_radius_bottom_left = 6
		stylebox.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("normal", stylebox)
		btn.add_theme_stylebox_override("hover", stylebox)
		btn.add_theme_stylebox_override("pressed", stylebox)
		btn.add_theme_stylebox_override("focus", stylebox)
		btn.add_theme_font_size_override("font_size", 20)
		var idx: int = i
		btn.pressed.connect(_on_color_selected.bind(idx))
		color_buttons_container.add_child(btn)
		_color_btns.append(btn)


func _generate_board() -> void:
	_moves = 0
	_update_moves_display()
	_grid.clear()
	for i: int in range(GRID_SIZE):
		_grid.append(randi() % NUM_COLORS)
	# Ensure at least 2 colors present so it's not already solved
	var first_color: int = _grid[0]
	var all_same: bool = true
	for i: int in range(1, GRID_SIZE):
		if _grid[i] != first_color:
			all_same = false
			break
	if all_same:
		# Force a different color somewhere
		_grid[GRID_SIZE - 1] = (first_color + 1) % NUM_COLORS
	_refresh_grid_display()


func _refresh_grid_display() -> void:
	# Clear old cells
	for child: Node in grid_container.get_children():
		child.queue_free()
	# Build grid cells
	for i: int in range(GRID_SIZE):
		var panel: Panel = Panel.new()
		panel.custom_minimum_size = Vector2(40, 40)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var stylebox: StyleBoxFlat = StyleBoxFlat.new()
		stylebox.bg_color = FLOOD_COLORS[_grid[i]]
		stylebox.corner_radius_top_left = 2
		stylebox.corner_radius_top_right = 2
		stylebox.corner_radius_bottom_left = 2
		stylebox.corner_radius_bottom_right = 2
		panel.add_theme_stylebox_override("panel", stylebox)
		grid_container.add_child(panel)


func _on_color_selected(color_idx: int) -> void:
	if not game_active:
		return
	var current_color: int = _grid[0]
	# Ignore if selecting the same color as the origin
	if color_idx == current_color:
		return
	_flood_fill(color_idx)
	_moves += 1
	_update_moves_display()
	_refresh_grid_display()
	# Check if board is fully one color
	if _check_board_cleared():
		_score += 1
		_update_score_display()
		if _score >= COMPLETION_TARGET:
			mark_completed(_score)
			return
		_generate_board()


func _flood_fill(new_color: int) -> void:
	var old_color: int = _grid[0]
	if old_color == new_color:
		return
	# BFS from top-left corner
	var visited: Array[bool] = []
	for i: int in range(GRID_SIZE):
		visited.append(false)
	var queue: Array[int] = [0]
	visited[0] = true
	while queue.size() > 0:
		var cell: int = queue[0]
		queue.remove_at(0)
		_grid[cell] = new_color
		# Check neighbors
		var row: int = cell / GRID_COLS
		var col: int = cell % GRID_COLS
		# Up
		if row > 0:
			var neighbor: int = (row - 1) * GRID_COLS + col
			if not visited[neighbor] and _grid[neighbor] == old_color:
				visited[neighbor] = true
				queue.append(neighbor)
		# Down
		if row < GRID_ROWS - 1:
			var neighbor: int = (row + 1) * GRID_COLS + col
			if not visited[neighbor] and _grid[neighbor] == old_color:
				visited[neighbor] = true
				queue.append(neighbor)
		# Left
		if col > 0:
			var neighbor: int = row * GRID_COLS + (col - 1)
			if not visited[neighbor] and _grid[neighbor] == old_color:
				visited[neighbor] = true
				queue.append(neighbor)
		# Right
		if col < GRID_COLS - 1:
			var neighbor: int = row * GRID_COLS + (col + 1)
			if not visited[neighbor] and _grid[neighbor] == old_color:
				visited[neighbor] = true
				queue.append(neighbor)


func _check_board_cleared() -> bool:
	var first_color: int = _grid[0]
	for i: int in range(1, GRID_SIZE):
		if _grid[i] != first_color:
			return false
	return true


func _update_score_display() -> void:
	score_label.text = "Boards: " + str(_score) + "/" + str(COMPLETION_TARGET)


func _update_moves_display() -> void:
	moves_label.text = "Moves: " + str(_moves)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
