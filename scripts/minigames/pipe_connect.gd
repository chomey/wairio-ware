extends MiniGameBase

## Pipe Connect minigame.
## A grid of pipe tiles that the player rotates by clicking.
## Connect the start (left) to the end (right) to solve each puzzle.
## Race to solve 5 puzzles.
## Score = number of puzzles solved within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var pipe_grid: GridContainer = %PipeGrid

const COMPLETION_TARGET: int = 5
const GRID_COLS: int = 5
const GRID_ROWS: int = 4
const GRID_SIZE: int = GRID_COLS * GRID_ROWS
const CELL_SIZE: Vector2 = Vector2(70, 70)

## Pipe types and their base connections (before rotation).
## Connections are bitmask: UP=1, RIGHT=2, DOWN=4, LEFT=8
const UP: int = 1
const RIGHT: int = 2
const DOWN: int = 4
const LEFT: int = 8

## Pipe shapes: straight (h/v), elbow (4 rotations), tee (4 rotations), cross
const PIPE_STRAIGHT_H: int = RIGHT | LEFT      # 10
const PIPE_STRAIGHT_V: int = UP | DOWN          # 5
const PIPE_ELBOW_UR: int = UP | RIGHT           # 3
const PIPE_ELBOW_RD: int = RIGHT | DOWN         # 6
const PIPE_ELBOW_DL: int = DOWN | LEFT          # 12
const PIPE_ELBOW_LU: int = LEFT | UP            # 9
const PIPE_TEE_URD: int = UP | RIGHT | DOWN     # 7
const PIPE_TEE_RDL: int = RIGHT | DOWN | LEFT   # 14
const PIPE_TEE_DLU: int = DOWN | LEFT | UP      # 13
const PIPE_TEE_LUR: int = LEFT | UP | RIGHT     # 11

## Tiles store their current connection mask
var _tiles: Array[int] = []
## The solution connections (for generating a valid puzzle)
var _solution: Array[int] = []
var _score: int = 0
## Start/end row
var _start_row: int = 0
var _end_row: int = 0

## Color constants
const COLOR_BG: Color = Color(0.15, 0.15, 0.2)
const COLOR_PIPE: Color = Color(0.3, 0.6, 0.8)
const COLOR_PIPE_CONNECTED: Color = Color(0.2, 0.9, 0.3)
const COLOR_CELL_BG: Color = Color(0.1, 0.1, 0.15)
const COLOR_START: Color = Color(0.2, 0.9, 0.3)
const COLOR_END: Color = Color(0.9, 0.3, 0.2)


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	instruction_label.text = "Get ready..."
	_update_score_display()
	pipe_grid.columns = GRID_COLS


func _on_game_start() -> void:
	_score = 0
	_update_score_display()
	instruction_label.text = "CLICK PIPES TO ROTATE! CONNECT START TO END!"
	countdown_label.visible = false
	_generate_puzzle()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_score)


func _generate_puzzle() -> void:
	_tiles.clear()
	_solution.clear()

	# Pick random start and end rows
	_start_row = randi() % GRID_ROWS
	_end_row = randi() % GRID_ROWS

	# Initialize all tiles to 0
	for i: int in range(GRID_SIZE):
		_solution.append(0)
		_tiles.append(0)

	# Generate a path from left column to right column using BFS-like random walk
	_generate_path()

	# Now randomize tile rotations (rotate each tile a random number of times)
	for i: int in range(GRID_SIZE):
		_tiles[i] = _solution[i]
		if _tiles[i] != 0:
			var rotations: int = randi() % 4
			for r: int in range(rotations):
				_tiles[i] = _rotate_cw(_tiles[i])

	# Make sure puzzle isn't already solved
	if _check_connected():
		# Rotate a random non-zero tile once more
		var non_zero: Array[int] = []
		for i: int in range(GRID_SIZE):
			if _tiles[i] != 0:
				non_zero.append(i)
		if non_zero.size() > 0:
			var idx: int = non_zero[randi() % non_zero.size()]
			_tiles[idx] = _rotate_cw(_tiles[idx])

	_rebuild_grid()


