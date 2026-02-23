extends MiniGameBase

## Signal Flag minigame.
## A flag pattern of colored squares is displayed.
## Player selects the matching flag name from 4 choices.
## Race to 10 correct identifications.
## Score = number of correct identifications within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var flag_grid: GridContainer = %FlagGrid
@onready var choices_container: VBoxContainer = %ChoicesContainer

const COMPLETION_TARGET: int = 10
const GRID_SIZE: int = 4
const CELL_SIZE: Vector2 = Vector2(40, 40)
const NUM_CHOICES: int = 4

## Each flag is defined as a name and a 4x4 grid of color indices.
## Colors: 0=Red, 1=White, 2=Blue, 3=Yellow, 4=Black, 5=Green
const FLAG_COLORS: Array[Color] = [
	Color(0.9, 0.1, 0.1),   # 0 Red
	Color(1.0, 1.0, 1.0),   # 1 White
	Color(0.1, 0.2, 0.8),   # 2 Blue
	Color(0.95, 0.85, 0.1), # 3 Yellow
	Color(0.1, 0.1, 0.1),   # 4 Black
	Color(0.1, 0.7, 0.2),   # 5 Green
]

## Flag definitions: [name, [16 color indices for 4x4 grid]]
var FLAG_DATA: Array[Array] = [
	["Alpha", [1, 2, 1, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1]],
	["Bravo", [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]],
	["Charlie", [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 0, 0, 0, 0]],
	["Delta", [2, 3, 3, 2, 2, 3, 3, 2, 2, 3, 3, 2, 2, 3, 3, 2]],
	["Echo", [2, 2, 2, 2, 0, 0, 0, 0, 2, 2, 2, 2, 0, 0, 0, 0]],
	["Foxtrot", [1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1]],
	["Golf", [3, 3, 3, 3, 3, 2, 2, 3, 3, 2, 2, 3, 3, 3, 3, 3]],
	["Hotel", [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]],
	["India", [3, 3, 3, 3, 3, 4, 4, 3, 3, 4, 4, 3, 3, 3, 3, 3]],
	["Juliet", [2, 2, 2, 2, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2]],
	["Kilo", [3, 2, 3, 2, 2, 3, 2, 3, 3, 2, 3, 2, 2, 3, 2, 3]],
	["Lima", [3, 3, 4, 4, 3, 3, 4, 4, 4, 4, 3, 3, 4, 4, 3, 3]],
	["Mike", [2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1]],
	["November", [2, 2, 1, 1, 2, 2, 1, 1, 1, 1, 2, 2, 1, 1, 2, 2]],
	["Oscar", [0, 0, 0, 0, 0, 3, 3, 0, 0, 3, 3, 0, 0, 0, 0, 0]],
	["Papa", [2, 2, 2, 2, 2, 1, 1, 2, 2, 1, 1, 2, 2, 2, 2, 2]],
	["Quebec", [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]],
	["Romeo", [0, 0, 3, 3, 0, 0, 3, 3, 3, 3, 0, 0, 3, 3, 0, 0]],
	["Sierra", [1, 1, 1, 1, 1, 2, 2, 1, 1, 2, 2, 1, 1, 1, 1, 1]],
	["Tango", [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1]],
	["Uniform", [0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0]],
	["Victor", [1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 1]],
	["Whiskey", [2, 1, 2, 1, 1, 0, 1, 0, 2, 1, 2, 1, 0, 0, 0, 0]],
	["X-ray", [1, 2, 2, 1, 2, 1, 1, 2, 2, 1, 1, 2, 1, 2, 2, 1]],
	["Yankee", [0, 0, 3, 3, 0, 0, 3, 3, 0, 0, 3, 3, 0, 0, 3, 3]],
	["Zulu", [0, 3, 0, 3, 4, 0, 3, 0, 0, 3, 0, 3, 3, 0, 3, 0]],
]

var _score: int = 0
var _correct_name: String = ""
var _used_indices: Array[int] = []


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
	_used_indices.clear()
	_update_score_display()
	instruction_label.text = "SELECT THE FLAG NAME!"
	countdown_label.visible = false
	_generate_round()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_score)


func _generate_round() -> void:
	# Pick a flag not yet used
	var available: Array[int] = []
	for i: int in range(FLAG_DATA.size()):
		if not _used_indices.has(i):
			available.append(i)
	if available.is_empty():
		_used_indices.clear()
		for i: int in range(FLAG_DATA.size()):
			available.append(i)

	var target_idx: int = available[randi() % available.size()]
	_used_indices.append(target_idx)
	var target_flag: Array = FLAG_DATA[target_idx]
	_correct_name = target_flag[0] as String
	var grid_data: Array = target_flag[1] as Array

	# Draw the flag grid
	_rebuild_flag(grid_data)

	# Build choices: correct + 3 distractors
	var choice_names: Array[String] = [_correct_name]
	var distractor_pool: Array[int] = []
	for i: int in range(FLAG_DATA.size()):
		if i != target_idx:
			distractor_pool.append(i)
	distractor_pool.shuffle()
	for i: int in range(mini(3, distractor_pool.size())):
		choice_names.append(FLAG_DATA[distractor_pool[i]][0] as String)

	choice_names.shuffle()
	_rebuild_choices(choice_names)


func _rebuild_flag(grid_data: Array) -> void:
	for child: Node in flag_grid.get_children():
		child.queue_free()

	flag_grid.columns = GRID_SIZE
	for i: int in range(grid_data.size()):
		var cell: ColorRect = ColorRect.new()
		cell.custom_minimum_size = CELL_SIZE
		var color_idx: int = grid_data[i] as int
		if color_idx >= 0 and color_idx < FLAG_COLORS.size():
			cell.color = FLAG_COLORS[color_idx]
		else:
			cell.color = Color.GRAY
		flag_grid.add_child(cell)


func _rebuild_choices(names: Array[String]) -> void:
	for child: Node in choices_container.get_children():
		child.queue_free()

	for i: int in range(names.size()):
		var btn: Button = Button.new()
		btn.text = names[i]
		btn.custom_minimum_size = Vector2(200, 40)
		var name_val: String = names[i]
		btn.pressed.connect(_on_choice_clicked.bind(name_val))
		choices_container.add_child(btn)


func _on_choice_clicked(chosen_name: String) -> void:
	if not game_active:
		return

	if chosen_name == _correct_name:
		_score += 1
		_update_score_display()
		if _score >= COMPLETION_TARGET:
			mark_completed(_score)
			return
		_generate_round()
	else:
		instruction_label.text = "WRONG! It was " + _correct_name
		var timer: SceneTreeTimer = get_tree().create_timer(0.5)
		timer.timeout.connect(func() -> void:
			if game_active:
				instruction_label.text = "SELECT THE FLAG NAME!"
		)


func _update_score_display() -> void:
	score_label.text = "Identified: " + str(_score) + " / " + str(COMPLETION_TARGET)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
