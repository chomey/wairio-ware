extends MiniGameBase

## Spot the Diff minigame.
## Two 5x5 grids shown side-by-side. One cell differs between them.
## Click the differing cell on the right grid.
## Race to find 8 differences.
## Score = number of differences found within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var left_grid: GridContainer = %LeftGrid
@onready var right_grid: GridContainer = %RightGrid

const COMPLETION_TARGET: int = 8
const GRID_COLS: int = 5
const GRID_ROWS: int = 5
const GRID_SIZE: int = GRID_COLS * GRID_ROWS
const CELL_SIZE: Vector2 = Vector2(50, 50)

const COLORS: Array[Color] = [
	Color(0.9, 0.2, 0.2),
	Color(0.2, 0.7, 0.2),
	Color(0.2, 0.4, 0.9),
	Color(0.9, 0.8, 0.2),
	Color(0.7, 0.3, 0.8),
	Color(0.2, 0.8, 0.8),
	Color(0.9, 0.5, 0.2),
]

var _score: int = 0
var _left_colors: Array[Color] = []
var _right_colors: Array[Color] = []
var _diff_index: int = -1


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	instruction_label.text = "Get ready..."
	_update_score_display()
	left_grid.columns = GRID_COLS
	right_grid.columns = GRID_COLS


func _on_game_start() -> void:
	_score = 0
	_update_score_display()
	instruction_label.text = "CLICK THE DIFFERENT CELL!"
	countdown_label.visible = false
	_generate_round()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_score)


func _generate_round() -> void:
	_left_colors.clear()
	_right_colors.clear()

	# Fill both grids with random colors
	for i: int in range(GRID_SIZE):
		var c: Color = COLORS[randi() % COLORS.size()]
		_left_colors.append(c)
		_right_colors.append(c)

	# Pick one cell to differ
	_diff_index = randi() % GRID_SIZE

	# Pick a different color for that cell on the right grid
	var original_color: Color = _left_colors[_diff_index]
	var new_color: Color = original_color
	while new_color == original_color:
		new_color = COLORS[randi() % COLORS.size()]
	_right_colors[_diff_index] = new_color

	_rebuild_left_grid()
	_rebuild_right_grid()


func _rebuild_left_grid() -> void:
	for child: Node in left_grid.get_children():
		child.queue_free()

	for i: int in range(GRID_SIZE):
		var panel: ColorRect = ColorRect.new()
		panel.custom_minimum_size = CELL_SIZE
		panel.color = _left_colors[i]
		left_grid.add_child(panel)


func _rebuild_right_grid() -> void:
	for child: Node in right_grid.get_children():
		child.queue_free()

	for i: int in range(GRID_SIZE):
		var btn: Button = Button.new()
		btn.custom_minimum_size = CELL_SIZE
		var stylebox: StyleBoxFlat = StyleBoxFlat.new()
		stylebox.bg_color = _right_colors[i]
		stylebox.corner_radius_top_left = 2
		stylebox.corner_radius_top_right = 2
		stylebox.corner_radius_bottom_left = 2
		stylebox.corner_radius_bottom_right = 2
		btn.add_theme_stylebox_override("normal", stylebox)
		btn.add_theme_stylebox_override("hover", stylebox)
		btn.add_theme_stylebox_override("pressed", stylebox)
		btn.add_theme_stylebox_override("focus", stylebox)
		var idx: int = i
		btn.pressed.connect(_on_cell_clicked.bind(idx))
		right_grid.add_child(btn)


func _on_cell_clicked(index: int) -> void:
	if not game_active:
		return

	if index == _diff_index:
		_score += 1
		_update_score_display()
		if _score >= COMPLETION_TARGET:
			mark_completed(_score)
			return
		_generate_round()
	else:
		instruction_label.text = "WRONG! Try again..."
		# Brief feedback then reset text
		var timer: SceneTreeTimer = get_tree().create_timer(0.5)
		timer.timeout.connect(func() -> void:
			if game_active:
				instruction_label.text = "CLICK THE DIFFERENT CELL!"
		)


func _update_score_display() -> void:
	score_label.text = "Found: " + str(_score) + " / " + str(COMPLETION_TARGET)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
