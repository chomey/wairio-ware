extends MiniGameBase

## Word Scramble minigame.
## Unscramble anagram words, type the correct word and press Enter.
## Race to 5 correct words. Score = number of correct words.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var scramble_label: Label = %ScrambleLabel
@onready var answer_input: LineEdit = %AnswerInput
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel

const COMPLETION_TARGET: int = 5

const WORD_LIST: Array[String] = [
	"apple", "brain", "chair", "dance", "eagle",
	"flame", "grape", "house", "ivory", "juice",
	"knife", "lemon", "mouse", "night", "ocean",
	"piano", "queen", "river", "snake", "tiger",
	"under", "voice", "water", "yield", "zebra",
	"beach", "clock", "dream", "earth", "frost",
	"ghost", "heart", "joint", "light", "medal",
	"nerve", "orbit", "plant", "reign", "stone",
	"train", "unity", "valid", "wheat", "blank",
	"charm", "drift", "flock", "glove", "haste",
]

var _current_word: String = ""
var _correct_count: int = 0
var _used_words: Array[String] = []


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	answer_input.text_submitted.connect(_on_answer_submitted)
	scramble_label.text = ""
	feedback_label.text = ""
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)
	answer_input.editable = false
	answer_input.placeholder_text = "Type the word + Enter"


func _on_game_start() -> void:
	countdown_label.visible = false
	_correct_count = 0
	_used_words.clear()
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)
	answer_input.editable = true
	answer_input.grab_focus()
	_generate_scramble()


func _on_game_end() -> void:
	answer_input.editable = false
	feedback_label.text = "Time's up! You got " + str(_correct_count) + " correct!"
	submit_score(_correct_count)


func _generate_scramble() -> void:
	# Pick a word we haven't used yet
	var available: Array[String] = []
	for w: String in WORD_LIST:
		if w not in _used_words:
			available.append(w)
	if available.is_empty():
		_used_words.clear()
		for w: String in WORD_LIST:
			available.append(w)

	_current_word = available[randi_range(0, available.size() - 1)]
	_used_words.append(_current_word)

	# Scramble the word (ensure it's different from original)
	var scrambled: String = _scramble_word(_current_word)
	scramble_label.text = scrambled.to_upper()
	answer_input.text = ""
	answer_input.grab_focus()
	feedback_label.text = ""


func _scramble_word(word: String) -> String:
	var chars: Array[String] = []
	for i: int in range(word.length()):
		chars.append(word[i])

	# Shuffle until different from original (max 20 attempts)
	for _attempt: int in range(20):
		# Fisher-Yates shuffle
		for i: int in range(chars.size() - 1, 0, -1):
			var j: int = randi_range(0, i)
			var tmp: String = chars[i]
			chars[i] = chars[j]
			chars[j] = tmp
		var result: String = "".join(chars)
		if result != word:
			return result

	# Fallback: reverse the word
	var reversed: String = ""
	for i: int in range(word.length() - 1, -1, -1):
		reversed += word[i]
	return reversed


func _on_answer_submitted(text: String) -> void:
	if not game_active:
		return

	var stripped: String = text.strip_edges().to_lower()
	if stripped.is_empty():
		return

	if stripped == _current_word:
		_correct_count += 1
		feedback_label.text = "Correct!"
		score_label.text = "Correct: " + str(_correct_count) + " / " + str(COMPLETION_TARGET)
		if _correct_count >= COMPLETION_TARGET:
			mark_completed(_correct_count)
			return
	else:
		feedback_label.text = "Wrong! It was: " + _current_word.to_upper()

	_generate_scramble()


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
