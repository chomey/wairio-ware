extends MiniGameBase

## Firewalk minigame (Survival).
## Floor tiles randomly ignite. Move to safe tiles with arrow keys.
## Standing on a fire tile eliminates the player.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const GRID_COLS: int = 8
const GRID_ROWS: int = 6
const PLAYER_SPEED: float = 5.0  # Grid cells per second (smooth movement)

const IGNITE_INTERVAL_INITIAL: float = 2.0
const IGNITE_INTERVAL_MIN: float = 0.5
const WARNING_DURATION: float = 1.2
const FIRE_DURATION: float = 2.5

var _player_col: int = 0
var _player_row: int = 0
var _player_x: float = 0.0
var _player_y: float = 0.0
var _target_x: float = 0.0
var _target_y: float = 0.0
var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _ignite_timer: float = 1.5

# Input
var _input_left: bool = false
var _input_right: bool = false
var _input_up: bool = false
var _input_down: bool = false

# Tile states: 0=safe, 1=warning, 2=fire
var _tile_states: Array[int] = []
# Tile timers (time remaining in current state)
var _tile_timers: Array[float] = []


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	_init_grid()
	_update_score_display()
	instruction_label.text = "Get ready..."
	play_area.draw.connect(_on_play_area_draw)


func _init_grid() -> void:
	_tile_states.clear()
	_tile_timers.clear()
	for i: int in range(GRID_COLS * GRID_ROWS):
		_tile_states.append(0)
		_tile_timers.append(0.0)


func _get_tile_size() -> Vector2:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y
	return Vector2(pw / float(GRID_COLS), ph / float(GRID_ROWS))


func _grid_to_pos(col: int, row: int) -> Vector2:
	var ts: Vector2 = _get_tile_size()
	return Vector2(float(col) * ts.x + ts.x * 0.5, float(row) * ts.y + ts.y * 0.5)


func _process(delta: float) -> void:
	if not game_active or _eliminated:
		return

	_elapsed_time += delta
	_score = int(_elapsed_time * 10.0)
	_update_score_display()

	# Update tile timers
	for i: int in range(GRID_COLS * GRID_ROWS):
		if _tile_states[i] == 0:
			continue
		_tile_timers[i] -= delta
		if _tile_timers[i] <= 0.0:
			if _tile_states[i] == 1:
				# Warning -> Fire
				_tile_states[i] = 2
				_tile_timers[i] = FIRE_DURATION
			else:
				# Fire -> Safe
				_tile_states[i] = 0
				_tile_timers[i] = 0.0

	# Spawn new fires
	_ignite_timer -= delta
	if _ignite_timer <= 0.0:
		_ignite_random_tile()
		var interval: float = maxf(IGNITE_INTERVAL_INITIAL - _elapsed_time * 0.15, IGNITE_INTERVAL_MIN)
		_ignite_timer = interval

	# Move player smoothly toward target
	var ts: Vector2 = _get_tile_size()
	var speed: float = PLAYER_SPEED * maxf(ts.x, ts.y) * delta
	var dx: float = _target_x - _player_x
	var dy: float = _target_y - _player_y
	var dist: float = sqrt(dx * dx + dy * dy)
	if dist > 1.0:
		var move_dist: float = minf(speed, dist)
		_player_x += dx / dist * move_dist
		_player_y += dy / dist * move_dist
	else:
		_player_x = _target_x
		_player_y = _target_y

	# Check if player is on a fire tile
	var player_idx: int = _player_row * GRID_COLS + _player_col
	if _tile_states[player_idx] == 2:
		_eliminated = true
		instruction_label.text = "Burned! Eliminated!"
		play_area.queue_redraw()
		mark_completed(_score)
		return

	play_area.queue_redraw()


