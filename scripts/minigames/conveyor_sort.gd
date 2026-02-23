extends MiniGameBase

## Conveyor Sort minigame.
## Items slide across from left to right on a conveyor belt.
## Press LEFT arrow to sort into left bin, RIGHT arrow to sort into right bin.
## Each item has a label indicating which bin it belongs to.
## Race to sort 15 items correctly.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var status_label: Label = %StatusLabel
@onready var play_area: Control = %PlayArea
@onready var left_bin: ColorRect = %LeftBin
@onready var right_bin: ColorRect = %RightBin
@onready var left_bin_label: Label = %LeftBinLabel
@onready var right_bin_label: Label = %RightBinLabel

const COMPLETION_TARGET: int = 15
const CONVEYOR_SPEED: float = 120.0
const ITEM_WIDTH: float = 60.0
const ITEM_HEIGHT: float = 40.0
const SPAWN_INTERVAL: float = 1.8
const DECISION_ZONE_START: float = 0.3  # Fraction of play area width where item becomes sortable
const DECISION_ZONE_END: float = 0.7    # Fraction of play area width where item auto-fails

## Category pairs: [left_category, right_category, items_left, items_right]
const CATEGORY_SETS: Array = [
	["FRUIT", "VEGGIE", ["Apple", "Banana", "Grape", "Mango", "Peach"], ["Carrot", "Onion", "Pepper", "Corn", "Bean"]],
	["HOT", "COLD", ["Fire", "Sun", "Lava", "Steam", "Torch"], ["Ice", "Snow", "Frost", "Chill", "Sleet"]],
	["LAND", "SEA", ["Dog", "Cat", "Horse", "Bear", "Fox"], ["Whale", "Shark", "Squid", "Crab", "Eel"]],
	["BIG", "SMALL", ["Whale", "House", "Tower", "Giant", "Train"], ["Ant", "Coin", "Seed", "Fly", "Bead"]],
	["SOFT", "HARD", ["Pillow", "Cloud", "Silk", "Foam", "Wool"], ["Rock", "Steel", "Brick", "Glass", "Iron"]],
]

var _score: int = 0
var _spawn_timer: float = 0.0
var _current_item: Dictionary = {}  # {rect: ColorRect, label: Label, goes_left: bool, x: float}
var _has_active_item: bool = false
var _category_left: String = ""
var _category_right: String = ""
var _items_left: Array = []
var _items_right: Array = []
var _item_decided: bool = false
var _area_width: float = 500.0


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	status_label.text = ""
	score_label.text = "Sorted: 0 / " + str(COMPLETION_TARGET)
	left_bin.visible = false
	right_bin.visible = false
	left_bin_label.visible = false
	right_bin_label.visible = false


func _on_game_start() -> void:
	countdown_label.visible = false
	_score = 0
	_spawn_timer = SPAWN_INTERVAL  # Spawn immediately
	_has_active_item = false
	_item_decided = false
	score_label.text = "Sorted: 0 / " + str(COMPLETION_TARGET)

	# Pick a random category set
	var cat_set: Array = CATEGORY_SETS[randi() % CATEGORY_SETS.size()]
	_category_left = cat_set[0] as String
	_category_right = cat_set[1] as String
	_items_left = cat_set[2] as Array
	_items_right = cat_set[3] as Array

	_area_width = play_area.size.x

	# Show bins
	left_bin.visible = true
	right_bin.visible = true
	left_bin_label.visible = true
	right_bin_label.visible = true
	left_bin_label.text = "<- " + _category_left
	right_bin_label.text = _category_right + " ->"
	status_label.text = "LEFT = " + _category_left + "  |  RIGHT = " + _category_right


func _on_game_end() -> void:
	status_label.text = "Time's up! Sorted " + str(_score) + "!"
	_clear_active_item()
	submit_score(_score)


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or not _has_active_item or _item_decided:
		return

	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	# Check if item is in decision zone
	var item_center_x: float = _current_item["x"] as float + ITEM_WIDTH / 2.0
	var zone_start: float = _area_width * DECISION_ZONE_START
	var zone_end: float = _area_width * DECISION_ZONE_END

	if item_center_x < zone_start or item_center_x > zone_end:
		return  # Not in sortable zone yet

	var goes_left: bool = _current_item["goes_left"] as bool

	if key_event.keycode == KEY_LEFT:
		_item_decided = true
		if goes_left:
			_score += 1
			_show_result(true)
		else:
			_show_result(false)
		_schedule_next_item()
	elif key_event.keycode == KEY_RIGHT:
		_item_decided = true
		if not goes_left:
			_score += 1
			_show_result(true)
		else:
			_show_result(false)
		_schedule_next_item()


func _process(delta: float) -> void:
	if not game_active:
		return

	# Spawn items
	if not _has_active_item:
		_spawn_timer += delta
		if _spawn_timer >= SPAWN_INTERVAL:
			_spawn_timer = 0.0
			_spawn_item()
		return

	if _item_decided:
		return

	# Move active item across conveyor
	var new_x: float = (_current_item["x"] as float) + CONVEYOR_SPEED * delta
	_current_item["x"] = new_x
	var rect: ColorRect = _current_item["rect"] as ColorRect
	var lbl: Label = _current_item["label"] as Label
	rect.position.x = new_x
	lbl.position.x = new_x

	# Check if item passed the decision zone without being sorted
	var item_center_x: float = new_x + ITEM_WIDTH / 2.0
	var zone_end: float = _area_width * DECISION_ZONE_END
	if item_center_x > zone_end:
		_item_decided = true
		_show_result(false)
		_schedule_next_item()


func _spawn_item() -> void:
	var goes_left: bool = randi() % 2 == 0
	var item_name: String = ""
	if goes_left:
		item_name = _items_left[randi() % _items_left.size()] as String
	else:
		item_name = _items_right[randi() % _items_right.size()] as String

	var area_height: float = play_area.size.y
	var y_pos: float = (area_height - ITEM_HEIGHT) / 2.0

	var rect: ColorRect = ColorRect.new()
	rect.size = Vector2(ITEM_WIDTH, ITEM_HEIGHT)
	rect.position = Vector2(-ITEM_WIDTH, y_pos)
	rect.color = Color(0.3, 0.5, 0.7) if goes_left else Color(0.7, 0.5, 0.3)
	play_area.add_child(rect)

	var lbl: Label = Label.new()
	lbl.text = item_name
	lbl.position = Vector2(-ITEM_WIDTH, y_pos + 10.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(ITEM_WIDTH, ITEM_HEIGHT)
	play_area.add_child(lbl)

	_current_item = {"rect": rect, "label": lbl, "goes_left": goes_left, "x": -ITEM_WIDTH}
	_has_active_item = true
	_item_decided = false


func _show_result(correct: bool) -> void:
	if correct:
		status_label.text = "Correct! " + str(_score) + " / " + str(COMPLETION_TARGET)
	else:
		status_label.text = "Wrong!"
	score_label.text = "Sorted: " + str(_score) + " / " + str(COMPLETION_TARGET)

	if _score >= COMPLETION_TARGET:
		_clear_active_item()
		mark_completed(_score)


func _schedule_next_item() -> void:
	# Brief delay then clear and allow next spawn
	var tween: Tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_callback(_clear_active_item)


func _clear_active_item() -> void:
	if _has_active_item:
		var rect: ColorRect = _current_item["rect"] as ColorRect
		var lbl: Label = _current_item["label"] as Label
		if is_instance_valid(rect):
			rect.queue_free()
		if is_instance_valid(lbl):
			lbl.queue_free()
		_has_active_item = false
		_current_item = {}
		_spawn_timer = 0.0


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
