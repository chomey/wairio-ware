extends MiniGameBase

## Light Switch minigame.
## A 4x4 grid of lights plus a 4x4 target pattern shown side by side.
## Clicking a light toggles only that light (on/off).
## Match the target pattern to clear the puzzle.
## Race to solve 5 puzzles.
## Score = number of puzzles solved within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var target_grid: GridContainer = %TargetGrid
@onready var player_grid: GridContainer = %PlayerGrid

const COMPLETION_TARGET: int = 5
const GRID_COLS: int = 4
const GRID_ROWS: int = 4
const GRID_SIZE: int = GRID_COLS * GRID_ROWS
const CELL_SIZE: Vector2 = Vector2(60, 60)

const COLOR_OFF: Color = Color(0.15, 0.15, 0.2)
const COLOR_ON: Color = Color(1.0, 0.9, 0.2)
const COLOR_TARGET_OFF: Color = Color(0.2, 0.2, 0.25)
const COLOR_TARGET_ON: Color = Color(0.8, 0.7, 0.15)

var _score: int = 0
var _target: Array[bool] = []
var _player: Array[bool] = []


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	instruction_label.text = "Get ready..."
	_update_score_display()
	target_grid.columns = GRID_COLS
	player_grid.columns = GRID_COLS


func _on_game_start() -> void:
	_score = 0
	_update_score_display()
	instruction_label.text = "CLICK TO MATCH THE TARGET PATTERN!"
	countdown_label.visible = false
	_generate_puzzle()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_score)


func _generate_puzzle() -> void:
	_target.clear()
	_player.clear()

	# Generate random target with 5-10 lit cells
	var lit_count: int = 5 + randi() % 6
	var indices: Array[int] = []
	for i: int in range(GRID_SIZE):
		_target.append(false)
		_player.append(false)
		indices.append(i)
	indices.shuffle()
	for i: int in range(lit_count):
		_target[indices[i]] = true

	_rebuild_target_grid()
	_rebuild_player_grid()


func _rebuild_target_grid() -> void:
	for child: Node in target_grid.get_children():
		child.queue_free()

	for i: int in range(GRID_SIZE):
		var panel: ColorRect = ColorRect.new()
		panel.custom_minimum_size = CELL_SIZE
		if _target[i]:
			panel.color = COLOR_TARGET_ON
		else:
			panel.color = COLOR_TARGET_OFF
		target_grid.add_child(panel)


func _rebuild_player_grid() -> void:
	for child: Node in player_grid.get_children():
		child.queue_free()

	for i: int in range(GRID_SIZE):
		var btn: Button = Button.new()
		btn.custom_minimum_size = CELL_SIZE
		_apply_player_style(btn, i)
		var idx: int = i
		btn.pressed.connect(_on_cell_clicked.bind(idx))
		player_grid.add_child(btn)


func _apply_player_style(btn: Button, index: int) -> void:
	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	if _player[index]:
		stylebox.bg_color = COLOR_ON
	else:
		stylebox.bg_color = COLOR_OFF
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

	_player[index] = not _player[index]
	_update_player_cell_style(index)

	if _check_match():
		_score += 1
		_update_score_display()
		if _score >= COMPLETION_TARGET:
			mark_completed(_score)
			return
		_generate_puzzle()


func _update_player_cell_style(index: int) -> void:
	var buttons: Array[Node] = player_grid.get_children()
	if index < buttons.size():
		var btn: Button = buttons[index] as Button
		if btn != null:
			_apply_player_style(btn, index)


func _check_match() -> bool:
	for i: int in range(GRID_SIZE):
		if _target[i] != _player[i]:
			return false
	return true


func _update_score_display() -> void:
	score_label.text = "Solved: " + str(_score) + " / " + str(COMPLETION_TARGET)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
