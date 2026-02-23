extends MiniGameBase

## Color Mixer minigame.
## A target color is shown. Player clicks R, G, B buttons to adjust
## their color to match. Race to 6 colors matched. Score = colors matched.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var target_color_rect: ColorRect = %TargetColorRect
@onready var player_color_rect: ColorRect = %PlayerColorRect
@onready var target_label: Label = %TargetLabel
@onready var yours_label: Label = %YoursLabel
@onready var r_up_button: Button = %RUpButton
@onready var r_down_button: Button = %RDownButton
@onready var g_up_button: Button = %GUpButton
@onready var g_down_button: Button = %GDownButton
@onready var b_up_button: Button = %BUpButton
@onready var b_down_button: Button = %BDownButton
@onready var submit_button: Button = %SubmitButton
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel
@onready var rgb_label: Label = %RGBLabel

const COMPLETION_TARGET: int = 6
const STEP: int = 32
const TOLERANCE: int = 16

var _correct_count: int = 0
var _target_r: int = 0
var _target_g: int = 0
var _target_b: int = 0
var _player_r: int = 128
var _player_g: int = 128
var _player_b: int = 128


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	r_up_button.pressed.connect(_on_r_up)
	r_down_button.pressed.connect(_on_r_down)
	g_up_button.pressed.connect(_on_g_up)
	g_down_button.pressed.connect(_on_g_down)
	b_up_button.pressed.connect(_on_b_up)
	b_down_button.pressed.connect(_on_b_down)
	submit_button.pressed.connect(_on_submit)
	feedback_label.text = ""
	score_label.text = "Matched: 0 / " + str(COMPLETION_TARGET)
	rgb_label.text = ""
	_set_buttons_enabled(false)


func _on_game_start() -> void:
	countdown_label.visible = false
	_correct_count = 0
	score_label.text = "Matched: 0 / " + str(COMPLETION_TARGET)
	_set_buttons_enabled(true)
	_generate_target()


func _on_game_end() -> void:
	_set_buttons_enabled(false)
	feedback_label.text = "Time's up! You matched " + str(_correct_count) + " colors!"
	submit_score(_correct_count)


func _set_buttons_enabled(enabled: bool) -> void:
	r_up_button.disabled = not enabled
	r_down_button.disabled = not enabled
	g_up_button.disabled = not enabled
	g_down_button.disabled = not enabled
	b_up_button.disabled = not enabled
	b_down_button.disabled = not enabled
	submit_button.disabled = not enabled


func _generate_target() -> void:
	# Generate target color using multiples of STEP (0-224 range)
	_target_r = randi_range(0, 7) * STEP
	_target_g = randi_range(0, 7) * STEP
	_target_b = randi_range(0, 7) * STEP
	target_color_rect.color = Color8(_target_r, _target_g, _target_b)
	# Reset player color
	_player_r = 128
	_player_g = 128
	_player_b = 128
	_update_player_color()
	feedback_label.text = "Adjust R/G/B to match the target!"


func _update_player_color() -> void:
	player_color_rect.color = Color8(_player_r, _player_g, _player_b)
	rgb_label.text = "R:" + str(_player_r) + " G:" + str(_player_g) + " B:" + str(_player_b)


func _on_r_up() -> void:
	if not game_active:
		return
	_player_r = mini(_player_r + STEP, 224)
	_update_player_color()


func _on_r_down() -> void:
	if not game_active:
		return
	_player_r = maxi(_player_r - STEP, 0)
	_update_player_color()


func _on_g_up() -> void:
	if not game_active:
		return
	_player_g = mini(_player_g + STEP, 224)
	_update_player_color()


func _on_g_down() -> void:
	if not game_active:
		return
	_player_g = maxi(_player_g - STEP, 0)
	_update_player_color()


func _on_b_up() -> void:
	if not game_active:
		return
	_player_b = mini(_player_b + STEP, 224)
	_update_player_color()


func _on_b_down() -> void:
	if not game_active:
		return
	_player_b = maxi(_player_b - STEP, 0)
	_update_player_color()


func _on_submit() -> void:
	if not game_active:
		return
	var dr: int = absi(_player_r - _target_r)
	var dg: int = absi(_player_g - _target_g)
	var db: int = absi(_player_b - _target_b)
	if dr <= TOLERANCE and dg <= TOLERANCE and db <= TOLERANCE:
		_correct_count += 1
		feedback_label.text = "Matched!"
		score_label.text = "Matched: " + str(_correct_count) + " / " + str(COMPLETION_TARGET)
		if _correct_count >= COMPLETION_TARGET:
			mark_completed(_correct_count)
			return
		_generate_target()
	else:
		feedback_label.text = "Not close enough! Keep adjusting."


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
