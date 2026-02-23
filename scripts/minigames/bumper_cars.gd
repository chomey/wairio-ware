extends MiniGameBase

## Bumper Cars minigame (Survival).
## Move in an arena while AI bumper cars roam.
## Getting knocked out of bounds eliminates you.
## Use arrow keys to move.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const PLAYER_SIZE: float = 24.0
const CAR_SIZE: float = 20.0
const PLAYER_SPEED: float = 180.0
const CAR_BASE_SPEED: float = 100.0
const CAR_SPEED_INCREMENT: float = 8.0
const BOUNCE_FORCE: float = 300.0
const FRICTION: float = 3.0
const SPAWN_INTERVAL_INITIAL: float = 4.0
const SPAWN_INTERVAL_MIN: float = 2.0
const MAX_CARS: int = 10
const DIRECTION_CHANGE_MIN: float = 0.8
const DIRECTION_CHANGE_MAX: float = 2.5
const BOUNDARY_MARGIN: float = 30.0

var _player_x: float = 0.0
var _player_y: float = 0.0
var _player_vx: float = 0.0
var _player_vy: float = 0.0
var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _spawn_timer: float = 2.0

# Input
var _input_left: bool = false
var _input_right: bool = false
var _input_up: bool = false
var _input_down: bool = false

# AI cars: {x, y, vx, vy, dir_timer, hue}
var _cars: Array[Dictionary] = []


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

	# Player input movement
	var move_x: float = 0.0
	var move_y: float = 0.0
	if _input_left:
		move_x -= 1.0
	if _input_right:
		move_x += 1.0
	if _input_up:
		move_y -= 1.0
	if _input_down:
		move_y += 1.0

	var move_len: float = sqrt(move_x * move_x + move_y * move_y)
	if move_len > 0.0:
		move_x = move_x / move_len * PLAYER_SPEED
		move_y = move_y / move_len * PLAYER_SPEED

	# Apply friction to knockback velocity
	_player_vx *= maxf(0.0, 1.0 - FRICTION * delta)
	_player_vy *= maxf(0.0, 1.0 - FRICTION * delta)

	# Update player position (input + knockback)
	_player_x += (move_x + _player_vx) * delta
	_player_y += (move_y + _player_vy) * delta

	# Check if player is out of bounds (eliminated)
	var half: float = PLAYER_SIZE * 0.5
	if _player_x < -half or _player_x > pw + half or _player_y < -half or _player_y > ph + half:
		_eliminated = true
		instruction_label.text = "Knocked out! Eliminated!"
		play_area.queue_redraw()
		mark_completed(_score)
		return

	# Spawn AI cars
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _cars.size() < MAX_CARS:
		_spawn_car(pw, ph)
		var interval: float = maxf(SPAWN_INTERVAL_INITIAL - _elapsed_time * 0.2, SPAWN_INTERVAL_MIN)
		_spawn_timer = interval

	# Update AI cars
	var current_speed: float = CAR_BASE_SPEED + _elapsed_time * CAR_SPEED_INCREMENT

	for i: int in range(_cars.size()):
		var c: Dictionary = _cars[i]

		# Direction change timer
		c["dir_timer"] = (c["dir_timer"] as float) - delta
		if (c["dir_timer"] as float) <= 0.0:
			var angle: float = randf() * TAU
			c["vx"] = cos(angle)
			c["vy"] = sin(angle)
			c["dir_timer"] = randf_range(DIRECTION_CHANGE_MIN, DIRECTION_CHANGE_MAX)

		# Move car
		c["x"] = (c["x"] as float) + (c["vx"] as float) * current_speed * delta
		c["y"] = (c["y"] as float) + (c["vy"] as float) * current_speed * delta

		# Bounce off arena walls
		if (c["x"] as float) < CAR_SIZE * 0.5:
			c["x"] = CAR_SIZE * 0.5
			c["vx"] = absf(c["vx"] as float)
		elif (c["x"] as float) > pw - CAR_SIZE * 0.5:
			c["x"] = pw - CAR_SIZE * 0.5
			c["vx"] = -absf(c["vx"] as float)

		if (c["y"] as float) < CAR_SIZE * 0.5:
			c["y"] = CAR_SIZE * 0.5
			c["vy"] = absf(c["vy"] as float)
		elif (c["y"] as float) > ph - CAR_SIZE * 0.5:
			c["y"] = ph - CAR_SIZE * 0.5
			c["vy"] = -absf(c["vy"] as float)

		# Check collision with player
		var dx: float = _player_x - (c["x"] as float)
		var dy: float = _player_y - (c["y"] as float)
		var dist: float = sqrt(dx * dx + dy * dy)
		var min_dist: float = (PLAYER_SIZE + CAR_SIZE) * 0.45

		if dist < min_dist and dist > 0.01:
			# Bump player away
			var nx: float = dx / dist
			var ny: float = dy / dist
			var bump_strength: float = BOUNCE_FORCE + _elapsed_time * 15.0
			_player_vx += nx * bump_strength
			_player_vy += ny * bump_strength
			# Push player out of overlap
			var overlap: float = min_dist - dist
			_player_x += nx * overlap
			_player_y += ny * overlap

	play_area.queue_redraw()


