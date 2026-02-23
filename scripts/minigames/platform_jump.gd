extends MiniGameBase

## Platform Jump minigame (Survival).
## Platforms scroll from right to left. Player stands on platforms.
## Use LEFT/RIGHT arrow keys to move and SPACE to jump.
## Falling off the bottom of the screen eliminates the player.
## Scroll speed increases over time.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const PLAYER_WIDTH: float = 16.0
const PLAYER_HEIGHT: float = 24.0
const PLATFORM_WIDTH: float = 80.0
const PLATFORM_HEIGHT: float = 10.0
const MOVE_SPEED: float = 180.0
const JUMP_VELOCITY: float = -350.0
const GRAVITY: float = 800.0
const INITIAL_SCROLL_SPEED: float = 60.0
const SCROLL_SPEED_INCREMENT: float = 5.0
const PLATFORM_SPACING_X: float = 140.0
const PLATFORM_Y_VARIANCE: float = 80.0

var _player_x: float = 0.0
var _player_y: float = 0.0
var _player_vy: float = 0.0
var _on_ground: bool = false
var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _scroll_speed: float = INITIAL_SCROLL_SPEED
var _platforms_passed: int = 0

# Input
var _move_left: bool = false
var _move_right: bool = false

# Platforms: {x, y, width}
var _platforms: Array[Dictionary] = []
var _next_platform_x: float = 0.0


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

	_scroll_speed = INITIAL_SCROLL_SPEED + _elapsed_time * SCROLL_SPEED_INCREMENT

	# Scroll platforms left
	for platform: Dictionary in _platforms:
		platform["x"] = (platform["x"] as float) - _scroll_speed * delta

	# Player also scrolls with platforms (standing on one)
	_player_x -= _scroll_speed * delta

	# Player horizontal movement (relative to scroll)
	if _move_left:
		_player_x -= MOVE_SPEED * delta
	if _move_right:
		_player_x += MOVE_SPEED * delta

	# Clamp to screen width
	_player_x = clampf(_player_x, 0.0, pw - PLAYER_WIDTH)

	# Apply gravity
	_player_vy += GRAVITY * delta
	_player_y += _player_vy * delta
	_on_ground = false

	# Check platform collisions (only when falling)
	if _player_vy >= 0.0:
		for platform: Dictionary in _platforms:
			var px: float = platform["x"] as float
			var py: float = platform["y"] as float
			var p_width: float = platform["width"] as float

			# Check if player is above platform and feet reach it
			if _player_x + PLAYER_WIDTH > px and _player_x < px + p_width:
				if _player_y + PLAYER_HEIGHT >= py and _player_y + PLAYER_HEIGHT <= py + PLATFORM_HEIGHT + _player_vy * delta + 5.0:
					_player_y = py - PLAYER_HEIGHT
					_player_vy = 0.0
					_on_ground = true
					break

	# Generate new platforms
	_generate_platforms(pw, ph)

	# Remove old platforms
	_cleanup_platforms()

	# Check if fell off screen
	if _player_y > ph + PLAYER_HEIGHT:
		_eliminated = true
		instruction_label.text = "Fell off! Eliminated!"
		play_area.queue_redraw()
		mark_completed(_score)
		return

	play_area.queue_redraw()


func _generate_platforms(pw: float, ph: float) -> void:
	while _next_platform_x < pw + PLATFORM_SPACING_X:
		var base_y: float = ph * 0.6
		var y_offset: float = randf_range(-PLATFORM_Y_VARIANCE, PLATFORM_Y_VARIANCE * 0.3)
		var width: float = PLATFORM_WIDTH * randf_range(0.7, 1.3)

		var platform: Dictionary = {
			"x": _next_platform_x,
			"y": base_y + y_offset,
			"width": width
		}
		_platforms.append(platform)
		_next_platform_x += PLATFORM_SPACING_X * randf_range(0.8, 1.2)


func _cleanup_platforms() -> void:
	var remove_count: int = 0
	for platform: Dictionary in _platforms:
		if (platform["x"] as float) + (platform["width"] as float) < -20.0:
			remove_count += 1
			_platforms_passed += 1
		else:
			break

	for i: int in range(remove_count):
		_platforms.remove_at(0)


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
		elif key_event.keycode == KEY_SPACE:
			if key_event.pressed and not key_event.echo and _on_ground:
				_player_vy = JUMP_VELOCITY
				_on_ground = false
				get_viewport().set_input_as_handled()


func _on_play_area_draw() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y

	# Draw platforms
	for platform: Dictionary in _platforms:
		var px: float = platform["x"] as float
		var py: float = platform["y"] as float
		var p_width: float = platform["width"] as float

		if px + p_width < 0.0 or px > pw:
			continue

		play_area.draw_rect(Rect2(px, py, p_width, PLATFORM_HEIGHT), Color(0.35, 0.3, 0.25, 0.9))
		play_area.draw_rect(Rect2(px, py, p_width, 3.0), Color(0.5, 0.45, 0.35, 0.9))

	# Draw player
	if not _eliminated:
		var player_color: Color
		if _on_ground:
			player_color = Color(0.3, 0.8, 0.4, 1.0)
		else:
			player_color = Color(0.8, 0.8, 0.3, 1.0)

		play_area.draw_rect(Rect2(_player_x, _player_y, PLAYER_WIDTH, PLAYER_HEIGHT), player_color)
		play_area.draw_rect(Rect2(_player_x + 2.0, _player_y + 2.0, PLAYER_WIDTH - 4.0, PLAYER_HEIGHT - 4.0), player_color.lightened(0.2))

	# Danger zone at bottom
	play_area.draw_rect(Rect2(0.0, ph - 5.0, pw, 5.0), Color(0.6, 0.1, 0.1, 0.4))

	# Platforms passed
	var pass_text: String = "Platforms: " + str(_platforms_passed)
	play_area.draw_string(ThemeDB.fallback_font, Vector2(pw * 0.5 - 35.0, ph - 10.0), pass_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.8, 0.8, 0.8))


func _on_game_start() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y

	_platforms.clear()
	_next_platform_x = 50.0
	_generate_platforms(pw, ph)

	# Place player on first platform
	if _platforms.size() > 0:
		var first_plat: Dictionary = _platforms[0]
		_player_x = (first_plat["x"] as float) + (first_plat["width"] as float) * 0.5 - PLAYER_WIDTH * 0.5
		_player_y = (first_plat["y"] as float) - PLAYER_HEIGHT
	else:
		_player_x = pw * 0.3
		_player_y = ph * 0.5

	_player_vy = 0.0
	_on_ground = true
	_elapsed_time = 0.0
	_score = 0
	_eliminated = false
	_scroll_speed = INITIAL_SCROLL_SPEED
	_platforms_passed = 0
	_move_left = false
	_move_right = false
	_update_score_display()
	instruction_label.text = "LEFT/RIGHT + SPACE to jump!"
	countdown_label.visible = false
	play_area.queue_redraw()


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! Survived!"
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Platforms: " + str(_platforms_passed)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
