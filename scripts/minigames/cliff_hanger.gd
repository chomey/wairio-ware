extends MiniGameBase

## Cliff Hanger minigame (Survival).
## Character slides toward the cliff edge with increasing speed.
## Tap spacebar to brake. Each tap reduces speed but doesn't stop you completely.
## If you overshoot the cliff edge, you're eliminated.
## After stopping near the edge, you reset further back with higher speed.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const CLIFF_X_RATIO: float = 0.85
const PLAYER_SIZE: float = 24.0
const INITIAL_SPEED: float = 80.0
const SPEED_INCREMENT: float = 12.0
const BRAKE_STRENGTH: float = 60.0
const MIN_SPEED_AFTER_BRAKE: float = 5.0
const RESET_X_RATIO: float = 0.15
const DANGER_ZONE_RATIO: float = 0.6

var _player_x: float = 0.0
var _speed: float = INITIAL_SPEED
var _base_speed: float = INITIAL_SPEED
var _round_count: int = 0
var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _resetting: bool = false
var _reset_timer: float = 0.0


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

	if _resetting:
		_reset_timer -= delta
		if _reset_timer <= 0.0:
			_resetting = false
			_start_new_slide()
		play_area.queue_redraw()
		return

	# Slide toward cliff
	_player_x += _speed * delta

	# Check if fell off the cliff
	var cliff_x: float = play_area.size.x * CLIFF_X_RATIO
	if _player_x + PLAYER_SIZE >= cliff_x:
		_eliminated = true
		instruction_label.text = "Fell off! Eliminated!"
		play_area.queue_redraw()
		mark_completed(_score)
		return

	# Check if speed is very low (stopped) - success, move to next round
	if _speed <= MIN_SPEED_AFTER_BRAKE:
		_resetting = true
		_reset_timer = 0.5
		_round_count += 1
		instruction_label.text = "Safe! Round " + str(_round_count) + " cleared!"

	play_area.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _eliminated or _resetting:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
			_brake()
			get_viewport().set_input_as_handled()


func _brake() -> void:
	_speed = maxf(_speed - BRAKE_STRENGTH, 0.0)


func _start_new_slide() -> void:
	_base_speed += SPEED_INCREMENT
	_speed = _base_speed
	_player_x = play_area.size.x * RESET_X_RATIO
	instruction_label.text = "Tap SPACE to brake!"


func _on_play_area_draw() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y
	var cliff_x: float = pw * CLIFF_X_RATIO
	var ground_y: float = ph * 0.65

	# Draw ground
	play_area.draw_rect(Rect2(0.0, ground_y, cliff_x, ph - ground_y), Color(0.35, 0.25, 0.15, 1.0))

	# Draw cliff edge marker
	play_area.draw_rect(Rect2(cliff_x - 3.0, ground_y - 20.0, 6.0, 20.0), Color(0.8, 0.2, 0.2, 1.0))

	# Draw abyss below cliff
	play_area.draw_rect(Rect2(cliff_x, ground_y, pw - cliff_x, ph - ground_y), Color(0.02, 0.02, 0.05, 1.0))

	# Draw danger zone warning
	var danger_start: float = cliff_x * DANGER_ZONE_RATIO
	play_area.draw_rect(Rect2(danger_start, ground_y - 2.0, cliff_x - danger_start, 2.0), Color(1.0, 0.3, 0.0, 0.5))

	# Draw player
	if not _eliminated:
		var player_y: float = ground_y - PLAYER_SIZE
		var progress: float = _player_x / cliff_x if cliff_x > 0.0 else 0.0
		var player_color: Color
		if progress < 0.5:
			player_color = Color(0.2, 0.8, 0.2, 1.0)
		elif progress < 0.75:
			player_color = Color(0.9, 0.9, 0.1, 1.0)
		else:
			player_color = Color(0.9, 0.2, 0.1, 1.0)
		play_area.draw_rect(Rect2(_player_x, player_y, PLAYER_SIZE, PLAYER_SIZE), player_color)

	# Draw speed bar
	var bar_y: float = ph - 30.0
	var bar_width: float = pw * 0.6
	var bar_x: float = (pw - bar_width) * 0.5
	play_area.draw_rect(Rect2(bar_x, bar_y, bar_width, 12.0), Color(0.15, 0.15, 0.2, 1.0))
	var speed_ratio: float = clampf(_speed / (_base_speed * 1.2), 0.0, 1.0)
	var speed_color: Color = Color(speed_ratio, 1.0 - speed_ratio, 0.1, 1.0)
	play_area.draw_rect(Rect2(bar_x, bar_y, bar_width * speed_ratio, 12.0), speed_color)
	play_area.draw_string(ThemeDB.fallback_font, Vector2(bar_x + bar_width + 8.0, bar_y + 10.0), "Speed", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.7, 0.7, 0.7))


func _on_game_start() -> void:
	_player_x = play_area.size.x * RESET_X_RATIO
	_speed = INITIAL_SPEED
	_base_speed = INITIAL_SPEED
	_round_count = 0
	_elapsed_time = 0.0
	_score = 0
	_eliminated = false
	_resetting = false
	_reset_timer = 0.0
	_update_score_display()
	instruction_label.text = "Tap SPACE to brake!"
	countdown_label.visible = false
	play_area.queue_redraw()


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! Survived!"
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Rounds: " + str(_round_count)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
