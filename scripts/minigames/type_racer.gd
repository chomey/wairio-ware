extends MiniGameBase

## Type Racer minigame.
## Type displayed words exactly as fast as possible.
## Score = number of correct words typed. Race to 8.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var word_label: Label = %WordLabel
@onready var type_input: LineEdit = %TypeInput
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel

const COMPLETION_TARGET: int = 8

var _correct_count: int = 0
var _current_word: String = ""

const WORD_LIST: Array[String] = [
	"apple", "bridge", "castle", "dragon", "engine", "forest", "garden",
	"hammer", "island", "jungle", "knight", "lemon", "mirror", "nectar",
	"orange", "planet", "quartz", "rocket", "silver", "temple", "ultra",
	"violet", "wonder", "yellow", "zipper", "anchor", "basket", "circle",
	"desert", "falcon", "guitar", "harbor", "insect", "jigsaw", "kernel",
	"laptop", "marble", "needle", "oyster", "pepper", "rabbit", "saddle",
	"timber", "umbrella", "vacuum", "walrus", "cobalt", "frozen", "global",
	"helium", "magnet", "nimble", "pirate", "riddle", "summit", "turtle",
]


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	type_input.text_submitted.connect(_on_text_submitted)
	word_label.text = ""
	feedback_label.text = ""
	score_label.text = "Words: 0 / " + str(COMPLETION_TARGET)
	type_input.editable = false
	type_input.placeholder_text = "Type the word + Enter"


func _on_game_start() -> void:
	countdown_label.visible = false
	_correct_count = 0
	score_label.text = "Words: 0 / " + str(COMPLETION_TARGET)
	type_input.editable = true
	type_input.grab_focus()
	_pick_word()


func _on_game_end() -> void:
	type_input.editable = false
	feedback_label.text = "Time's up! You typed " + str(_correct_count) + " words!"
	submit_score(_correct_count)


func _pick_word() -> void:
	_current_word = WORD_LIST[randi_range(0, WORD_LIST.size() - 1)]
	word_label.text = _current_word
	type_input.text = ""
	type_input.grab_focus()


func _on_text_submitted(text: String) -> void:
	if not game_active:
		return

	var stripped: String = text.strip_edges()
	if stripped.is_empty():
		return

	if stripped == _current_word:
		_correct_count += 1
		feedback_label.text = "Correct!"
		score_label.text = "Words: " + str(_correct_count) + " / " + str(COMPLETION_TARGET)
		if _correct_count >= COMPLETION_TARGET:
			mark_completed(_correct_count)
			return
	else:
		feedback_label.text = "Wrong! It was: " + _current_word

	_pick_word()


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
