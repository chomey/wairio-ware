extends MiniGameBase

## Number Sort minigame.
## Numbers are scattered as buttons. Click them in ascending order.
## Race to sort 10 numbers. Score = numbers correctly sorted within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const COMPLETION_TARGET: int = 10
const NUMBER_COUNT: int = 10
const BUTTON_SIZE: Vector2 = Vector2(60, 60)

var _score: int = 0
var _next_expected: int = 0
var _numbers: Array[int] = []
var _buttons: Array[Button] = []


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
	_next_expected = 0
	_update_score_display()
	instruction_label.text = "CLICK NUMBERS IN ORDER: SMALLEST FIRST!"
	countdown_label.visible = false
	_generate_round()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_score)


func _generate_round() -> void:
	# Clear old buttons
	for child: Node in play_area.get_children():
		child.queue_free()
	_buttons.clear()
	_numbers.clear()
	_next_expected = 0

	# Generate unique random numbers
	var pool: Array[int] = []
	for i: int in range(1, 100):
		pool.append(i)
	pool.shuffle()
	for i: int in range(NUMBER_COUNT):
		_numbers.append(pool[i])
	_numbers.sort()

	# Get play area size for positioning
	var area_size: Vector2 = play_area.size
	if area_size.x < BUTTON_SIZE.x or area_size.y < BUTTON_SIZE.y:
		area_size = Vector2(600, 400)

	# Place buttons at random non-overlapping positions
	var positions: Array[Vector2] = []
	var shuffled_numbers: Array[int] = _numbers.duplicate()
	shuffled_numbers.shuffle()

	for num: int in shuffled_numbers:
		var pos: Vector2 = _find_non_overlapping_position(positions, area_size)
		positions.append(pos)

		var btn: Button = Button.new()
		btn.text = str(num)
		btn.custom_minimum_size = BUTTON_SIZE
		btn.size = BUTTON_SIZE
		btn.position = pos

		var stylebox: StyleBoxFlat = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.25, 0.35, 0.55)
		stylebox.corner_radius_top_left = 8
		stylebox.corner_radius_top_right = 8
		stylebox.corner_radius_bottom_left = 8
		stylebox.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", stylebox)

		var hover_box: StyleBoxFlat = StyleBoxFlat.new()
		hover_box.bg_color = Color(0.35, 0.45, 0.65)
		hover_box.corner_radius_top_left = 8
		hover_box.corner_radius_top_right = 8
		hover_box.corner_radius_bottom_left = 8
		hover_box.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("hover", hover_box)

		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_on_number_clicked.bind(num, btn))
		play_area.add_child(btn)
		_buttons.append(btn)


func _find_non_overlapping_position(existing: Array[Vector2], area_size: Vector2) -> Vector2:
	var max_x: float = maxf(area_size.x - BUTTON_SIZE.x, 0.0)
	var max_y: float = maxf(area_size.y - BUTTON_SIZE.y, 0.0)
	var padding: float = 10.0

	for _attempt: int in range(100):
		var x: float = randf() * max_x
		var y: float = randf() * max_y
		var overlaps: bool = false
		for other: Vector2 in existing:
			if absf(x - other.x) < BUTTON_SIZE.x + padding and absf(y - other.y) < BUTTON_SIZE.y + padding:
				overlaps = true
				break
		if not overlaps:
			return Vector2(x, y)

	# Fallback: grid placement if random fails
	var idx: int = existing.size()
	var cols: int = ceili(sqrtf(float(NUMBER_COUNT)))
	var row: int = idx / cols
	var col: int = idx % cols
	return Vector2(col * (BUTTON_SIZE.x + padding), row * (BUTTON_SIZE.y + padding))


func _on_number_clicked(num: int, btn: Button) -> void:
	if not game_active:
		return
	if _next_expected >= _numbers.size():
		return

	if num == _numbers[_next_expected]:
		# Correct click
		_score += 1
		_next_expected += 1
		_update_score_display()

		# Visually mark as done
		var done_style: StyleBoxFlat = StyleBoxFlat.new()
		done_style.bg_color = Color(0.2, 0.7, 0.2)
		done_style.corner_radius_top_left = 8
		done_style.corner_radius_top_right = 8
		done_style.corner_radius_bottom_left = 8
		done_style.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", done_style)
		btn.add_theme_stylebox_override("hover", done_style)
		btn.disabled = true

		if _score >= COMPLETION_TARGET:
			mark_completed(_score)
	else:
		# Wrong click - flash red briefly
		instruction_label.text = "WRONG! Find " + str(_numbers[_next_expected]) + " next!"


func _update_score_display() -> void:
	score_label.text = "Sorted: " + str(_score) + " / " + str(COMPLETION_TARGET)
	if _next_expected < _numbers.size():
		instruction_label.text = "CLICK NUMBERS IN ORDER: SMALLEST FIRST!"


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
