extends MiniGameBase

## Block Breaker minigame.
## Classic breakout: move paddle with arrow keys, bounce ball to break blocks.
## Race to break 20 blocks.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var play_area: Control = %PlayArea

const COMPLETION_TARGET: int = 20
const PADDLE_WIDTH: float = 80.0
const PADDLE_HEIGHT: float = 10.0
const PADDLE_SPEED: float = 400.0
const BALL_SIZE: float = 8.0
const BALL_SPEED: float = 250.0
const BLOCK_COLS: int = 8
const BLOCK_ROWS: int = 4
const BLOCK_WIDTH: float = 50.0
const BLOCK_HEIGHT: float = 16.0
const BLOCK_PADDING: float = 4.0
const BLOCK_TOP_OFFSET: float = 20.0

var _score: int = 0
var _paddle_x: float = 0.0
var _ball_pos: Vector2 = Vector2.ZERO
var _ball_vel: Vector2 = Vector2.ZERO
var _blocks: Array[Rect2] = []
var _block_colors: Array[Color] = []
var _area_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	score_label.text = "Blocks: 0 / " + str(COMPLETION_TARGET)
	feedback_label.text = ""
	play_area.draw.connect(_on_play_area_draw)


func _on_game_start() -> void:
	countdown_label.visible = false
	_score = 0
	score_label.text = "Blocks: 0 / " + str(COMPLETION_TARGET)
	_area_size = play_area.size
	_setup_blocks()
	_reset_ball()


func _on_game_end() -> void:
	feedback_label.text = "Time's up! Broke " + str(_score) + " blocks!"
	submit_score(_score)


func _setup_blocks() -> void:
	_blocks.clear()
	_block_colors.clear()
	var total_width: float = BLOCK_COLS * (BLOCK_WIDTH + BLOCK_PADDING) - BLOCK_PADDING
	var start_x: float = (_area_size.x - total_width) / 2.0
	var row_colors: Array[Color] = [
		Color(1.0, 0.2, 0.2),  # red
		Color(1.0, 0.6, 0.1),  # orange
		Color(0.2, 0.8, 0.2),  # green
		Color(0.3, 0.5, 1.0),  # blue
	]
	for row: int in range(BLOCK_ROWS):
		for col: int in range(BLOCK_COLS):
			var bx: float = start_x + col * (BLOCK_WIDTH + BLOCK_PADDING)
			var by: float = BLOCK_TOP_OFFSET + row * (BLOCK_HEIGHT + BLOCK_PADDING)
			_blocks.append(Rect2(bx, by, BLOCK_WIDTH, BLOCK_HEIGHT))
			_block_colors.append(row_colors[row])


func _reset_ball() -> void:
	_paddle_x = _area_size.x / 2.0
	_ball_pos = Vector2(_area_size.x / 2.0, _area_size.y - 40.0)
	var angle: float = randf_range(-PI / 4.0, PI / 4.0) - PI / 2.0
	_ball_vel = Vector2(cos(angle), sin(angle)) * BALL_SPEED


func _process(delta: float) -> void:
	if not game_active:
		play_area.queue_redraw()
		return

	# Move paddle
	if Input.is_action_pressed("ui_left"):
		_paddle_x -= PADDLE_SPEED * delta
	if Input.is_action_pressed("ui_right"):
		_paddle_x += PADDLE_SPEED * delta
	_paddle_x = clampf(_paddle_x, PADDLE_WIDTH / 2.0, _area_size.x - PADDLE_WIDTH / 2.0)

	# Move ball
	_ball_pos += _ball_vel * delta

	# Wall collisions (left/right)
	if _ball_pos.x - BALL_SIZE < 0.0:
		_ball_pos.x = BALL_SIZE
		_ball_vel.x = absf(_ball_vel.x)
	elif _ball_pos.x + BALL_SIZE > _area_size.x:
		_ball_pos.x = _area_size.x - BALL_SIZE
		_ball_vel.x = -absf(_ball_vel.x)

	# Top wall
	if _ball_pos.y - BALL_SIZE < 0.0:
		_ball_pos.y = BALL_SIZE
		_ball_vel.y = absf(_ball_vel.y)

	# Paddle collision
	var paddle_rect: Rect2 = Rect2(
		_paddle_x - PADDLE_WIDTH / 2.0,
		_area_size.y - 20.0,
		PADDLE_WIDTH,
		PADDLE_HEIGHT
	)
	if _ball_vel.y > 0.0 and _ball_rect().intersects(paddle_rect):
		_ball_pos.y = paddle_rect.position.y - BALL_SIZE
		# Angle based on where the ball hit the paddle
		var hit_offset: float = (_ball_pos.x - _paddle_x) / (PADDLE_WIDTH / 2.0)
		hit_offset = clampf(hit_offset, -0.8, 0.8)
		var angle: float = hit_offset * PI / 3.0 - PI / 2.0
		_ball_vel = Vector2(cos(angle), sin(angle)) * _ball_vel.length()

	# Block collisions
	var i: int = _blocks.size() - 1
	while i >= 0:
		if _ball_rect().intersects(_blocks[i]):
			var block: Rect2 = _blocks[i]
			_blocks.remove_at(i)
			_block_colors.remove_at(i)
			_score += 1
			score_label.text = "Blocks: " + str(_score) + " / " + str(COMPLETION_TARGET)

			# Reflect ball based on overlap direction
			var ball_center: Vector2 = _ball_pos
			var block_center: Vector2 = block.get_center()
			var dx: float = absf(ball_center.x - block_center.x) - block.size.x / 2.0
			var dy: float = absf(ball_center.y - block_center.y) - block.size.y / 2.0
			if dx > dy:
				_ball_vel.x = -_ball_vel.x
			else:
				_ball_vel.y = -_ball_vel.y

			if _score >= COMPLETION_TARGET:
				mark_completed(_score)
				play_area.queue_redraw()
				return

			# Respawn blocks if all cleared before target
			if _blocks.is_empty():
				_setup_blocks()
			break
		i -= 1

	# Ball falls below paddle -> reset
	if _ball_pos.y > _area_size.y + BALL_SIZE:
		_reset_ball()

	play_area.queue_redraw()


func _ball_rect() -> Rect2:
	return Rect2(_ball_pos.x - BALL_SIZE, _ball_pos.y - BALL_SIZE, BALL_SIZE * 2.0, BALL_SIZE * 2.0)


func _on_play_area_draw() -> void:
	# Draw blocks
	for i: int in range(_blocks.size()):
		play_area.draw_rect(_blocks[i], _block_colors[i])

	# Draw paddle
	var paddle_rect: Rect2 = Rect2(
		_paddle_x - PADDLE_WIDTH / 2.0,
		_area_size.y - 20.0,
		PADDLE_WIDTH,
		PADDLE_HEIGHT
	)
	play_area.draw_rect(paddle_rect, Color.WHITE)

	# Draw ball
	play_area.draw_circle(_ball_pos, BALL_SIZE, Color.YELLOW)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
