extends MiniGameBase

## Laser Dodge minigame (Survival).
## Lasers sweep across the arena in patterns. Move to gaps to survive.
## Hit by a laser = eliminated.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea
@onready var player_rect: ColorRect = %PlayerRect

const PLAYER_SIZE: float = 14.0
const PLAYER_SPEED: float = 280.0
const LASER_THICKNESS: float = 6.0
const LASER_GAP: float = 80.0  # Size of the gap in each laser
const INITIAL_LASER_INTERVAL: float = 2.5
const MIN_LASER_INTERVAL: float = 0.8
const LASER_SPEED: float = 200.0  # Pixels per second
const LASER_SPEED_INCREASE: float = 15.0  # Speed increase per second elapsed

var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _player_pos: Vector2 = Vector2.ZERO
var _lasers: Array[Dictionary] = []
var _spawn_timer: float = 0.0
var _next_spawn_interval: float = INITIAL_LASER_INTERVAL


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	_update_score_display()
	instruction_label.text = "Get ready..."
	player_rect.visible = false


func _process(delta: float) -> void:
	if not game_active or _eliminated:
		return

	_elapsed_time += delta
	_score = int(_elapsed_time * 10.0)
	_update_score_display()

	# Player movement
	var move_dir: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		move_dir.x -= 1.0
	if Input.is_action_pressed("ui_right"):
		move_dir.x += 1.0
	if Input.is_action_pressed("ui_up"):
		move_dir.y -= 1.0
	if Input.is_action_pressed("ui_down"):
		move_dir.y += 1.0

	if move_dir.length() > 0.0:
		move_dir = move_dir.normalized()
		_player_pos += move_dir * PLAYER_SPEED * delta

	# Clamp player to play area
	var area_w: float = play_area.size.x
	var area_h: float = play_area.size.y
	_player_pos.x = clampf(_player_pos.x, 0.0, area_w - PLAYER_SIZE)
	_player_pos.y = clampf(_player_pos.y, 0.0, area_h - PLAYER_SIZE)
	player_rect.position = _player_pos

	# Spawn lasers
	_spawn_timer += delta
	if _spawn_timer >= _next_spawn_interval:
		_spawn_timer = 0.0
		_spawn_laser()
		_next_spawn_interval = maxf(INITIAL_LASER_INTERVAL - (_elapsed_time * 0.15), MIN_LASER_INTERVAL)

	# Move lasers and check collisions
	var current_speed: float = LASER_SPEED + (_elapsed_time * LASER_SPEED_INCREASE)
	var player_center_x: float = _player_pos.x + PLAYER_SIZE / 2.0
	var player_center_y: float = _player_pos.y + PLAYER_SIZE / 2.0
	var player_half: float = PLAYER_SIZE / 2.0 - 2.0  # Slight forgiveness

	var i: int = _lasers.size() - 1
	while i >= 0:
		var laser: Dictionary = _lasers[i]
		var dir: int = laser["direction"] as int
		laser["pos"] = (laser["pos"] as float) + current_speed * delta * (1.0 if dir == 0 or dir == 2 else -1.0)

		# Check if laser is off screen
		var pos: float = laser["pos"] as float
		var off_screen: bool = false
		if dir == 0 and pos > area_w + 10.0:  # Left to right
			off_screen = true
		elif dir == 1 and pos < -10.0:  # Right to left
			off_screen = true
		elif dir == 2 and pos > area_h + 10.0:  # Top to bottom
			off_screen = true
		elif dir == 3 and pos < -10.0:  # Bottom to top
			off_screen = true

		if off_screen:
			# Remove laser visual
			var rect: ColorRect = laser["node"] as ColorRect
			rect.queue_free()
			_lasers.remove_at(i)
			i -= 1
			continue

		# Update laser visual position
		_update_laser_visual(laser)

		# Collision detection
		var gap_start: float = laser["gap_start"] as float
		var gap_end: float = gap_start + LASER_GAP
		var hit: bool = false

		if dir == 0 or dir == 1:
			# Horizontal laser (moves left/right, beam is vertical)
			var laser_x: float = pos
			if absf(player_center_x - laser_x) < (player_half + LASER_THICKNESS / 2.0):
				# Player is at the laser's x position - check if in the gap
				if player_center_y < gap_start or player_center_y > gap_end:
					hit = true
		else:
			# Vertical laser (moves up/down, beam is horizontal)
			var laser_y: float = pos
			if absf(player_center_y - laser_y) < (player_half + LASER_THICKNESS / 2.0):
				# Player is at the laser's y position - check if in the gap
				if player_center_x < gap_start or player_center_x > gap_end:
					hit = true

		if hit:
			_eliminated = true
			instruction_label.text = "Hit by laser! Eliminated!"
			player_rect.color = Color(0.8, 0.2, 0.2, 1.0)
			mark_completed(_score)
			return

		i -= 1

	play_area.queue_redraw()


