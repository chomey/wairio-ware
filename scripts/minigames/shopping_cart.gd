extends MiniGameBase

## Shopping Cart minigame.
## Items with prices are shown one at a time. Player must type the running total.
## Race to 8 items totaled correctly. Score = number of correct totals.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var item_label: Label = %ItemLabel
@onready var price_label: Label = %PriceLabel
@onready var total_hint_label: Label = %TotalHintLabel
@onready var answer_input: LineEdit = %AnswerInput
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel

const COMPLETION_TARGET: int = 8

var _correct_count: int = 0
var _running_total: float = 0.0
var _current_price: float = 0.0

const ITEMS: Array[String] = [
	"Apple", "Banana", "Bread", "Milk", "Cheese", "Eggs", "Butter", "Juice",
	"Cereal", "Rice", "Pasta", "Chicken", "Beef", "Fish", "Yogurt", "Chips",
	"Cookies", "Tomato", "Onion", "Carrot", "Potato", "Lettuce", "Pepper",
	"Soap", "Towel", "Sponge", "Battery", "Candle", "Pen", "Tape",
]


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	answer_input.text_submitted.connect(_on_answer_submitted)
	item_label.text = ""
	price_label.text = ""
	total_hint_label.text = ""
	feedback_label.text = ""
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)
	answer_input.editable = false
	answer_input.placeholder_text = "Type running total + Enter"


func _on_game_start() -> void:
	countdown_label.visible = false
	_correct_count = 0
	_running_total = 0.0
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)
	answer_input.editable = true
	answer_input.grab_focus()
	_generate_item()


func _on_game_end() -> void:
	answer_input.editable = false
	feedback_label.text = "Time's up! You got " + str(_correct_count) + " correct!"
	submit_score(_correct_count)


func _generate_item() -> void:
	var item_name: String = ITEMS[randi_range(0, ITEMS.size() - 1)]
	# Price between $0.50 and $9.99, rounded to cents
	_current_price = snapped(randf_range(0.5, 9.99), 0.01)
	_running_total += _current_price

	item_label.text = "Item: " + item_name
	price_label.text = "Price: $" + _format_price(_current_price)
	total_hint_label.text = "What is the running total?"
	answer_input.text = ""
	answer_input.grab_focus()


func _format_price(value: float) -> String:
	var cents: int = roundi(value * 100)
	var dollars: int = cents / 100
	var remainder: int = cents % 100
	if remainder < 10:
		return str(dollars) + ".0" + str(remainder)
	return str(dollars) + "." + str(remainder)


func _on_answer_submitted(text: String) -> void:
	if not game_active:
		return

	var stripped: String = text.strip_edges()
	if stripped.is_empty():
		return

	# Remove optional $ prefix
	if stripped.begins_with("$"):
		stripped = stripped.substr(1).strip_edges()

	if not stripped.is_valid_float():
		feedback_label.text = "Enter a number!"
		answer_input.text = ""
		answer_input.grab_focus()
		return

	var player_answer: float = stripped.to_float()
	var expected: float = snapped(_running_total, 0.01)
	# Allow small floating point tolerance
	if absf(player_answer - expected) < 0.015:
		_correct_count += 1
		feedback_label.text = "Correct! Total: $" + _format_price(expected)
		score_label.text = "Correct: " + str(_correct_count) + " / " + str(COMPLETION_TARGET)
		if _correct_count >= COMPLETION_TARGET:
			mark_completed(_correct_count)
			return
		_generate_item()
	else:
		feedback_label.text = "Wrong! Total was $" + _format_price(expected) + ". Resetting cart."
		_running_total = 0.0
		_generate_item()


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
