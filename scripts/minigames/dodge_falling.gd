extends MiniGameBase

## Dodge Falling minigame.
## Player moves left/right to dodge falling obstacles.
## Score = number of obstacles that pass below without hitting the player.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea
@onready var player_rect: ColorRect = %PlayerRect

const PLAYER_SPEED: float = 400.0
const PLAYER_WIDTH: float = 40.0
const PLAYER_HEIGHT: float = 20.0
const OBSTACLE_WIDTH: float = 50.0
const OBSTACLE_HEIGHT: float = 20.0
const OBSTACLE_SPEED_BASE: float = 200.0
const OBSTACLE_SPEED_INCREMENT: float = 20.0
const SPAWN_INTERVAL_BASE: float = 0.8
const SPAWN_INTERVAL_MIN: float = 0.3

var _score: int = 0
var _obstacles: Array[ColorRect] = []
var _spawn_timer: float = 0.0
var _current_spawn_interval: float = SPAWN_INTERVAL_BASE
var _current_obstacle_speed: float = OBSTACLE_SPEED_BASE
var _elapsed_time: float = 0.0
var _game_over: bool = false


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	_update_score_display()
	instruction_label.text = "Get ready..."


func _process(delta: float) -> void:
	if not game_active or _game_over:
		return

	_elapsed_time += delta

	# Increase difficulty over time
	_current_obstacle_speed = OBSTACLE_SPEED_BASE + (_elapsed_time * OBSTACLE_SPEED_INCREMENT)
	_current_spawn_interval = maxf(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_BASE - (_elapsed_time * 0.05))

	# Move player with arrow keys
	var play_area_width: float = play_area.size.x
	if Input.is_action_pressed("ui_left"):
		player_rect.position.x -= PLAYER_SPEED * delta
	if Input.is_action_pressed("ui_right"):
		player_rect.position.x += PLAYER_SPEED * delta

	# Clamp player within play area
	player_rect.position.x = clampf(player_rect.position.x, 0.0, play_area_width - PLAYER_WIDTH)

	# Spawn obstacles
	_spawn_timer += delta
	if _spawn_timer >= _current_spawn_interval:
		_spawn_timer = 0.0
		_spawn_obstacle()

	# Move obstacles and check collisions
	var player_rect_area: Rect2 = Rect2(player_rect.position, player_rect.size)
	var to_remove: Array[ColorRect] = []

	for obstacle: ColorRect in _obstacles:
		obstacle.position.y += _current_obstacle_speed * delta

		# Check collision with player
		var obs_rect: Rect2 = Rect2(obstacle.position, obstacle.size)
		if obs_rect.intersects(player_rect_area):
			_game_over = true
			instruction_label.text = "HIT! Game Over!"
			mark_completed(_score)
			return

		# Check if obstacle passed below play area
		if obstacle.position.y > play_area.size.y:
			_score += 1
			_update_score_display()
			to_remove.append(obstacle)

	# Remove passed obstacles
	for obstacle: ColorRect in to_remove:
		_obstacles.erase(obstacle)
		obstacle.queue_free()


func _spawn_obstacle() -> void:
	var play_area_width: float = play_area.size.x
	var obstacle: ColorRect = ColorRect.new()
	obstacle.size = Vector2(OBSTACLE_WIDTH, OBSTACLE_HEIGHT)
	obstacle.color = Color(0.9, 0.2, 0.2, 1.0)
	obstacle.position = Vector2(
		randf_range(0.0, play_area_width - OBSTACLE_WIDTH),
		-OBSTACLE_HEIGHT
	)
	play_area.add_child(obstacle)
	_obstacles.append(obstacle)


func _on_game_start() -> void:
	_score = 0
	_obstacles.clear()
	_spawn_timer = 0.0
	_elapsed_time = 0.0
	_game_over = false
	_current_spawn_interval = SPAWN_INTERVAL_BASE
	_current_obstacle_speed = OBSTACLE_SPEED_BASE
	_update_score_display()
	instruction_label.text = "Arrow keys to dodge!"
	countdown_label.visible = false

	# Position player at bottom center of play area
	var play_area_width: float = play_area.size.x
	var play_area_height: float = play_area.size.y
	player_rect.position = Vector2(
		(play_area_width - PLAYER_WIDTH) / 2.0,
		play_area_height - PLAYER_HEIGHT - 10.0
	)
	player_rect.visible = true


func _on_game_end() -> void:
	if not _game_over:
		instruction_label.text = "Time's up! You survived!"
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Dodged: " + str(_score)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
