extends MiniGameBase

## Wind Runner minigame (Survival).
## Wind gusts push the player in random directions.
## Use arrow keys to counter the wind and stay within the arena bounds.
## Getting blown off the edge eliminates the player.
## Wind strength and frequency increase over time.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const PLAYER_SIZE: float = 18.0
const MOVE_FORCE: float = 300.0
const DAMPING: float = 0.92
const INITIAL_WIND_STRENGTH: float = 120.0
const WIND_STRENGTH_INCREMENT: float = 15.0
const WIND_CHANGE_INTERVAL: float = 2.0
const WIND_CHANGE_ACCELERATION: float = 0.08
const GUST_CHANCE: float = 0.15
const GUST_MULTIPLIER: float = 2.5
const ARENA_MARGIN: float = 30.0

var _player_x: float = 0.0
var _player_y: float = 0.0
var _velocity_x: float = 0.0
var _velocity_y: float = 0.0
var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false

# Wind state
var _wind_x: float = 0.0
var _wind_y: float = 0.0
var _target_wind_x: float = 0.0
var _target_wind_y: float = 0.0
var _wind_timer: float = 0.0
var _wind_change_rate: float = WIND_CHANGE_INTERVAL
var _wind_strength: float = INITIAL_WIND_STRENGTH
var _is_gust: bool = false

# Input
var _input_left: bool = false
var _input_right: bool = false
var _input_up: bool = false
var _input_down: bool = false

# Visual wind particles
var _particles: Array[Dictionary] = []


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

	# Update wind
	_wind_strength = INITIAL_WIND_STRENGTH + _elapsed_time * WIND_STRENGTH_INCREMENT
	_wind_change_rate = maxf(WIND_CHANGE_INTERVAL - _elapsed_time * WIND_CHANGE_ACCELERATION, 0.6)

	_wind_timer -= delta
	if _wind_timer <= 0.0:
		_change_wind()
		_wind_timer = _wind_change_rate

	# Interpolate wind toward target
	_wind_x = lerpf(_wind_x, _target_wind_x, delta * 3.0)
	_wind_y = lerpf(_wind_y, _target_wind_y, delta * 3.0)

	# Apply wind force to player
	_velocity_x += _wind_x * delta
	_velocity_y += _wind_y * delta

	# Apply player input force
	if _input_left:
		_velocity_x -= MOVE_FORCE * delta
	if _input_right:
		_velocity_x += MOVE_FORCE * delta
	if _input_up:
		_velocity_y -= MOVE_FORCE * delta
	if _input_down:
		_velocity_y += MOVE_FORCE * delta

	# Apply damping
	_velocity_x *= DAMPING
	_velocity_y *= DAMPING

	# Update position
	_player_x += _velocity_x * delta
	_player_y += _velocity_y * delta

	# Check bounds
	if _player_x < ARENA_MARGIN - PLAYER_SIZE or _player_x > pw - ARENA_MARGIN or \
	   _player_y < ARENA_MARGIN - PLAYER_SIZE or _player_y > ph - ARENA_MARGIN:
		_eliminated = true
		instruction_label.text = "Blown away! Eliminated!"
		play_area.queue_redraw()
		mark_completed(_score)
		return

	# Update wind particles
	_update_particles(delta, pw, ph)

	play_area.queue_redraw()


func _change_wind() -> void:
	var angle: float = randf() * TAU
	var strength: float = _wind_strength

	_is_gust = randf() < GUST_CHANCE and _elapsed_time > 2.0
	if _is_gust:
		strength *= GUST_MULTIPLIER

	_target_wind_x = cos(angle) * strength
	_target_wind_y = sin(angle) * strength

	if _is_gust:
		instruction_label.text = "GUST!"
	else:
		# Show wind direction
		var dir_text: String = ""
		if absf(_target_wind_x) > absf(_target_wind_y):
			dir_text = "Wind: " + ("RIGHT" if _target_wind_x > 0.0 else "LEFT")
		else:
			dir_text = "Wind: " + ("DOWN" if _target_wind_y > 0.0 else "UP")
		instruction_label.text = dir_text


