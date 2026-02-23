extends MiniGameBase

## Tornado Dodge minigame (Survival).
## Tornadoes wander the arena with semi-random movement.
## Use arrow keys to move and avoid them.
## More tornadoes spawn over time.
## Touching a tornado eliminates the player.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const PLAYER_RADIUS: float = 10.0
const TORNADO_RADIUS: float = 16.0
const PLAYER_SPEED: float = 200.0
const TORNADO_SPEED: float = 80.0
const TORNADO_SPEED_INCREMENT: float = 5.0
const SPAWN_INTERVAL_INITIAL: float = 3.0
const SPAWN_INTERVAL_MIN: float = 1.5
const MAX_TORNADOES: int = 12
const DIRECTION_CHANGE_INTERVAL: float = 1.5

var _player_x: float = 0.0
var _player_y: float = 0.0
var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _spawn_timer: float = 2.0

# Input
var _input_left: bool = false
var _input_right: bool = false
var _input_up: bool = false
var _input_down: bool = false

# Tornadoes: {x, y, vx, vy, dir_timer}
var _tornadoes: Array[Dictionary] = []


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

	# Move player
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

	# Normalize diagonal movement
	var move_len: float = sqrt(move_x * move_x + move_y * move_y)
	if move_len > 0.0:
		move_x = move_x / move_len * PLAYER_SPEED * delta
		move_y = move_y / move_len * PLAYER_SPEED * delta
		_player_x += move_x
		_player_y += move_y

	# Clamp player to arena
	_player_x = clampf(_player_x, PLAYER_RADIUS, pw - PLAYER_RADIUS)
	_player_y = clampf(_player_y, PLAYER_RADIUS, ph - PLAYER_RADIUS)

	# Spawn tornadoes
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _tornadoes.size() < MAX_TORNADOES:
		_spawn_tornado(pw, ph)
		var interval: float = maxf(SPAWN_INTERVAL_INITIAL - _elapsed_time * 0.15, SPAWN_INTERVAL_MIN)
		_spawn_timer = interval

	# Update tornadoes
	var current_speed: float = TORNADO_SPEED + _elapsed_time * TORNADO_SPEED_INCREMENT

	for i: int in range(_tornadoes.size()):
		var t: Dictionary = _tornadoes[i]

		# Direction change timer
		t["dir_timer"] = (t["dir_timer"] as float) - delta
		if (t["dir_timer"] as float) <= 0.0:
			var angle: float = randf() * TAU
			t["vx"] = cos(angle)
			t["vy"] = sin(angle)
			t["dir_timer"] = randf_range(0.8, DIRECTION_CHANGE_INTERVAL)

		# Move tornado
		t["x"] = (t["x"] as float) + (t["vx"] as float) * current_speed * delta
		t["y"] = (t["y"] as float) + (t["vy"] as float) * current_speed * delta

		# Bounce off walls
		if (t["x"] as float) < TORNADO_RADIUS:
			t["x"] = TORNADO_RADIUS
			t["vx"] = absf(t["vx"] as float)
		elif (t["x"] as float) > pw - TORNADO_RADIUS:
			t["x"] = pw - TORNADO_RADIUS
			t["vx"] = -absf(t["vx"] as float)

		if (t["y"] as float) < TORNADO_RADIUS:
			t["y"] = TORNADO_RADIUS
			t["vy"] = absf(t["vy"] as float)
		elif (t["y"] as float) > ph - TORNADO_RADIUS:
			t["y"] = ph - TORNADO_RADIUS
			t["vy"] = -absf(t["vy"] as float)

		# Check collision with player
		var dx: float = (t["x"] as float) - _player_x
		var dy: float = (t["y"] as float) - _player_y
		var dist: float = sqrt(dx * dx + dy * dy)
		var min_dist: float = PLAYER_RADIUS + TORNADO_RADIUS * 0.8

		if dist < min_dist:
			_eliminated = true
			instruction_label.text = "Caught by tornado! Eliminated!"
			play_area.queue_redraw()
			mark_completed(_score)
			return

	play_area.queue_redraw()


