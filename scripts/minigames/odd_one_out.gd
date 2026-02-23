extends MiniGameBase

## Odd One Out minigame.
## A grid of colored rectangles where all but one are the same color.
## Click the different one to score. Race to 10 rounds.
## Score = number of correct clicks within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var grid_container: GridContainer = %GridContainer

const COMPLETION_TARGET: int = 10
const GRID_SIZE: int = 16  # 4x4 grid

var _score: int = 0
var _odd_index: int = -1

## Pool of colors to pick from
const COLORS: Array[Color] = [
	Color(0.9, 0.2, 0.2),   # Red
	Color(0.2, 0.7, 0.2),   # Green
	Color(0.2, 0.4, 0.9),   # Blue
	Color(0.9, 0.8, 0.1),   # Yellow
	Color(0.8, 0.3, 0.8),   # Purple
	Color(0.1, 0.8, 0.8),   # Cyan
	Color(0.9, 0.5, 0.1),   # Orange
]


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	instruction_label.text = "Get ready..."
	_update_score_display()
	grid_container.columns = 4


func _on_game_start() -> void:
	_score = 0
	_update_score_display()
	instruction_label.text = "CLICK THE DIFFERENT ONE!"
	countdown_label.visible = false
	_generate_round()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_score)


func _generate_round() -> void:
	# Clear old cells
	for child: Node in grid_container.get_children():
		child.queue_free()

	# Pick two distinct colors
	var main_color_idx: int = randi() % COLORS.size()
	var odd_color_idx: int = (main_color_idx + 1 + randi() % (COLORS.size() - 1)) % COLORS.size()
	var main_color: Color = COLORS[main_color_idx]
	var odd_color: Color = COLORS[odd_color_idx]

	# Pick which cell is the odd one
	_odd_index = randi() % GRID_SIZE

	for i: int in range(GRID_SIZE):
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL

		var color: Color = odd_color if i == _odd_index else main_color
		var stylebox: StyleBoxFlat = StyleBoxFlat.new()
		stylebox.bg_color = color
		stylebox.corner_radius_top_left = 4
		stylebox.corner_radius_top_right = 4
		stylebox.corner_radius_bottom_left = 4
		stylebox.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("normal", stylebox)
		btn.add_theme_stylebox_override("hover", stylebox)
		btn.add_theme_stylebox_override("pressed", stylebox)
		btn.add_theme_stylebox_override("focus", stylebox)

		var idx: int = i
		btn.pressed.connect(_on_cell_clicked.bind(idx))
		grid_container.add_child(btn)


func _on_cell_clicked(index: int) -> void:
	if not game_active:
		return
	if index == _odd_index:
		_score += 1
		_update_score_display()
		if _score >= COMPLETION_TARGET:
			mark_completed(_score)
			return
		_generate_round()


func _update_score_display() -> void:
	score_label.text = "Score: " + str(_score)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
