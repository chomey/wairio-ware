extends MiniGameBase

## Target Click minigame.
## Click on targets that appear at random positions.
## Score = number of targets clicked within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var target_area: Control = %TargetArea
@onready var target_button: Button = %TargetButton

const COMPLETION_TARGET: int = 15

var _score: int = 0

const TARGET_SIZE: Vector2 = Vector2(60, 60)


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	target_button.pressed.connect(_on_target_clicked)
	target_button.visible = false
	_update_score_display()
	instruction_label.text = "Get ready..."


func _on_game_start() -> void:
	_score = 0
	_update_score_display()
	instruction_label.text = "CLICK THE TARGETS!"
	countdown_label.visible = false
	_spawn_target()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	target_button.visible = false
	submit_score(_score)


func _on_target_clicked() -> void:
	if not game_active:
		return
	_score += 1
	_update_score_display()
	if _score >= COMPLETION_TARGET:
		target_button.visible = false
		mark_completed(_score)
		return
	_spawn_target()


func _spawn_target() -> void:
	target_button.visible = true
	var area_size: Vector2 = target_area.size
	var max_x: float = maxf(0.0, area_size.x - TARGET_SIZE.x)
	var max_y: float = maxf(0.0, area_size.y - TARGET_SIZE.y)
	var new_pos: Vector2 = Vector2(
		randf() * max_x,
		randf() * max_y
	)
	target_button.position = new_pos


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
