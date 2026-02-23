extends MiniGameBase

## Hex Match minigame.
## A hex color code is displayed along with 4 color swatches.
## Player clicks the swatch that matches the hex code.
## Race to 10 correct matches.
## Score = number of correct matches within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var hex_label: Label = %HexLabel
@onready var choices_container: HBoxContainer = %ChoicesContainer

const COMPLETION_TARGET: int = 10
const SWATCH_SIZE: Vector2 = Vector2(80, 80)
const NUM_CHOICES: int = 4

var _score: int = 0
var _correct_index: int = -1


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	instruction_label.text = "Get ready..."
	hex_label.text = ""
	_update_score_display()


func _on_game_start() -> void:
	_score = 0
	_update_score_display()
	instruction_label.text = "CLICK THE MATCHING COLOR!"
	countdown_label.visible = false
	_generate_round()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_score)


func _generate_round() -> void:
	# Generate a random target color
	var target_color: Color = _random_color()
	var hex_string: String = "#" + _color_to_hex(target_color)
	hex_label.text = hex_string

	# Build choices: one correct + 3 distractors
	var choices: Array[Color] = []
	choices.append(target_color)

	while choices.size() < NUM_CHOICES:
		var distractor: Color = _random_color()
		# Ensure distractors are visually distinct (differ by at least 48 in some channel)
		var too_close: bool = false
		for existing: Color in choices:
			if _colors_too_close(distractor, existing):
				too_close = true
				break
		if not too_close:
			choices.append(distractor)

	# Shuffle and find the correct index
	choices.shuffle()
	_correct_index = choices.find(target_color)

	_rebuild_choices(choices)


func _random_color() -> Color:
	# Generate colors with components in steps of 16 for readable hex
	var r: int = (randi() % 14 + 1) * 16  # 16-224 range, avoids pure black/white
	var g: int = (randi() % 14 + 1) * 16
	var b: int = (randi() % 14 + 1) * 16
	return Color(r / 255.0, g / 255.0, b / 255.0)


func _color_to_hex(c: Color) -> String:
	var r: int = roundi(c.r * 255.0)
	var g: int = roundi(c.g * 255.0)
	var b: int = roundi(c.b * 255.0)
	return "%02X%02X%02X" % [r, g, b]


func _colors_too_close(a: Color, b: Color) -> bool:
	var dr: int = absi(roundi(a.r * 255.0) - roundi(b.r * 255.0))
	var dg: int = absi(roundi(a.g * 255.0) - roundi(b.g * 255.0))
	var db: int = absi(roundi(a.b * 255.0) - roundi(b.b * 255.0))
	return dr < 48 and dg < 48 and db < 48


func _rebuild_choices(colors: Array[Color]) -> void:
	for child: Node in choices_container.get_children():
		child.queue_free()

	for i: int in range(colors.size()):
		var btn: Button = Button.new()
		btn.custom_minimum_size = SWATCH_SIZE
		var stylebox: StyleBoxFlat = StyleBoxFlat.new()
		stylebox.bg_color = colors[i]
		stylebox.corner_radius_top_left = 4
		stylebox.corner_radius_top_right = 4
		stylebox.corner_radius_bottom_left = 4
		stylebox.corner_radius_bottom_right = 4
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
				instruction_label.text = "CLICK THE MATCHING COLOR!"
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
