extends MiniGameBase

## Stack Tower minigame (Survival).
## A moving block slides back and forth at the top of the screen.
## Press spacebar to drop it onto the stack. The block is trimmed to
## the overlapping portion with the block below. If you miss entirely
## (no overlap), you're eliminated.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const BLOCK_HEIGHT: float = 20.0
const INITIAL_BLOCK_WIDTH: float = 200.0
const INITIAL_SPEED: float = 250.0
const SPEED_INCREMENT: float = 15.0
const BASE_COLOR: Color = Color(0.3, 0.3, 0.8, 1.0)

## Stack of placed blocks: each is {x: float, width: float, y: float}
var _stack: Array[Dictionary] = []
## Current moving block state
var _moving_x: float = 0.0
var _moving_width: float = INITIAL_BLOCK_WIDTH
var _moving_direction: float = 1.0
var _moving_speed: float = INITIAL_SPEED
var _moving_y: float = 0.0

var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _dropping: bool = false


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
	if not game_active or _eliminated or _dropping:
		return

	_elapsed_time += delta
	_score = int(_elapsed_time * 10.0)
	_update_score_display()

	# Move the current block back and forth
	var play_width: float = play_area.size.x
	_moving_x += _moving_direction * _moving_speed * delta
	if _moving_x + _moving_width > play_width:
		_moving_x = play_width - _moving_width
		_moving_direction = -1.0
	elif _moving_x < 0.0:
		_moving_x = 0.0
		_moving_direction = 1.0

	play_area.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _eliminated or _dropping:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
			_drop_block()
			get_viewport().set_input_as_handled()


func _drop_block() -> void:
	_dropping = true
	var play_height: float = play_area.size.y

	if _stack.is_empty():
		# First block: just place it
		var block: Dictionary = {
			"x": _moving_x,
			"width": _moving_width,
			"y": play_height - BLOCK_HEIGHT
		}
		_stack.append(block)
		_advance_to_next_block()
		return

	# Calculate overlap with the top block
	var top_block: Dictionary = _stack[_stack.size() - 1]
	var top_left: float = top_block["x"] as float
	var top_right: float = top_left + (top_block["width"] as float)
	var moving_left: float = _moving_x
	var moving_right: float = _moving_x + _moving_width

	var overlap_left: float = maxf(top_left, moving_left)
	var overlap_right: float = minf(top_right, moving_right)
	var overlap_width: float = overlap_right - overlap_left

	if overlap_width <= 0.0:
		# Missed completely - eliminated
		_eliminated = true
		instruction_label.text = "Missed! Eliminated!"
		play_area.queue_redraw()
		mark_completed(_score)
		return

	# Place the trimmed block
	var block: Dictionary = {
		"x": overlap_left,
		"width": overlap_width,
		"y": (top_block["y"] as float) - BLOCK_HEIGHT
	}
	_stack.append(block)
	_advance_to_next_block()


func _advance_to_next_block() -> void:
	_dropping = false
	var top_block: Dictionary = _stack[_stack.size() - 1]
	_moving_width = top_block["width"] as float
	_moving_y = (top_block["y"] as float) - BLOCK_HEIGHT
	_moving_speed += SPEED_INCREMENT
	# Start from the left edge moving right
	_moving_x = 0.0
	_moving_direction = 1.0
	play_area.queue_redraw()


func _on_play_area_draw() -> void:
	var play_height: float = play_area.size.y

	# Draw placed blocks
	for i: int in range(_stack.size()):
		var block: Dictionary = _stack[i]
		var bx: float = block["x"] as float
		var bw: float = block["width"] as float
		var by: float = block["y"] as float
		# Shift blocks down if stack grows above the play area
		var draw_y: float = by + _get_camera_offset()
		if draw_y + BLOCK_HEIGHT < 0.0 or draw_y > play_height:
			continue
		var hue: float = fmod(float(i) * 0.08, 1.0)
		var block_color: Color = Color.from_hsv(hue, 0.6, 0.85, 1.0)
		play_area.draw_rect(Rect2(bx, draw_y, bw, BLOCK_HEIGHT - 1.0), block_color)

	# Draw moving block (if game is active and not eliminated)
	if game_active and not _eliminated:
		var draw_y: float = _moving_y + _get_camera_offset()
		var moving_color: Color = Color(1.0, 1.0, 1.0, 0.9)
		play_area.draw_rect(Rect2(_moving_x, draw_y, _moving_width, BLOCK_HEIGHT - 1.0), moving_color)


func _get_camera_offset() -> float:
	## Scrolls the view up when the stack gets tall
	var play_height: float = play_area.size.y
	if _stack.is_empty():
		return 0.0
	var top_y: float = _stack[_stack.size() - 1]["y"] as float
	# Keep the top of the stack visible in the upper third
	var target_y: float = play_height * 0.3
	if top_y < target_y:
		return target_y - top_y
	return 0.0


func _on_game_start() -> void:
	_stack.clear()
	_moving_x = 0.0
	_moving_width = INITIAL_BLOCK_WIDTH
	_moving_speed = INITIAL_SPEED
	_moving_direction = 1.0
	_elapsed_time = 0.0
	_score = 0
	_eliminated = false
	_dropping = false
	# Position the first moving block near the bottom
	var play_height: float = play_area.size.y
	_moving_y = play_height - BLOCK_HEIGHT
	_update_score_display()
	instruction_label.text = "Press SPACE to drop!"
	countdown_label.visible = false
	play_area.queue_redraw()


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! Height: " + str(_stack.size())
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Height: " + str(_stack.size())


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
