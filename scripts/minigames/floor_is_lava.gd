extends MiniGameBase

## Floor is Lava minigame (Survival).
## Platforms shrink and disappear over time. Move with arrow keys to stay on solid ground.
## Fall into lava = eliminated. Score = survival time in tenths of seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const PLAYER_SIZE: Vector2 = Vector2(20.0, 20.0)
const PLAYER_SPEED: float = 250.0
const PLATFORM_COLS: int = 5
const PLATFORM_ROWS: int = 4
const PLATFORM_PADDING: float = 8.0
const SHRINK_INTERVAL_BASE: float = 2.5
const SHRINK_INTERVAL_MIN: float = 0.8
const SHRINK_RATE: float = 0.15  # how fast interval decreases per second
const LAVA_COLOR: Color = Color(0.9, 0.3, 0.1, 1.0)
const PLATFORM_COLOR: Color = Color(0.3, 0.5, 0.3, 1.0)
const PLATFORM_WARN_COLOR: Color = Color(0.7, 0.6, 0.2, 1.0)
const PLAYER_COLOR: Color = Color(0.2, 0.9, 0.3, 1.0)

var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _player_pos: Vector2 = Vector2.ZERO
var _platforms: Array[Dictionary] = []  # {rect: Rect2, node: ColorRect, health: float, shrinking: bool}
var _shrink_timer: float = 0.0
var _player_node: ColorRect = null
var _lava_node: ColorRect = null


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	_update_score_display()
	instruction_label.text = "Get ready..."


func _on_game_start() -> void:
	_score = 0
	_elapsed_time = 0.0
	_eliminated = false
	_shrink_timer = 0.0
	_update_score_display()
	instruction_label.text = "Arrow keys to move! Stay on platforms!"
	countdown_label.visible = false

	_create_arena()


func _create_arena() -> void:
	# Clear old nodes
	for p: Dictionary in _platforms:
		var node: ColorRect = p["node"] as ColorRect
		if is_instance_valid(node):
			node.queue_free()
	_platforms.clear()
	if is_instance_valid(_player_node):
		_player_node.queue_free()
	if is_instance_valid(_lava_node):
		_lava_node.queue_free()

	var area_w: float = play_area.size.x
	var area_h: float = play_area.size.y

	# Lava background
	_lava_node = ColorRect.new()
	_lava_node.position = Vector2.ZERO
	_lava_node.size = Vector2(area_w, area_h)
	_lava_node.color = LAVA_COLOR
	play_area.add_child(_lava_node)

	# Create platform grid
	var plat_w: float = (area_w - PLATFORM_PADDING * (PLATFORM_COLS + 1)) / PLATFORM_COLS
	var plat_h: float = (area_h - PLATFORM_PADDING * (PLATFORM_ROWS + 1)) / PLATFORM_ROWS

	for row: int in range(PLATFORM_ROWS):
		for col: int in range(PLATFORM_COLS):
			var px: float = PLATFORM_PADDING + col * (plat_w + PLATFORM_PADDING)
			var py: float = PLATFORM_PADDING + row * (plat_h + PLATFORM_PADDING)
			var rect: Rect2 = Rect2(px, py, plat_w, plat_h)

			var node: ColorRect = ColorRect.new()
			node.position = Vector2(px, py)
			node.size = Vector2(plat_w, plat_h)
			node.color = PLATFORM_COLOR
			play_area.add_child(node)

			var platform: Dictionary = {
				"rect": rect,
				"node": node,
				"health": 1.0,
				"shrinking": false,
				"original_rect": rect,
			}
			_platforms.append(platform)

	# Player starts at center platform
	var center_idx: int = (PLATFORM_ROWS / 2) * PLATFORM_COLS + (PLATFORM_COLS / 2)
	var center_rect: Rect2 = _platforms[center_idx]["rect"] as Rect2
	_player_pos = Vector2(
		center_rect.position.x + center_rect.size.x / 2.0 - PLAYER_SIZE.x / 2.0,
		center_rect.position.y + center_rect.size.y / 2.0 - PLAYER_SIZE.y / 2.0
	)

	# Player node
	_player_node = ColorRect.new()
	_player_node.size = PLAYER_SIZE
	_player_node.color = PLAYER_COLOR
	_player_node.position = _player_pos
	play_area.add_child(_player_node)


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

	# Clamp to play area
	var area_w: float = play_area.size.x
	var area_h: float = play_area.size.y
	_player_pos.x = clampf(_player_pos.x, 0.0, area_w - PLAYER_SIZE.x)
	_player_pos.y = clampf(_player_pos.y, 0.0, area_h - PLAYER_SIZE.y)
	_player_node.position = _player_pos

	# Shrink timer - pick a platform to start shrinking
	var current_interval: float = maxf(SHRINK_INTERVAL_MIN, SHRINK_INTERVAL_BASE - _elapsed_time * SHRINK_RATE)
	_shrink_timer += delta
	if _shrink_timer >= current_interval:
		_shrink_timer = 0.0
		_start_shrinking_random_platform()

	# Update shrinking platforms
	_update_platforms(delta)

	# Check if player is on any platform
	var player_rect: Rect2 = Rect2(_player_pos, PLAYER_SIZE)
	var on_platform: bool = false
	for p: Dictionary in _platforms:
		var health: float = p["health"] as float
		if health <= 0.0:
			continue
		var prect: Rect2 = p["rect"] as Rect2
		if player_rect.intersects(prect):
			on_platform = true
			break

	if not on_platform:
		_eliminated = true
		instruction_label.text = "You fell in the lava! Eliminated!"
		mark_completed(_score)


