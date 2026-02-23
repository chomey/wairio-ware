extends MiniGameBase

## Gravity Flip minigame (Survival).
## Auto-scrolling platformer. Press space to flip gravity direction.
## Hit an obstacle = eliminated. Score = survival time in tenths of seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const PLAYER_SIZE: Vector2 = Vector2(20.0, 20.0)
const GRAVITY_STRENGTH: float = 300.0
const OBSTACLE_WIDTH: float = 30.0
const OBSTACLE_SPEED_BASE: float = 200.0
const OBSTACLE_SPEED_ACCEL: float = 15.0  # speed increase per second
const GAP_SIZE_BASE: float = 120.0
const GAP_SIZE_MIN: float = 70.0
const GAP_SHRINK_RATE: float = 3.0  # gap shrinks per second
const SPAWN_INTERVAL_BASE: float = 1.5
const SPAWN_INTERVAL_MIN: float = 0.7
const SPAWN_INTERVAL_ACCEL: float = 0.05  # interval decrease per second
const PLAYER_X: float = 60.0
const CEILING_FLOOR_HEIGHT: float = 10.0

const BG_COLOR: Color = Color(0.05, 0.05, 0.15, 1.0)
const PLAYER_COLOR: Color = Color(0.2, 0.9, 0.3, 1.0)
const OBSTACLE_COLOR: Color = Color(0.8, 0.2, 0.2, 1.0)
const BOUNDARY_COLOR: Color = Color(0.4, 0.4, 0.5, 1.0)

var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _gravity_up: bool = false  # false = falling down, true = falling up
var _player_y: float = 0.0
var _player_vy: float = 0.0
var _player_node: ColorRect = null
var _bg_node: ColorRect = null
var _ceiling_node: ColorRect = null
var _floor_node: ColorRect = null
var _spawn_timer: float = 0.0

## Each obstacle: {top_node: ColorRect, bottom_node: ColorRect, x: float, gap_y: float, gap_h: float}
var _obstacles: Array[Dictionary] = []


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
	_gravity_up = false
	_player_vy = 0.0
	_spawn_timer = 0.0
	_update_score_display()
	instruction_label.text = "SPACE to flip gravity! Avoid obstacles!"
	countdown_label.visible = false

	_create_arena()


func _create_arena() -> void:
	# Clear old nodes
	_clear_obstacles()
	if is_instance_valid(_player_node):
		_player_node.queue_free()
	if is_instance_valid(_bg_node):
		_bg_node.queue_free()
	if is_instance_valid(_ceiling_node):
		_ceiling_node.queue_free()
	if is_instance_valid(_floor_node):
		_floor_node.queue_free()

	var area_w: float = play_area.size.x
	var area_h: float = play_area.size.y

	# Background
	_bg_node = ColorRect.new()
	_bg_node.position = Vector2.ZERO
	_bg_node.size = Vector2(area_w, area_h)
	_bg_node.color = BG_COLOR
	play_area.add_child(_bg_node)

	# Ceiling
	_ceiling_node = ColorRect.new()
	_ceiling_node.position = Vector2.ZERO
	_ceiling_node.size = Vector2(area_w, CEILING_FLOOR_HEIGHT)
	_ceiling_node.color = BOUNDARY_COLOR
	play_area.add_child(_ceiling_node)

	# Floor
	_floor_node = ColorRect.new()
	_floor_node.position = Vector2(0.0, area_h - CEILING_FLOOR_HEIGHT)
	_floor_node.size = Vector2(area_w, CEILING_FLOOR_HEIGHT)
	_floor_node.color = BOUNDARY_COLOR
	play_area.add_child(_floor_node)

	# Player starts in the middle, gravity down
	var playable_top: float = CEILING_FLOOR_HEIGHT
	var playable_bottom: float = area_h - CEILING_FLOOR_HEIGHT
	_player_y = (playable_top + playable_bottom) / 2.0 - PLAYER_SIZE.y / 2.0

	_player_node = ColorRect.new()
	_player_node.size = PLAYER_SIZE
	_player_node.color = PLAYER_COLOR
	_player_node.position = Vector2(PLAYER_X, _player_y)
	play_area.add_child(_player_node)


func _clear_obstacles() -> void:
	for obs: Dictionary in _obstacles:
		var top_node: ColorRect = obs["top_node"] as ColorRect
		var bottom_node: ColorRect = obs["bottom_node"] as ColorRect
		if is_instance_valid(top_node):
			top_node.queue_free()
		if is_instance_valid(bottom_node):
			bottom_node.queue_free()
	_obstacles.clear()


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _eliminated:
		return

	if event.is_action_pressed("ui_accept"):
		_gravity_up = not _gravity_up
		_player_vy = 0.0  # reset velocity on flip for snappier control


