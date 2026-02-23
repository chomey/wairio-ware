extends MiniGameBase

## Decoy Detect minigame.
## A group of moving dots travel in the same pattern, but one moves differently.
## Click the odd one out. Race to 10 spotted.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var status_label: Label = %StatusLabel
@onready var play_area: Control = %PlayArea

const COMPLETION_TARGET: int = 10
const DOT_COUNT: int = 12
const DOT_RADIUS: float = 12.0
const NORMAL_SPEED: float = 80.0
const DECOY_SPEED: float = 140.0

var _score: int = 0
var _dots: Array[Dictionary] = []  # {pos: Vector2, vel: Vector2, is_decoy: bool}
var _decoy_index: int = -1
var _feedback_timer: float = 0.0
var _feedback_text: String = ""


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	status_label.text = ""
	score_label.text = "Spotted: 0 / " + str(COMPLETION_TARGET)
	play_area.draw.connect(_on_play_area_draw)
	play_area.gui_input.connect(_on_play_area_input)


func _on_game_start() -> void:
	countdown_label.visible = false
	_score = 0
	score_label.text = "Spotted: 0 / " + str(COMPLETION_TARGET)
	status_label.text = "Click the dot that moves differently!"
	_spawn_dots()


func _on_game_end() -> void:
	status_label.text = "Time's up! Spotted " + str(_score) + "!"
	submit_score(_score)


func _spawn_dots() -> void:
	_dots.clear()
	var area_size: Vector2 = play_area.size
	if area_size.x < 1.0 or area_size.y < 1.0:
		area_size = Vector2(500, 350)

	# Random shared direction for normal dots
	var normal_angle: float = randf() * TAU
	var normal_vel: Vector2 = Vector2(cos(normal_angle), sin(normal_angle)) * NORMAL_SPEED

	# Decoy moves in a noticeably different direction and speed
	var decoy_angle: float = normal_angle + PI * randf_range(0.4, 0.8) * (1 if randi() % 2 == 0 else -1)
	var decoy_vel: Vector2 = Vector2(cos(decoy_angle), sin(decoy_angle)) * DECOY_SPEED

	_decoy_index = randi_range(0, DOT_COUNT - 1)

	var margin: float = DOT_RADIUS + 5.0
	for i: int in range(DOT_COUNT):
		var pos: Vector2 = Vector2(
			randf_range(margin, area_size.x - margin),
			randf_range(margin, area_size.y - margin)
		)
		var vel: Vector2 = decoy_vel if i == _decoy_index else normal_vel
		_dots.append({"pos": pos, "vel": vel, "is_decoy": i == _decoy_index})


func _process(delta: float) -> void:
	if not game_active:
		return

	var area_size: Vector2 = play_area.size
	if area_size.x < 1.0 or area_size.y < 1.0:
		return

	# Move dots and bounce off walls
	for dot: Dictionary in _dots:
		var pos: Vector2 = dot["pos"] as Vector2
		var vel: Vector2 = dot["vel"] as Vector2
		pos += vel * delta

		# Bounce off edges
		if pos.x < DOT_RADIUS:
			pos.x = DOT_RADIUS
			vel.x = absf(vel.x)
		elif pos.x > area_size.x - DOT_RADIUS:
			pos.x = area_size.x - DOT_RADIUS
			vel.x = -absf(vel.x)

		if pos.y < DOT_RADIUS:
			pos.y = DOT_RADIUS
			vel.y = absf(vel.y)
		elif pos.y > area_size.y - DOT_RADIUS:
			pos.y = area_size.y - DOT_RADIUS
			vel.y = -absf(vel.y)

		dot["pos"] = pos
		dot["vel"] = vel

	# Feedback timer
	if _feedback_timer > 0.0:
		_feedback_timer -= delta
		if _feedback_timer <= 0.0:
			_feedback_text = ""

	play_area.queue_redraw()


func _on_play_area_input(event: InputEvent) -> void:
	if not game_active:
		return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(mb.position)


func _handle_click(click_pos: Vector2) -> void:
	# Find closest dot to click
	var closest_idx: int = -1
	var closest_dist: float = INF
	for i: int in range(_dots.size()):
		var dist: float = click_pos.distance_to(_dots[i]["pos"] as Vector2)
		if dist < closest_dist:
			closest_dist = dist
			closest_idx = i

	if closest_idx < 0 or closest_dist > DOT_RADIUS * 2.5:
		return  # Clicked too far from any dot

	if _dots[closest_idx]["is_decoy"] as bool:
		_score += 1
		score_label.text = "Spotted: " + str(_score) + " / " + str(COMPLETION_TARGET)
		_feedback_text = "Correct!"
		_feedback_timer = 0.5

		if _score >= COMPLETION_TARGET:
			mark_completed(_score)
			return

		_spawn_dots()
	else:
		_feedback_text = "Wrong!"
		_feedback_timer = 0.5


func _on_play_area_draw() -> void:
	# Draw dots
	for i: int in range(_dots.size()):
		var pos: Vector2 = _dots[i]["pos"] as Vector2
		var color: Color = Color(0.3, 0.7, 1.0)  # All look the same
		play_area.draw_circle(pos, DOT_RADIUS, color)

	# Draw feedback
	if _feedback_text != "":
		var font: Font = ThemeDB.fallback_font
		var font_size: int = 20
		var text_color: Color = Color.GREEN if _feedback_text == "Correct!" else Color.RED
		var text_pos: Vector2 = Vector2(play_area.size.x / 2.0 - 30.0, 25.0)
		play_area.draw_string(font, text_pos, _feedback_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
