extends MiniGameBase

## Falling Letters minigame.
## Letters rain down from the top, type them before they hit the bottom.
## Score = number of letters typed. Race to 25.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var play_area: Control = %PlayArea

const COMPLETION_TARGET: int = 25
const FALL_SPEED_BASE: float = 100.0
const FALL_SPEED_INCREMENT: float = 5.0
const SPAWN_INTERVAL_BASE: float = 0.7
const SPAWN_INTERVAL_MIN: float = 0.3
const LETTER_SIZE: float = 36.0

var _typed_count: int = 0
var _letters: Array[Dictionary] = []
var _spawn_timer: float = 0.0
var _missed_count: int = 0

const ALPHABET: Array[String] = [
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
	"K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
	"U", "V", "W", "X", "Y", "Z"
]


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	score_label.text = "Typed: 0 / " + str(COMPLETION_TARGET)
	feedback_label.text = ""
	play_area.draw.connect(_on_play_area_draw)


func _on_game_start() -> void:
	countdown_label.visible = false
	_typed_count = 0
	_letters.clear()
	_spawn_timer = 0.0
	_missed_count = 0
	score_label.text = "Typed: 0 / " + str(COMPLETION_TARGET)
	feedback_label.text = "Type the falling letters!"
	_spawn_letter()


func _on_game_end() -> void:
	feedback_label.text = "Time's up! You typed " + str(_typed_count) + "!"
	submit_score(_typed_count)


func _process(delta: float) -> void:
	if not game_active:
		return

	# Spawn new letters periodically (faster over time)
	var spawn_interval: float = maxf(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_BASE - _typed_count * 0.015)
	_spawn_timer += delta
	if _spawn_timer >= spawn_interval:
		_spawn_timer -= spawn_interval
		_spawn_letter()

	# Move letters downward, remove ones that hit the bottom
	var area_height: float = play_area.size.y
	var fall_speed: float = FALL_SPEED_BASE + _typed_count * FALL_SPEED_INCREMENT
	var i: int = _letters.size() - 1
	while i >= 0:
		_letters[i]["y"] = (_letters[i]["y"] as float) + fall_speed * delta
		if (_letters[i]["y"] as float) > area_height:
			_letters.remove_at(i)
			_missed_count += 1
		i -= 1

	play_area.queue_redraw()


func _spawn_letter() -> void:
	var area_size: Vector2 = play_area.size
	var letter: Dictionary = {
		"letter": ALPHABET[randi_range(0, ALPHABET.size() - 1)],
		"x": randf_range(LETTER_SIZE, area_size.x - LETTER_SIZE),
		"y": 0.0,
	}
	_letters.append(letter)


func _unhandled_input(event: InputEvent) -> void:
	if not game_active:
		return

	if not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var pressed_letter: String = ""
	if key_event.keycode >= KEY_A and key_event.keycode <= KEY_Z:
		pressed_letter = char(key_event.keycode - KEY_A + 65)
	else:
		return

	get_viewport().set_input_as_handled()

	# Find the lowest letter (closest to bottom) with this key
	var best_index: int = -1
	var best_y: float = -1.0
	for idx: int in range(_letters.size()):
		if _letters[idx]["letter"] == pressed_letter:
			var ly: float = _letters[idx]["y"] as float
			if ly > best_y:
				best_y = ly
				best_index = idx

	if best_index >= 0:
		_letters.remove_at(best_index)
		_typed_count += 1
		score_label.text = "Typed: " + str(_typed_count) + " / " + str(COMPLETION_TARGET)
		feedback_label.text = pressed_letter + "!"
		if _typed_count >= COMPLETION_TARGET:
			mark_completed(_typed_count)
			return
	else:
		feedback_label.text = "No '" + pressed_letter + "' falling!"


func _on_play_area_draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 24

	for letter_data: Dictionary in _letters:
		var lx: float = letter_data["x"] as float
		var ly: float = letter_data["y"] as float
		var letter: String = letter_data["letter"] as String

		# Color shifts from white to red as letter approaches bottom
		var progress: float = clampf(ly / play_area.size.y, 0.0, 1.0)
		var color: Color = Color(1.0, 1.0 - progress * 0.7, 1.0 - progress * 0.7)

		var text_size: Vector2 = font.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos: Vector2 = Vector2(lx - text_size.x / 2.0, ly + text_size.y * 0.35)
		play_area.draw_string(font, text_pos, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
