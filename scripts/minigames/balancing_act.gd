extends MiniGameBase

## Balancing Act minigame (Survival).
## Keep a balance bar centered with left/right arrow keys as it drifts randomly.
## If the bar hits either edge, you're eliminated.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea
@onready var bar_indicator: ColorRect = %BarIndicator
@onready var center_zone: ColorRect = %CenterZone
@onready var left_edge: ColorRect = %LeftEdge
@onready var right_edge: ColorRect = %RightEdge

const BAR_WIDTH: float = 20.0
const BAR_HEIGHT: float = 40.0
const PLAYER_SPEED: float = 300.0
const DRIFT_BASE: float = 80.0
const DRIFT_INCREMENT: float = 15.0
const DRIFT_CHANGE_INTERVAL: float = 1.5
const CENTER_ZONE_WIDTH: float = 60.0
const EDGE_WIDTH: float = 10.0

var _score: int = 0
var _bar_position: float = 0.5  # 0.0 = left edge, 1.0 = right edge
var _drift_velocity: float = 0.0
var _drift_timer: float = 0.0
var _elapsed_time: float = 0.0
var _eliminated: bool = false


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	_update_score_display()
	instruction_label.text = "Get ready..."
	bar_indicator.visible = false


func _process(delta: float) -> void:
	if not game_active or _eliminated:
		return

	_elapsed_time += delta
	_score = int(_elapsed_time * 10.0)
	_update_score_display()

	# Change drift direction periodically
	_drift_timer += delta
	if _drift_timer >= DRIFT_CHANGE_INTERVAL:
		_drift_timer = 0.0
		_randomize_drift()

	# Apply drift (increases over time)
	var drift_strength: float = DRIFT_BASE + (_elapsed_time * DRIFT_INCREMENT)
	var play_width: float = play_area.size.x
	if play_width > 0.0:
		_bar_position += (_drift_velocity * drift_strength * delta) / play_width

	# Player input to counteract drift
	if Input.is_action_pressed("ui_left"):
		if play_width > 0.0:
			_bar_position -= (PLAYER_SPEED * delta) / play_width
	if Input.is_action_pressed("ui_right"):
		if play_width > 0.0:
			_bar_position += (PLAYER_SPEED * delta) / play_width

	# Check elimination
	if _bar_position <= 0.0 or _bar_position >= 1.0:
		_eliminated = true
		_bar_position = clampf(_bar_position, 0.0, 1.0)
		_update_bar_visual()
		instruction_label.text = "You fell off! Eliminated!"
		mark_completed(_score)
		return

	_update_bar_visual()


func _randomize_drift() -> void:
	# Random drift direction and intensity
	_drift_velocity = randf_range(-1.0, 1.0)
	# Bias away from center to make it harder
	if _bar_position > 0.5:
		_drift_velocity += 0.3
	else:
		_drift_velocity -= 0.3


func _update_bar_visual() -> void:
	var play_width: float = play_area.size.x
	var play_height: float = play_area.size.y
	bar_indicator.position.x = (_bar_position * play_width) - (BAR_WIDTH / 2.0)
	bar_indicator.position.y = (play_height - BAR_HEIGHT) / 2.0
	bar_indicator.size = Vector2(BAR_WIDTH, BAR_HEIGHT)

	# Color based on proximity to edges
	var distance_from_center: float = absf(_bar_position - 0.5) * 2.0  # 0.0 at center, 1.0 at edge
	if distance_from_center < 0.3:
		bar_indicator.color = Color(0.2, 0.9, 0.3, 1.0)  # Green = safe
	elif distance_from_center < 0.7:
		bar_indicator.color = Color(0.9, 0.9, 0.2, 1.0)  # Yellow = warning
	else:
		bar_indicator.color = Color(0.9, 0.2, 0.2, 1.0)  # Red = danger


func _on_game_start() -> void:
	_score = 0
	_bar_position = 0.5
	_drift_velocity = 0.0
	_drift_timer = 0.0
	_elapsed_time = 0.0
	_eliminated = false
	_update_score_display()
	instruction_label.text = "Left/Right to balance!"
	countdown_label.visible = false
	bar_indicator.visible = true

	# Set up center zone visual
	var play_width: float = play_area.size.x
	var play_height: float = play_area.size.y
	center_zone.position.x = (play_width - CENTER_ZONE_WIDTH) / 2.0
	center_zone.position.y = 0.0
	center_zone.size = Vector2(CENTER_ZONE_WIDTH, play_height)

	# Set up edge markers
	left_edge.position = Vector2.ZERO
	left_edge.size = Vector2(EDGE_WIDTH, play_height)
	right_edge.position.x = play_width - EDGE_WIDTH
	right_edge.position.y = 0.0
	right_edge.size = Vector2(EDGE_WIDTH, play_height)

	_update_bar_visual()
	_randomize_drift()


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
