extends MiniGameBase

## Minefield minigame (Survival).
## Grid of cells, click to reveal safe/mine. Clear a path across the grid.
## Hit mine = eliminated.
## Score = survival time in tenths of seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const GRID_COLS: int = 8
const GRID_ROWS: int = 6
const MINE_RATIO: float = 0.20  # 20% of cells are mines
const CELL_SIZE: float = 50.0
const CELL_GAP: float = 4.0

const COLOR_HIDDEN: Color = Color(0.35, 0.35, 0.45, 1.0)
const COLOR_SAFE: Color = Color(0.3, 0.8, 0.4, 1.0)
const COLOR_MINE: Color = Color(0.9, 0.2, 0.2, 1.0)
const COLOR_FLAG: Color = Color(0.9, 0.8, 0.2, 1.0)
const COLOR_PATH: Color = Color(0.2, 0.6, 0.9, 1.0)
const BG_COLOR: Color = Color(0.15, 0.2, 0.15, 1.0)

var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _grid: Array[Array] = []  # 2D array: 0 = safe, 1 = mine
var _revealed: Array[Array] = []  # 2D array: false = hidden, true = revealed
var _cell_buttons: Array[Array] = []  # 2D array of Button nodes
var _bg_node: ColorRect = null
var _grid_container: Control = null
var _paths_cleared: int = 0
var _adjacent_mines_cache: Array[Array] = []  # cached adjacent mine counts


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	_update_score_display()
	instruction_label.text = "Get ready..."


func _on_game_start() -> void:
	_score = 0
	_elapsed_time = 0.0
	_eliminated = false
	_paths_cleared = 0
	_update_score_display()
	instruction_label.text = "Click cells to reveal! Avoid mines! Clear a path left to right!"
	countdown_label.visible = false

	_create_grid()


func _create_grid() -> void:
	# Clear old nodes
	if is_instance_valid(_bg_node):
		_bg_node.queue_free()
	if is_instance_valid(_grid_container):
		_grid_container.queue_free()
	_cell_buttons.clear()
	_grid.clear()
	_revealed.clear()
	_adjacent_mines_cache.clear()

	var area_w: float = play_area.size.x
	var area_h: float = play_area.size.y

	# Background
	_bg_node = ColorRect.new()
	_bg_node.position = Vector2.ZERO
	_bg_node.size = Vector2(area_w, area_h)
	_bg_node.color = BG_COLOR
	play_area.add_child(_bg_node)

	# Grid container
	_grid_container = Control.new()
	var grid_w: float = float(GRID_COLS) * (CELL_SIZE + CELL_GAP) - CELL_GAP
	var grid_h: float = float(GRID_ROWS) * (CELL_SIZE + CELL_GAP) - CELL_GAP
	var offset_x: float = (area_w - grid_w) / 2.0
	var offset_y: float = (area_h - grid_h) / 2.0
	_grid_container.position = Vector2(offset_x, offset_y)
	_grid_container.size = Vector2(grid_w, grid_h)
	play_area.add_child(_grid_container)

	# Generate mines ensuring a safe path exists
	_generate_minefield()

	# Cache adjacent mine counts
	for row: int in range(GRID_ROWS):
		var row_cache: Array = []
		for col: int in range(GRID_COLS):
			row_cache.append(_count_adjacent_mines(row, col))
		_adjacent_mines_cache.append(row_cache)

	# Create buttons
	for row: int in range(GRID_ROWS):
		var button_row: Array = []
		for col: int in range(GRID_COLS):
			var btn: Button = Button.new()
			btn.position = Vector2(
				float(col) * (CELL_SIZE + CELL_GAP),
				float(row) * (CELL_SIZE + CELL_GAP)
			)
			btn.size = Vector2(CELL_SIZE, CELL_SIZE)
			btn.text = ""
			btn.add_theme_color_override("font_color", Color.WHITE)
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = COLOR_HIDDEN
			style.set_corner_radius_all(4)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style.duplicate())
			btn.add_theme_stylebox_override("pressed", style.duplicate())
			btn.add_theme_stylebox_override("focus", style.duplicate())
			var r: int = row
			var c: int = col
			btn.pressed.connect(_on_cell_pressed.bind(r, c))
			_grid_container.add_child(btn)
			button_row.append(btn)
		_cell_buttons.append(button_row)


