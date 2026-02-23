extends MiniGameBase

## Conveyor Chaos minigame (Survival).
## Stand on conveyors moving in different directions, stay in bounds.
## Arrow keys to move, conveyors push you toward edges.
## Pushed off edge = eliminated.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea
@onready var player_rect: ColorRect = %PlayerRect

const PLAYER_SIZE: float = 16.0
const PLAYER_SPEED: float = 200.0
const CONVEYOR_BASE_SPEED: float = 80.0
const CONVEYOR_SPEED_INCREASE: float = 8.0  # Per second of elapsed time
const GRID_COLS: int = 6
const GRID_ROWS: int = 5
const SHUFFLE_INTERVAL_START: float = 4.0
const SHUFFLE_INTERVAL_MIN: float = 2.0
const SHUFFLE_INTERVAL_DECAY: float = 0.15  # Decrease per second

## Direction vectors for conveyors: 0=left, 1=right, 2=up, 3=down
const DIR_VECTORS: Array[Vector2] = [
	Vector2(-1.0, 0.0),
	Vector2(1.0, 0.0),
	Vector2(0.0, -1.0),
	Vector2(0.0, 1.0),
]
const DIR_CHARS: Array[String] = ["<", ">", "^", "v"]
const DIR_COLORS: Array[Color] = [
	Color(0.6, 0.2, 0.2, 0.6),  # Left - red
	Color(0.2, 0.6, 0.2, 0.6),  # Right - green
	Color(0.2, 0.2, 0.6, 0.6),  # Up - blue
	Color(0.6, 0.6, 0.2, 0.6),  # Down - yellow
]

var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _player_pos: Vector2 = Vector2.ZERO
var _shuffle_timer: float = 0.0

## Grid of conveyor directions (index 0-3)
var _conveyor_dirs: Array[int] = []
## Visual nodes for conveyors
var _conveyor_rects: Array[ColorRect] = []
var _conveyor_labels: Array[Label] = []


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	_update_score_display()
	instruction_label.text = "Get ready..."
	player_rect.visible = false


func _process(delta: float) -> void:
	if not game_active or _eliminated:
		return

	_elapsed_time += delta
	_score = int(_elapsed_time * 10.0)
	_update_score_display()

	var play_w: float = play_area.size.x
	var play_h: float = play_area.size.y
	var cell_w: float = play_w / float(GRID_COLS)
	var cell_h: float = play_h / float(GRID_ROWS)

	# Determine which conveyor cell the player center is on
	var player_center: Vector2 = _player_pos + Vector2(PLAYER_SIZE / 2.0, PLAYER_SIZE / 2.0)
	var col: int = clampi(int(player_center.x / cell_w), 0, GRID_COLS - 1)
	var row: int = clampi(int(player_center.y / cell_h), 0, GRID_ROWS - 1)
	var cell_idx: int = row * GRID_COLS + col

	# Apply conveyor push
	var conveyor_speed: float = CONVEYOR_BASE_SPEED + _elapsed_time * CONVEYOR_SPEED_INCREASE
	if cell_idx >= 0 and cell_idx < _conveyor_dirs.size():
		var dir_idx: int = _conveyor_dirs[cell_idx]
		var push: Vector2 = DIR_VECTORS[dir_idx] * conveyor_speed * delta
		_player_pos += push

	# Player movement
	var move_dir: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		move_dir.x -= 1.0
	if Input.is_action_pressed("ui_right"):
		move_dir.x += 1.0
	if Input.is_action_pressed("ui_up"):
		move_dir.y -= 1.0
	if Input.is_action_pressed("ui_down"):
		move_dir.y += 1.0

	if move_dir.length() > 0.0:
		move_dir = move_dir.normalized()
		_player_pos += move_dir * PLAYER_SPEED * delta

	player_rect.position = _player_pos

	# Check if player is off the play area
	if _player_pos.x + PLAYER_SIZE < 0.0 or _player_pos.x > play_w or _player_pos.y + PLAYER_SIZE < 0.0 or _player_pos.y > play_h:
		_eliminated = true
		instruction_label.text = "Pushed off edge! Eliminated!"
		mark_completed(_score)
		return

	# Shuffle timer
	_shuffle_timer -= delta
	if _shuffle_timer <= 0.0:
		var interval: float = maxf(SHUFFLE_INTERVAL_MIN, SHUFFLE_INTERVAL_START - _elapsed_time * SHUFFLE_INTERVAL_DECAY)
		_shuffle_timer = interval
		_shuffle_conveyors()


func _build_conveyor_grid() -> void:
	_clear_conveyors()

	var play_w: float = play_area.size.x
	var play_h: float = play_area.size.y
	var cell_w: float = play_w / float(GRID_COLS)
	var cell_h: float = play_h / float(GRID_ROWS)

	_conveyor_dirs.clear()
	_conveyor_rects.clear()
	_conveyor_labels.clear()

	for row: int in range(GRID_ROWS):
		for col: int in range(GRID_COLS):
			var dir_idx: int = randi_range(0, 3)
			_conveyor_dirs.append(dir_idx)

			var rect: ColorRect = ColorRect.new()
			rect.position = Vector2(col * cell_w, row * cell_h)
			rect.size = Vector2(cell_w - 1.0, cell_h - 1.0)
			rect.color = DIR_COLORS[dir_idx]
			play_area.add_child(rect)
			# Move behind player
			play_area.move_child(rect, 0)
			_conveyor_rects.append(rect)

			var lbl: Label = Label.new()
			lbl.position = Vector2(col * cell_w, row * cell_h)
			lbl.size = Vector2(cell_w - 1.0, cell_h - 1.0)
			lbl.text = DIR_CHARS[dir_idx]
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			play_area.add_child(lbl)
			# Move behind player but in front of rect
			play_area.move_child(lbl, 1)
			_conveyor_labels.append(lbl)


func _shuffle_conveyors() -> void:
	var total_cells: int = GRID_COLS * GRID_ROWS
	if _conveyor_dirs.size() != total_cells:
		return

	for i: int in range(total_cells):
		var new_dir: int = randi_range(0, 3)
		_conveyor_dirs[i] = new_dir
		if i < _conveyor_rects.size():
			_conveyor_rects[i].color = DIR_COLORS[new_dir]
		if i < _conveyor_labels.size():
			_conveyor_labels[i].text = DIR_CHARS[new_dir]


func _clear_conveyors() -> void:
	for rect: ColorRect in _conveyor_rects:
		if is_instance_valid(rect):
			rect.queue_free()
	_conveyor_rects.clear()
	for lbl: Label in _conveyor_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_conveyor_labels.clear()
	_conveyor_dirs.clear()


func _on_game_start() -> void:
	_score = 0
	_elapsed_time = 0.0
	_eliminated = false
	_shuffle_timer = SHUFFLE_INTERVAL_START

	var play_w: float = play_area.size.x
	var play_h: float = play_area.size.y

	# Center player
	_player_pos = Vector2(
		(play_w - PLAYER_SIZE) / 2.0,
		(play_h - PLAYER_SIZE) / 2.0
	)
	player_rect.position = _player_pos

	_build_conveyor_grid()

	_update_score_display()
	instruction_label.text = "Arrow keys to move! Stay on the platform!"
	countdown_label.visible = false
	player_rect.visible = true


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! You survived!"
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
