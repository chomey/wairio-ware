extends MiniGameBase

## Wrecking Ball minigame (Survival).
## A wrecking ball swings back and forth across the screen at varying heights.
## Player must jump (space) over low swings or duck (down arrow) under high swings.
## Getting hit by the ball eliminates the player.
## Speed and unpredictability increase over time.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const PLAYER_WIDTH: float = 24.0
const PLAYER_HEIGHT: float = 48.0
const GROUND_RATIO: float = 0.78
const BALL_RADIUS: float = 22.0
const JUMP_VELOCITY: float = -420.0
const GRAVITY: float = 900.0
const DUCK_HEIGHT: float = 24.0
const INITIAL_SWING_SPEED: float = 2.2
const SPEED_INCREMENT: float = 0.12
const WARNING_TIME: float = 1.0

enum BallHeight { LOW, HIGH }

var _player_x: float = 0.0
var _player_y: float = 0.0
var _player_vy: float = 0.0
var _ground_y: float = 0.0
var _is_jumping: bool = false
var _is_ducking: bool = false
var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false

# Ball state
var _ball_x: float = 0.0
var _ball_active: bool = false
var _ball_height: int = 0  # BallHeight enum
var _ball_direction: float = 1.0  # 1.0 = left to right, -1.0 = right to left
var _ball_speed: float = 300.0
var _swing_speed_mult: float = INITIAL_SWING_SPEED

# Warning / spawn
var _warning_timer: float = 0.0
var _warning_active: bool = false
var _next_ball_height: int = 0
var _next_ball_direction: float = 1.0
var _spawn_cooldown: float = 0.0
var _balls_dodged: int = 0


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

	var pw: float = play_area.size.x

	# Player physics
	if _is_jumping:
		_player_vy += GRAVITY * delta
		_player_y += _player_vy * delta
		if _player_y >= _ground_y:
			_player_y = _ground_y
			_player_vy = 0.0
			_is_jumping = false

	# Warning phase
	if _warning_active:
		_warning_timer -= delta
		if _warning_timer <= 0.0:
			_warning_active = false
			_ball_active = true
			_ball_height = _next_ball_height
			_ball_direction = _next_ball_direction
			if _ball_direction > 0.0:
				_ball_x = -BALL_RADIUS * 2.0
			else:
				_ball_x = pw + BALL_RADIUS * 2.0
			_ball_speed = 200.0 + _balls_dodged * 15.0

	# Ball movement
	if _ball_active:
		_ball_x += _ball_direction * _ball_speed * _swing_speed_mult * delta

		# Check collision
		if _check_ball_collision():
			_eliminated = true
			instruction_label.text = "HIT! Eliminated!"
			play_area.queue_redraw()
			mark_completed(_score)
			return

		# Ball passed through
		if (_ball_direction > 0.0 and _ball_x > pw + BALL_RADIUS * 3.0) or \
		   (_ball_direction < 0.0 and _ball_x < -BALL_RADIUS * 3.0):
			_ball_active = false
			_balls_dodged += 1
			_spawn_cooldown = maxf(0.6 - _balls_dodged * 0.02, 0.2)
			_swing_speed_mult += SPEED_INCREMENT * 0.3

	# Spawn next ball
	if not _ball_active and not _warning_active:
		_spawn_cooldown -= delta
		if _spawn_cooldown <= 0.0:
			_start_warning()

	play_area.queue_redraw()


func _check_ball_collision() -> bool:
	var pw: float = play_area.size.x
	var player_top: float
	var player_height: float

	if _is_ducking:
		player_height = DUCK_HEIGHT
		player_top = _ground_y - DUCK_HEIGHT
	else:
		player_height = PLAYER_HEIGHT
		player_top = _player_y - PLAYER_HEIGHT

	var player_center_x: float = _player_x + PLAYER_WIDTH * 0.5
	var player_center_y: float = player_top + player_height * 0.5

	# Ball center Y
	var ball_y: float
	if _ball_height == BallHeight.LOW:
		ball_y = _ground_y - BALL_RADIUS - 4.0  # Low: near ground, must jump
	else:
		ball_y = _ground_y - PLAYER_HEIGHT - BALL_RADIUS + 4.0  # High: above standing height, must duck

	# AABB vs circle approximation
	var dx: float = absf(_ball_x - player_center_x)
	var dy: float = absf(ball_y - player_center_y)
	var half_w: float = PLAYER_WIDTH * 0.5 + BALL_RADIUS * 0.7
	var half_h: float = player_height * 0.5 + BALL_RADIUS * 0.7

	return dx < half_w and dy < half_h