func _generate_minefield() -> void:
	# Initialize empty grid
	_grid.clear()
	_revealed.clear()
	for row: int in range(GRID_ROWS):
		var grid_row: Array = []
		var revealed_row: Array = []
		for col: int in range(GRID_COLS):
			grid_row.append(0)
			revealed_row.append(false)
		_grid.append(grid_row)
		_revealed.append(revealed_row)

	# First generate a guaranteed safe path from left to right
	var safe_path: Array[Vector2i] = []
	var current_row: int = randi_range(0, GRID_ROWS - 1)
	safe_path.append(Vector2i(current_row, 0))
	for col: int in range(1, GRID_COLS):
		# Can go straight, up, or down
		var possible_rows: Array[int] = [current_row]
		if current_row > 0:
			possible_rows.append(current_row - 1)
		if current_row < GRID_ROWS - 1:
			possible_rows.append(current_row + 1)
		current_row = possible_rows[randi_range(0, possible_rows.size() - 1)]
		safe_path.append(Vector2i(current_row, col))

	# Place mines randomly, avoiding the safe path
	var total_cells: int = GRID_COLS * GRID_ROWS
	var mine_count: int = int(float(total_cells) * MINE_RATIO)

	var mines_placed: int = 0
	var attempts: int = 0
	while mines_placed < mine_count and attempts < 1000:
		attempts += 1
		var r: int = randi_range(0, GRID_ROWS - 1)
		var c: int = randi_range(0, GRID_COLS - 1)
		# Skip if already a mine
		if _grid[r][c] == 1:
			continue
		# Skip if on the safe path
		var on_path: bool = false
		for p: Vector2i in safe_path:
			if p.x == r and p.y == c:
				on_path = true
				break
		if on_path:
			continue
		_grid[r][c] = 1
		mines_placed += 1


func _count_adjacent_mines(row: int, col: int) -> int:
	var count: int = 0
	for dr: int in range(-1, 2):
		for dc: int in range(-1, 2):
			if dr == 0 and dc == 0:
				continue
			var nr: int = row + dr
			var nc: int = col + dc
			if nr >= 0 and nr < GRID_ROWS and nc >= 0 and nc < GRID_COLS:
				count += _grid[nr][nc]
	return count


func _on_cell_pressed(row: int, col: int) -> void:
	if not game_active or _eliminated:
		return
	if _revealed[row][col]:
		return

	_revealed[row][col] = true

	if _grid[row][col] == 1:
		# Hit a mine!
		_eliminated = true
		_reveal_cell_visual(row, col)
		_reveal_all_mines()
		instruction_label.text = "BOOM! You hit a mine!"
		mark_completed(_score)
		return

	# Safe cell
	_reveal_cell_visual(row, col)

	# Auto-reveal adjacent cells with 0 adjacent mines
	var adjacent: int = _adjacent_mines_cache[row][col]
	if adjacent == 0:
		_flood_reveal(row, col)

	# Check if path from left to right is cleared
	if _check_path_cleared():
		_paths_cleared += 1
		instruction_label.text = "Path cleared! New field... (" + str(_paths_cleared) + " cleared)"
		# Generate a new grid
		_reset_grid_for_new_field()


func _reveal_cell_visual(row: int, col: int) -> void:
	if row >= _cell_buttons.size() or col >= _cell_buttons[row].size():
		return
	var btn: Button = _cell_buttons[row][col] as Button
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.set_corner_radius_all(4)

	if _grid[row][col] == 1:
		style.bg_color = COLOR_MINE
		btn.text = "X"
	else:
		var adjacent: int = _adjacent_mines_cache[row][col]
		style.bg_color = COLOR_SAFE
		if adjacent > 0:
			btn.text = str(adjacent)
		else:
			btn.text = ""
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)
	btn.disabled = true


