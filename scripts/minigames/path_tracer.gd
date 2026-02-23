extends MiniGameBase

## Path Tracer minigame.
## Numbered waypoints appear on screen. Click them in order (1, 2, 3, ...).
## Each completed path generates a new one. Race to trace 3 paths.
## Score = number of paths traced within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const COMPLETION_TARGET: int = 3
const WAYPOINT_COUNT: int = 8
const WAYPOINT_SIZE: Vector2 = Vector2(50, 50)

var _score: int = 0
var _next_index: int = 0
var _waypoint_buttons: Array[Button] = []


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
	_next_index = 0
	_update_score_display()
	instruction_label.text = "CLICK WAYPOINTS IN ORDER: 1, 2, 3..."
	countdown_label.visible = false
	_generate_path()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_score)


func _generate_path() -> void:
	# Clear old waypoints
	for child: Node in play_area.get_children():
		child.queue_free()
	_waypoint_buttons.clear()
	_next_index = 0

	# Get play area size
	var area_size: Vector2 = play_area.size
	if area_size.x < WAYPOINT_SIZE.x or area_size.y < WAYPOINT_SIZE.y:
		area_size = Vector2(600, 400)

	# Place waypoints at random non-overlapping positions
	var positions: Array[Vector2] = []
	for i: int in range(WAYPOINT_COUNT):
		var pos: Vector2 = _find_non_overlapping_position(positions, area_size)
		positions.append(pos)

		var btn: Button = Button.new()
		btn.text = str(i + 1)
		btn.custom_minimum_size = WAYPOINT_SIZE
		btn.size = WAYPOINT_SIZE
		btn.position = pos

		var stylebox: StyleBoxFlat = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.3, 0.4, 0.6)
		stylebox.corner_radius_top_left = 25
		stylebox.corner_radius_top_right = 25
		stylebox.corner_radius_bottom_left = 25
		stylebox.corner_radius_bottom_right = 25
		btn.add_theme_stylebox_override("normal", stylebox)

		var hover_box: StyleBoxFlat = StyleBoxFlat.new()
		hover_box.bg_color = Color(0.4, 0.5, 0.7)
		hover_box.corner_radius_top_left = 25
		hover_box.corner_radius_top_right = 25
		hover_box.corner_radius_bottom_left = 25
		hover_box.corner_radius_bottom_right = 25
		btn.add_theme_stylebox_override("hover", hover_box)

		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_waypoint_clicked.bind(i, btn))
		play_area.add_child(btn)
		_waypoint_buttons.append(btn)


func _find_non_overlapping_position(existing: Array[Vector2], area_size: Vector2) -> Vector2:
	var max_x: float = maxf(area_size.x - WAYPOINT_SIZE.x, 0.0)
	var max_y: float = maxf(area_size.y - WAYPOINT_SIZE.y, 0.0)
	var padding: float = 10.0

	for _attempt: int in range(100):
		var x: float = randf() * max_x
		var y: float = randf() * max_y
		var overlaps: bool = false
		for other: Vector2 in existing:
			if absf(x - other.x) < WAYPOINT_SIZE.x + padding and absf(y - other.y) < WAYPOINT_SIZE.y + padding:
				overlaps = true
				break
		if not overlaps:
			return Vector2(x, y)

	# Fallback: grid placement
	var idx: int = existing.size()
	var cols: int = ceili(sqrtf(float(WAYPOINT_COUNT)))
	var row: int = idx / cols
	var col: int = idx % cols
	return Vector2(col * (WAYPOINT_SIZE.x + padding), row * (WAYPOINT_SIZE.y + padding))


func _on_waypoint_clicked(index: int, btn: Button) -> void:
	if not game_active:
		return

	if index == _next_index:
		# Correct waypoint
		_next_index += 1

		# Mark as visited
		var done_style: StyleBoxFlat = StyleBoxFlat.new()
		done_style.bg_color = Color(0.2, 0.7, 0.2)
		done_style.corner_radius_top_left = 25
		done_style.corner_radius_top_right = 25
		done_style.corner_radius_bottom_left = 25
		done_style.corner_radius_bottom_right = 25
		btn.add_theme_stylebox_override("normal", done_style)
		btn.add_theme_stylebox_override("hover", done_style)
		btn.disabled = true

		if _next_index >= WAYPOINT_COUNT:
			# Path completed
			_score += 1
			_update_score_display()
			if _score >= COMPLETION_TARGET:
				mark_completed(_score)
			else:
				_generate_path()
	else:
		# Wrong waypoint
		instruction_label.text = "WRONG! Click waypoint " + str(_next_index + 1) + " next!"


func _update_score_display() -> void:
	score_label.text = "Paths: " + str(_score) + " / " + str(COMPLETION_TARGET)
	instruction_label.text = "CLICK WAYPOINTS IN ORDER: 1, 2, 3..."


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
