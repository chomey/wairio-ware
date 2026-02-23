extends MiniGameBase

## Word Chain minigame.
## Given a word, type a word starting with its last letter.
## Score = number of chains completed. Race to 8.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var current_word_label: Label = %CurrentWordLabel
@onready var hint_label: Label = %HintLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var input_field: LineEdit = %InputField

const COMPLETION_TARGET: int = 8

var _chain_count: int = 0
var _current_word: String = ""
var _required_letter: String = ""
var _used_words: Dictionary = {}

const WORD_LIST: Array[String] = [
	"apple", "eagle", "earth", "horse", "ember", "robot", "tiger", "river",
	"melon", "night", "train", "noble", "elbow", "water", "rider", "round",
	"dance", "eager", "ranch", "house", "enter", "reign", "never", "reach",
	"honey", "yield", "dream", "metal", "lemon", "north", "heart", "tower",
	"robin", "nerve", "elite", "every", "youth", "happy", "young", "grain",
	"noise", "equal", "lodge", "event", "table", "empty", "yeast", "trace",
	"error", "royal", "level", "laser", "right", "trend", "drill", "label",
	"lunar", "rally", "yacht", "tulip", "piano", "ocean", "nurse", "extra",
	"anger", "ridge", "ember", "radio", "olive", "orbit", "thorn", "novel",
	"light", "tangy", "yield", "donor", "rough", "haste", "elbow", "wagon",
	"nylon", "nexus", "steel", "lucky", "yearn", "arrow", "waltz", "zebra",
	"arena", "after", "blaze", "crane", "dodge", "flame", "grape", "ivory",
	"joker", "knife", "maple", "ozone", "pearl", "quiet", "stone", "unite",
	"value", "wheat", "adapt", "blend", "charm", "dusty", "frost", "gleam",
	"haven", "jolly", "kneel", "minor", "pride", "quest", "swift", "ultra",
]

## Words indexed by first letter for quick lookup
var _words_by_letter: Dictionary = {}


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	input_field.text_submitted.connect(_on_input_submitted)
	score_label.text = "Chains: 0 / " + str(COMPLETION_TARGET)
	feedback_label.text = ""
	hint_label.text = ""
	current_word_label.text = ""
	input_field.editable = false
	_build_word_index()


func _build_word_index() -> void:
	for word: String in WORD_LIST:
		var first: String = word[0].to_lower()
		if not _words_by_letter.has(first):
			_words_by_letter[first] = []
		var list: Array = _words_by_letter[first] as Array
		# Avoid duplicates
		if not list.has(word):
			list.append(word)


func _on_game_start() -> void:
	countdown_label.visible = false
	_chain_count = 0
	_used_words.clear()
	score_label.text = "Chains: 0 / " + str(COMPLETION_TARGET)
	feedback_label.text = ""
	input_field.editable = true
	input_field.text = ""
	input_field.grab_focus()
	_pick_starting_word()


func _on_game_end() -> void:
	input_field.editable = false
	feedback_label.text = "Time's up! Chains: " + str(_chain_count)
	submit_score(_chain_count)


func _pick_starting_word() -> void:
	var available: Array[String] = []
	for word: String in WORD_LIST:
		if not _used_words.has(word):
			available.append(word)
	if available.is_empty():
		_used_words.clear()
		available = WORD_LIST.duplicate()
	var word: String = available[randi_range(0, available.size() - 1)]
	_set_current_word(word)


func _set_current_word(word: String) -> void:
	_current_word = word
	_used_words[word] = true
	_required_letter = word[word.length() - 1].to_lower()
	current_word_label.text = _current_word.to_upper()
	hint_label.text = "Type a word starting with '" + _required_letter.to_upper() + "'"
	input_field.text = ""
	input_field.grab_focus()


func _on_input_submitted(text: String) -> void:
	if not game_active:
		return

	var answer: String = text.strip_edges().to_lower()
	if answer.length() < 2:
		feedback_label.text = "Too short! At least 2 letters."
		input_field.text = ""
		input_field.grab_focus()
		return

	if answer[0] != _required_letter:
		feedback_label.text = "Must start with '" + _required_letter.to_upper() + "'!"
		input_field.text = ""
		input_field.grab_focus()
		return

	# Check if the word is in our word list
	if not _words_by_letter.has(answer[0]):
		feedback_label.text = "Unknown word! Try another."
		input_field.text = ""
		input_field.grab_focus()
		return

	var list: Array = _words_by_letter[answer[0]] as Array
	if not list.has(answer):
		feedback_label.text = "Unknown word! Try another."
		input_field.text = ""
		input_field.grab_focus()
		return

	if _used_words.has(answer):
		feedback_label.text = "Already used! Try another."
		input_field.text = ""
		input_field.grab_focus()
		return

	# Valid chain!
	_chain_count += 1
	score_label.text = "Chains: " + str(_chain_count) + " / " + str(COMPLETION_TARGET)
	feedback_label.text = "Correct! " + answer.to_upper()

	if _chain_count >= COMPLETION_TARGET:
		mark_completed(_chain_count)
		return

	# The player's word becomes the new current word
	_set_current_word(answer)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