func _start_shrinking_random_platform() -> void:
	# Find platforms that aren't already shrinking and still alive
	var candidates: Array[int] = []
	for i: int in range(_platforms.size()):
		var p: Dictionary = _platforms[i]
		var health: float = p["health"] as float
		var shrinking: bool = p["shrinking"] as bool
		if health > 0.0 and not shrinking:
			candidates.append(i)

	if candidates.size() == 0:
		return

	# Don't shrink the last remaining platform (keep at least 2 alive non-shrinking)
	var alive_count: int = 0
	for p: Dictionary in _platforms:
		var health: float = p["health"] as float
		if health > 0.0:
			alive_count += 1

	if alive_count <= 2:
		return

	var idx: int = candidates[randi() % candidates.size()]
	_platforms[idx]["shrinking"] = true


func _update_platforms(delta: float) -> void:
	for p: Dictionary in _platforms:
		var health: float = p["health"] as float
		if health <= 0.0:
			continue

		var shrinking: bool = p["shrinking"] as bool
		if not shrinking:
			continue

		# Shrink: decrease health
		var shrink_speed: float = 0.3 + _elapsed_time * 0.03
		health -= shrink_speed * delta
		p["health"] = health

		var node: ColorRect = p["node"] as ColorRect
		var original: Rect2 = p["original_rect"] as Rect2

		if health <= 0.0:
			# Platform gone
			p["health"] = 0.0
			node.visible = false
			p["rect"] = Rect2(0, 0, 0, 0)
		else:
			# Shrink visually from center
			var scale_factor: float = maxf(health, 0.0)
			var new_w: float = original.size.x * scale_factor
			var new_h: float = original.size.y * scale_factor
			var center_x: float = original.position.x + original.size.x / 2.0
			var center_y: float = original.position.y + original.size.y / 2.0
			var new_rect: Rect2 = Rect2(
				center_x - new_w / 2.0,
				center_y - new_h / 2.0,
				new_w,
				new_h
			)
			p["rect"] = new_rect
			node.position = new_rect.position
			node.size = new_rect.size

			# Warning color when low health
			if health < 0.4:
				node.color = PLATFORM_WARN_COLOR
			else:
				node.color = PLATFORM_COLOR


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
