extends MiniGameBase

## Fruit Catcher minigame.
## Move basket left/right with arrow keys to catch falling fruit (green).
## Avoid falling bad items (red). Race to 15 caught.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var status_label: Label = %StatusLabel
@onready var play_area: Control = %PlayArea
@onready var basket: ColorRect = %Basket

const COMPLETION_TARGET: int = 15
const BASKET_SPEED: float = 400.0
const BASKET_WIDTH: float = 80.0
const BASKET_HEIGHT: float = 20.0
const ITEM_SIZE: float = 20.0
const SPAWN_INTERVAL: float = 0.5
const FALL_SPEED_BASE: float = 200.0
const FALL_SPEED_INCREASE: float = 15.0
const BAD_ITEM_CHANCE: float = 0.25

var _score: int = 0
var _spawn_timer: float = 0.0
var _items: Array[Dictionary] = []  # {rect: ColorRect, bad: bool, speed: float}
var _elapsed: float = 0.0


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	status_label.text = ""
	score_label.text = "Caught: 0 / " + str(COMPLETION_TARGET)
	basket.visible = false


func _on_game_start() -> void:
	countdown_label.visible = false
	_score = 0
	_elapsed = 0.0
	_spawn_timer = 0.0
	_items.clear()
	score_label.text = "Caught: 0 / " + str(COMPLETION_TARGET)
	status_label.text = "Catch the green fruit! Avoid the red!"

	# Position basket at bottom center of play area
	var area_size: Vector2 = play_area.size
	basket.position = Vector2((area_size.x - BASKET_WIDTH) / 2.0, area_size.y - BASKET_HEIGHT - 5.0)
	basket.size = Vector2(BASKET_WIDTH, BASKET_HEIGHT)
	basket.visible = true


func _on_game_end() -> void:
	status_label.text = "Time's up! Caught " + str(_score) + "!"
	_clear_items()
	submit_score(_score)


func _process(delta: float) -> void:
	if not game_active:
		return

	_elapsed += delta

	# Move basket with arrow keys
	var move_dir: float = 0.0
	if Input.is_action_pressed("ui_left"):
		move_dir -= 1.0
	if Input.is_action_pressed("ui_right"):
		move_dir += 1.0

	var area_size: Vector2 = play_area.size
	basket.position.x += move_dir * BASKET_SPEED * delta
	basket.position.x = clampf(basket.position.x, 0.0, area_size.x - BASKET_WIDTH)

	# Spawn items
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer = 0.0
		_spawn_item()

	# Update falling items
	var to_remove: Array[int] = []
	for i: int in range(_items.size()):
		var item: Dictionary = _items[i]
		var rect: ColorRect = item["rect"] as ColorRect
		var is_bad: bool = item["bad"] as bool
		var speed: float = item["speed"] as float

		rect.position.y += speed * delta

		# Check collision with basket
		var item_rect: Rect2 = Rect2(rect.position, rect.size)
		var basket_rect: Rect2 = Rect2(basket.position, basket.size)
		if item_rect.intersects(basket_rect):
			to_remove.append(i)
			if is_bad:
				# Bad item: lose 2 points (min 0)
				_score = maxi(_score - 2, 0)
				status_label.text = "Bad item! -2"
			else:
				_score += 1
				status_label.text = "Caught! " + str(_score) + " / " + str(COMPLETION_TARGET)
			score_label.text = "Caught: " + str(_score) + " / " + str(COMPLETION_TARGET)

			if _score >= COMPLETION_TARGET:
				_clear_items()
				mark_completed(_score)
				return
			continue

		# Remove if below play area
		if rect.position.y > area_size.y:
			to_remove.append(i)

	# Remove items in reverse order
	to_remove.reverse()
	for idx: int in to_remove:
		var rect: ColorRect = _items[idx]["rect"] as ColorRect
		rect.queue_free()
		_items.remove_at(idx)


func _spawn_item() -> void:
	var area_size: Vector2 = play_area.size
	var is_bad: bool = randf() < BAD_ITEM_CHANCE
	var speed: float = FALL_SPEED_BASE + _elapsed * FALL_SPEED_INCREASE

	var rect: ColorRect = ColorRect.new()
	rect.size = Vector2(ITEM_SIZE, ITEM_SIZE)
	rect.position = Vector2(randf_range(0.0, area_size.x - ITEM_SIZE), -ITEM_SIZE)

	if is_bad:
		rect.color = Color(0.9, 0.2, 0.2)
	else:
		rect.color = Color(0.2, 0.9, 0.2)

	play_area.add_child(rect)
	_items.append({"rect": rect, "bad": is_bad, "speed": speed})


func _clear_items() -> void:
	for item: Dictionary in _items:
		var rect: ColorRect = item["rect"] as ColorRect
		rect.queue_free()
	_items.clear()


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