func _spawn_car(pw: float, ph: float) -> void:
	var x: float
	var y: float
	var attempts: int = 0

	while attempts < 20:
		var side: int = randi() % 4
		match side:
			0:  # Top
				x = randf_range(BOUNDARY_MARGIN, pw - BOUNDARY_MARGIN)
				y = CAR_SIZE
			1:  # Bottom
				x = randf_range(BOUNDARY_MARGIN, pw - BOUNDARY_MARGIN)
				y = ph - CAR_SIZE
			2:  # Left
				x = CAR_SIZE
				y = randf_range(BOUNDARY_MARGIN, ph - BOUNDARY_MARGIN)
			_:  # Right
				x = pw - CAR_SIZE
				y = randf_range(BOUNDARY_MARGIN, ph - BOUNDARY_MARGIN)

		var dx: float = x - _player_x
		var dy: float = y - _player_y
		if sqrt(dx * dx + dy * dy) > 80.0:
			break
		attempts += 1

	var angle: float = randf() * TAU
	var car: Dictionary = {
		"x": x,
		"y": y,
		"vx": cos(angle),
		"vy": sin(angle),
		"dir_timer": randf_range(DIRECTION_CHANGE_MIN, DIRECTION_CHANGE_MAX),
		"hue": randf()
	}
	_cars.append(car)


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _eliminated:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == KEY_LEFT:
			_input_left = key_event.pressed
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_RIGHT:
			_input_right = key_event.pressed
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_UP:
			_input_up = key_event.pressed
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_DOWN:
			_input_down = key_event.pressed
			get_viewport().set_input_as_handled()


func _on_play_area_draw() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y

	# Draw arena border with danger zone
	play_area.draw_rect(Rect2(0.0, 0.0, pw, ph), Color(0.4, 0.3, 0.2, 0.5), false, 2.0)

	# Draw AI bumper cars
	for c: Dictionary in _cars:
		var cx: float = c["x"] as float
		var cy: float = c["y"] as float
		var hue: float = c["hue"] as float
		var car_color: Color = Color.from_hsv(hue, 0.7, 0.8, 1.0)
		var car_dark: Color = Color.from_hsv(hue, 0.6, 0.5, 1.0)

		# Car body (rounded rect via circle + rect)
		var car_half: float = CAR_SIZE * 0.5
		play_area.draw_rect(Rect2(cx - car_half, cy - car_half, CAR_SIZE, CAR_SIZE), car_color)
		play_area.draw_rect(Rect2(cx - car_half, cy - car_half, CAR_SIZE, CAR_SIZE), car_dark, false, 2.0)

		# Bumper ring
		play_area.draw_circle(Vector2(cx, cy), CAR_SIZE * 0.6, Color(0.8, 0.8, 0.8, 0.3))

	# Draw player
	if not _eliminated:
		var danger: float = 0.0
		var edge_dist: float = minf(minf(_player_x, pw - _player_x), minf(_player_y, ph - _player_y))
		if edge_dist < BOUNDARY_MARGIN:
			danger = 1.0 - edge_dist / BOUNDARY_MARGIN
		var player_color: Color = Color(0.3 + danger * 0.5, 0.8 - danger * 0.5, 0.4 - danger * 0.3, 1.0)

		var p_half: float = PLAYER_SIZE * 0.5
		play_area.draw_rect(Rect2(_player_x - p_half, _player_y - p_half, PLAYER_SIZE, PLAYER_SIZE), player_color)
		play_area.draw_rect(Rect2(_player_x - p_half, _player_y - p_half, PLAYER_SIZE, PLAYER_SIZE), Color.WHITE, false, 2.0)

		# Knockback indicator
		var knock_mag: float = sqrt(_player_vx * _player_vx + _player_vy * _player_vy)
		if knock_mag > 30.0:
			var trail_alpha: float = minf(knock_mag / 300.0, 0.6)
			play_area.draw_circle(Vector2(_player_x, _player_y), PLAYER_SIZE * 0.8, Color(1.0, 0.9, 0.3, trail_alpha))

	# Car count
	var count_text: String = "Cars: " + str(_cars.size())
	play_area.draw_string(ThemeDB.fallback_font, Vector2(pw * 0.5 - 25.0, ph - 10.0), count_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.8, 0.8, 0.8))


func _on_game_start() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y
	_player_x = pw * 0.5
	_player_y = ph * 0.5
	_player_vx = 0.0
	_player_vy = 0.0
	_elapsed_time = 0.0
	_score = 0
	_eliminated = false
	_spawn_timer = 1.5
	_input_left = false
	_input_right = false
	_input_up = false
	_input_down = false
	_cars.clear()
	# Start with 3 AI bumper cars
	_spawn_car(pw, ph)
	_spawn_car(pw, ph)
	_spawn_car(pw, ph)
	_update_score_display()
	instruction_label.text = "Arrow keys to dodge bumper cars!"
	countdown_label.visible = false
	play_area.queue_redraw()


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! Survived!"
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Cars: " + str(_cars.size())


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