func _spawn_tornado(pw: float, ph: float) -> void:
	# Spawn at a random edge, away from player
	var x: float
	var y: float
	var attempts: int = 0

	while attempts < 20:
		var side: int = randi() % 4
		match side:
			0:  # Top
				x = randf_range(TORNADO_RADIUS, pw - TORNADO_RADIUS)
				y = TORNADO_RADIUS
			1:  # Bottom
				x = randf_range(TORNADO_RADIUS, pw - TORNADO_RADIUS)
				y = ph - TORNADO_RADIUS
			2:  # Left
				x = TORNADO_RADIUS
				y = randf_range(TORNADO_RADIUS, ph - TORNADO_RADIUS)
			_:  # Right
				x = pw - TORNADO_RADIUS
				y = randf_range(TORNADO_RADIUS, ph - TORNADO_RADIUS)

		var dx: float = x - _player_x
		var dy: float = y - _player_y
		if sqrt(dx * dx + dy * dy) > 100.0:
			break
		attempts += 1

	var angle: float = randf() * TAU
	var tornado: Dictionary = {
		"x": x,
		"y": y,
		"vx": cos(angle),
		"vy": sin(angle),
		"dir_timer": randf_range(0.5, DIRECTION_CHANGE_INTERVAL),
		"phase": randf() * TAU  # For visual rotation
	}
	_tornadoes.append(tornado)


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

	# Draw arena border
	play_area.draw_rect(Rect2(0.0, 0.0, pw, ph), Color(0.3, 0.3, 0.35, 0.4), false, 2.0)

	# Draw tornadoes
	for t: Dictionary in _tornadoes:
		var tx: float = t["x"] as float
		var ty: float = t["y"] as float
		var phase: float = t["phase"] as float

		# Spinning visual
		var spin: float = _elapsed_time * 5.0 + phase
		for ring: int in range(3):
			var ring_radius: float = TORNADO_RADIUS * (0.4 + float(ring) * 0.3)
			var ring_alpha: float = 0.7 - float(ring) * 0.2
			var offset_x: float = cos(spin + float(ring) * 2.0) * 3.0
			var offset_y: float = sin(spin + float(ring) * 2.0) * 3.0
			play_area.draw_circle(Vector2(tx + offset_x, ty + offset_y), ring_radius, Color(0.5, 0.5, 0.6, ring_alpha))

		# Core
		play_area.draw_circle(Vector2(tx, ty), TORNADO_RADIUS * 0.3, Color(0.7, 0.7, 0.8, 0.9))

	# Draw player
	if not _eliminated:
		play_area.draw_circle(Vector2(_player_x, _player_y), PLAYER_RADIUS, Color(0.3, 0.8, 0.4, 1.0))
		play_area.draw_circle(Vector2(_player_x, _player_y), PLAYER_RADIUS - 3.0, Color(0.4, 0.9, 0.5, 1.0))

	# Tornado count
	var count_text: String = "Tornadoes: " + str(_tornadoes.size())
	play_area.draw_string(ThemeDB.fallback_font, Vector2(pw * 0.5 - 40.0, ph - 10.0), count_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.8, 0.8, 0.8))


func _on_game_start() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y
	_player_x = pw * 0.5
	_player_y = ph * 0.5
	_elapsed_time = 0.0
	_score = 0
	_eliminated = false
	_spawn_timer = 1.0
	_input_left = false
	_input_right = false
	_input_up = false
	_input_down = false
	_tornadoes.clear()
	# Start with 2 tornadoes
	_spawn_tornado(pw, ph)
	_spawn_tornado(pw, ph)
	_update_score_display()
	instruction_label.text = "Arrow keys to dodge tornadoes!"
	countdown_label.visible = false
	play_area.queue_redraw()


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! Survived!"
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Tornadoes: " + str(_tornadoes.size())


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
