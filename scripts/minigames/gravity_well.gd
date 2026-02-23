extends MiniGameBase

## Gravity Well minigame (Survival).
## Player orbits a center gravity well. Orbit drifts outward over time.
## Press arrow keys to apply thrust inward (toward center) or tangentially.
## If player drifts off screen, they are eliminated.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const PLAYER_RADIUS: float = 8.0
const WELL_RADIUS: float = 14.0
const INITIAL_ORBIT_RADIUS: float = 80.0
const INITIAL_ORBIT_SPEED: float = 1.8
const DRIFT_RATE: float = 12.0
const DRIFT_ACCELERATION: float = 1.5
const THRUST_STRENGTH: float = 180.0
const DAMPING: float = 0.97
const DANGER_ZONE_RATIO: float = 0.85

var _player_angle: float = 0.0
var _player_radius: float = INITIAL_ORBIT_RADIUS
var _radial_velocity: float = 0.0
var _angular_velocity: float = INITIAL_ORBIT_SPEED
var _center_x: float = 0.0
var _center_y: float = 0.0
var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _current_drift: float = DRIFT_RATE
var _orbits_completed: int = 0
var _last_quadrant: int = 0

# Input state
var _thrust_up: bool = false
var _thrust_down: bool = false
var _thrust_left: bool = false
var _thrust_right: bool = false


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
	_center_x = pw * 0.5
	_center_y = ph * 0.5

	# Apply drift outward (increasing over time)
	_current_drift = DRIFT_RATE + _elapsed_time * DRIFT_ACCELERATION
	_radial_velocity += _current_drift * delta

	# Apply player thrust (arrow keys map to directions relative to orbit)
	if _thrust_up:
		# Thrust inward (toward center)
		_radial_velocity -= THRUST_STRENGTH * delta
	if _thrust_down:
		# Thrust outward (away from center)
		_radial_velocity += THRUST_STRENGTH * 0.5 * delta
	if _thrust_left:
		# Speed up orbit (counter-clockwise)
		_angular_velocity += 2.0 * delta
	if _thrust_right:
		# Slow down orbit (clockwise boost)
		_angular_velocity -= 2.0 * delta

	# Apply damping to radial velocity
	_radial_velocity *= DAMPING

	# Update radius
	_player_radius += _radial_velocity * delta
	_player_radius = maxf(_player_radius, 15.0)  # Minimum orbit radius

	# Update angle
	_player_angle += _angular_velocity * delta

	# Track orbits
	var current_quadrant: int = int(_player_angle / (PI * 0.5)) % 4
	if current_quadrant < 0:
		current_quadrant += 4
	if _last_quadrant == 3 and current_quadrant == 0:
		_orbits_completed += 1
	_last_quadrant = current_quadrant

	# Check if off screen
	var player_x: float = _center_x + cos(_player_angle) * _player_radius
	var player_y: float = _center_y + sin(_player_angle) * _player_radius
	var margin: float = PLAYER_RADIUS + 5.0

	if player_x < -margin or player_x > pw + margin or player_y < -margin or player_y > ph + margin:
		_eliminated = true
		instruction_label.text = "Drifted away! Eliminated!"
		play_area.queue_redraw()
		mark_completed(_score)
		return

	play_area.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _eliminated:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == KEY_UP:
			_thrust_up = key_event.pressed
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_DOWN:
			_thrust_down = key_event.pressed
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_LEFT:
			_thrust_left = key_event.pressed
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_RIGHT:
			_thrust_right = key_event.pressed
			get_viewport().set_input_as_handled()


