extends MiniGameBase

## Color Match minigame (Stroop test).
## A color word is displayed in a random color. Press "Match" if the word
## matches the displayed color, or "No Match" if it doesn't.
## Score = number of correct answers within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var color_word_label: Label = %ColorWordLabel
@onready var match_button: Button = %MatchButton
@onready var no_match_button: Button = %NoMatchButton

const COMPLETION_TARGET: int = 12

var _score: int = 0
var _current_is_match: bool = false

const COLOR_MAP: Dictionary = {
	"RED": Color(1, 0, 0),
	"GREEN": Color(0, 1, 0),
	"BLUE": Color(0.2, 0.4, 1),
	"YELLOW": Color(1, 1, 0),
	"PURPLE": Color(0.7, 0, 1),
}

var _color_names: Array[String] = []


func _ready() -> void:
	super._ready()
	_color_names.clear()
	for key: String in COLOR_MAP:
		_color_names.append(key)
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	match_button.pressed.connect(_on_match_pressed)
	no_match_button.pressed.connect(_on_no_match_pressed)
	match_button.visible = false
	no_match_button.visible = false
	color_word_label.visible = false
	_update_score_display()
	instruction_label.text = "Get ready..."


func _on_game_start() -> void:
	_score = 0
	_update_score_display()
	instruction_label.text = "Does the WORD match the COLOR?"
	countdown_label.visible = false
	match_button.visible = true
	no_match_button.visible = true
	color_word_label.visible = true
	_show_next_prompt()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	match_button.visible = false
	no_match_button.visible = false
	color_word_label.visible = false
	submit_score(_score)


func _on_match_pressed() -> void:
	if not game_active:
		return
	if _current_is_match:
		_score += 1
	_update_score_display()
	if _score >= COMPLETION_TARGET:
		mark_completed(_score)
		return
	_show_next_prompt()


func _on_no_match_pressed() -> void:
	if not game_active:
		return
	if not _current_is_match:
		_score += 1
	_update_score_display()
	if _score >= COMPLETION_TARGET:
		mark_completed(_score)
		return
	_show_next_prompt()


func _show_next_prompt() -> void:
	var word_index: int = randi() % _color_names.size()
	var color_index: int = randi() % _color_names.size()

	# 50% chance of matching
	if randf() < 0.5:
		color_index = word_index
		_current_is_match = true
	else:
		# Ensure mismatch
		while color_index == word_index:
			color_index = randi() % _color_names.size()
		_current_is_match = false

	var word_name: String = _color_names[word_index]
	var display_color: Color = COLOR_MAP[_color_names[color_index]]
	color_word_label.text = word_name
	color_word_label.add_theme_color_override("font_color", display_color)


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
