extends MiniGameBase

## Tightrope Walk minigame (Survival).
## Character auto-walks forward on a tightrope. Press left/right to balance.
## If the character tilts too far off the rope, you're eliminated.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea
@onready var rope_line: ColorRect = %RopeLine
@onready var walker: ColorRect = %Walker
@onready var balance_bar_bg: ColorRect = %BalanceBarBG
@onready var balance_bar_fill: ColorRect = %BalanceBarFill

const WALKER_WIDTH: float = 16.0
const WALKER_HEIGHT: float = 30.0
const ROPE_HEIGHT: float = 4.0
const PLAYER_SPEED: float = 250.0
const TILT_BASE: float = 60.0
const TILT_INCREMENT: float = 18.0
const TILT_CHANGE_INTERVAL: float = 1.2
const BALANCE_BAR_WIDTH: float = 200.0
const BALANCE_BAR_HEIGHT: float = 16.0
const FALL_THRESHOLD: float = 1.0  # normalized 0-1, falls at edges

var _score: int = 0
var _balance: float = 0.5  # 0.0 = far left, 1.0 = far right, 0.5 = centered
var _tilt_velocity: float = 0.0
var _tilt_timer: float = 0.0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _wind_gust_timer: float = 0.0
var _wind_gust_active: bool = false
var _wind_gust_direction: float = 0.0


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	_update_score_display()
	instruction_label.text = "Get ready..."
	walker.visible = false
	balance_bar_bg.visible = false
	balance_bar_fill.visible = false


func _process(delta: float) -> void:
	if not game_active or _eliminated:
		return

	_elapsed_time += delta
	_score = int(_elapsed_time * 10.0)
	_update_score_display()

	# Change tilt direction periodically
	_tilt_timer += delta
	if _tilt_timer >= TILT_CHANGE_INTERVAL:
		_tilt_timer = 0.0
		_randomize_tilt()

	# Wind gusts - occasional strong pushes
	_wind_gust_timer += delta
	if not _wind_gust_active and _wind_gust_timer >= 3.0 + randf() * 2.0:
		_wind_gust_active = true
		_wind_gust_timer = 0.0
		_wind_gust_direction = 1.0 if randf() > 0.5 else -1.0
	if _wind_gust_active:
		if _wind_gust_timer >= 0.4:
			_wind_gust_active = false
			_wind_gust_timer = 0.0

	# Apply tilt (increases over time)
	var tilt_strength: float = TILT_BASE + (_elapsed_time * TILT_INCREMENT)
	var play_width: float = play_area.size.x
	if play_width > 0.0:
		_balance += (_tilt_velocity * tilt_strength * delta) / play_width
		# Apply wind gust
		if _wind_gust_active:
			_balance += (_wind_gust_direction * tilt_strength * 1.5 * delta) / play_width

	# Player input to counteract tilt
	if Input.is_action_pressed("ui_left"):
		if play_width > 0.0:
			_balance -= (PLAYER_SPEED * delta) / play_width
	if Input.is_action_pressed("ui_right"):
		if play_width > 0.0:
			_balance += (PLAYER_SPEED * delta) / play_width

	# Check elimination
	if _balance <= 0.0 or _balance >= FALL_THRESHOLD:
		_eliminated = true
		_balance = clampf(_balance, 0.0, 1.0)
		_update_walker_visual()
		instruction_label.text = "You fell off! Eliminated!"
		mark_completed(_score)
		return

	_update_walker_visual()


func _randomize_tilt() -> void:
	_tilt_velocity = randf_range(-1.0, 1.0)
	# Bias away from center to increase difficulty
	if _balance > 0.5:
		_tilt_velocity += 0.35
	else:
		_tilt_velocity -= 0.35


func _update_walker_visual() -> void:
	var play_width: float = play_area.size.x
	var play_height: float = play_area.size.y

	# Position rope at vertical center
	var rope_y: float = play_height * 0.6
	rope_line.position = Vector2(0.0, rope_y)
	rope_line.size = Vector2(play_width, ROPE_HEIGHT)

	# Position walker on rope
	var walker_x: float = (_balance * play_width) - (WALKER_WIDTH / 2.0)
	var walker_y: float = rope_y - WALKER_HEIGHT
	walker.position = Vector2(walker_x, walker_y)
	walker.size = Vector2(WALKER_WIDTH, WALKER_HEIGHT)

	# Walker color based on balance danger
	var distance_from_center: float = absf(_balance - 0.5) * 2.0
	if distance_from_center < 0.3:
		walker.color = Color(0.2, 0.9, 0.3, 1.0)  # Green = safe
	elif distance_from_center < 0.6:
		walker.color = Color(0.9, 0.9, 0.2, 1.0)  # Yellow = warning
	else:
		walker.color = Color(0.9, 0.2, 0.2, 1.0)  # Red = danger

	# Update balance bar
	var bar_x: float = (play_width - BALANCE_BAR_WIDTH) / 2.0
	var bar_y: float = play_height * 0.85
	balance_bar_bg.position = Vector2(bar_x, bar_y)
	balance_bar_bg.size = Vector2(BALANCE_BAR_WIDTH, BALANCE_BAR_HEIGHT)

	# Fill shows balance position (centered = middle of bar)
	var fill_width: float = BALANCE_BAR_WIDTH * _balance
	balance_bar_fill.position = Vector2(bar_x, bar_y)
	balance_bar_fill.size = Vector2(fill_width, BALANCE_BAR_HEIGHT)

	# Fill color matches walker
	balance_bar_fill.color = walker.color

	# Wind indicator
	if _wind_gust_active:
		if _wind_gust_direction > 0.0:
			instruction_label.text = "WIND >>>"
		else:
			instruction_label.text = "<<< WIND"
	elif game_active and not _eliminated:
		instruction_label.text = "Left/Right to balance!"


func _on_game_start() -> void:
	_score = 0
	_balance = 0.5
	_tilt_velocity = 0.0
	_tilt_timer = 0.0
	_elapsed_time = 0.0
	_eliminated = false
	_wind_gust_timer = 0.0
	_wind_gust_active = false
	_update_score_display()
	instruction_label.text = "Left/Right to balance!"
	countdown_label.visible = false
	walker.visible = true
	balance_bar_bg.visible = true
	balance_bar_fill.visible = true
	_update_walker_visual()
	_randomize_tilt()


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
