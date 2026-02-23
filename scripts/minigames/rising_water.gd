extends MiniGameBase

## Rising Water minigame (Survival).
## Platforms at various heights. Jump between them as water rises.
## Arrow keys to move, Space to jump. Submerged = eliminated.
## Score = survival time in tenths of seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const PLAYER_SIZE: Vector2 = Vector2(18.0, 24.0)
const PLAYER_SPEED: float = 200.0
const GRAVITY: float = 600.0
const JUMP_VELOCITY: float = -320.0
const PLATFORM_COUNT: int = 8
const PLATFORM_WIDTH: float = 70.0
const PLATFORM_HEIGHT: float = 10.0
const WATER_RISE_BASE: float = 15.0  # pixels per second at start
const WATER_RISE_ACCEL: float = 3.0  # additional px/s per second elapsed

const PLAYER_COLOR: Color = Color(0.2, 0.9, 0.3, 1.0)
const PLATFORM_COLOR: Color = Color(0.5, 0.4, 0.3, 1.0)
const WATER_COLOR: Color = Color(0.2, 0.4, 0.9, 0.7)
const BG_COLOR: Color = Color(0.6, 0.8, 1.0, 1.0)

var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _player_pos: Vector2 = Vector2.ZERO
var _player_velocity: Vector2 = Vector2.ZERO
var _on_ground: bool = false
var _water_level: float = 0.0  # measured from bottom of play area
var _platforms: Array[Dictionary] = []  # {pos: Vector2, node: ColorRect}
var _player_node: ColorRect = null
var _water_node: ColorRect = null
var _bg_node: ColorRect = null


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
	_water_level = 0.0
	_player_velocity = Vector2.ZERO
	_on_ground = false
	_update_score_display()
	instruction_label.text = "Arrow keys + Space to jump! Stay above water!"
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
	if is_instance_valid(_water_node):
		_water_node.queue_free()
	if is_instance_valid(_bg_node):
		_bg_node.queue_free()

	var area_w: float = play_area.size.x
	var area_h: float = play_area.size.y

	# Sky background
	_bg_node = ColorRect.new()
	_bg_node.position = Vector2.ZERO
	_bg_node.size = Vector2(area_w, area_h)
	_bg_node.color = BG_COLOR
	play_area.add_child(_bg_node)

	# Create platforms at various heights
	# Bottom platform spans full width as starting ground
	var ground_node: ColorRect = ColorRect.new()
	ground_node.position = Vector2(0.0, area_h - PLATFORM_HEIGHT)
	ground_node.size = Vector2(area_w, PLATFORM_HEIGHT)
	ground_node.color = PLATFORM_COLOR
	play_area.add_child(ground_node)
	_platforms.append({
		"pos": Vector2(0.0, area_h - PLATFORM_HEIGHT),
		"width": area_w,
		"node": ground_node,
	})

	# Scattered platforms at increasing heights
	for i: int in range(PLATFORM_COUNT):
		var px: float = randf_range(10.0, area_w - PLATFORM_WIDTH - 10.0)
		# Distribute platforms vertically - lower ones closer to bottom, higher ones near top
		var min_y: float = 30.0
		var max_y: float = area_h - 50.0
		var py: float = max_y - (float(i) / float(PLATFORM_COUNT - 1)) * (max_y - min_y)
		# Add some randomness
		py += randf_range(-20.0, 20.0)
		py = clampf(py, min_y, max_y)

		var node: ColorRect = ColorRect.new()
		node.position = Vector2(px, py)
		node.size = Vector2(PLATFORM_WIDTH, PLATFORM_HEIGHT)
		node.color = PLATFORM_COLOR
		play_area.add_child(node)
		_platforms.append({
			"pos": Vector2(px, py),
			"width": PLATFORM_WIDTH,
			"node": node,
		})

	# Water node (rendered on top of platforms, below player)
	_water_node = ColorRect.new()
	_water_node.position = Vector2(0.0, area_h)
	_water_node.size = Vector2(area_w, 0.0)
	_water_node.color = WATER_COLOR
	play_area.add_child(_water_node)

	# Player starts on the ground platform
	_player_pos = Vector2(area_w / 2.0 - PLAYER_SIZE.x / 2.0, area_h - PLATFORM_HEIGHT - PLAYER_SIZE.y)

	# Player node (on top of everything)
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

	var area_w: float = play_area.size.x
	var area_h: float = play_area.size.y

	# Horizontal movement
	var move_x: float = 0.0
	if Input.is_action_pressed("ui_left"):
		move_x -= 1.0
	if Input.is_action_pressed("ui_right"):
		move_x += 1.0
	_player_velocity.x = move_x * PLAYER_SPEED

	# Apply gravity
	_player_velocity.y += GRAVITY * delta

	# Jump
	if _on_ground and Input.is_action_just_pressed("ui_accept"):
		_player_velocity.y = JUMP_VELOCITY
		_on_ground = false

	# Move player
	_player_pos += _player_velocity * delta

	# Clamp horizontal
	_player_pos.x = clampf(_player_pos.x, 0.0, area_w - PLAYER_SIZE.x)

	# Platform collision (only check when falling down)
	_on_ground = false
	if _player_velocity.y >= 0.0:
		var player_bottom: float = _player_pos.y + PLAYER_SIZE.y
		var player_left: float = _player_pos.x
		var player_right: float = _player_pos.x + PLAYER_SIZE.x

		for p: Dictionary in _platforms:
			var plat_pos: Vector2 = p["pos"] as Vector2
			var plat_width: float = p["width"] as float
			var plat_top: float = plat_pos.y
			var plat_left: float = plat_pos.x
			var plat_right: float = plat_pos.x + plat_width

			# Check horizontal overlap
			if player_right > plat_left and player_left < plat_right:
				# Check if player just crossed or is at platform top
				var prev_bottom: float = player_bottom - _player_velocity.y * delta
				if prev_bottom <= plat_top + 2.0 and player_bottom >= plat_top:
					_player_pos.y = plat_top - PLAYER_SIZE.y
					_player_velocity.y = 0.0
					_on_ground = true
					break

	# Prevent falling below play area bottom
	if _player_pos.y + PLAYER_SIZE.y > area_h:
		_player_pos.y = area_h - PLAYER_SIZE.y
		_player_velocity.y = 0.0
		_on_ground = true

	_player_node.position = _player_pos

	# Rise water
	var rise_speed: float = WATER_RISE_BASE + _elapsed_time * WATER_RISE_ACCEL
	_water_level += rise_speed * delta
	var water_top: float = area_h - _water_level
	_water_node.position = Vector2(0.0, water_top)
	_water_node.size = Vector2(area_w, _water_level)

	# Check if player is submerged (player center below water)
	var player_center_y: float = _player_pos.y + PLAYER_SIZE.y / 2.0
	if player_center_y > water_top:
		_eliminated = true
		instruction_label.text = "Submerged! Eliminated!"
		mark_completed(_score)


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