func _generate_path() -> void:
	## Generate a winding path from (0, _start_row) to (GRID_COLS-1, _end_row)
	var visited: Array[bool] = []
	for i: int in range(GRID_SIZE):
		visited.append(false)

	# Use a random walk with backtracking to create the path
	var path: Array[Vector2i] = []
	var current: Vector2i = Vector2i(0, _start_row)
	path.append(current)
	visited[current.y * GRID_COLS + current.x] = true
	var target: Vector2i = Vector2i(GRID_COLS - 1, _end_row)

	while current != target:
		var neighbors: Array[Vector2i] = _get_unvisited_neighbors(current, visited)

		if neighbors.size() == 0:
			# Backtrack
			if path.size() <= 1:
				# Restart entirely
				for i: int in range(GRID_SIZE):
					visited[i] = false
					_solution[i] = 0
				path.clear()
				current = Vector2i(0, _start_row)
				path.append(current)
				visited[current.y * GRID_COLS + current.x] = true
				continue
			path.pop_back()
			# Clear connections from current
			var ci: int = current.y * GRID_COLS + current.x
			_solution[ci] = 0
			current = path[path.size() - 1]
			continue

		# Prefer moving toward target
		var next: Vector2i = _pick_neighbor(neighbors, current, target)
		path.append(next)
		visited[next.y * GRID_COLS + next.x] = true

		# Set connections between current and next
		var dir_to_next: int = _direction_between(current, next)
		var dir_to_current: int = _direction_between(next, current)
		var ci: int = current.y * GRID_COLS + current.x
		var ni: int = next.y * GRID_COLS + next.x
		_solution[ci] = _solution[ci] | dir_to_next
		_solution[ni] = _solution[ni] | dir_to_current

		current = next

	# Add LEFT connection to start tile and RIGHT connection to end tile
	var start_idx: int = _start_row * GRID_COLS
	_solution[start_idx] = _solution[start_idx] | LEFT
	var end_idx: int = _end_row * GRID_COLS + (GRID_COLS - 1)
	_solution[end_idx] = _solution[end_idx] | RIGHT


