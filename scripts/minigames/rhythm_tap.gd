extends MiniGameBase

## Rhythm Tap minigame.
## Beats appear at regular intervals. Player presses spacebar when the
## beat indicator aligns with the hit zone. Score = total points from
## Perfect (3), Good (1) hits. Misses score 0.

signal beat_result(result_text: String)

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var result_label: Label = %ResultLabel
@onready var track_area: ColorRect = %TrackArea
@onready var hit_zone: ColorRect = %HitZone
@onready var combo_label: Label = %ComboLabel

## Beats per minute
const BPM: float = 100.0
## Seconds between beats
var _beat_interval: float = 60.0 / BPM
## Time window for "Perfect" hit (seconds, +/-)
const PERFECT_WINDOW: float = 0.08
## Time window for "Good" hit (seconds, +/-)
const GOOD_WINDOW: float = 0.2

var _score: int = 0
var _combo: int = 0
var _best_combo: int = 0

## Time since game started (used to schedule beats)
var _elapsed: float = 0.0
## Next beat index to spawn
var _next_beat_index: int = 0
## Active beat times (absolute times when beat should be hit)
var _active_beats: Array[float] = []
## Beat visual nodes
var _beat_nodes: Array[ColorRect] = []

## Track dimensions for beat movement
const TRACK_HEIGHT: float = 400.0
## How far in advance beats appear (seconds before they reach hit zone)
const BEAT_LEAD_TIME: float = 1.2
## Hit zone Y position relative to track (from top)
const HIT_ZONE_RATIO: float = 0.85


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	_update_score_display()
	instruction_label.text = "Get ready..."
	result_label.text = ""
	combo_label.text = ""


func _process(delta: float) -> void:
	if not game_active:
		return

	_elapsed += delta

	# Spawn new beats as needed
	var next_beat_time: float = _next_beat_index * _beat_interval
	while next_beat_time - _elapsed < BEAT_LEAD_TIME and next_beat_time < GAME_DURATION:
		_spawn_beat(next_beat_time)
		_next_beat_index += 1
		next_beat_time = _next_beat_index * _beat_interval

	# Move beat visuals and check for missed beats
	var i: int = 0
	while i < _active_beats.size():
		var beat_time: float = _active_beats[i]
		var time_until_hit: float = beat_time - _elapsed
		var ratio: float = time_until_hit / BEAT_LEAD_TIME

		if i < _beat_nodes.size() and is_instance_valid(_beat_nodes[i]):
			# Position: ratio=1 at top, ratio=0 at hit zone
			var y_pos: float = (1.0 - HIT_ZONE_RATIO) * TRACK_HEIGHT * ratio + HIT_ZONE_RATIO * TRACK_HEIGHT * (1.0 - ratio)
			# Simplified: lerp from top to hit zone
			y_pos = lerpf(HIT_ZONE_RATIO * TRACK_HEIGHT, 0.0, ratio)
			_beat_nodes[i].position.y = y_pos - 10.0  # center the 20px rect

		# Check if beat was missed (passed beyond hit zone)
		if time_until_hit < -GOOD_WINDOW:
			_on_miss(i)
			# Don't increment i since we removed the element
			continue
		i += 1


func _unhandled_input(event: InputEvent) -> void:
	if not game_active:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
			_handle_tap()


func _handle_tap() -> void:
	if _active_beats.is_empty():
		_show_result("MISS", Color.GRAY)
		_combo = 0
		_update_combo_display()
		return

	# Find the closest beat
	var closest_index: int = 0
	var closest_diff: float = absf(_active_beats[0] - _elapsed)
	for i: int in range(1, _active_beats.size()):
		var diff: float = absf(_active_beats[i] - _elapsed)
		if diff < closest_diff:
			closest_diff = diff
			closest_index = i

	if closest_diff <= PERFECT_WINDOW:
		_score += 3
		_combo += 1
		_show_result("PERFECT!", Color.GOLD)
		_remove_beat(closest_index)
	elif closest_diff <= GOOD_WINDOW:
		_score += 1
		_combo += 1
		_show_result("GOOD", Color.GREEN)
		_remove_beat(closest_index)
	else:
		_show_result("MISS", Color.GRAY)
		_combo = 0

	if _combo > _best_combo:
		_best_combo = _combo
	_update_score_display()
	_update_combo_display()


func _spawn_beat(beat_time: float) -> void:
	_active_beats.append(beat_time)
	var beat_rect: ColorRect = ColorRect.new()
	beat_rect.custom_minimum_size = Vector2(60, 20)
	beat_rect.size = Vector2(60, 20)
	beat_rect.color = Color.CYAN
	beat_rect.position.x = 70.0  # centered in 200px wide track
	track_area.add_child(beat_rect)
	_beat_nodes.append(beat_rect)


func _remove_beat(index: int) -> void:
	_active_beats.remove_at(index)
	if index < _beat_nodes.size():
		var node: ColorRect = _beat_nodes[index]
		_beat_nodes.remove_at(index)
		if is_instance_valid(node):
			node.queue_free()


func _on_miss(index: int) -> void:
	_combo = 0
	_show_result("MISS", Color.GRAY)
	_remove_beat(index)
	_update_combo_display()


func _show_result(text: String, color: Color) -> void:
	result_label.text = text
	result_label.add_theme_color_override("font_color", color)


func _on_game_start() -> void:
	_score = 0
	_combo = 0
	_best_combo = 0
	_elapsed = 0.0
	_next_beat_index = 0
	_active_beats.clear()
	_beat_nodes.clear()
	_update_score_display()
	_update_combo_display()
	instruction_label.text = "Press SPACE on the beat!"
	countdown_label.visible = false


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	# Clean up remaining beat nodes
	for node: ColorRect in _beat_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_beat_nodes.clear()
	_active_beats.clear()
	submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Score: " + str(_score)


func _update_combo_display() -> void:
	if _combo >= 2:
		combo_label.text = "Combo: " + str(_combo) + "x"
	else:
		combo_label.text = ""


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
