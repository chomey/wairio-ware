extends MiniGameBase

## Shrinking Arena minigame (Survival).
## Play area shrinks over time. Stay inside with arrow keys.
## Touching the boundary eliminates you.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea
@onready var arena_rect: ColorRect = %ArenaRect
@onready var player_rect: ColorRect = %PlayerRect

const PLAYER_SIZE: float = 16.0
const PLAYER_SPEED: float = 250.0
const SHRINK_RATE: float = 8.0  # Pixels per second per side
const SHRINK_ACCELERATION: float = 1.5  # Additional pixels/s per second elapsed
const MIN_ARENA_SIZE: float = 40.0

var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _player_pos: Vector2 = Vector2.ZERO
var _arena_margin: float = 0.0  # How much the arena has shrunk on each side


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

	# Shrink arena
	var shrink_speed: float = SHRINK_RATE + (_elapsed_time * SHRINK_ACCELERATION)
	_arena_margin += shrink_speed * delta

	# Clamp so arena doesn't get too small
	var play_width: float = play_area.size.x
	var play_height: float = play_area.size.y
	var max_margin_x: float = (play_width - MIN_ARENA_SIZE) / 2.0
	var max_margin_y: float = (play_height - MIN_ARENA_SIZE) / 2.0
	var max_margin: float = minf(max_margin_x, max_margin_y)
	_arena_margin = minf(_arena_margin, max_margin)

	_update_arena_visual()

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

	# Check if player is outside arena bounds
	var arena_left: float = _arena_margin
	var arena_top: float = _arena_margin
	var arena_right: float = play_width - _arena_margin
	var arena_bottom: float = play_height - _arena_margin

	var player_left: float = _player_pos.x
	var player_top: float = _player_pos.y
	var player_right: float = _player_pos.x + PLAYER_SIZE
	var player_bottom: float = _player_pos.y + PLAYER_SIZE

	if player_left < arena_left or player_top < arena_top or player_right > arena_right or player_bottom > arena_bottom:
		_eliminated = true
		instruction_label.text = "You touched the boundary! Eliminated!"
		mark_completed(_score)
		return

	_update_player_visual()


func _update_arena_visual() -> void:
	var play_width: float = play_area.size.x
	var play_height: float = play_area.size.y
	arena_rect.position = Vector2(_arena_margin, _arena_margin)
	arena_rect.size = Vector2(play_width - _arena_margin * 2.0, play_height - _arena_margin * 2.0)

	# Color shifts as arena shrinks
	var shrink_ratio: float = _arena_margin / ((play_width - MIN_ARENA_SIZE) / 2.0)
	shrink_ratio = clampf(shrink_ratio, 0.0, 1.0)
	arena_rect.color = Color(
		lerpf(0.1, 0.3, shrink_ratio),
		lerpf(0.2, 0.08, shrink_ratio),
		lerpf(0.15, 0.08, shrink_ratio),
		1.0
	)


func _update_player_visual() -> void:
	player_rect.position = _player_pos
	player_rect.size = Vector2(PLAYER_SIZE, PLAYER_SIZE)


func _on_game_start() -> void:
	_score = 0
	_elapsed_time = 0.0
	_eliminated = false
	_arena_margin = 0.0

	var play_width: float = play_area.size.x
	var play_height: float = play_area.size.y

	# Center player
	_player_pos = Vector2(
		(play_width - PLAYER_SIZE) / 2.0,
		(play_height - PLAYER_SIZE) / 2.0
	)

	_update_score_display()
	instruction_label.text = "Arrow keys to move! Stay inside!"
	countdown_label.visible = false
	player_rect.visible = true

	_update_arena_visual()
	_update_player_visual()


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
