extends MiniGameBase

## Ice Breaker minigame.
## Tap spacebar with correct timing to break ice blocks in sequence.
## A power bar oscillates back and forth; press spacebar in the green zone to break.
## Race to break 12 blocks.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var status_label: Label = %StatusLabel
@onready var power_bar: ColorRect = %PowerBar
@onready var power_indicator: ColorRect = %PowerIndicator
@onready var green_zone: ColorRect = %GreenZone
@onready var ice_container: HBoxContainer = %IceContainer

const COMPLETION_TARGET: int = 12
const BAR_WIDTH: float = 400.0
const INDICATOR_WIDTH: float = 8.0
const GREEN_ZONE_WIDTH: float = 80.0  # Gets narrower over time
const MIN_GREEN_ZONE: float = 40.0

var _blocks_broken: int = 0
var _indicator_pos: float = 0.0
var _indicator_speed: float = 300.0
var _indicator_direction: float = 1.0
var _green_zone_start: float = 0.0
var _waiting_for_next: bool = false
var _wait_timer: float = 0.0
var _ice_blocks: Array[ColorRect] = []


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	status_label.text = ""
	score_label.text = "Blocks: 0 / " + str(COMPLETION_TARGET)
	_create_ice_blocks()
	_setup_green_zone()


func _on_game_start() -> void:
	countdown_label.visible = false
	_blocks_broken = 0
	_indicator_pos = 0.0
	_indicator_speed = 300.0
	_indicator_direction = 1.0
	_waiting_for_next = false
	score_label.text = "Blocks: 0 / " + str(COMPLETION_TARGET)
	status_label.text = "Press SPACE in the GREEN zone!"
	_setup_green_zone()
	_update_indicator()


func _on_game_end() -> void:
	status_label.text = "Time's up! Broke " + str(_blocks_broken) + " blocks!"
	submit_score(_blocks_broken)


func _process(delta: float) -> void:
	if not game_active:
		return

	if _waiting_for_next:
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_waiting_for_next = false
			_setup_green_zone()
			status_label.text = "Press SPACE in the GREEN zone!"
		return

	# Oscillate indicator back and forth
	_indicator_pos += _indicator_speed * _indicator_direction * delta
	if _indicator_pos >= BAR_WIDTH - INDICATOR_WIDTH:
		_indicator_pos = BAR_WIDTH - INDICATOR_WIDTH
		_indicator_direction = -1.0
	elif _indicator_pos <= 0.0:
		_indicator_pos = 0.0
		_indicator_direction = 1.0

	_update_indicator()


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _waiting_for_next:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
			_check_timing()


func _check_timing() -> void:
	var indicator_center: float = _indicator_pos + INDICATOR_WIDTH / 2.0
	var current_zone_width: float = _get_current_green_zone_width()
	var zone_end: float = _green_zone_start + current_zone_width

	if indicator_center >= _green_zone_start and indicator_center <= zone_end:
		# Hit the green zone - break the block!
		_blocks_broken += 1
		score_label.text = "Blocks: " + str(_blocks_broken) + " / " + str(COMPLETION_TARGET)

		# Update ice block visuals
		if _blocks_broken <= COMPLETION_TARGET and _blocks_broken - 1 < _ice_blocks.size():
			_ice_blocks[_blocks_broken - 1].color = Color(0.2, 0.6, 1.0, 0.2)

		if _blocks_broken >= COMPLETION_TARGET:
			status_label.text = "ALL BLOCKS BROKEN!"
			mark_completed(_blocks_broken)
			return

		# Speed up and brief pause
		_indicator_speed += 15.0
		_waiting_for_next = true
		_wait_timer = 0.3
		status_label.text = "CRACK! Block " + str(_blocks_broken) + " broken!"
	else:
		# Missed - penalty pause, indicator resets
		_waiting_for_next = true
		_wait_timer = 0.5
		_indicator_pos = 0.0
		_indicator_direction = 1.0
		status_label.text = "MISS! Try again..."
		_update_indicator()


func _create_ice_blocks() -> void:
	_ice_blocks.clear()
	# Remove old children
	for child: Node in ice_container.get_children():
		child.queue_free()

	for i: int in range(COMPLETION_TARGET):
		var block: ColorRect = ColorRect.new()
		block.custom_minimum_size = Vector2(28, 40)
		block.color = Color(0.6, 0.85, 1.0, 1.0)
		ice_container.add_child(block)
		_ice_blocks.append(block)


func _setup_green_zone() -> void:
	var current_width: float = _get_current_green_zone_width()
	_green_zone_start = randf_range(0.0, BAR_WIDTH - current_width)
	green_zone.position.x = _green_zone_start
	green_zone.size.x = current_width


func _get_current_green_zone_width() -> float:
	var progress: float = float(_blocks_broken) / float(COMPLETION_TARGET)
	return lerpf(GREEN_ZONE_WIDTH, MIN_GREEN_ZONE, progress)


func _update_indicator() -> void:
	power_indicator.position.x = _indicator_pos


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