func _process(delta: float) -> void:
	if not game_active or _eliminated:
		return

	_elapsed_time += delta
	_score = int(_elapsed_time * 10.0)
	_update_score_display()

	var area_h: float = play_area.size.y
	var area_w: float = play_area.size.x
	var playable_top: float = CEILING_FLOOR_HEIGHT
	var playable_bottom: float = area_h - CEILING_FLOOR_HEIGHT

	# Apply gravity
	if _gravity_up:
		_player_vy -= GRAVITY_STRENGTH * delta
	else:
		_player_vy += GRAVITY_STRENGTH * delta

	_player_y += _player_vy * delta

	# Clamp to playable area (ceiling/floor boundaries)
	if _player_y < playable_top:
		_player_y = playable_top
		_player_vy = 0.0
	elif _player_y + PLAYER_SIZE.y > playable_bottom:
		_player_y = playable_bottom - PLAYER_SIZE.y
		_player_vy = 0.0

	_player_node.position = Vector2(PLAYER_X, _player_y)

	# Spawn obstacles
	var current_interval: float = maxf(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_BASE - _elapsed_time * SPAWN_INTERVAL_ACCEL)
	_spawn_timer += delta
	if _spawn_timer >= current_interval:
		_spawn_timer = 0.0
		_spawn_obstacle()

	# Move obstacles and check collisions
	var current_speed: float = OBSTACLE_SPEED_BASE + _elapsed_time * OBSTACLE_SPEED_ACCEL
	var player_rect: Rect2 = Rect2(Vector2(PLAYER_X, _player_y), PLAYER_SIZE)
	var to_remove: Array[int] = []

	for i: int in range(_obstacles.size()):
		var obs: Dictionary = _obstacles[i]
		var ox: float = obs["x"] as float
		ox -= current_speed * delta
		obs["x"] = ox

		var top_node: ColorRect = obs["top_node"] as ColorRect
		var bottom_node: ColorRect = obs["bottom_node"] as ColorRect
		var gap_y: float = obs["gap_y"] as float
		var gap_h: float = obs["gap_h"] as float

		# Top obstacle: from ceiling to gap_y
		top_node.position = Vector2(ox, playable_top)
		top_node.size = Vector2(OBSTACLE_WIDTH, gap_y - playable_top)

		# Bottom obstacle: from gap_y + gap_h to floor
		bottom_node.position = Vector2(ox, gap_y + gap_h)
		bottom_node.size = Vector2(OBSTACLE_WIDTH, playable_bottom - (gap_y + gap_h))

		# Check collision with top obstacle
		var top_rect: Rect2 = Rect2(top_node.position, top_node.size)
		var bottom_rect: Rect2 = Rect2(bottom_node.position, bottom_node.size)

		if top_rect.size.y > 0.0 and player_rect.intersects(top_rect):
			_eliminate()
			return
		if bottom_rect.size.y > 0.0 and player_rect.intersects(bottom_rect):
			_eliminate()
			return

		# Remove off-screen obstacles
		if ox + OBSTACLE_WIDTH < 0.0:
			to_remove.append(i)

	# Remove off-screen (iterate backwards)
	for i: int in range(to_remove.size() - 1, -1, -1):
		var idx: int = to_remove[i]
		var obs: Dictionary = _obstacles[idx]
		var top_n: ColorRect = obs["top_node"] as ColorRect
		var bottom_n: ColorRect = obs["bottom_node"] as ColorRect
		if is_instance_valid(top_n):
			top_n.queue_free()
		if is_instance_valid(bottom_n):
			bottom_n.queue_free()
		_obstacles.remove_at(idx)


func _spawn_obstacle() -> void:
	var area_h: float = play_area.size.y
	var area_w: float = play_area.size.x
	var playable_top: float = CEILING_FLOOR_HEIGHT
	var playable_bottom: float = area_h - CEILING_FLOOR_HEIGHT
	var playable_height: float = playable_bottom - playable_top

	# Gap size decreases over time
	var gap_h: float = maxf(GAP_SIZE_MIN, GAP_SIZE_BASE - _elapsed_time * GAP_SHRINK_RATE)

	# Random gap position within playable area
	var min_gap_y: float = playable_top + 10.0
	var max_gap_y: float = playable_bottom - gap_h - 10.0
	if max_gap_y < min_gap_y:
		max_gap_y = min_gap_y
	var gap_y: float = randf_range(min_gap_y, max_gap_y)

	# Top obstacle
	var top_node: ColorRect = ColorRect.new()
	top_node.color = OBSTACLE_COLOR
	play_area.add_child(top_node)

	# Bottom obstacle
	var bottom_node: ColorRect = ColorRect.new()
	bottom_node.color = OBSTACLE_COLOR
	play_area.add_child(bottom_node)

	# Make sure player node stays on top visually
	if is_instance_valid(_player_node):
		play_area.move_child(_player_node, -1)

	var obs: Dictionary = {
		"top_node": top_node,
		"bottom_node": bottom_node,
		"x": area_w,
		"gap_y": gap_y,
		"gap_h": gap_h,
	}
	_obstacles.append(obs)


func _eliminate() -> void:
	_eliminated = true
	instruction_label.text = "You hit an obstacle! Eliminated!"
	mark_completed(_score)


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
