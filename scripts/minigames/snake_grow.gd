extends MiniGameBase

## Snake Grow minigame (Survival).
## Classic snake movement on a grid. Eat dots to grow.
## Don't hit walls or your own body.
## Arrow keys to change direction.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const GRID_COLS: int = 20
const GRID_ROWS: int = 15
const INITIAL_MOVE_INTERVAL: float = 0.2
const MIN_MOVE_INTERVAL: float = 0.08
const SPEED_UP_RATE: float = 0.005
const INITIAL_LENGTH: int = 3

enum Direction { UP, DOWN, LEFT, RIGHT }

var _snake: Array[Vector2i] = []  # Head is index 0
var _direction: int = Direction.RIGHT
var _next_direction: int = Direction.RIGHT
var _food_pos: Vector2i = Vector2i.ZERO
var _move_timer: float = 0.0
var _move_interval: float = INITIAL_MOVE_INTERVAL
var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _dots_eaten: int = 0


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	_update_score_display()
	instruction_label.text = "Get ready..."
	play_area.draw.connect(_on_play_area_draw)


func _process(delta: float) -> void:
	if not game_active or _eliminated:
		return

	_elapsed_time += delta
	_score = int(_elapsed_time * 10.0)
	_update_score_display()

	# Speed up over time
	_move_interval = maxf(INITIAL_MOVE_INTERVAL - _elapsed_time * SPEED_UP_RATE, MIN_MOVE_INTERVAL)

	_move_timer -= delta
	if _move_timer <= 0.0:
		_move_timer = _move_interval
		_move_snake()

	play_area.queue_redraw()


func _move_snake() -> void:
	_direction = _next_direction

	var head: Vector2i = _snake[0]
	var new_head: Vector2i = head

	match _direction:
		Direction.UP:
			new_head = Vector2i(head.x, head.y - 1)
		Direction.DOWN:
			new_head = Vector2i(head.x, head.y + 1)
		Direction.LEFT:
			new_head = Vector2i(head.x - 1, head.y)
		Direction.RIGHT:
			new_head = Vector2i(head.x + 1, head.y)

	# Check wall collision
	if new_head.x < 0 or new_head.x >= GRID_COLS or new_head.y < 0 or new_head.y >= GRID_ROWS:
		_eliminated = true
		instruction_label.text = "Hit wall! Eliminated!"
		play_area.queue_redraw()
		mark_completed(_score)
		return

	# Check self collision (skip the tail since it will move)
	for i: int in range(_snake.size() - 1):
		if new_head == _snake[i]:
			_eliminated = true
			instruction_label.text = "Hit yourself! Eliminated!"
			play_area.queue_redraw()
			mark_completed(_score)
			return

	# Move snake
	_snake.insert(0, new_head)

	# Check food
	if new_head == _food_pos:
		_dots_eaten += 1
		_spawn_food()
		# Don't remove tail (grow)
	else:
		_snake.pop_back()


func _spawn_food() -> void:
	var attempts: int = 0
	while attempts < 200:
		var pos: Vector2i = Vector2i(randi() % GRID_COLS, randi() % GRID_ROWS)
		var on_snake: bool = false
		for segment: Vector2i in _snake:
			if segment == pos:
				on_snake = true
				break
		if not on_snake:
			_food_pos = pos
			return
		attempts += 1
	# Fallback: place at first empty cell
	for y: int in range(GRID_ROWS):
		for x: int in range(GRID_COLS):
			var pos: Vector2i = Vector2i(x, y)
			var on_snake: bool = false
			for segment: Vector2i in _snake:
				if segment == pos:
					on_snake = true
					break
			if not on_snake:
				_food_pos = pos
				return


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _eliminated:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_UP and _direction != Direction.DOWN:
				_next_direction = Direction.UP
				get_viewport().set_input_as_handled()
			elif key_event.keycode == KEY_DOWN and _direction != Direction.UP:
				_next_direction = Direction.DOWN
				get_viewport().set_input_as_handled()
			elif key_event.keycode == KEY_LEFT and _direction != Direction.RIGHT:
				_next_direction = Direction.LEFT
				get_viewport().set_input_as_handled()
			elif key_event.keycode == KEY_RIGHT and _direction != Direction.LEFT:
				_next_direction = Direction.RIGHT
				get_viewport().set_input_as_handled()


func _on_play_area_draw() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y

	var cell_w: float = pw / float(GRID_COLS)
	var cell_h: float = ph / float(GRID_ROWS)

	# Draw grid background
	for y: int in range(GRID_ROWS):
		for x: int in range(GRID_COLS):
			var color: Color
			if (x + y) % 2 == 0:
				color = Color(0.08, 0.1, 0.12, 1.0)
			else:
				color = Color(0.1, 0.12, 0.14, 1.0)
			play_area.draw_rect(Rect2(float(x) * cell_w, float(y) * cell_h, cell_w, cell_h), color)

	# Draw food
	var food_pulse: float = 0.7 + absf(sin(_elapsed_time * 5.0)) * 0.3
	var food_color: Color = Color(1.0, 0.3, 0.3, food_pulse)
	var fx: float = float(_food_pos.x) * cell_w + cell_w * 0.5
	var fy: float = float(_food_pos.y) * cell_h + cell_h * 0.5
	var food_size: float = minf(cell_w, cell_h) * 0.35
	play_area.draw_circle(Vector2(fx, fy), food_size, food_color)

	# Draw snake
	for i: int in range(_snake.size()):
		var segment: Vector2i = _snake[i]
		var sx: float = float(segment.x) * cell_w
		var sy: float = float(segment.y) * cell_h
		var margin: float = 1.0

		var seg_color: Color
		if i == 0:
			# Head
			seg_color = Color(0.3, 0.9, 0.3, 1.0)
		else:
			# Body - gradient from bright to dim
			var ratio: float = float(i) / float(maxi(_snake.size(), 1))
			seg_color = Color(0.2 + ratio * 0.15, 0.7 - ratio * 0.2, 0.2 + ratio * 0.1, 1.0)

		play_area.draw_rect(Rect2(sx + margin, sy + margin, cell_w - margin * 2.0, cell_h - margin * 2.0), seg_color)

	# Draw border
	play_area.draw_rect(Rect2(0.0, 0.0, pw, ph), Color(0.4, 0.4, 0.5, 0.6), false, 2.0)


func _on_game_start() -> void:
	# Initialize snake in center
	var start_x: int = GRID_COLS / 2
	var start_y: int = GRID_ROWS / 2
	_snake.clear()
	for i: int in range(INITIAL_LENGTH):
		_snake.append(Vector2i(start_x - i, start_y))

	_direction = Direction.RIGHT
	_next_direction = Direction.RIGHT
	_elapsed_time = 0.0
	_score = 0
	_eliminated = false
	_dots_eaten = 0
	_move_timer = INITIAL_MOVE_INTERVAL
	_move_interval = INITIAL_MOVE_INTERVAL
	_spawn_food()
	_update_score_display()
	instruction_label.text = "Arrow keys to steer!"
	countdown_label.visible = false
	play_area.queue_redraw()


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! Survived!"
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Eaten: " + str(_dots_eaten)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
