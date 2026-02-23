extends MiniGameBase

## Bubble Pop minigame.
## Bubbles float upward with letters on them, type the letter to pop.
## Score = number of bubbles popped. Race to 20.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var play_area: Control = %PlayArea

const COMPLETION_TARGET: int = 20
const BUBBLE_SPEED: float = 80.0
const SPAWN_INTERVAL: float = 0.6
const BUBBLE_SIZE: float = 40.0

var _popped_count: int = 0
var _bubbles: Array[Dictionary] = []
var _spawn_timer: float = 0.0

const LETTERS: Array[String] = [
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
	score_label.text = "Popped: 0 / " + str(COMPLETION_TARGET)
	feedback_label.text = ""
	play_area.draw.connect(_on_play_area_draw)


func _on_game_start() -> void:
	countdown_label.visible = false
	_popped_count = 0
	_bubbles.clear()
	_spawn_timer = 0.0
	score_label.text = "Popped: 0 / " + str(COMPLETION_TARGET)
	feedback_label.text = "Type the letters on the bubbles!"
	_spawn_bubble()


func _on_game_end() -> void:
	feedback_label.text = "Time's up! You popped " + str(_popped_count) + "!"
	submit_score(_popped_count)


func _process(delta: float) -> void:
	if not game_active:
		return

	# Spawn new bubbles periodically
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer -= SPAWN_INTERVAL
		_spawn_bubble()

	# Move bubbles upward and remove ones that go off-screen
	var area_size: Vector2 = play_area.size
	var i: int = _bubbles.size() - 1
	while i >= 0:
		_bubbles[i]["y"] -= BUBBLE_SPEED * delta
		if _bubbles[i]["y"] + BUBBLE_SIZE < 0:
			_bubbles.remove_at(i)
		i -= 1

	play_area.queue_redraw()


func _spawn_bubble() -> void:
	var area_size: Vector2 = play_area.size
	var bubble: Dictionary = {
		"letter": LETTERS[randi_range(0, LETTERS.size() - 1)],
		"x": randf_range(BUBBLE_SIZE, area_size.x - BUBBLE_SIZE),
		"y": area_size.y - BUBBLE_SIZE,
	}
	_bubbles.append(bubble)


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

	# Find the lowest bubble (closest to bottom) with this letter
	var best_index: int = -1
	var best_y: float = -1.0
	for i: int in range(_bubbles.size()):
		if _bubbles[i]["letter"] == pressed_letter:
			var by: float = _bubbles[i]["y"] as float
			if by > best_y:
				best_y = by
				best_index = i

	if best_index >= 0:
		_bubbles.remove_at(best_index)
		_popped_count += 1
		score_label.text = "Popped: " + str(_popped_count) + " / " + str(COMPLETION_TARGET)
		feedback_label.text = "Pop! " + pressed_letter
		if _popped_count >= COMPLETION_TARGET:
			mark_completed(_popped_count)
			return
	else:
		feedback_label.text = "No '" + pressed_letter + "' bubble!"


func _on_play_area_draw() -> void:
	for bubble: Dictionary in _bubbles:
		var bx: float = bubble["x"] as float
		var by: float = bubble["y"] as float
		var letter: String = bubble["letter"] as String

		# Draw bubble circle
		var center: Vector2 = Vector2(bx, by)
		play_area.draw_circle(center, BUBBLE_SIZE / 2.0, Color(0.3, 0.6, 1.0, 0.7))
		play_area.draw_arc(center, BUBBLE_SIZE / 2.0, 0, TAU, 32, Color(0.5, 0.8, 1.0), 2.0)

		# Draw letter centered in bubble
		var font: Font = ThemeDB.fallback_font
		var font_size: int = 20
		var text_size: Vector2 = font.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos: Vector2 = center - text_size / 2.0 + Vector2(0, text_size.y * 0.35)
		play_area.draw_string(font, text_pos, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
