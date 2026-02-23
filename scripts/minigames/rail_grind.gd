extends MiniGameBase

## Rail Grind minigame (Survival).
## Character rides on one of 3 horizontal rails. Obstacles scroll from right to left.
## Press UP/DOWN arrow keys to switch tracks and avoid obstacles.
## Hitting an obstacle eliminates the player.
## Speed increases over time.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const NUM_TRACKS: int = 3
const PLAYER_SIZE: float = 20.0
const OBSTACLE_WIDTH: float = 30.0
const OBSTACLE_HEIGHT: float = 24.0
const INITIAL_SPEED: float = 180.0
const SPEED_INCREMENT: float = 8.0
const MIN_SPAWN_INTERVAL: float = 0.5
const MAX_SPAWN_INTERVAL: float = 1.2
const PLAYER_X_RATIO: float = 0.15

var _current_track: int = 1  # 0=top, 1=middle, 2=bottom
var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _scroll_speed: float = INITIAL_SPEED
var _obstacles_dodged: int = 0

# Obstacles: each is {track: int, x: float}
var _obstacles: Array[Dictionary] = []
var _spawn_timer: float = 0.0
var _next_spawn_interval: float = 0.8


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

	# Increase speed
	_scroll_speed = INITIAL_SPEED + _elapsed_time * SPEED_INCREMENT

	# Spawn obstacles
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_obstacle(pw)
		_spawn_timer = _next_spawn_interval

	# Move obstacles
	var player_x: float = pw * PLAYER_X_RATIO
	var remove_indices: Array[int] = []

	for i: int in range(_obstacles.size()):
		_obstacles[i]["x"] = (_obstacles[i]["x"] as float) - _scroll_speed * delta

		# Check collision with player
		var obs_x: float = _obstacles[i]["x"] as float
		var obs_track: int = _obstacles[i]["track"] as int

		if obs_track == _current_track:
			if obs_x < player_x + PLAYER_SIZE and obs_x + OBSTACLE_WIDTH > player_x:
				_eliminated = true
				instruction_label.text = "Hit obstacle! Eliminated!"
				play_area.queue_redraw()
				mark_completed(_score)
				return

		# Mark for removal if off screen
		if obs_x + OBSTACLE_WIDTH < -10.0:
			remove_indices.append(i)

	# Remove off-screen obstacles (reverse order)
	for i: int in range(remove_indices.size() - 1, -1, -1):
		_obstacles.remove_at(remove_indices[i])
		_obstacles_dodged += 1

	play_area.queue_redraw()


func _spawn_obstacle(play_width: float) -> void:
	# Pick 1-2 tracks to block
	var blocked_tracks: Array[int] = []
	var first_track: int = randi() % NUM_TRACKS
	blocked_tracks.append(first_track)

	# Sometimes block a second track (but never all 3)
	if _elapsed_time > 3.0 and randf() < 0.4:
		var second_track: int = (first_track + 1 + randi() % (NUM_TRACKS - 1)) % NUM_TRACKS
		blocked_tracks.append(second_track)

	for track: int in blocked_tracks:
		var obstacle: Dictionary = {
			"track": track,
			"x": play_width + 10.0
		}
		_obstacles.append(obstacle)

	# Adjust next spawn interval (gets faster over time)
	var interval_range: float = MAX_SPAWN_INTERVAL - MIN_SPAWN_INTERVAL
	var time_factor: float = clampf(_elapsed_time / 10.0, 0.0, 0.7)
	_next_spawn_interval = MAX_SPAWN_INTERVAL - interval_range * time_factor
	_next_spawn_interval *= randf_range(0.8, 1.2)
	_next_spawn_interval = maxf(_next_spawn_interval, MIN_SPAWN_INTERVAL)


func _get_track_y(track: int, play_height: float) -> float:
	var usable_height: float = play_height * 0.7
	var top_offset: float = play_height * 0.15
	var track_spacing: float = usable_height / float(NUM_TRACKS - 1) if NUM_TRACKS > 1 else 0.0
	return top_offset + float(track) * track_spacing


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _eliminated:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_UP:
				if _current_track > 0:
					_current_track -= 1
				get_viewport().set_input_as_handled()
			elif key_event.keycode == KEY_DOWN:
				if _current_track < NUM_TRACKS - 1:
					_current_track += 1
				get_viewport().set_input_as_handled()


func _on_play_area_draw() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y

	# Draw rails
	for i: int in range(NUM_TRACKS):
		var track_y: float = _get_track_y(i, ph)
		var rail_color: Color = Color(0.3, 0.3, 0.35, 0.6)
		play_area.draw_line(Vector2(0.0, track_y), Vector2(pw, track_y), rail_color, 2.0)

		# Track label
		var label_text: String = str(i + 1)
		play_area.draw_string(ThemeDB.fallback_font, Vector2(5.0, track_y - 8.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.5, 0.5))

	# Draw obstacles
	for obstacle: Dictionary in _obstacles:
		var obs_x: float = obstacle["x"] as float
		var obs_track: int = obstacle["track"] as int
		var track_y: float = _get_track_y(obs_track, ph)

		var obs_color: Color = Color(0.8, 0.2, 0.15, 0.9)
		play_area.draw_rect(Rect2(obs_x, track_y - OBSTACLE_HEIGHT * 0.5, OBSTACLE_WIDTH, OBSTACLE_HEIGHT), obs_color)
		play_area.draw_rect(Rect2(obs_x + 2.0, track_y - OBSTACLE_HEIGHT * 0.5 + 2.0, OBSTACLE_WIDTH - 4.0, OBSTACLE_HEIGHT - 4.0), Color(0.9, 0.35, 0.25, 0.9))

	# Draw player
	if not _eliminated:
		var player_x: float = pw * PLAYER_X_RATIO
		var player_y: float = _get_track_y(_current_track, ph)

		# Glow effect
		var pulse: float = 0.7 + absf(sin(_elapsed_time * 4.0)) * 0.3
		play_area.draw_circle(Vector2(player_x + PLAYER_SIZE * 0.5, player_y), PLAYER_SIZE * 0.5 + 4.0, Color(0.2, 0.7, 1.0, 0.2 * pulse))
		play_area.draw_circle(Vector2(player_x + PLAYER_SIZE * 0.5, player_y), PLAYER_SIZE * 0.5, Color(0.3, 0.8, 0.4, 1.0))
		play_area.draw_circle(Vector2(player_x + PLAYER_SIZE * 0.5, player_y), PLAYER_SIZE * 0.5 - 3.0, Color(0.4, 0.9, 0.5, 1.0))

	# Speed indicator
	var speed_text: String = "Speed: " + str(int(_scroll_speed))
	play_area.draw_string(ThemeDB.fallback_font, Vector2(pw - 100.0, ph - 10.0), speed_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.6, 0.6))

	# Dodged counter
	var dodge_text: String = "Dodged: " + str(_obstacles_dodged)
	play_area.draw_string(ThemeDB.fallback_font, Vector2(pw * 0.5 - 30.0, ph - 10.0), dodge_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.8, 0.8, 0.8))


func _on_game_start() -> void:
	_current_track = 1
	_elapsed_time = 0.0
	_score = 0
	_eliminated = false
	_scroll_speed = INITIAL_SPEED
	_obstacles_dodged = 0
	_obstacles.clear()
	_spawn_timer = 1.0
	_next_spawn_interval = 0.8
	_update_score_display()
	instruction_label.text = "UP/DOWN to switch tracks!"
	countdown_label.visible = false
	play_area.queue_redraw()


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! Survived!"
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Dodged: " + str(_obstacles_dodged)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
