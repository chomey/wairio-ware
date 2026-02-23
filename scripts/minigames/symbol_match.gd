extends MiniGameBase

## Symbol Match minigame.
## Grid of symbols displayed face-up. Find and click matching pairs.
## Race to clear 8 pairs. Score = pairs cleared.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var grid_container: GridContainer = %GridContainer

const GRID_COLS: int = 4
const GRID_ROWS: int = 4
const TOTAL_CARDS: int = GRID_COLS * GRID_ROWS  # 16
const NUM_PAIRS: int = TOTAL_CARDS / 2  # 8
const TARGET_PAIRS: int = 8

## Symbols used on cards
const SYMBOLS: Array[String] = [
	"@", "#", "$", "%", "&", "*", "+", "=",
]

## Colors for each symbol pair
const SYMBOL_COLORS: Array[Color] = [
	Color(0.9, 0.2, 0.2),   # Red
	Color(0.2, 0.7, 0.2),   # Green
	Color(0.2, 0.4, 0.9),   # Blue
	Color(0.9, 0.8, 0.1),   # Yellow
	Color(0.8, 0.3, 0.8),   # Purple
	Color(0.1, 0.8, 0.8),   # Cyan
	Color(0.9, 0.5, 0.1),   # Orange
	Color(0.5, 0.3, 0.7),   # Indigo
]

var _score: int = 0
var _card_values: Array[int] = []  # Pair index for each card position
var _card_buttons: Array[Button] = []
var _matched: Array[bool] = []
var _first_pick: int = -1
var _error_timer: Timer = null


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	instruction_label.text = "Get ready..."
	_update_score_display()
	grid_container.columns = GRID_COLS

	_error_timer = Timer.new()
	_error_timer.wait_time = 0.4
	_error_timer.one_shot = true
	_error_timer.timeout.connect(_on_error_timeout)
	add_child(_error_timer)


func _on_game_start() -> void:
	_score = 0
	_update_score_display()
	instruction_label.text = "CLICK MATCHING SYMBOL PAIRS!"
	countdown_label.visible = false
	_generate_board()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_score)


func _generate_board() -> void:
	for child: Node in grid_container.get_children():
		child.queue_free()
	_card_buttons.clear()
	_card_values.clear()
	_matched.clear()
	_first_pick = -1

	# Create pairs (each pair index appears twice)
	for i: int in range(NUM_PAIRS):
		_card_values.append(i)
		_card_values.append(i)

	# Fisher-Yates shuffle
	for i: int in range(_card_values.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp: int = _card_values[i]
		_card_values[i] = _card_values[j]
		_card_values[j] = tmp

	# Create card buttons - symbols visible from the start
	for i: int in range(TOTAL_CARDS):
		_matched.append(false)
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var idx: int = i
		btn.pressed.connect(_on_card_clicked.bind(idx))
		grid_container.add_child(btn)
		_card_buttons.append(btn)
		_style_card_normal(btn, _card_values[i])


func _on_card_clicked(index: int) -> void:
	if not game_active:
		return
	if _matched[index]:
		return
	if _error_timer.time_left > 0.0:
		return

	if _first_pick == -1:
		# First selection
		_first_pick = index
		_style_card_selected(_card_buttons[index], _card_values[index])
	elif index == _first_pick:
		# Clicked same card - deselect
		_first_pick = -1
		_style_card_normal(_card_buttons[index], _card_values[index])
	else:
		# Second selection - check match
		if _card_values[_first_pick] == _card_values[index]:
			# Match found
			_matched[_first_pick] = true
			_matched[index] = true
			_style_card_matched(_card_buttons[_first_pick])
			_style_card_matched(_card_buttons[index])
			_score += 1
			_update_score_display()
			_first_pick = -1

			if _score >= TARGET_PAIRS:
				mark_completed(_score)
		else:
			# No match - flash error briefly
			_style_card_error(_card_buttons[_first_pick], _card_values[_first_pick])
			_style_card_error(_card_buttons[index], _card_values[index])
			_error_timer.start()
			_first_pick = -1


func _on_error_timeout() -> void:
	# Reset error cards to normal
	for i: int in range(TOTAL_CARDS):
		if not _matched[i]:
			_style_card_normal(_card_buttons[i], _card_values[i])


func _style_card_normal(btn: Button, pair_idx: int) -> void:
	var col: Color = SYMBOL_COLORS[pair_idx]
	btn.text = SYMBOLS[pair_idx]
	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.22, 0.3)
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_left = 6
	stylebox.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", stylebox)
	btn.add_theme_stylebox_override("hover", stylebox)
	btn.add_theme_stylebox_override("pressed", stylebox)
	btn.add_theme_stylebox_override("focus", stylebox)
	btn.add_theme_font_size_override("font_size", 32)
	btn.add_theme_color_override("font_color", col)
	btn.disabled = false


func _style_card_selected(btn: Button, pair_idx: int) -> void:
	var col: Color = SYMBOL_COLORS[pair_idx]
	btn.text = SYMBOLS[pair_idx]
	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.35, 0.38, 0.5)
	stylebox.border_width_left = 3
	stylebox.border_width_top = 3
	stylebox.border_width_right = 3
	stylebox.border_width_bottom = 3
	stylebox.border_color = col
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_left = 6
	stylebox.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", stylebox)
	btn.add_theme_stylebox_override("hover", stylebox)
	btn.add_theme_stylebox_override("pressed", stylebox)
	btn.add_theme_stylebox_override("focus", stylebox)
	btn.add_theme_font_size_override("font_size", 32)
	btn.add_theme_color_override("font_color", Color.WHITE)


func _style_card_error(btn: Button, pair_idx: int) -> void:
	btn.text = SYMBOLS[pair_idx]
	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.5, 0.15, 0.15)
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_left = 6
	stylebox.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", stylebox)
	btn.add_theme_stylebox_override("hover", stylebox)
	btn.add_theme_stylebox_override("pressed", stylebox)
	btn.add_theme_stylebox_override("focus", stylebox)
	btn.add_theme_font_size_override("font_size", 32)
	btn.add_theme_color_override("font_color", SYMBOL_COLORS[pair_idx])


func _style_card_matched(btn: Button) -> void:
	btn.text = ""
	btn.disabled = true
	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.15, 0.25, 0.15, 0.4)
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_left = 6
	stylebox.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", stylebox)
	btn.add_theme_stylebox_override("disabled", stylebox)


func _update_score_display() -> void:
	score_label.text = "Pairs: " + str(_score) + " / " + str(TARGET_PAIRS)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
