extends MiniGameBase

## Speed Clicker minigame.
## Targets appear in sequence - click only GREEN ones, avoid RED ones.
## Race to 15 correct green clicks.
## Score = number of correct green clicks within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const COMPLETION_TARGET: int = 15
const TARGET_SIZE: Vector2 = Vector2(60, 60)
const TARGET_LIFETIME: float = 1.2
const SPAWN_INTERVAL_START: float = 0.8
const SPAWN_INTERVAL_MIN: float = 0.35
const GREEN_CHANCE: float = 0.6

var _score: int = 0
var _spawn_timer: float = 0.0
var _spawn_interval: float = SPAWN_INTERVAL_START
var _active_targets: Array[Dictionary] = []


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	instruction_label.text = "Get ready..."
	_update_score_display()


func _on_game_start() -> void:
	_score = 0
	_spawn_timer = 0.0
	_spawn_interval = SPAWN_INTERVAL_START
	_active_targets.clear()
	_update_score_display()
	instruction_label.text = "CLICK GREEN - AVOID RED!"
	countdown_label.visible = false
	_spawn_target()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	_clear_all_targets()
	submit_score(_score)


func _process(delta: float) -> void:
	if not game_active:
		return

	_spawn_timer += delta
	if _spawn_timer >= _spawn_interval:
		_spawn_timer = 0.0
		_spawn_target()

	# Check expired targets
	var expired: Array[int] = []
	for i: int in range(_active_targets.size()):
		_active_targets[i]["lifetime"] = (_active_targets[i]["lifetime"] as float) - delta
		if (_active_targets[i]["lifetime"] as float) <= 0.0:
			expired.append(i)

	# Remove expired targets in reverse order
	for i: int in range(expired.size() - 1, -1, -1):
		var idx: int = expired[i]
		var btn: Button = _active_targets[idx]["button"] as Button
		btn.queue_free()
		_active_targets.remove_at(idx)


func _spawn_target() -> void:
	if not game_active:
		return

	var area_size: Vector2 = play_area.size
	if area_size.x < TARGET_SIZE.x or area_size.y < TARGET_SIZE.y:
		return

	var is_green: bool = randf() < GREEN_CHANCE
	var btn: Button = Button.new()
	btn.custom_minimum_size = TARGET_SIZE
	btn.size = TARGET_SIZE

	var style: StyleBoxFlat = StyleBoxFlat.new()
	if is_green:
		style.bg_color = Color(0.1, 0.8, 0.15)
		btn.text = "O"
	else:
		style.bg_color = Color(0.85, 0.1, 0.1)
		btn.text = "X"
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

	var max_x: float = area_size.x - TARGET_SIZE.x
	var max_y: float = area_size.y - TARGET_SIZE.y
	var pos_x: float = randf() * max_x
	var pos_y: float = randf() * max_y
	btn.position = Vector2(pos_x, pos_y)

	var target_data: Dictionary = {
		"button": btn,
		"is_green": is_green,
		"lifetime": TARGET_LIFETIME,
	}

	btn.pressed.connect(_on_target_clicked.bind(target_data))
	play_area.add_child(btn)
	_active_targets.append(target_data)

	# Speed up spawning over time
	_spawn_interval = maxf(SPAWN_INTERVAL_MIN, _spawn_interval - 0.02)


func _on_target_clicked(target_data: Dictionary) -> void:
	if not game_active:
		return

	var btn: Button = target_data["button"] as Button
	var is_green: bool = target_data["is_green"] as bool

	# Remove from active list
	for i: int in range(_active_targets.size()):
		if _active_targets[i]["button"] == btn:
			_active_targets.remove_at(i)
			break
	btn.queue_free()

	if is_green:
		_score += 1
		_update_score_display()
		if _score >= COMPLETION_TARGET:
			mark_completed(_score)
			return
	else:
		# Penalty: lose 1 point (min 0)
		_score = maxi(0, _score - 1)
		_update_score_display()
		instruction_label.text = "WRONG! Avoid RED!"
		var timer: SceneTreeTimer = get_tree().create_timer(0.5)
		timer.timeout.connect(func() -> void:
			if game_active:
				instruction_label.text = "CLICK GREEN - AVOID RED!"
		)


func _clear_all_targets() -> void:
	for target: Dictionary in _active_targets:
		var btn: Button = target["button"] as Button
		if is_instance_valid(btn):
			btn.queue_free()
	_active_targets.clear()


func _update_score_display() -> void:
	score_label.text = "Score: " + str(_score) + " / " + str(COMPLETION_TARGET)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