func _spawn_laser() -> void:
	var area_w: float = play_area.size.x
	var area_h: float = play_area.size.y

	# Direction: 0=left-to-right, 1=right-to-left, 2=top-to-bottom, 3=bottom-to-top
	var dir: int = randi_range(0, 3)
	var gap_start: float = 0.0
	var start_pos: float = 0.0

	if dir == 0 or dir == 1:
		# Horizontal laser: gap is along Y axis
		gap_start = randf_range(10.0, area_h - LASER_GAP - 10.0)
		start_pos = -LASER_THICKNESS if dir == 0 else area_w + LASER_THICKNESS
	else:
		# Vertical laser: gap is along X axis
		gap_start = randf_range(10.0, area_w - LASER_GAP - 10.0)
		start_pos = -LASER_THICKNESS if dir == 2 else area_h + LASER_THICKNESS

	# Create visual node for laser
	var laser_node: ColorRect = ColorRect.new()
	laser_node.color = Color(1.0, 0.1, 0.1, 0.85)
	play_area.add_child(laser_node)

	var laser: Dictionary = {
		"direction": dir,
		"gap_start": gap_start,
		"pos": start_pos,
		"node": laser_node,
	}
	_lasers.append(laser)
	_update_laser_visual(laser)


func _update_laser_visual(laser: Dictionary) -> void:
	var area_w: float = play_area.size.x
	var area_h: float = play_area.size.y
	var dir: int = laser["direction"] as int
	var pos: float = laser["pos"] as float
	var gap_start: float = laser["gap_start"] as float
	var node: ColorRect = laser["node"] as ColorRect

	# We draw only the top/left segment (before the gap).
	# We need a second rect for the bottom/right segment.
	# Instead, use one rect and draw the full beam, relying on the gap being visible
	# Actually, let's use the ColorRect for the top segment and create a second if needed.
	# Simpler: use a single tall/wide rect and handle the gap visually by covering it.
	# Simplest approach: use _draw on PlayArea instead.

	# For simplicity, position the single rect as the full beam (no gap visual with single rect).
	# We'll use the play_area _draw for proper rendering.
	node.visible = false  # Hide the ColorRect, we'll draw with _draw


func _draw_lasers() -> void:
	for laser: Dictionary in _lasers:
		var dir: int = laser["direction"] as int
		var pos: float = laser["pos"] as float
		var gap_start: float = laser["gap_start"] as float
		var gap_end: float = gap_start + LASER_GAP
		var area_w: float = play_area.size.x
		var area_h: float = play_area.size.y
		var laser_color: Color = Color(1.0, 0.15, 0.15, 0.9)
		var glow_color: Color = Color(1.0, 0.3, 0.3, 0.3)

		if dir == 0 or dir == 1:
			# Vertical beam at x=pos, gap in Y
			var x: float = pos - LASER_THICKNESS / 2.0
			# Top segment
			if gap_start > 0.0:
				play_area.draw_rect(Rect2(x - 2.0, 0.0, LASER_THICKNESS + 4.0, gap_start), glow_color)
				play_area.draw_rect(Rect2(x, 0.0, LASER_THICKNESS, gap_start), laser_color)
			# Bottom segment
			if gap_end < area_h:
				play_area.draw_rect(Rect2(x - 2.0, gap_end, LASER_THICKNESS + 4.0, area_h - gap_end), glow_color)
				play_area.draw_rect(Rect2(x, gap_end, LASER_THICKNESS, area_h - gap_end), laser_color)
		else:
			# Horizontal beam at y=pos, gap in X
			var y: float = pos - LASER_THICKNESS / 2.0
			# Left segment
			if gap_start > 0.0:
				play_area.draw_rect(Rect2(0.0, y - 2.0, gap_start, LASER_THICKNESS + 4.0), glow_color)
				play_area.draw_rect(Rect2(0.0, y, gap_start, LASER_THICKNESS), laser_color)
			# Right segment
			if gap_end < area_w:
				play_area.draw_rect(Rect2(gap_end, y - 2.0, area_w - gap_end, LASER_THICKNESS + 4.0), glow_color)
				play_area.draw_rect(Rect2(gap_end, y, area_w - gap_end, LASER_THICKNESS), laser_color)


func _on_play_area_draw() -> void:
	_draw_lasers()


func _on_game_start() -> void:
	_score = 0
	_elapsed_time = 0.0
	_eliminated = false
	_spawn_timer = 0.0
	_next_spawn_interval = INITIAL_LASER_INTERVAL

	# Clear any existing lasers
	for laser: Dictionary in _lasers:
		var node: ColorRect = laser["node"] as ColorRect
		if is_instance_valid(node):
			node.queue_free()
	_lasers.clear()

	var area_w: float = play_area.size.x
	var area_h: float = play_area.size.y

	# Center player
	_player_pos = Vector2(
		(area_w - PLAYER_SIZE) / 2.0,
		(area_h - PLAYER_SIZE) / 2.0
	)

	player_rect.position = _player_pos
	player_rect.size = Vector2(PLAYER_SIZE, PLAYER_SIZE)
	player_rect.visible = true
	player_rect.color = Color(0.2, 0.9, 0.3, 1.0)

	_update_score_display()
	instruction_label.text = "Arrow keys to dodge lasers! Find the gaps!"
	countdown_label.visible = false

	# Connect draw signal for laser rendering
	if not play_area.draw.is_connected(_on_play_area_draw):
		play_area.draw.connect(_on_play_area_draw)


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! You survived!"
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Time: " + str(_score / 10.0) + "s"


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