func _start_warning() -> void:
	_warning_active = true
	_warning_timer = maxf(WARNING_TIME - _balls_dodged * 0.03, 0.3)
	_next_ball_height = randi() % 2
	_next_ball_direction = 1.0 if randi() % 2 == 0 else -1.0

	if _next_ball_height == BallHeight.LOW:
		instruction_label.text = "LOW! Press SPACE to jump!"
	else:
		instruction_label.text = "HIGH! Press DOWN to duck!"


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _eliminated:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == KEY_SPACE:
			if key_event.pressed and not key_event.echo and not _is_jumping:
				_is_jumping = true
				_player_vy = JUMP_VELOCITY
				_is_ducking = false
				get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_DOWN:
			if key_event.pressed and not _is_jumping:
				_is_ducking = true
				get_viewport().set_input_as_handled()
			elif not key_event.pressed:
				_is_ducking = false
				get_viewport().set_input_as_handled()


func _on_play_area_draw() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y
	_ground_y = ph * GROUND_RATIO

	# Draw ground
	play_area.draw_rect(Rect2(0.0, _ground_y, pw, ph - _ground_y), Color(0.25, 0.2, 0.15, 1.0))

	# Draw player
	if not _eliminated:
		var player_height: float = DUCK_HEIGHT if _is_ducking else PLAYER_HEIGHT
		var player_top: float
		if _is_ducking:
			player_top = _ground_y - DUCK_HEIGHT
		else:
			player_top = _player_y - PLAYER_HEIGHT

		var player_color: Color = Color(0.2, 0.8, 0.3, 1.0)
		if _is_ducking:
			player_color = Color(0.2, 0.6, 0.8, 1.0)
		elif _is_jumping:
			player_color = Color(0.8, 0.8, 0.2, 1.0)

		play_area.draw_rect(Rect2(_player_x, player_top, PLAYER_WIDTH, player_height), player_color)

	# Draw warning indicator
	if _warning_active:
		var warn_side: float
		if _next_ball_direction > 0.0:
			warn_side = 5.0
		else:
			warn_side = pw - 25.0

		var warn_y: float
		if _next_ball_height == BallHeight.LOW:
			warn_y = _ground_y - BALL_RADIUS * 2.0 - 4.0
		else:
			warn_y = _ground_y - PLAYER_HEIGHT - BALL_RADIUS * 2.0 + 4.0

		var blink: float = absf(sin(_elapsed_time * 8.0))
		var warn_color: Color = Color(1.0, 0.3, 0.0, 0.5 + blink * 0.5)
		play_area.draw_circle(Vector2(warn_side + 10.0, warn_y + BALL_RADIUS), BALL_RADIUS * 0.6, warn_color)
		play_area.draw_string(ThemeDB.fallback_font, Vector2(warn_side - 5.0, warn_y - 5.0), "!", HORIZONTAL_ALIGNMENT_CENTER, 30, 18, warn_color)

	# Draw wrecking ball
	if _ball_active:
		var ball_y: float
		if _ball_height == BallHeight.LOW:
			ball_y = _ground_y - BALL_RADIUS - 4.0
		else:
			ball_y = _ground_y - PLAYER_HEIGHT - BALL_RADIUS + 4.0

		# Chain
		var chain_start_x: float = _ball_x
		var chain_start_y: float = 0.0
		play_area.draw_line(Vector2(chain_start_x, chain_start_y), Vector2(_ball_x, ball_y - BALL_RADIUS), Color(0.5, 0.5, 0.5, 0.6), 2.0)

		# Ball
		play_area.draw_circle(Vector2(_ball_x, ball_y), BALL_RADIUS, Color(0.4, 0.4, 0.45, 1.0))
		play_area.draw_circle(Vector2(_ball_x, ball_y), BALL_RADIUS - 3.0, Color(0.55, 0.55, 0.6, 1.0))

	# Height guide lines
	var low_y: float = _ground_y - BALL_RADIUS * 2.0 - 4.0
	var high_y: float = _ground_y - PLAYER_HEIGHT - BALL_RADIUS * 2.0 + 4.0
	play_area.draw_line(Vector2(0.0, low_y), Vector2(pw, low_y), Color(0.3, 0.15, 0.1, 0.2), 1.0)
	play_area.draw_line(Vector2(0.0, high_y), Vector2(pw, high_y), Color(0.1, 0.15, 0.3, 0.2), 1.0)

	# Balls dodged counter
	var dodge_text: String = "Dodged: " + str(_balls_dodged)
	play_area.draw_string(ThemeDB.fallback_font, Vector2(pw * 0.5 - 30.0, ph - 10.0), dodge_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.8, 0.8, 0.8))


func _on_game_start() -> void:
	var pw: float = play_area.size.x
	_ground_y = play_area.size.y * GROUND_RATIO
	_player_x = (pw - PLAYER_WIDTH) * 0.5
	_player_y = _ground_y
	_player_vy = 0.0
	_is_jumping = false
	_is_ducking = false
	_elapsed_time = 0.0
	_score = 0
	_eliminated = false
	_ball_active = false
	_warning_active = false
	_balls_dodged = 0
	_swing_speed_mult = INITIAL_SWING_SPEED
	_spawn_cooldown = 0.8
	_update_score_display()
	instruction_label.text = "SPACE = Jump, DOWN = Duck!"
	countdown_label.visible = false
	play_area.queue_redraw()


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! Survived!"
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Dodged: " + str(_balls_dodged)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
