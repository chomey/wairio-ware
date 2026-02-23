extends MiniGameBase

## Pinball Bounce minigame (Survival).
## A ball bounces around the play area. Player controls a paddle at the bottom.
## Use LEFT/RIGHT arrow keys to move the paddle and keep the ball alive.
## If the ball falls below the paddle, the player is eliminated.
## Ball speed increases over time.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const PADDLE_WIDTH: float = 80.0
const PADDLE_HEIGHT: float = 12.0
const PADDLE_Y_OFFSET: float = 30.0
const PADDLE_SPEED: float = 350.0
const BALL_RADIUS: float = 8.0
const INITIAL_BALL_SPEED: float = 180.0
const SPEED_INCREMENT: float = 8.0
const MAX_BALL_SPEED: float = 500.0
const PADDLE_SHRINK_RATE: float = 1.5
const MIN_PADDLE_WIDTH: float = 40.0

var _paddle_x: float = 0.0
var _paddle_y: float = 0.0
var _current_paddle_width: float = PADDLE_WIDTH
var _ball_x: float = 0.0
var _ball_y: float = 0.0
var _ball_vx: float = 0.0
var _ball_vy: float = 0.0
var _ball_speed: float = INITIAL_BALL_SPEED
var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _bounces: int = 0

# Input
var _move_left: bool = false
var _move_right: bool = false


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
	var ph: float = play_area.size.y
	_paddle_y = ph - PADDLE_Y_OFFSET

	# Increase ball speed over time
	_ball_speed = minf(INITIAL_BALL_SPEED + _elapsed_time * SPEED_INCREMENT, MAX_BALL_SPEED)

	# Shrink paddle over time
	_current_paddle_width = maxf(PADDLE_WIDTH - _elapsed_time * PADDLE_SHRINK_RATE, MIN_PADDLE_WIDTH)

	# Move paddle
	if _move_left:
		_paddle_x -= PADDLE_SPEED * delta
	if _move_right:
		_paddle_x += PADDLE_SPEED * delta
	_paddle_x = clampf(_paddle_x, 0.0, pw - _current_paddle_width)

	# Normalize ball velocity to current speed
	var vel_len: float = sqrt(_ball_vx * _ball_vx + _ball_vy * _ball_vy)
	if vel_len > 0.0:
		_ball_vx = _ball_vx / vel_len * _ball_speed
		_ball_vy = _ball_vy / vel_len * _ball_speed

	# Move ball
	_ball_x += _ball_vx * delta
	_ball_y += _ball_vy * delta

	# Wall bounces (left, right, top)
	if _ball_x - BALL_RADIUS < 0.0:
		_ball_x = BALL_RADIUS
		_ball_vx = absf(_ball_vx)
	elif _ball_x + BALL_RADIUS > pw:
		_ball_x = pw - BALL_RADIUS
		_ball_vx = -absf(_ball_vx)

	if _ball_y - BALL_RADIUS < 0.0:
		_ball_y = BALL_RADIUS
		_ball_vy = absf(_ball_vy)

	# Paddle collision
	if _ball_vy > 0.0:  # Ball moving downward
		if _ball_y + BALL_RADIUS >= _paddle_y and _ball_y + BALL_RADIUS <= _paddle_y + PADDLE_HEIGHT + 5.0:
			if _ball_x >= _paddle_x - BALL_RADIUS and _ball_x <= _paddle_x + _current_paddle_width + BALL_RADIUS:
				_ball_y = _paddle_y - BALL_RADIUS
				_ball_vy = -absf(_ball_vy)
				_bounces += 1

				# Add angle variation based on where ball hits paddle
				var hit_pos: float = (_ball_x - _paddle_x) / _current_paddle_width  # 0.0 to 1.0
				var angle_offset: float = (hit_pos - 0.5) * 0.6
				_ball_vx += angle_offset * _ball_speed

	# Check if ball fell below paddle
	if _ball_y - BALL_RADIUS > ph:
		_eliminated = true
		instruction_label.text = "Ball lost! Eliminated!"
		play_area.queue_redraw()
		mark_completed(_score)
		return

	play_area.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _eliminated:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == KEY_LEFT:
			_move_left = key_event.pressed
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_RIGHT:
			_move_right = key_event.pressed
			get_viewport().set_input_as_handled()


func _on_play_area_draw() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y
	_paddle_y = ph - PADDLE_Y_OFFSET

	# Draw walls (top and sides)
	play_area.draw_line(Vector2(0.0, 0.0), Vector2(pw, 0.0), Color(0.4, 0.4, 0.5, 0.6), 2.0)
	play_area.draw_line(Vector2(0.0, 0.0), Vector2(0.0, ph), Color(0.4, 0.4, 0.5, 0.6), 2.0)
	play_area.draw_line(Vector2(pw, 0.0), Vector2(pw, ph), Color(0.4, 0.4, 0.5, 0.6), 2.0)

	# Draw danger zone (below paddle)
	play_area.draw_rect(Rect2(0.0, _paddle_y + PADDLE_HEIGHT, pw, ph - _paddle_y - PADDLE_HEIGHT), Color(0.3, 0.05, 0.05, 0.2))

	# Draw paddle
	var paddle_color: Color = Color(0.3, 0.7, 0.9, 1.0)
	play_area.draw_rect(Rect2(_paddle_x, _paddle_y, _current_paddle_width, PADDLE_HEIGHT), paddle_color)
	play_area.draw_rect(Rect2(_paddle_x + 2.0, _paddle_y + 2.0, _current_paddle_width - 4.0, PADDLE_HEIGHT - 4.0), paddle_color.lightened(0.2))

	# Draw ball
	if not _eliminated:
		var ball_pulse: float = 0.8 + absf(sin(_elapsed_time * 6.0)) * 0.2
		play_area.draw_circle(Vector2(_ball_x, _ball_y), BALL_RADIUS, Color(1.0, 0.9, 0.3, ball_pulse))
		play_area.draw_circle(Vector2(_ball_x, _ball_y), BALL_RADIUS - 2.0, Color(1.0, 1.0, 0.6, ball_pulse))

	# Bounces counter
	var bounce_text: String = "Bounces: " + str(_bounces)
	play_area.draw_string(ThemeDB.fallback_font, Vector2(pw * 0.5 - 30.0, ph - 5.0), bounce_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.8, 0.8, 0.8))


func _on_game_start() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y
	_paddle_y = ph - PADDLE_Y_OFFSET
	_paddle_x = (pw - PADDLE_WIDTH) * 0.5
	_current_paddle_width = PADDLE_WIDTH

	# Launch ball from center, angled downward
	_ball_x = pw * 0.5
	_ball_y = ph * 0.3
	var launch_angle: float = randf_range(0.8, 1.2)  # Slightly random downward angle
	_ball_vx = cos(launch_angle) * INITIAL_BALL_SPEED * (1.0 if randf() > 0.5 else -1.0)
	_ball_vy = sin(launch_angle) * INITIAL_BALL_SPEED

	_ball_speed = INITIAL_BALL_SPEED
	_elapsed_time = 0.0
	_score = 0
	_eliminated = false
	_bounces = 0
	_move_left = false
	_move_right = false
	_update_score_display()
	instruction_label.text = "LEFT/RIGHT to move paddle!"
	countdown_label.visible = false
	play_area.queue_redraw()


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! Survived!"
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Bounces: " + str(_bounces)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
