extends MiniGameBase

## Pattern Match minigame.
## Two 4x4 grids side by side: target (left) and player (right).
## Click cells on the player grid to toggle them on/off to match the target.
## Race to match 8 patterns.
## Score = number of patterns matched within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var target_grid: GridContainer = %TargetGrid
@onready var player_grid: GridContainer = %PlayerGrid

const COMPLETION_TARGET: int = 8
const GRID_COLS: int = 4
const GRID_ROWS: int = 4
const GRID_SIZE: int = GRID_COLS * GRID_ROWS
const CELL_SIZE: Vector2 = Vector2(60, 60)

const COLOR_ON: Color = Color(0.2, 0.7, 0.9)
const COLOR_OFF: Color = Color(0.25, 0.28, 0.35)

var _score: int = 0
var _target_pattern: Array[bool] = []
var _player_pattern: Array[bool] = []


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
	instruction_label.text = "MATCH THE PATTERN!"
	countdown_label.visible = false
	_generate_round()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_score)


func _generate_round() -> void:
	# Generate a random target pattern with 4-8 cells on
	_target_pattern.clear()
	_player_pattern.clear()
	for i: int in range(GRID_SIZE):
		_target_pattern.append(false)
		_player_pattern.append(false)

	var on_count: int = 4 + randi() % 5  # 4 to 8 cells on
	var indices: Array[int] = []
	for i: int in range(GRID_SIZE):
		indices.append(i)
	indices.shuffle()
	for i: int in range(on_count):
		_target_pattern[indices[i]] = true

	_rebuild_target_grid()
	_rebuild_player_grid()


func _rebuild_target_grid() -> void:
	for child: Node in target_grid.get_children():
		child.queue_free()

	for i: int in range(GRID_SIZE):
		var panel: ColorRect = ColorRect.new()
		panel.custom_minimum_size = CELL_SIZE
		panel.color = COLOR_ON if _target_pattern[i] else COLOR_OFF
		target_grid.add_child(panel)


func _rebuild_player_grid() -> void:
	for child: Node in player_grid.get_children():
		child.queue_free()

	for i: int in range(GRID_SIZE):
		var btn: Button = Button.new()
		btn.custom_minimum_size = CELL_SIZE
		_apply_cell_style(btn, _player_pattern[i])
		var idx: int = i
		btn.pressed.connect(_on_cell_clicked.bind(idx))
		player_grid.add_child(btn)


func _apply_cell_style(btn: Button, is_on: bool) -> void:
	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	stylebox.bg_color = COLOR_ON if is_on else COLOR_OFF
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

	# Toggle the cell
	_player_pattern[index] = not _player_pattern[index]

	# Update just this button's style
	var buttons: Array[Node] = player_grid.get_children()
	if index < buttons.size():
		var btn: Button = buttons[index] as Button
		if btn != null:
			_apply_cell_style(btn, _player_pattern[index])

	# Check if patterns match
	if _patterns_match():
		_score += 1
		_update_score_display()
		if _score >= COMPLETION_TARGET:
			mark_completed(_score)
			return
		_generate_round()


func _patterns_match() -> bool:
	for i: int in range(GRID_SIZE):
		if _target_pattern[i] != _player_pattern[i]:
			return false
	return true


func _update_score_display() -> void:
	score_label.text = "Score: " + str(_score) + " / " + str(COMPLETION_TARGET)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