func _ignite_random_tile() -> void:
	# Collect safe tiles that aren't the player's tile
	var safe_tiles: Array[int] = []
	var player_idx: int = _player_row * GRID_COLS + _player_col
	for i: int in range(GRID_COLS * GRID_ROWS):
		if _tile_states[i] == 0 and i != player_idx:
			safe_tiles.append(i)

	if safe_tiles.is_empty():
		return

	# Pick 1-3 tiles to ignite depending on elapsed time
	var count: int = mini(1 + int(_elapsed_time / 4.0), 3)
	count = mini(count, safe_tiles.size())

	for c: int in range(count):
		if safe_tiles.is_empty():
			break
		var idx: int = randi() % safe_tiles.size()
		var tile_idx: int = safe_tiles[idx]
		_tile_states[tile_idx] = 1
		_tile_timers[tile_idx] = WARNING_DURATION
		safe_tiles.remove_at(idx)


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _eliminated:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == KEY_LEFT:
			_input_left = key_event.pressed
			if key_event.pressed and _player_col > 0:
				_player_col -= 1
				_target_x = _grid_to_pos(_player_col, _player_row).x
				_target_y = _grid_to_pos(_player_col, _player_row).y
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_RIGHT:
			_input_right = key_event.pressed
			if key_event.pressed and _player_col < GRID_COLS - 1:
				_player_col += 1
				_target_x = _grid_to_pos(_player_col, _player_row).x
				_target_y = _grid_to_pos(_player_col, _player_row).y
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_UP:
			_input_up = key_event.pressed
			if key_event.pressed and _player_row > 0:
				_player_row -= 1
				_target_x = _grid_to_pos(_player_col, _player_row).x
				_target_y = _grid_to_pos(_player_col, _player_row).y
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_DOWN:
			_input_down = key_event.pressed
			if key_event.pressed and _player_row < GRID_ROWS - 1:
				_player_row += 1
				_target_x = _grid_to_pos(_player_col, _player_row).x
				_target_y = _grid_to_pos(_player_col, _player_row).y
			get_viewport().set_input_as_handled()


func _on_play_area_draw() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y
	var ts: Vector2 = _get_tile_size()

	# Draw tiles
	for row: int in range(GRID_ROWS):
		for col: int in range(GRID_COLS):
			var idx: int = row * GRID_COLS + col
			var rect: Rect2 = Rect2(float(col) * ts.x + 1.0, float(row) * ts.y + 1.0, ts.x - 2.0, ts.y - 2.0)

			var tile_color: Color
			match _tile_states[idx]:
				0:  # Safe
					var checker: float = 0.18 if (col + row) % 2 == 0 else 0.14
					tile_color = Color(checker, checker + 0.05, checker, 1.0)
				1:  # Warning - pulsing yellow/orange
					var pulse: float = 0.5 + 0.5 * sin(_elapsed_time * 8.0)
					tile_color = Color(0.9, 0.6 + pulse * 0.3, 0.1, 1.0)
				2:  # Fire - bright red/orange
					var flicker: float = 0.8 + 0.2 * sin(_elapsed_time * 12.0 + float(idx) * 0.5)
					tile_color = Color(0.9 * flicker, 0.2 * flicker, 0.05, 1.0)
				_:
					tile_color = Color(0.15, 0.15, 0.15, 1.0)

			play_area.draw_rect(rect, tile_color)

			# Draw fire effect on burning tiles
			if _tile_states[idx] == 2:
				var cx: float = float(col) * ts.x + ts.x * 0.5
				var cy: float = float(row) * ts.y + ts.y * 0.5
				var flame_offset: float = sin(_elapsed_time * 10.0 + float(idx)) * 3.0
				play_area.draw_circle(Vector2(cx + flame_offset, cy - 5.0), ts.x * 0.2, Color(1.0, 0.5, 0.0, 0.6))
				play_area.draw_circle(Vector2(cx - flame_offset, cy + 3.0), ts.x * 0.15, Color(1.0, 0.3, 0.0, 0.4))

	# Draw player
	if not _eliminated:
		var player_radius: float = minf(ts.x, ts.y) * 0.35
		play_area.draw_circle(Vector2(_player_x, _player_y), player_radius, Color(0.2, 0.7, 1.0, 1.0))
		play_area.draw_circle(Vector2(_player_x, _player_y), player_radius - 3.0, Color(0.3, 0.8, 1.0, 1.0))

	# Draw grid lines
	for col: int in range(GRID_COLS + 1):
		var x: float = float(col) * ts.x
		play_area.draw_line(Vector2(x, 0.0), Vector2(x, ph), Color(0.3, 0.3, 0.3, 0.3), 1.0)
	for row: int in range(GRID_ROWS + 1):
		var y: float = float(row) * ts.y
		play_area.draw_line(Vector2(0.0, y), Vector2(pw, y), Color(0.3, 0.3, 0.3, 0.3), 1.0)


func _on_game_start() -> void:
	_init_grid()
	_player_col = GRID_COLS / 2
	_player_row = GRID_ROWS / 2
	var start_pos: Vector2 = _grid_to_pos(_player_col, _player_row)
	_player_x = start_pos.x
	_player_y = start_pos.y
	_target_x = start_pos.x
	_target_y = start_pos.y
	_elapsed_time = 0.0
	_score = 0
	_eliminated = false
	_ignite_timer = 1.5
	_input_left = false
	_input_right = false
	_input_up = false
	_input_down = false
	_update_score_display()
	instruction_label.text = "Arrow keys to move! Avoid fire tiles!"
	countdown_label.visible = false
	play_area.queue_redraw()


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! Survived!"
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Time: " + str(snappedi(_elapsed_time * 10, 1) / 10.0) + "s"


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
