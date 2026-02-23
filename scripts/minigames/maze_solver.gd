extends MiniGameBase

## Maze Solver minigame.
## Navigate a grid maze with arrow keys from start to exit.
## Score = number of mazes solved. Race to 3.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel
@onready var maze_container: Control = %MazeContainer

const COMPLETION_TARGET: int = 3

## Maze dimensions (must be odd for wall/path grid)
const MAZE_COLS: int = 11
const MAZE_ROWS: int = 11

## Cell size in pixels
const CELL_SIZE: int = 40

## Maze grid: true = passable, false = wall
var _maze: Array = []

## Player position in grid coords
var _player_row: int = 1
var _player_col: int = 1

## Exit position in grid coords
var _exit_row: int = MAZE_ROWS - 2
var _exit_col: int = MAZE_COLS - 2

## Number of mazes solved
var _solved_count: int = 0

## Cell visual nodes
var _cell_nodes: Array = []
var _player_node: ColorRect = null
var _exit_node: ColorRect = null


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	feedback_label.text = ""
	score_label.text = "Solved: 0 / " + str(COMPLETION_TARGET)


func _on_game_start() -> void:
	countdown_label.visible = false
	_solved_count = 0
	score_label.text = "Solved: 0 / " + str(COMPLETION_TARGET)
	_generate_and_display_maze()


func _on_game_end() -> void:
	feedback_label.text = "Time's up! You solved " + str(_solved_count) + " mazes!"
	submit_score(_solved_count)


func _generate_and_display_maze() -> void:
	_generate_maze()
	_player_row = 1
	_player_col = 1
	_exit_row = MAZE_ROWS - 2
	_exit_col = MAZE_COLS - 2
	_draw_maze()
	feedback_label.text = "Find the exit!"


func _generate_maze() -> void:
	# Initialize grid: all walls (false)
	_maze.clear()
	for r: int in range(MAZE_ROWS):
		var row: Array = []
		for c: int in range(MAZE_COLS):
			row.append(false)
		_maze.append(row)

	# Recursive backtracker on odd-indexed cells
	var visited: Dictionary = {}
	var stack: Array = []
	var start_r: int = 1
	var start_c: int = 1
	_maze[start_r][start_c] = true
	visited[Vector2i(start_r, start_c)] = true
	stack.append(Vector2i(start_r, start_c))

	while stack.size() > 0:
		var current: Vector2i = stack[stack.size() - 1]
		var neighbors: Array[Vector2i] = _get_unvisited_neighbors(current.x, current.y, visited)
		if neighbors.size() == 0:
			stack.pop_back()
		else:
			var next: Vector2i = neighbors[randi_range(0, neighbors.size() - 1)]
			# Carve wall between current and next
			var wall_r: int = (current.x + next.x) / 2
			var wall_c: int = (current.y + next.y) / 2
			_maze[wall_r][wall_c] = true
			_maze[next.x][next.y] = true
			visited[Vector2i(next.x, next.y)] = true
			stack.append(next)


func _get_unvisited_neighbors(r: int, c: int, visited: Dictionary) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions: Array[Vector2i] = [
		Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2), Vector2i(0, 2)
	]
	for d: Vector2i in directions:
		var nr: int = r + d.x
		var nc: int = c + d.y
		if nr >= 1 and nr < MAZE_ROWS - 1 and nc >= 1 and nc < MAZE_COLS - 1:
			if not visited.has(Vector2i(nr, nc)):
				neighbors.append(Vector2i(nr, nc))
	return neighbors


func _draw_maze() -> void:
	# Clear existing cells
	for node: Node in _cell_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_cell_nodes.clear()
	if _player_node != null and is_instance_valid(_player_node):
		_player_node.queue_free()
	if _exit_node != null and is_instance_valid(_exit_node):
		_exit_node.queue_free()

	# Center the maze in the container
	var maze_width: int = MAZE_COLS * CELL_SIZE
	var maze_height: int = MAZE_ROWS * CELL_SIZE
	var offset_x: float = (maze_container.size.x - maze_width) / 2.0
	var offset_y: float = (maze_container.size.y - maze_height) / 2.0

	# Draw cells
	for r: int in range(MAZE_ROWS):
		for c: int in range(MAZE_COLS):
			var cell: ColorRect = ColorRect.new()
			cell.size = Vector2(CELL_SIZE - 1, CELL_SIZE - 1)
			cell.position = Vector2(offset_x + c * CELL_SIZE, offset_y + r * CELL_SIZE)
			if _maze[r][c]:
				cell.color = Color(0.85, 0.85, 0.85, 1.0)  # Path: light gray
			else:
				cell.color = Color(0.15, 0.15, 0.2, 1.0)  # Wall: dark
			maze_container.add_child(cell)
			_cell_nodes.append(cell)

	# Draw exit marker
	_exit_node = ColorRect.new()
	_exit_node.size = Vector2(CELL_SIZE - 4, CELL_SIZE - 4)
	_exit_node.position = Vector2(offset_x + _exit_col * CELL_SIZE + 2, offset_y + _exit_row * CELL_SIZE + 2)
	_exit_node.color = Color(0.9, 0.2, 0.2, 1.0)  # Red exit
	maze_container.add_child(_exit_node)

	# Draw player
	_player_node = ColorRect.new()
	_player_node.size = Vector2(CELL_SIZE - 4, CELL_SIZE - 4)
	_player_node.position = Vector2(offset_x + _player_col * CELL_SIZE + 2, offset_y + _player_row * CELL_SIZE + 2)
	_player_node.color = Color(0.2, 0.8, 0.2, 1.0)  # Green player
	maze_container.add_child(_player_node)


func _update_player_position() -> void:
	if _player_node == null or not is_instance_valid(_player_node):
		return
	var maze_width: int = MAZE_COLS * CELL_SIZE
	var maze_height: int = MAZE_ROWS * CELL_SIZE
	var offset_x: float = (maze_container.size.x - maze_width) / 2.0
	var offset_y: float = (maze_container.size.y - maze_height) / 2.0
	_player_node.position = Vector2(offset_x + _player_col * CELL_SIZE + 2, offset_y + _player_row * CELL_SIZE + 2)


func _unhandled_input(event: InputEvent) -> void:
	if not game_active:
		return

	if not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var dr: int = 0
	var dc: int = 0
	if key_event.keycode == KEY_UP:
		dr = -1
	elif key_event.keycode == KEY_DOWN:
		dr = 1
	elif key_event.keycode == KEY_LEFT:
		dc = -1
	elif key_event.keycode == KEY_RIGHT:
		dc = 1
	else:
		return

	get_viewport().set_input_as_handled()

	var new_row: int = _player_row + dr
	var new_col: int = _player_col + dc

	# Bounds check
	if new_row < 0 or new_row >= MAZE_ROWS or new_col < 0 or new_col >= MAZE_COLS:
		return

	# Wall check
	if not _maze[new_row][new_col]:
		return

	_player_row = new_row
	_player_col = new_col
	_update_player_position()

	# Check if reached exit
	if _player_row == _exit_row and _player_col == _exit_col:
		_solved_count += 1
		score_label.text = "Solved: " + str(_solved_count) + " / " + str(COMPLETION_TARGET)
		if _solved_count >= COMPLETION_TARGET:
			feedback_label.text = "All mazes solved!"
			mark_completed(_solved_count)
			return
		_generate_and_display_maze()


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