func _update_particles(delta: float, pw: float, ph: float) -> void:
	# Spawn new particles
	if _particles.size() < 20:
		var p: Dictionary = {
			"x": randf() * pw,
			"y": randf() * ph,
			"life": randf_range(0.5, 1.5)
		}
		_particles.append(p)

	# Update existing
	var remove_list: Array[int] = []
	for i: int in range(_particles.size()):
		_particles[i]["x"] = (_particles[i]["x"] as float) + _wind_x * delta * 0.5
		_particles[i]["y"] = (_particles[i]["y"] as float) + _wind_y * delta * 0.5
		_particles[i]["life"] = (_particles[i]["life"] as float) - delta

		if (_particles[i]["life"] as float) <= 0.0:
			remove_list.append(i)

	for i: int in range(remove_list.size() - 1, -1, -1):
		_particles.remove_at(remove_list[i])


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

	# Draw arena boundary
	var arena_rect: Rect2 = Rect2(ARENA_MARGIN, ARENA_MARGIN, pw - ARENA_MARGIN * 2.0, ph - ARENA_MARGIN * 2.0)
	play_area.draw_rect(arena_rect, Color(0.15, 0.2, 0.25, 0.3))
	play_area.draw_rect(arena_rect, Color(0.4, 0.5, 0.6, 0.5), false, 2.0)

	# Draw wind particles
	for p: Dictionary in _particles:
		var life: float = p["life"] as float
		var alpha: float = clampf(life, 0.0, 0.6)
		var color: Color = Color(0.7, 0.8, 0.9, alpha) if not _is_gust else Color(1.0, 0.6, 0.3, alpha)
		play_area.draw_circle(Vector2(p["x"] as float, p["y"] as float), 2.0, color)

	# Draw wind direction arrow at center
	var center_x: float = pw * 0.5
	var center_y: float = ph * 0.5
	var wind_len: float = sqrt(_wind_x * _wind_x + _wind_y * _wind_y)
	if wind_len > 10.0:
		var norm_x: float = _wind_x / wind_len
		var norm_y: float = _wind_y / wind_len
		var arrow_len: float = minf(wind_len * 0.3, 60.0)
		var arrow_end_x: float = center_x + norm_x * arrow_len
		var arrow_end_y: float = center_y + norm_y * arrow_len
		var arrow_color: Color = Color(0.5, 0.7, 0.9, 0.3) if not _is_gust else Color(1.0, 0.4, 0.2, 0.5)
		play_area.draw_line(Vector2(center_x, center_y), Vector2(arrow_end_x, arrow_end_y), arrow_color, 3.0)

	# Draw player
	if not _eliminated:
		var cx: float = _player_x + PLAYER_SIZE * 0.5
		var cy: float = _player_y + PLAYER_SIZE * 0.5

		# Danger color based on proximity to edge
		var edge_dist: float = minf(
			minf(_player_x - ARENA_MARGIN, pw - ARENA_MARGIN - _player_x - PLAYER_SIZE),
			minf(_player_y - ARENA_MARGIN, ph - ARENA_MARGIN - _player_y - PLAYER_SIZE)
		)
		var max_dist: float = minf(pw, ph) * 0.25
		var danger: float = 1.0 - clampf(edge_dist / max_dist, 0.0, 1.0)

		var player_color: Color = Color(0.3 + danger * 0.6, 0.8 - danger * 0.5, 0.3, 1.0)
		play_area.draw_circle(Vector2(cx, cy), PLAYER_SIZE * 0.5, player_color)
		play_area.draw_circle(Vector2(cx, cy), PLAYER_SIZE * 0.5 - 3.0, player_color.lightened(0.3))


func _on_game_start() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y
	_player_x = (pw - PLAYER_SIZE) * 0.5
	_player_y = (ph - PLAYER_SIZE) * 0.5
	_velocity_x = 0.0
	_velocity_y = 0.0
	_elapsed_time = 0.0
	_score = 0
	_eliminated = false
	_wind_x = 0.0
	_wind_y = 0.0
	_target_wind_x = 0.0
	_target_wind_y = 0.0
	_wind_timer = 1.0
	_wind_change_rate = WIND_CHANGE_INTERVAL
	_wind_strength = INITIAL_WIND_STRENGTH
	_is_gust = false
	_input_left = false
	_input_right = false
	_input_up = false
	_input_down = false
	_particles.clear()
	_update_score_display()
	instruction_label.text = "Arrow keys to fight the wind!"
	countdown_label.visible = false
	play_area.queue_redraw()


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! Survived!"
		submit_score(_score)


func _update_score_display() -> void:
	var time_str: String = str(snappedi(_elapsed_time * 10, 1) / 10.0)
	score_label.text = "Survived: " + time_str + "s"


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
