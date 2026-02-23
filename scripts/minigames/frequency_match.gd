extends MiniGameBase

## Frequency Match minigame.
## A "tone" is displayed as a visual wave pattern (sine wave).
## Player selects the matching frequency bar from 4 choices.
## Race to 10 correct matches.
## Score = number of correct matches within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var wave_display: Control = %WaveDisplay
@onready var choices_container: HBoxContainer = %ChoicesContainer

const COMPLETION_TARGET: int = 10
const NUM_CHOICES: int = 4
const BAR_WIDTH: float = 60.0
const BAR_MAX_HEIGHT: float = 160.0
const BAR_MIN_HEIGHT: float = 30.0

## Frequency values to pick from (in arbitrary "Hz" units for display)
const FREQUENCIES: Array[float] = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0]

var _score: int = 0
var _target_freq: float = 0.0
var _correct_index: int = -1
var _wave_time: float = 0.0


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	instruction_label.text = "Get ready..."
	_update_score_display()
	wave_display.draw.connect(_on_wave_draw)


func _process(delta: float) -> void:
	if game_active:
		_wave_time += delta
		wave_display.queue_redraw()


func _on_game_start() -> void:
	_score = 0
	_wave_time = 0.0
	_update_score_display()
	instruction_label.text = "CLICK THE MATCHING FREQUENCY!"
	countdown_label.visible = false
	_generate_round()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_score)


func _generate_round() -> void:
	# Pick a target frequency
	var available: Array[float] = FREQUENCIES.duplicate()
	available.shuffle()
	_target_freq = available[0]

	# Build choices: one correct + 3 distractors
	var choices: Array[float] = []
	choices.append(_target_freq)

	var idx: int = 1
	while choices.size() < NUM_CHOICES and idx < available.size():
		var candidate: float = available[idx]
		# Ensure distractors differ by at least 0.5 from all existing choices
		var too_close: bool = false
		for existing: float in choices:
			if absf(candidate - existing) < 0.5:
				too_close = true
				break
		if not too_close:
			choices.append(candidate)
		idx += 1

	# Fallback: if not enough distinct choices, just add remaining
	idx = 1
	while choices.size() < NUM_CHOICES and idx < available.size():
		if not choices.has(available[idx]):
			choices.append(available[idx])
		idx += 1

	# Shuffle and find the correct index
	choices.shuffle()
	_correct_index = -1
	for i: int in range(choices.size()):
		if absf(choices[i] - _target_freq) < 0.01:
			_correct_index = i
			break

	_rebuild_choices(choices)
	wave_display.queue_redraw()


func _on_wave_draw() -> void:
	if _target_freq <= 0.0:
		return

	var w: float = wave_display.size.x
	var h: float = wave_display.size.y
	var amplitude: float = h * 0.35
	var center_y: float = h * 0.5

	# Draw a sine wave representing the target frequency
	var prev_point: Vector2 = Vector2.ZERO
	var step_count: int = int(w / 2.0)
	for i: int in range(step_count + 1):
		var x: float = (float(i) / float(step_count)) * w
		var t: float = (x / w) * TAU * _target_freq * 2.0
		var y: float = center_y + sin(t + _wave_time * 4.0) * amplitude
		var point: Vector2 = Vector2(x, y)
		if i > 0:
			wave_display.draw_line(prev_point, point, Color(0.3, 0.9, 0.3), 3.0)
		prev_point = point

	# Draw center line
	wave_display.draw_line(Vector2(0, center_y), Vector2(w, center_y), Color(0.3, 0.3, 0.3, 0.5), 1.0)

	# Draw frequency label
	wave_display.draw_string(
		ThemeDB.fallback_font,
		Vector2(8, 18),
		"%.1f Hz" % _target_freq,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color(0.3, 0.9, 0.3, 0.7)
	)


func _rebuild_choices(freqs: Array[float]) -> void:
	for child: Node in choices_container.get_children():
		child.queue_free()

	for i: int in range(freqs.size()):
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(BAR_WIDTH, BAR_MAX_HEIGHT + 40)
		btn.text = "%.1f Hz" % freqs[i]

		# Height of bar proportional to frequency
		var freq_ratio: float = (freqs[i] - FREQUENCIES[0]) / (FREQUENCIES[FREQUENCIES.size() - 1] - FREQUENCIES[0])
		var bar_height: float = BAR_MIN_HEIGHT + freq_ratio * (BAR_MAX_HEIGHT - BAR_MIN_HEIGHT)

		# Color varies with frequency (low=blue, high=red)
		var bar_color: Color = Color.from_hsv(0.6 - freq_ratio * 0.6, 0.7, 0.9)

		var stylebox: StyleBoxFlat = StyleBoxFlat.new()
		stylebox.bg_color = bar_color
		stylebox.corner_radius_top_left = 4
		stylebox.corner_radius_top_right = 4
		stylebox.corner_radius_bottom_left = 4
		stylebox.corner_radius_bottom_right = 4
		stylebox.content_margin_top = BAR_MAX_HEIGHT - bar_height
		btn.add_theme_stylebox_override("normal", stylebox)
		btn.add_theme_stylebox_override("hover", stylebox)
		btn.add_theme_stylebox_override("pressed", stylebox)
		btn.add_theme_stylebox_override("focus", stylebox)

		var idx: int = i
		btn.pressed.connect(_on_choice_clicked.bind(idx))
		choices_container.add_child(btn)


func _on_choice_clicked(index: int) -> void:
	if not game_active:
		return

	if index == _correct_index:
		_score += 1
		_update_score_display()
		if _score >= COMPLETION_TARGET:
			mark_completed(_score)
			return
		_generate_round()
	else:
		instruction_label.text = "WRONG! Try again..."
		var timer: SceneTreeTimer = get_tree().create_timer(0.5)
		timer.timeout.connect(func() -> void:
			if game_active:
				instruction_label.text = "CLICK THE MATCHING FREQUENCY!"
		)


func _update_score_display() -> void:
	score_label.text = "Matched: " + str(_score) + " / " + str(COMPLETION_TARGET)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
