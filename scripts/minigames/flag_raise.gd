extends MiniGameBase

## Flag Raise minigame.
## Tap spacebar with correct rhythm to raise the flag smoothly.
## A beat indicator oscillates; tap when it's in the green zone.
## Good taps raise the flag, off-rhythm taps lower it.
## Race: flag reaches the top to complete.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var status_label: Label = %StatusLabel
@onready var flag_pole: ColorRect = %FlagPole
@onready var flag_rect: ColorRect = %FlagRect
@onready var beat_bar: ColorRect = %BeatBar
@onready var beat_indicator: ColorRect = %BeatIndicator
@onready var beat_zone: ColorRect = %BeatZone

const BAR_WIDTH: float = 300.0
const INDICATOR_WIDTH: float = 8.0
const ZONE_WIDTH: float = 60.0
const POLE_HEIGHT: float = 300.0
const RAISE_AMOUNT: float = 0.08
const DROP_AMOUNT: float = 0.05
const BPM: float = 90.0

var _flag_progress: float = 0.0  # 0.0 = bottom, 1.0 = top
var _indicator_pos: float = 0.0
var _indicator_speed: float = 0.0
var _indicator_direction: float = 1.0
var _zone_center: float = 150.0
var _beat_count: int = 0
var _good_taps: int = 0
var _total_taps: int = 0


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	status_label.text = ""
	score_label.text = "Flag: 0%"
	_update_flag_visual()
	_setup_beat_zone()


func _on_game_start() -> void:
	countdown_label.visible = false
	_flag_progress = 0.0
	_indicator_pos = 0.0
	_indicator_direction = 1.0
	_beat_count = 0
	_good_taps = 0
	_total_taps = 0
	# Speed derived from BPM: one full bar sweep per beat
	# Beat interval = 60/BPM seconds, indicator travels BAR_WIDTH in that time
	_indicator_speed = BAR_WIDTH / (60.0 / BPM)
	status_label.text = "Tap SPACE in the GREEN zone!"
	score_label.text = "Flag: 0%"
	_setup_beat_zone()
	_update_flag_visual()
	_update_indicator()


func _on_game_end() -> void:
	var pct: int = int(_flag_progress * 100.0)
	status_label.text = "Time's up! Flag at " + str(pct) + "%"
	submit_score(_good_taps)


func _process(delta: float) -> void:
	if not game_active:
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
	if not game_active:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
			_handle_tap()


func _handle_tap() -> void:
	_total_taps += 1
	var indicator_center: float = _indicator_pos + INDICATOR_WIDTH / 2.0
	var zone_start: float = _zone_center - ZONE_WIDTH / 2.0
	var zone_end: float = _zone_center + ZONE_WIDTH / 2.0

	if indicator_center >= zone_start and indicator_center <= zone_end:
		# Good tap - raise the flag
		_good_taps += 1
		_flag_progress = minf(_flag_progress + RAISE_AMOUNT, 1.0)
		_beat_count += 1
		status_label.text = "GOOD! Keep the rhythm!"

		# Reposition zone for variety
		if _beat_count % 3 == 0:
			_setup_beat_zone()

		if _flag_progress >= 1.0:
			status_label.text = "FLAG RAISED!"
			mark_completed(_good_taps)
			return
	else:
		# Off rhythm - flag drops
		_flag_progress = maxf(_flag_progress - DROP_AMOUNT, 0.0)
		status_label.text = "Off rhythm! Flag drops..."

	_update_flag_visual()
	var pct: int = int(_flag_progress * 100.0)
	score_label.text = "Flag: " + str(pct) + "%"


func _setup_beat_zone() -> void:
	_zone_center = randf_range(ZONE_WIDTH / 2.0, BAR_WIDTH - ZONE_WIDTH / 2.0)
	beat_zone.position.x = _zone_center - ZONE_WIDTH / 2.0
	beat_zone.size.x = ZONE_WIDTH


func _update_indicator() -> void:
	beat_indicator.position.x = _indicator_pos


func _update_flag_visual() -> void:
	# Flag moves up the pole based on progress
	var flag_y: float = POLE_HEIGHT * (1.0 - _flag_progress)
	flag_rect.position.y = flag_y
	# Color shifts from red (bottom) to green (top)
	var r: float = 1.0 - _flag_progress
	var g: float = _flag_progress
	flag_rect.color = Color(r, g, 0.2, 1.0)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
