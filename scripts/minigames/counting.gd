extends MiniGameBase

## Counting minigame.
## Objects flash on screen briefly, player types the count.
## Score = number of correct counts. Race to 8.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel
@onready var input_field: LineEdit = %InputField
@onready var object_area: Control = %ObjectArea

const COMPLETION_TARGET: int = 8
const FLASH_DURATION: float = 1.5
const OBJECT_SIZE: Vector2 = Vector2(30, 30)

var _correct_count: int = 0
var _current_answer: int = 0
var _showing_objects: bool = false
var _waiting_for_input: bool = false
var _flash_timer: Timer = null
var _objects: Array[ColorRect] = []

const OBJECT_COLORS: Array[Color] = [
	Color(1.0, 0.3, 0.3, 1.0),
	Color(0.3, 1.0, 0.3, 1.0),
	Color(0.3, 0.3, 1.0, 1.0),
	Color(1.0, 1.0, 0.3, 1.0),
	Color(1.0, 0.3, 1.0, 1.0),
	Color(0.3, 1.0, 1.0, 1.0),
]


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)

	_flash_timer = Timer.new()
	_flash_timer.one_shot = true
	_flash_timer.timeout.connect(_on_flash_timeout)
	add_child(_flash_timer)

	feedback_label.text = ""
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)
	input_field.visible = false
	input_field.text_submitted.connect(_on_answer_submitted)


func _on_game_start() -> void:
	countdown_label.visible = false
	_correct_count = 0
	score_label.text = "Correct: 0 / " + str(COMPLETION_TARGET)
	_show_objects()


func _on_game_end() -> void:
	_showing_objects = false
	_waiting_for_input = false
	input_field.visible = false
	_clear_objects()
	feedback_label.text = "Time's up! You got " + str(_correct_count) + " correct!"
	submit_score(_correct_count)


func _show_objects() -> void:
	_clear_objects()
	_waiting_for_input = false
	_showing_objects = true
	input_field.visible = false
	feedback_label.text = "Count the shapes!"

	# Random count between 3 and 12
	_current_answer = randi_range(3, 12)

	# Pick a random color for this round
	var color: Color = OBJECT_COLORS[randi_range(0, OBJECT_COLORS.size() - 1)]

	# Get area size
	var area_size: Vector2 = object_area.size
	if area_size.x < OBJECT_SIZE.x or area_size.y < OBJECT_SIZE.y:
		area_size = Vector2(400, 300)

	# Place objects at random positions
	for i: int in range(_current_answer):
		var obj: ColorRect = ColorRect.new()
		obj.custom_minimum_size = OBJECT_SIZE
		obj.size = OBJECT_SIZE
		obj.color = color
		var max_x: float = maxf(0.0, area_size.x - OBJECT_SIZE.x)
		var max_y: float = maxf(0.0, area_size.y - OBJECT_SIZE.y)
		obj.position = Vector2(randf_range(0.0, max_x), randf_range(0.0, max_y))
		object_area.add_child(obj)
		_objects.append(obj)

	# Start flash timer
	_flash_timer.wait_time = FLASH_DURATION
	_flash_timer.start()


func _on_flash_timeout() -> void:
	# Hide objects, show input
	_clear_objects()
	_showing_objects = false
	_waiting_for_input = true
	feedback_label.text = "How many were there?"
	input_field.visible = true
	input_field.text = ""
	input_field.grab_focus()


func _on_answer_submitted(answer_text: String) -> void:
	if not game_active or not _waiting_for_input:
		return

	_waiting_for_input = false
	input_field.visible = false

	if answer_text.strip_edges().is_valid_int():
		var answer: int = answer_text.strip_edges().to_int()
		if answer == _current_answer:
			_correct_count += 1
			feedback_label.text = "Correct! It was " + str(_current_answer)
			score_label.text = "Correct: " + str(_correct_count) + " / " + str(COMPLETION_TARGET)
			if _correct_count >= COMPLETION_TARGET:
				mark_completed(_correct_count)
				return
		else:
			feedback_label.text = "Wrong! It was " + str(_current_answer)
	else:
		feedback_label.text = "Wrong! It was " + str(_current_answer)

	# Next round after a brief pause
	if game_active:
		_show_objects()


func _clear_objects() -> void:
	for obj: ColorRect in _objects:
		if is_instance_valid(obj):
			obj.queue_free()
	_objects.clear()


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
