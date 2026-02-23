extends MiniGameBase

## Hot Potato minigame (Survival).
## A potato timer counts down; press space to throw it before it explodes.
## Each successful throw resets with a shorter fuse.
## If the potato explodes while you hold it, you're eliminated.
## Score = survival time (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea
@onready var potato_rect: ColorRect = %PotatoRect
@onready var fuse_bar: ColorRect = %FuseBar
@onready var fuse_bg: ColorRect = %FuseBG
@onready var throw_label: Label = %ThrowLabel

const INITIAL_FUSE: float = 3.0
const MIN_FUSE: float = 0.8
const FUSE_SHRINK: float = 0.15
const THROW_COOLDOWN: float = 0.5
const POTATO_SIZE: float = 80.0
const FUSE_BAR_WIDTH: float = 300.0
const FUSE_BAR_HEIGHT: float = 30.0

var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _holding_potato: bool = false
var _fuse_time: float = INITIAL_FUSE
var _fuse_remaining: float = INITIAL_FUSE
var _throw_cooldown_remaining: float = 0.0
var _throws: int = 0
var _potato_visible: bool = false


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	_update_score_display()
	instruction_label.text = "Get ready..."
	potato_rect.visible = false
	fuse_bar.visible = false
	fuse_bg.visible = false
	throw_label.visible = false


func _process(delta: float) -> void:
	if not game_active or _eliminated:
		return

	_elapsed_time += delta
	_score = int(_elapsed_time * 10.0)
	_update_score_display()

	if _throw_cooldown_remaining > 0.0:
		_throw_cooldown_remaining -= delta
		if _throw_cooldown_remaining <= 0.0:
			_throw_cooldown_remaining = 0.0
			# Potato returns after cooldown
			_holding_potato = true
			_fuse_time = maxf(INITIAL_FUSE - (_throws * FUSE_SHRINK), MIN_FUSE)
			_fuse_remaining = _fuse_time
			potato_rect.visible = true
			throw_label.visible = true
			instruction_label.text = "PRESS SPACE to throw!"
			_update_potato_color()
		return

	if _holding_potato:
		_fuse_remaining -= delta
		_update_fuse_display()
		_update_potato_color()

		if _fuse_remaining <= 0.0:
			# Potato exploded!
			_eliminated = true
			potato_rect.color = Color(0.1, 0.1, 0.1, 1.0)
			instruction_label.text = "BOOM! Eliminated!"
			throw_label.visible = false
			mark_completed(_score)
			return


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _eliminated:
		return
	if not _holding_potato:
		return
	if event.is_action_pressed("ui_accept"):
		_throw_potato()


func _throw_potato() -> void:
	_throws += 1
	_holding_potato = false
	_throw_cooldown_remaining = THROW_COOLDOWN
	potato_rect.visible = false
	throw_label.visible = false
	instruction_label.text = "Thrown! Waiting..."
	_update_fuse_display()


func _update_potato_color() -> void:
	if _fuse_time <= 0.0:
		return
	var ratio: float = _fuse_remaining / _fuse_time
	if ratio > 0.5:
		potato_rect.color = Color(0.9, 0.7, 0.1, 1.0)  # Yellow = safe
	elif ratio > 0.25:
		potato_rect.color = Color(0.9, 0.4, 0.1, 1.0)  # Orange = warning
	else:
		potato_rect.color = Color(0.9, 0.1, 0.1, 1.0)  # Red = danger


func _update_fuse_display() -> void:
	if _fuse_time <= 0.0:
		return
	var ratio: float = clampf(_fuse_remaining / _fuse_time, 0.0, 1.0)
	fuse_bar.size.x = FUSE_BAR_WIDTH * ratio
	# Color the fuse bar
	if ratio > 0.5:
		fuse_bar.color = Color(0.2, 0.9, 0.3, 1.0)  # Green
	elif ratio > 0.25:
		fuse_bar.color = Color(0.9, 0.9, 0.2, 1.0)  # Yellow
	else:
		fuse_bar.color = Color(0.9, 0.2, 0.2, 1.0)  # Red


func _on_game_start() -> void:
	_score = 0
	_elapsed_time = 0.0
	_eliminated = false
	_holding_potato = true
	_fuse_time = INITIAL_FUSE
	_fuse_remaining = INITIAL_FUSE
	_throw_cooldown_remaining = 0.0
	_throws = 0
	_update_score_display()
	instruction_label.text = "PRESS SPACE to throw!"
	countdown_label.visible = false

	# Position potato in center of play area
	var play_width: float = play_area.size.x
	var play_height: float = play_area.size.y
	potato_rect.position.x = (play_width - POTATO_SIZE) / 2.0
	potato_rect.position.y = (play_height - POTATO_SIZE) / 2.0
	potato_rect.size = Vector2(POTATO_SIZE, POTATO_SIZE)
	potato_rect.visible = true
	_update_potato_color()

	# Position fuse bar below potato
	fuse_bg.position.x = (play_width - FUSE_BAR_WIDTH) / 2.0
	fuse_bg.position.y = potato_rect.position.y + POTATO_SIZE + 20.0
	fuse_bg.size = Vector2(FUSE_BAR_WIDTH, FUSE_BAR_HEIGHT)
	fuse_bg.visible = true

	fuse_bar.position = fuse_bg.position
	fuse_bar.size = Vector2(FUSE_BAR_WIDTH, FUSE_BAR_HEIGHT)
	fuse_bar.visible = true

	# Position throw label
	throw_label.position.x = (play_width - 200.0) / 2.0
	throw_label.position.y = fuse_bg.position.y + FUSE_BAR_HEIGHT + 20.0
	throw_label.size.x = 200.0
	throw_label.visible = true


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