func _flood_reveal(start_row: int, start_col: int) -> void:
	var stack: Array[Vector2i] = [Vector2i(start_row, start_col)]
	while stack.size() > 0:
		var cell: Vector2i = stack.pop_back()
		var r: int = cell.x
		var c: int = cell.y
		for dr: int in range(-1, 2):
			for dc: int in range(-1, 2):
				if dr == 0 and dc == 0:
					continue
				var nr: int = r + dr
				var nc: int = c + dc
				if nr >= 0 and nr < GRID_ROWS and nc >= 0 and nc < GRID_COLS:
					if not _revealed[nr][nc] and _grid[nr][nc] == 0:
						_revealed[nr][nc] = true
						_reveal_cell_visual(nr, nc)
						if _adjacent_mines_cache[nr][nc] == 0:
							stack.append(Vector2i(nr, nc))


func _reveal_all_mines() -> void:
	for row: int in range(GRID_ROWS):
		for col: int in range(GRID_COLS):
			if _grid[row][col] == 1 and not _revealed[row][col]:
				_revealed[row][col] = true
				_reveal_cell_visual(row, col)


func _check_path_cleared() -> bool:
	# BFS from any revealed cell in column 0 to any revealed cell in last column
	var visited: Array[Array] = []
	for row: int in range(GRID_ROWS):
		var row_arr: Array = []
		for col: int in range(GRID_COLS):
			row_arr.append(false)
		visited.append(row_arr)

	var queue: Array[Vector2i] = []
	# Start from revealed cells in first column
	for row: int in range(GRID_ROWS):
		if _revealed[row][0] and _grid[row][0] == 0:
			queue.append(Vector2i(row, 0))
			visited[row][0] = true

	if queue.size() == 0:
		return false

	while queue.size() > 0:
		var cell: Vector2i = queue.pop_front()
		var r: int = cell.x
		var c: int = cell.y

		if c == GRID_COLS - 1:
			return true

		# Check 4-directional neighbors (not diagonal for path)
		var directions: Array[Vector2i] = [
			Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)
		]
		for d: Vector2i in directions:
			var nr: int = r + d.x
			var nc: int = c + d.y
			if nr >= 0 and nr < GRID_ROWS and nc >= 0 and nc < GRID_COLS:
				if not visited[nr][nc] and _revealed[nr][nc] and _grid[nr][nc] == 0:
					visited[nr][nc] = true
					queue.append(Vector2i(nr, nc))

	return false


func _reset_grid_for_new_field() -> void:
	# Remove old buttons
	if is_instance_valid(_grid_container):
		for child: Node in _grid_container.get_children():
			child.queue_free()
	_cell_buttons.clear()
	_adjacent_mines_cache.clear()

	# Generate new field
	_generate_minefield()

	# Cache adjacent mine counts
	for row: int in range(GRID_ROWS):
		var row_cache: Array = []
		for col: int in range(GRID_COLS):
			row_cache.append(_count_adjacent_mines(row, col))
		_adjacent_mines_cache.append(row_cache)

	# Create new buttons
	for row: int in range(GRID_ROWS):
		var button_row: Array = []
		for col: int in range(GRID_COLS):
			var btn: Button = Button.new()
			btn.position = Vector2(
				float(col) * (CELL_SIZE + CELL_GAP),
				float(row) * (CELL_SIZE + CELL_GAP)
			)
			btn.size = Vector2(CELL_SIZE, CELL_SIZE)
			btn.text = ""
			btn.add_theme_color_override("font_color", Color.WHITE)
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = COLOR_HIDDEN
			style.set_corner_radius_all(4)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style.duplicate())
			btn.add_theme_stylebox_override("pressed", style.duplicate())
			btn.add_theme_stylebox_override("focus", style.duplicate())
			var r: int = row
			var c: int = col
			btn.pressed.connect(_on_cell_pressed.bind(r, c))
			_grid_container.add_child(btn)
			button_row.append(btn)
		_cell_buttons.append(button_row)


func _process(delta: float) -> void:
	if not game_active or _eliminated:
		return
	_elapsed_time += delta
	_score = int(_elapsed_time * 10.0)
	_update_score_display()


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! You survived! Cleared " + str(_paths_cleared) + " fields."
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Time: " + str(_score / 10.0) + "s"


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