func _get_unvisited_neighbors(pos: Vector2i, visited: Array[bool]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for d: Vector2i in dirs:
		var np: Vector2i = pos + d
		if np.x >= 0 and np.x < GRID_COLS and np.y >= 0 and np.y < GRID_ROWS:
			if not visited[np.y * GRID_COLS + np.x]:
				result.append(np)
	return result


func _pick_neighbor(neighbors: Array[Vector2i], current: Vector2i, target: Vector2i) -> Vector2i:
	# 60% chance to pick one that's closer to target, 40% random
	if randf() < 0.6:
		var best: Vector2i = neighbors[0]
		var best_dist: int = abs(best.x - target.x) + abs(best.y - target.y)
		for n: Vector2i in neighbors:
			var d: int = abs(n.x - target.x) + abs(n.y - target.y)
			if d < best_dist:
				best = n
				best_dist = d
		return best
	return neighbors[randi() % neighbors.size()]


func _direction_between(from: Vector2i, to: Vector2i) -> int:
	var diff: Vector2i = to - from
	if diff == Vector2i(1, 0):
		return RIGHT
	elif diff == Vector2i(-1, 0):
		return LEFT
	elif diff == Vector2i(0, -1):
		return UP
	elif diff == Vector2i(0, 1):
		return DOWN
	return 0


func _rotate_cw(connections: int) -> int:
	## Rotate connection bitmask 90 degrees clockwise
	## UP->RIGHT, RIGHT->DOWN, DOWN->LEFT, LEFT->UP
	var result: int = 0
	if connections & UP:
		result |= RIGHT
	if connections & RIGHT:
		result |= DOWN
	if connections & DOWN:
		result |= LEFT
	if connections & LEFT:
		result |= UP
	return result


func _rebuild_grid() -> void:
	for child: Node in pipe_grid.get_children():
		child.queue_free()

	for i: int in range(GRID_SIZE):
		var cell: Control = Control.new()
		cell.custom_minimum_size = CELL_SIZE
		cell.draw.connect(_draw_pipe_cell.bind(cell, i))

		var btn: Button = Button.new()
		btn.custom_minimum_size = CELL_SIZE
		btn.flat = true
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx: int = i
		btn.pressed.connect(_on_tile_clicked.bind(idx))
		# Make button transparent so we see the custom draw behind it
		var stylebox: StyleBoxEmpty = StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", stylebox)
		btn.add_theme_stylebox_override("hover", stylebox)
		btn.add_theme_stylebox_override("pressed", stylebox)
		btn.add_theme_stylebox_override("focus", stylebox)

		cell.add_child(btn)
		pipe_grid.add_child(cell)


func _draw_pipe_cell(cell: Control, index: int) -> void:
	var size: Vector2 = CELL_SIZE
	var center: Vector2 = size / 2.0
	var pipe_width: float = 14.0
	var half_w: float = pipe_width / 2.0

	# Background
	cell.draw_rect(Rect2(Vector2.ZERO, size), COLOR_CELL_BG)

	# Draw border
	cell.draw_rect(Rect2(Vector2.ZERO, size), Color(0.25, 0.25, 0.3), false, 1.0)

	var connections: int = _tiles[index]
	if connections == 0:
		return

	# Check if this tile is part of the connected path
	var connected: bool = _is_tile_connected_to_start(index)
	var pipe_color: Color = COLOR_PIPE_CONNECTED if connected else COLOR_PIPE

	# Draw pipe segments from center to each connected edge
	if connections & UP:
		cell.draw_rect(Rect2(center.x - half_w, 0, pipe_width, center.y + half_w), pipe_color)
	if connections & DOWN:
		cell.draw_rect(Rect2(center.x - half_w, center.y - half_w, pipe_width, center.y + half_w), pipe_color)
	if connections & LEFT:
		cell.draw_rect(Rect2(0, center.y - half_w, center.x + half_w, pipe_width), pipe_color)
	if connections & RIGHT:
		cell.draw_rect(Rect2(center.x - half_w, center.y - half_w, center.x + half_w, pipe_width), pipe_color)

	# Draw center node
	cell.draw_rect(Rect2(center.x - half_w, center.y - half_w, pipe_width, pipe_width), pipe_color)

	# Draw start/end indicators
	var col: int = index % GRID_COLS
	var row: int = index / GRID_COLS
	if col == 0 and row == _start_row:
		cell.draw_rect(Rect2(0, center.y - 8, 6, 16), COLOR_START)
	if col == GRID_COLS - 1 and row == _end_row:
		cell.draw_rect(Rect2(size.x - 6, center.y - 8, 6, 16), COLOR_END)


func _is_tile_connected_to_start(target_index: int) -> bool:
	## BFS from start tile to see if target_index is reachable through connected pipes
	var start_idx: int = _start_row * GRID_COLS
	if _tiles[start_idx] == 0:
		return false

	var visited: Array[bool] = []
	for i: int in range(GRID_SIZE):
		visited.append(false)

	var queue: Array[int] = [start_idx]
	visited[start_idx] = true

	while queue.size() > 0:
		var current: int = queue.pop_front()
		if current == target_index:
			return true

		var cx: int = current % GRID_COLS
		var cy: int = current / GRID_COLS
		var conns: int = _tiles[current]

		# Check each direction
		if conns & UP and cy > 0:
			var neighbor: int = (cy - 1) * GRID_COLS + cx
			if not visited[neighbor] and (_tiles[neighbor] & DOWN):
				visited[neighbor] = true
				queue.append(neighbor)
		if conns & DOWN and cy < GRID_ROWS - 1:
			var neighbor: int = (cy + 1) * GRID_COLS + cx
			if not visited[neighbor] and (_tiles[neighbor] & UP):
				visited[neighbor] = true
				queue.append(neighbor)
		if conns & LEFT and cx > 0:
			var neighbor: int = cy * GRID_COLS + (cx - 1)
			if not visited[neighbor] and (_tiles[neighbor] & RIGHT):
				visited[neighbor] = true
				queue.append(neighbor)
		if conns & RIGHT and cx < GRID_COLS - 1:
			var neighbor: int = cy * GRID_COLS + (cx + 1)
			if not visited[neighbor] and (_tiles[neighbor] & LEFT):
				visited[neighbor] = true
				queue.append(neighbor)

	return false


func _check_connected() -> bool:
	## Check if start (left, _start_row) connects to end (right, _end_row) through matching pipes
	var start_idx: int = _start_row * GRID_COLS
	var end_idx: int = _end_row * GRID_COLS + (GRID_COLS - 1)

	# Start must have LEFT connection, end must have RIGHT connection
	if not (_tiles[start_idx] & LEFT):
		return false
	if not (_tiles[end_idx] & RIGHT):
		return false

	return _is_tile_connected_to_start(end_idx)


func _on_tile_clicked(index: int) -> void:
	if not game_active:
		return

	if _tiles[index] == 0:
		return

	# Rotate the tile clockwise
	_tiles[index] = _rotate_cw(_tiles[index])

	# Redraw all cells
	_redraw_all()

	# Check if puzzle is solved
	if _check_connected():
		_score += 1
		_update_score_display()
		if _score >= COMPLETION_TARGET:
			mark_completed(_score)
			return
		_generate_puzzle()


func _redraw_all() -> void:
	var children: Array[Node] = pipe_grid.get_children()
	for child: Node in children:
		if child is Control:
			(child as Control).queue_redraw()


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
