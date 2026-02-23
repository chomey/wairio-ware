extends MiniGameBase

## Asteroid Dodge minigame (Survival).
## Ship moves in 2D, dodge asteroids coming from all sides.
## Hit by asteroid = eliminated.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea
@onready var ship_rect: ColorRect = %ShipRect

const SHIP_SIZE: float = 16.0
const SHIP_SPEED: float = 280.0
const ASTEROID_SIZE: float = 20.0
const ASTEROID_BASE_SPEED: float = 150.0
const ASTEROID_SPEED_INCREASE: float = 15.0  # Per second of elapsed time
const SPAWN_INTERVAL_START: float = 0.6
const SPAWN_INTERVAL_MIN: float = 0.15
const SPAWN_INTERVAL_DECAY: float = 0.03  # Decrease per second of elapsed time

var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _ship_pos: Vector2 = Vector2.ZERO
var _spawn_timer: float = 0.0
var _current_spawn_interval: float = SPAWN_INTERVAL_START

## Each asteroid: { pos: Vector2, vel: Vector2, node: ColorRect }
var _asteroids: Array[Dictionary] = []


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	_update_score_display()
	instruction_label.text = "Get ready..."
	ship_rect.visible = false


func _process(delta: float) -> void:
	if not game_active or _eliminated:
		return

	_elapsed_time += delta
	_score = int(_elapsed_time * 10.0)
	_update_score_display()

	# Ship movement
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
		_ship_pos += move_dir * SHIP_SPEED * delta

	# Clamp ship within play area
	var play_w: float = play_area.size.x
	var play_h: float = play_area.size.y
	_ship_pos.x = clampf(_ship_pos.x, 0.0, play_w - SHIP_SIZE)
	_ship_pos.y = clampf(_ship_pos.y, 0.0, play_h - SHIP_SIZE)
	ship_rect.position = _ship_pos

	# Spawn asteroids
	_spawn_timer -= delta
	_current_spawn_interval = maxf(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_START - _elapsed_time * SPAWN_INTERVAL_DECAY)
	if _spawn_timer <= 0.0:
		_spawn_timer = _current_spawn_interval
		_spawn_asteroid()

	# Update asteroids
	var asteroid_speed: float = ASTEROID_BASE_SPEED + _elapsed_time * ASTEROID_SPEED_INCREASE
	var ship_center: Vector2 = _ship_pos + Vector2(SHIP_SIZE / 2.0, SHIP_SIZE / 2.0)
	var ship_half: float = SHIP_SIZE / 2.0
	var asteroid_half: float = ASTEROID_SIZE / 2.0
	var collision_dist: float = ship_half + asteroid_half - 4.0  # Slight forgiveness

	var to_remove: Array[int] = []
	for i: int in range(_asteroids.size()):
		var ast: Dictionary = _asteroids[i]
		var pos: Vector2 = ast["pos"] as Vector2
		var vel: Vector2 = ast["vel"] as Vector2
		pos += vel.normalized() * asteroid_speed * delta
		ast["pos"] = pos

		var node: ColorRect = ast["node"] as ColorRect
		node.position = pos

		# Check collision with ship (circle-ish approximation)
		var ast_center: Vector2 = pos + Vector2(ASTEROID_SIZE / 2.0, ASTEROID_SIZE / 2.0)
		if ast_center.distance_to(ship_center) < collision_dist:
			_eliminated = true
			instruction_label.text = "Hit by asteroid! Eliminated!"
			mark_completed(_score)
			return

		# Remove if off-screen
		if pos.x < -ASTEROID_SIZE * 2.0 or pos.x > play_w + ASTEROID_SIZE * 2.0 or pos.y < -ASTEROID_SIZE * 2.0 or pos.y > play_h + ASTEROID_SIZE * 2.0:
			to_remove.append(i)

	# Remove off-screen asteroids (reverse order to keep indices valid)
	for i: int in range(to_remove.size() - 1, -1, -1):
		var idx: int = to_remove[i]
		var node: ColorRect = _asteroids[idx]["node"] as ColorRect
		node.queue_free()
		_asteroids.remove_at(idx)


func _spawn_asteroid() -> void:
	var play_w: float = play_area.size.x
	var play_h: float = play_area.size.y

	var pos: Vector2 = Vector2.ZERO
	var vel: Vector2 = Vector2.ZERO

	# Pick a random side to spawn from: 0=top, 1=bottom, 2=left, 3=right
	var side: int = randi_range(0, 3)
	match side:
		0:  # Top
			pos = Vector2(randf_range(0.0, play_w - ASTEROID_SIZE), -ASTEROID_SIZE)
			vel = Vector2(randf_range(-0.3, 0.3), 1.0)
		1:  # Bottom
			pos = Vector2(randf_range(0.0, play_w - ASTEROID_SIZE), play_h)
			vel = Vector2(randf_range(-0.3, 0.3), -1.0)
		2:  # Left
			pos = Vector2(-ASTEROID_SIZE, randf_range(0.0, play_h - ASTEROID_SIZE))
			vel = Vector2(1.0, randf_range(-0.3, 0.3))
		3:  # Right
			pos = Vector2(play_w, randf_range(0.0, play_h - ASTEROID_SIZE))
			vel = Vector2(-1.0, randf_range(-0.3, 0.3))

	var node: ColorRect = ColorRect.new()
	node.size = Vector2(ASTEROID_SIZE, ASTEROID_SIZE)
	node.position = pos
	node.color = Color(0.7, 0.4, 0.2, 1.0)
	play_area.add_child(node)

	var ast: Dictionary = { "pos": pos, "vel": vel, "node": node }
	_asteroids.append(ast)


func _clear_asteroids() -> void:
	for ast: Dictionary in _asteroids:
		var node: ColorRect = ast["node"] as ColorRect
		if is_instance_valid(node):
			node.queue_free()
	_asteroids.clear()


func _on_game_start() -> void:
	_score = 0
	_elapsed_time = 0.0
	_eliminated = false
	_spawn_timer = SPAWN_INTERVAL_START
	_current_spawn_interval = SPAWN_INTERVAL_START
	_clear_asteroids()

	var play_w: float = play_area.size.x
	var play_h: float = play_area.size.y

	# Center ship
	_ship_pos = Vector2(
		(play_w - SHIP_SIZE) / 2.0,
		(play_h - SHIP_SIZE) / 2.0
	)
	ship_rect.position = _ship_pos

	_update_score_display()
	instruction_label.text = "Arrow keys to move! Dodge asteroids!"
	countdown_label.visible = false
	ship_rect.visible = true


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
