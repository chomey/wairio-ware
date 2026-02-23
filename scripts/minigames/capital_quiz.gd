extends MiniGameBase

## Capital Quiz minigame.
## Country name shown, type its capital city.
## Race to 8 correct. Score = number of correct answers.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var country_label: Label = %CountryLabel
@onready var answer_input: LineEdit = %AnswerInput
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel

const COMPLETION_TARGET: int = 8

## Country -> Capital pairs (well-known capitals only)
const CAPITALS: Dictionary = {
	"France": "Paris",
	"Germany": "Berlin",
	"Japan": "Tokyo",
	"Italy": "Rome",
	"Spain": "Madrid",
	"Canada": "Ottawa",
	"Australia": "Canberra",
	"Brazil": "Brasilia",
	"Egypt": "Cairo",
	"India": "New Delhi",
	"China": "Beijing",
	"Russia": "Moscow",
	"Mexico": "Mexico City",
	"Argentina": "Buenos Aires",
	"Peru": "Lima",
	"Cuba": "Havana",
	"Greece": "Athens",
	"Poland": "Warsaw",
	"Sweden": "Stockholm",
	"Norway": "Oslo",
	"Portugal": "Lisbon",
	"Austria": "Vienna",
	"Thailand": "Bangkok",
	"Turkey": "Ankara",
	"Kenya": "Nairobi",
	"Ireland": "Dublin",
	"Chile": "Santiago",
	"Colombia": "Bogota",
	"South Korea": "Seoul",
	"Netherlands": "Amsterdam",
	"Belgium": "Brussels",
	"Switzerland": "Bern",
	"Denmark": "Copenhagen",
	"Finland": "Helsinki",
	"Hungary": "Budapest",
	"Romania": "Bucharest",
	"Czech Republic": "Prague",
	"Ukraine": "Kyiv",
	"Vietnam": "Hanoi",
	"Philippines": "Manila",
}

var _score: int = 0
var _current_country: String = ""
var _current_capital: String = ""
var _used_countries: Array[String] = []
var _country_list: Array[String] = []


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	answer_input.text_submitted.connect(_on_answer_submitted)
	country_label.text = ""
	feedback_label.text = ""
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)
	answer_input.editable = false
	answer_input.placeholder_text = "Type capital + Enter"

	# Build shuffled country list
	var keys: Array = CAPITALS.keys()
	for k: String in keys:
		_country_list.append(k)
	_country_list.shuffle()


func _on_game_start() -> void:
	countdown_label.visible = false
	_score = 0
	_used_countries.clear()
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)
	answer_input.editable = true
	answer_input.grab_focus()
	_next_question()


func _on_game_end() -> void:
	answer_input.editable = false
	feedback_label.text = "Time's up!"
	submit_score(_score)


func _next_question() -> void:
	# Pick an unused country
	for c: String in _country_list:
		if not _used_countries.has(c):
			_current_country = c
			_current_capital = CAPITALS[c] as String
			_used_countries.append(c)
			break

	# If all used, reshuffle
	if _used_countries.size() >= _country_list.size():
		_used_countries.clear()

	country_label.text = _current_country
	answer_input.text = ""
	answer_input.grab_focus()


func _on_answer_submitted(text: String) -> void:
	if not game_active:
		return

	var stripped: String = text.strip_edges()
	if stripped.is_empty():
		return

	if stripped.to_lower() == _current_capital.to_lower():
		_score += 1
		feedback_label.text = "Correct!"
		feedback_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
		score_label.text = "Correct: " + str(_score) + " / " + str(COMPLETION_TARGET)
		if _score >= COMPLETION_TARGET:
			mark_completed(_score)
			return
	else:
		feedback_label.text = "Wrong! It was: " + _current_capital
		feedback_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

	_next_question()


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
