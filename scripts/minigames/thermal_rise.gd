extends MiniGameBase

## Thermal Rise minigame (Survival).
## Character floats upward automatically through gaps in horizontal platforms.
## Use left/right arrow keys to navigate through the gaps.
## Hitting a platform eliminates the player.
## Platforms scroll downward (player rises). Speed increases over time.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const PLAYER_WIDTH: float = 16.0
const PLAYER_HEIGHT: float = 16.0
const PLATFORM_HEIGHT: float = 12.0
const GAP_WIDTH: float = 80.0
const MIN_GAP_WIDTH: float = 45.0
const GAP_SHRINK_RATE: float = 1.5
const INITIAL_RISE_SPEED: float = 60.0
const SPEED_INCREMENT: float = 4.0
const MOVE_SPEED: float = 220.0
const PLATFORM_SPACING: float = 120.0

var _player_x: float = 0.0
var _player_y_ratio: float = 0.35  # Fixed vertical position ratio in play area
var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _rise_speed: float = INITIAL_RISE_SPEED
var _scroll_offset: float = 0.0
var _platforms_passed: int = 0

# Input state
var _move_left: bool = false
var _move_right: bool = false

# Platform data: each is [gap_center_x_ratio, gap_width, y_offset_from_start]
var _platforms: Array[Dictionary] = []
var _next_platform_y: float = 0.0


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

	# Increase speed over time
	_rise_speed = INITIAL_RISE_SPEED + _elapsed_time * SPEED_INCREMENT

	# Scroll platforms downward (player rises)
	_scroll_offset += _rise_speed * delta

	# Player horizontal movement
	if _move_left:
		_player_x -= MOVE_SPEED * delta
	if _move_right:
		_player_x += MOVE_SPEED * delta

	# Clamp player to play area
	_player_x = clampf(_player_x, 0.0, pw - PLAYER_WIDTH)

	# Generate new platforms as needed
	_generate_platforms()

	# Check collisions with platforms
	if _check_platform_collision():
		_eliminated = true
		instruction_label.text = "Hit a platform! Eliminated!"
		play_area.queue_redraw()
		mark_completed(_score)
		return

	# Remove platforms that scrolled off the bottom
	_cleanup_platforms()

	play_area.queue_redraw()


func _generate_platforms() -> void:
	var ph: float = play_area.size.y

	# Generate platforms above the visible area that will scroll into view
	while _next_platform_y < _scroll_offset + ph + PLATFORM_SPACING:
		var current_gap: float = maxf(GAP_WIDTH - _platforms_passed * GAP_SHRINK_RATE, MIN_GAP_WIDTH)
		var gap_center_ratio: float = randf_range(0.15, 0.85)

		var platform: Dictionary = {
			"gap_center_ratio": gap_center_ratio,
			"gap_width": current_gap,
			"y_offset": _next_platform_y
		}
		_platforms.append(platform)
		_next_platform_y += PLATFORM_SPACING


func _check_platform_collision() -> bool:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y
	var player_screen_y: float = ph * _player_y_ratio

	for platform: Dictionary in _platforms:
		# Calculate screen Y of this platform
		var screen_y: float = ph - (platform["y_offset"] as float - _scroll_offset)

		# Check vertical overlap
		if screen_y + PLATFORM_HEIGHT < player_screen_y:
			continue
		if screen_y > player_screen_y + PLAYER_HEIGHT:
			continue

		# Platform is at this Y - check if player is in the gap
		var gap_center: float = pw * (platform["gap_center_ratio"] as float)
		var gap_half: float = (platform["gap_width"] as float) * 0.5
		var gap_left: float = gap_center - gap_half
		var gap_right: float = gap_center + gap_half

		var player_left: float = _player_x
		var player_right: float = _player_x + PLAYER_WIDTH

		# Player is safe if entirely within the gap
		if player_left >= gap_left and player_right <= gap_right:
			continue

		# Player hits the platform
		return true

	return false


func _cleanup_platforms() -> void:
	var ph: float = play_area.size.y
	var remove_count: int = 0

	for platform: Dictionary in _platforms:
		var screen_y: float = ph - (platform["y_offset"] as float - _scroll_offset)
		if screen_y > ph + PLATFORM_HEIGHT + 20.0:
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


func _on_play_area_draw() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y
	var player_screen_y: float = ph * _player_y_ratio

	# Draw platforms
	for platform: Dictionary in _platforms:
		var screen_y: float = ph - (platform["y_offset"] as float - _scroll_offset)

		if screen_y < -PLATFORM_HEIGHT or screen_y > ph + PLATFORM_HEIGHT:
			continue

		var gap_center: float = pw * (platform["gap_center_ratio"] as float)
		var gap_half: float = (platform["gap_width"] as float) * 0.5
		var gap_left: float = gap_center - gap_half
		var gap_right: float = gap_center + gap_half

		var platform_color: Color = Color(0.4, 0.35, 0.3, 0.9)

		# Left segment
		if gap_left > 0.0:
			play_area.draw_rect(Rect2(0.0, screen_y, gap_left, PLATFORM_HEIGHT), platform_color)

		# Right segment
		if gap_right < pw:
			play_area.draw_rect(Rect2(gap_right, screen_y, pw - gap_right, PLATFORM_HEIGHT), platform_color)

		# Gap edges (visual highlight)
		play_area.draw_line(Vector2(gap_left, screen_y), Vector2(gap_left, screen_y + PLATFORM_HEIGHT), Color(0.7, 0.5, 0.3, 0.6), 2.0)
		play_area.draw_line(Vector2(gap_right, screen_y), Vector2(gap_right, screen_y + PLATFORM_HEIGHT), Color(0.7, 0.5, 0.3, 0.6), 2.0)

	# Draw rising heat effect at bottom
	for i: int in range(5):
		var heat_y: float = ph - float(i) * 8.0
		var heat_alpha: float = 0.15 * (1.0 - float(i) / 5.0)
		play_area.draw_rect(Rect2(0.0, heat_y, pw, 8.0), Color(1.0, 0.4, 0.1, heat_alpha))

	# Draw player
	if not _eliminated:
		var glow: float = 0.7 + absf(sin(_elapsed_time * 5.0)) * 0.3
		var player_color: Color = Color(1.0, 0.6, 0.1, glow)
		play_area.draw_rect(Rect2(_player_x, player_screen_y, PLAYER_WIDTH, PLAYER_HEIGHT), player_color)
		play_area.draw_rect(Rect2(_player_x + 2.0, player_screen_y + 2.0, PLAYER_WIDTH - 4.0, PLAYER_HEIGHT - 4.0), Color(1.0, 0.9, 0.4, glow))

	# Platforms passed counter
	var pass_text: String = "Passed: " + str(_platforms_passed)
	play_area.draw_string(ThemeDB.fallback_font, Vector2(pw * 0.5 - 30.0, ph - 10.0), pass_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.8, 0.8, 0.8))


func _on_game_start() -> void:
	var pw: float = play_area.size.x
	_player_x = (pw - PLAYER_WIDTH) * 0.5
	_elapsed_time = 0.0
	_score = 0
	_eliminated = false
	_rise_speed = INITIAL_RISE_SPEED
	_scroll_offset = 0.0
	_platforms_passed = 0
	_move_left = false
	_move_right = false
	_platforms.clear()
	_next_platform_y = PLATFORM_SPACING * 1.5  # First platform appears after some space
	_generate_platforms()
	_update_score_display()
	instruction_label.text = "LEFT/RIGHT to dodge platforms!"
	countdown_label.visible = false
	play_area.queue_redraw()


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! Survived!"
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Passed: " + str(_platforms_passed)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
