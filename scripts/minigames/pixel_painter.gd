extends MiniGameBase

## Pixel Painter minigame.
## A 6x6 grid with some cells marked as targets.
## Click the marked cells to fill them in.
## Each completed pattern generates a new one.
## Race to fill 20 cells total.
## Score = number of cells filled within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var paint_grid: GridContainer = %PaintGrid

const COMPLETION_TARGET: int = 20
const GRID_COLS: int = 6
const GRID_ROWS: int = 6
const GRID_SIZE: int = GRID_COLS * GRID_ROWS
const CELL_SIZE: Vector2 = Vector2(55, 55)

const COLOR_EMPTY: Color = Color(0.2, 0.22, 0.28)
const COLOR_TARGET: Color = Color(0.9, 0.6, 0.2, 0.5)
const COLOR_FILLED: Color = Color(0.2, 0.8, 0.4)

var _score: int = 0
var _target_cells: Array[bool] = []
var _filled_cells: Array[bool] = []
var _remaining_in_pattern: int = 0


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	instruction_label.text = "Get ready..."
	_update_score_display()
	paint_grid.columns = GRID_COLS


func _on_game_start() -> void:
	_score = 0
	_update_score_display()
	instruction_label.text = "CLICK THE MARKED CELLS!"
	countdown_label.visible = false
	_generate_pattern()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_score)


func _generate_pattern() -> void:
	_target_cells.clear()
	_filled_cells.clear()
	for i: int in range(GRID_SIZE):
		_target_cells.append(false)
		_filled_cells.append(false)

	# Mark 4-6 random cells as targets
	var target_count: int = 4 + randi() % 3
	var indices: Array[int] = []
	for i: int in range(GRID_SIZE):
		indices.append(i)
	indices.shuffle()
	for i: int in range(target_count):
		_target_cells[indices[i]] = true
	_remaining_in_pattern = target_count

	_rebuild_grid()


func _rebuild_grid() -> void:
	for child: Node in paint_grid.get_children():
		child.queue_free()

	for i: int in range(GRID_SIZE):
		var btn: Button = Button.new()
		btn.custom_minimum_size = CELL_SIZE
		_apply_cell_style(btn, i)
		var idx: int = i
		btn.pressed.connect(_on_cell_clicked.bind(idx))
		paint_grid.add_child(btn)


func _apply_cell_style(btn: Button, index: int) -> void:
	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	if _filled_cells[index]:
		stylebox.bg_color = COLOR_FILLED
	elif _target_cells[index]:
		stylebox.bg_color = COLOR_TARGET
	else:
		stylebox.bg_color = COLOR_EMPTY
	stylebox.corner_radius_top_left = 4
	stylebox.corner_radius_top_right = 4
	stylebox.corner_radius_bottom_left = 4
	stylebox.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", stylebox)
	btn.add_theme_stylebox_override("hover", stylebox)
	btn.add_theme_stylebox_override("pressed", stylebox)
	btn.add_theme_stylebox_override("focus", stylebox)


func _on_cell_clicked(index: int) -> void:
	if not game_active:
		return
	if not _target_cells[index]:
		return
	if _filled_cells[index]:
		return

	_filled_cells[index] = true
	_remaining_in_pattern -= 1
	_score += 1
	_update_score_display()

	# Update just this button's style
	var buttons: Array[Node] = paint_grid.get_children()
	if index < buttons.size():
		var btn: Button = buttons[index] as Button
		if btn != null:
			_apply_cell_style(btn, index)

	if _score >= COMPLETION_TARGET:
		mark_completed(_score)
		return

	if _remaining_in_pattern <= 0:
		_generate_pattern()


func _update_score_display() -> void:
	score_label.text = "Filled: " + str(_score) + " / " + str(COMPLETION_TARGET)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
