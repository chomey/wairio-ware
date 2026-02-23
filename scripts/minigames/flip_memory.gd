extends MiniGameBase

## Flip Memory minigame.
## 5x4 grid of face-down cards with colored number pairs.
## Flip two at a time to find matching pairs.
## Race to find all pairs. Score = pairs found.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var grid_container: GridContainer = %GridContainer

const GRID_COLS: int = 5
const GRID_ROWS: int = 4
const TOTAL_CARDS: int = GRID_COLS * GRID_ROWS
const NUM_PAIRS: int = TOTAL_CARDS / 2  # 10 pairs

## Numbers used on cards (1-10 for 10 pairs)
const CARD_NUMBERS: Array[String] = [
	"1", "2", "3", "4", "5", "6", "7", "8", "9", "10",
]

## Colors for each pair
const PAIR_COLORS: Array[Color] = [
	Color(0.9, 0.2, 0.2),   # Red
	Color(0.2, 0.7, 0.2),   # Green
	Color(0.2, 0.4, 0.9),   # Blue
	Color(0.9, 0.8, 0.1),   # Yellow
	Color(0.8, 0.3, 0.8),   # Purple
	Color(0.1, 0.8, 0.8),   # Cyan
	Color(0.9, 0.5, 0.1),   # Orange
	Color(0.5, 0.3, 0.7),   # Indigo
	Color(0.8, 0.6, 0.7),   # Pink
	Color(0.6, 0.8, 0.3),   # Lime
]

var _score: int = 0
var _card_values: Array[int] = []  # Pair index for each card position
var _card_buttons: Array[Button] = []
var _revealed: Array[bool] = []
var _first_pick: int = -1
var _second_pick: int = -1
var _checking: bool = false
var _check_timer: Timer = null


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	instruction_label.text = "Get ready..."
	_update_score_display()
	grid_container.columns = GRID_COLS

	_check_timer = Timer.new()
	_check_timer.wait_time = 0.6
	_check_timer.one_shot = true
	_check_timer.timeout.connect(_on_check_timeout)
	add_child(_check_timer)


func _on_game_start() -> void:
	_score = 0
	_update_score_display()
	instruction_label.text = "FIND MATCHING PAIRS!"
	countdown_label.visible = false
	_generate_board()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_score)


func _generate_board() -> void:
	# Clear old cards
	for child: Node in grid_container.get_children():
		child.queue_free()
	_card_buttons.clear()
	_card_values.clear()
	_revealed.clear()
	_first_pick = -1
	_second_pick = -1
	_checking = false

	# Create pairs (each pair index appears twice)
	for i: int in range(NUM_PAIRS):
		_card_values.append(i)
		_card_values.append(i)

	# Shuffle card positions (Fisher-Yates)
	for i: int in range(_card_values.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp: int = _card_values[i]
		_card_values[i] = _card_values[j]
		_card_values[j] = tmp

	# Create card buttons
	for i: int in range(TOTAL_CARDS):
		_revealed.append(false)
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(70, 70)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_set_card_face_down(btn)
		var idx: int = i
		btn.pressed.connect(_on_card_clicked.bind(idx))
		grid_container.add_child(btn)
		_card_buttons.append(btn)


func _on_card_clicked(index: int) -> void:
	if not game_active:
		return
	if _checking:
		return
	if _revealed[index]:
		return
	if index == _first_pick:
		return

	if _first_pick == -1:
		_first_pick = index
		_show_card(index)
	elif _second_pick == -1:
		_second_pick = index
		_show_card(index)
		_checking = true
		_check_timer.start()


func _on_check_timeout() -> void:
	if _first_pick < 0 or _second_pick < 0:
		_checking = false
		return

	if _card_values[_first_pick] == _card_values[_second_pick]:
		# Match found
		_revealed[_first_pick] = true
		_revealed[_second_pick] = true
		_set_card_matched(_card_buttons[_first_pick])
		_set_card_matched(_card_buttons[_second_pick])
		_score += 1
		_update_score_display()

		# Check if board is cleared
		var all_matched: bool = true
		for r: bool in _revealed:
			if not r:
				all_matched = false
				break

		if all_matched:
			mark_completed(_score)
			_first_pick = -1
			_second_pick = -1
			_checking = false
			return
	else:
		# No match - flip back
		_set_card_face_down(_card_buttons[_first_pick])
		_set_card_face_down(_card_buttons[_second_pick])

	_first_pick = -1
	_second_pick = -1
	_checking = false


func _show_card(index: int) -> void:
	var btn: Button = _card_buttons[index]
	var pair_idx: int = _card_values[index]
	var bg_color: Color = PAIR_COLORS[pair_idx]

	btn.text = CARD_NUMBERS[pair_idx]
	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	stylebox.bg_color = bg_color
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_left = 6
	stylebox.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", stylebox)
	btn.add_theme_stylebox_override("hover", stylebox)
	btn.add_theme_stylebox_override("pressed", stylebox)
	btn.add_theme_stylebox_override("focus", stylebox)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color.WHITE)


func _set_card_face_down(btn: Button) -> void:
	btn.text = "?"
	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.25, 0.3, 0.4)
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_left = 6
	stylebox.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", stylebox)
	btn.add_theme_stylebox_override("hover", stylebox)
	btn.add_theme_stylebox_override("pressed", stylebox)
	btn.add_theme_stylebox_override("focus", stylebox)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))


func _set_card_matched(btn: Button) -> void:
	btn.text = ""
	btn.disabled = true
	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.15, 0.2, 0.15, 0.4)
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_left = 6
	stylebox.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", stylebox)
	btn.add_theme_stylebox_override("disabled", stylebox)


func _update_score_display() -> void:
	score_label.text = "Pairs: " + str(_score) + " / " + str(NUM_PAIRS)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