func _on_play_area_draw() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y
	_center_x = pw * 0.5
	_center_y = ph * 0.5

	var max_radius: float = minf(pw, ph) * 0.5

	# Draw danger zone boundary
	var danger_radius: float = max_radius * DANGER_ZONE_RATIO
	play_area.draw_circle(Vector2(_center_x, _center_y), danger_radius, Color(0.3, 0.05, 0.05, 0.15))
	play_area.draw_arc(Vector2(_center_x, _center_y), danger_radius, 0.0, TAU, 64, Color(0.6, 0.15, 0.1, 0.4), 1.0)

	# Draw orbit rings (guides)
	for i: int in range(1, 5):
		var ring_radius: float = max_radius * 0.2 * float(i)
		play_area.draw_arc(Vector2(_center_x, _center_y), ring_radius, 0.0, TAU, 48, Color(0.2, 0.25, 0.35, 0.2), 1.0)

	# Draw gravity well center
	var pulse: float = 0.7 + absf(sin(_elapsed_time * 3.0)) * 0.3
	play_area.draw_circle(Vector2(_center_x, _center_y), WELL_RADIUS, Color(0.5, 0.2, 0.8, pulse))
	play_area.draw_circle(Vector2(_center_x, _center_y), WELL_RADIUS * 0.5, Color(0.7, 0.4, 1.0, pulse))

	# Draw orbit trail (fading dots behind the player)
	var trail_count: int = 12
	for i: int in range(trail_count):
		var trail_angle: float = _player_angle - float(i + 1) * 0.15
		var trail_r: float = _player_radius - float(i) * 0.5
		if trail_r > 0.0:
			var tx: float = _center_x + cos(trail_angle) * trail_r
			var ty: float = _center_y + sin(trail_angle) * trail_r
			var alpha: float = 0.4 * (1.0 - float(i) / float(trail_count))
			play_area.draw_circle(Vector2(tx, ty), 3.0, Color(0.3, 0.7, 1.0, alpha))

	# Draw player
	if not _eliminated:
		var player_x: float = _center_x + cos(_player_angle) * _player_radius
		var player_y: float = _center_y + sin(_player_angle) * _player_radius

		# Color based on distance from center (green = safe, red = danger)
		var ratio: float = clampf(_player_radius / (max_radius * DANGER_ZONE_RATIO), 0.0, 1.5)
		var player_color: Color
		if ratio < 0.7:
			player_color = Color(0.3, 0.9, 0.4, 1.0)
		elif ratio < 1.0:
			player_color = Color(0.9, 0.9, 0.2, 1.0)
		else:
			player_color = Color(0.9, 0.3, 0.2, 1.0)

		play_area.draw_circle(Vector2(player_x, player_y), PLAYER_RADIUS, player_color)
		play_area.draw_circle(Vector2(player_x, player_y), PLAYER_RADIUS - 2.0, player_color.lightened(0.3))

		# Draw thrust indicator
		if _thrust_up:
			var thrust_x: float = player_x + cos(_player_angle) * (PLAYER_RADIUS + 6.0)
			var thrust_y: float = player_y + sin(_player_angle) * (PLAYER_RADIUS + 6.0)
			play_area.draw_circle(Vector2(thrust_x, thrust_y), 4.0, Color(1.0, 0.6, 0.2, 0.8))

	# Draw orbit info
	var orbit_text: String = "Orbits: " + str(_orbits_completed)
	play_area.draw_string(ThemeDB.fallback_font, Vector2(pw * 0.5 - 30.0, ph - 10.0), orbit_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.8, 0.8, 0.8))


func _on_game_start() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y
	_center_x = pw * 0.5
	_center_y = ph * 0.5
	_player_angle = 0.0
	_player_radius = INITIAL_ORBIT_RADIUS
	_radial_velocity = 0.0
	_angular_velocity = INITIAL_ORBIT_SPEED
	_elapsed_time = 0.0
	_score = 0
	_eliminated = false
	_current_drift = DRIFT_RATE
	_orbits_completed = 0
	_last_quadrant = 0
	_thrust_up = false
	_thrust_down = false
	_thrust_left = false
	_thrust_right = false
	_update_score_display()
	instruction_label.text = "UP = Pull inward, Arrows = Adjust orbit!"
	countdown_label.visible = false
	play_area.queue_redraw()


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! Survived!"
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Orbits: " + str(_orbits_completed)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
