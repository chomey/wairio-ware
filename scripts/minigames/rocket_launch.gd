extends MiniGameBase

## Rocket Launch minigame.
## Hold spacebar to charge a power meter. Release in the green zone for a good launch.
## Best of 5 attempts. Score = inverse of best distance from center (higher = better).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var status_label: Label = %StatusLabel
@onready var meter_area: Control = %MeterArea
@onready var attempt_container: HBoxContainer = %AttemptContainer
@onready var best_label: Label = %BestLabel
@onready var instruction_label: Label = %InstructionLabel

const COMPLETION_TARGET: int = 5
const MAX_SCORE: int = 10000

## Green zone: center of the meter (40%-60%)
const GREEN_MIN: float = 0.40
const GREEN_MAX: float = 0.60
const GREEN_CENTER: float = 0.50

var _attempt: int = 0
var _best_error: float = 1.0  # Lower is better (0.0 = perfect center)
var _charging: bool = false
var _charge: float = 0.0
var _charge_speed: float = 1.2  # Fills in ~0.8 seconds
var _launched: bool = false
var _pause_timer: float = 0.0
var _paused: bool = false
var _attempt_markers: Array[ColorRect] = []
var _awaiting_press: bool = false


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	status_label.text = ""
	score_label.text = "Attempt: 0 / " + str(COMPLETION_TARGET)
	best_label.text = "Best: ---"
	instruction_label.text = "Hold SPACE to charge, release in GREEN zone!"
	meter_area.draw.connect(_on_meter_draw)
	_create_attempt_markers()


func _on_game_start() -> void:
	countdown_label.visible = false
	_attempt = 0
	_best_error = 1.0
	_charging = false
	_launched = false
	_paused = false
	_awaiting_press = true
	_charge = 0.0
	score_label.text = "Attempt: 0 / " + str(COMPLETION_TARGET)
	best_label.text = "Best: ---"
	status_label.text = "Hold SPACE to charge!"
	meter_area.queue_redraw()


func _on_game_end() -> void:
	var final_score: int = maxi(0, MAX_SCORE - int(_best_error * MAX_SCORE))
	status_label.text = "Time's up!"
	submit_score(final_score)


func _process(delta: float) -> void:
	if not game_active:
		return

	if _paused:
		_pause_timer -= delta
		if _pause_timer <= 0.0:
			_paused = false
			if _attempt >= COMPLETION_TARGET:
				var final_score: int = maxi(0, MAX_SCORE - int(_best_error * MAX_SCORE))
				status_label.text = "All attempts done!"
				mark_completed(final_score)
				return
			_reset_for_next()
		return

	if _charging:
		_charge += _charge_speed * delta
		if _charge >= 1.0:
			# Overcharged - auto release at max
			_charge = 1.0
			_handle_release()
		meter_area.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _paused or _launched:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == KEY_SPACE:
			if key_event.pressed and not key_event.echo and _awaiting_press:
				# Start charging
				_charging = true
				_awaiting_press = false
				_charge = 0.0
				status_label.text = "Charging... release in GREEN!"
				meter_area.queue_redraw()
			elif not key_event.pressed and _charging:
				# Released - evaluate
				_handle_release()


func _handle_release() -> void:
	_charging = false
	_launched = true
	_attempt += 1
	score_label.text = "Attempt: " + str(_attempt) + " / " + str(COMPLETION_TARGET)

	# Calculate distance from green center
	var error: float = absf(_charge - GREEN_CENTER)

	# Update attempt marker
	if _attempt - 1 < _attempt_markers.size():
		if _charge >= GREEN_MIN and _charge <= GREEN_MAX:
			if error <= 0.03:
				_attempt_markers[_attempt - 1].color = Color(0.2, 1.0, 0.2, 1.0)  # Green - great
			else:
				_attempt_markers[_attempt - 1].color = Color(0.6, 1.0, 0.2, 1.0)  # Light green - good
		else:
			_attempt_markers[_attempt - 1].color = Color(1.0, 0.3, 0.2, 1.0)  # Red - missed

	if error < _best_error:
		_best_error = error
		best_label.text = "Best: " + _format_error(_best_error)

	# Show result
	if _charge >= GREEN_MIN and _charge <= GREEN_MAX:
		if error <= 0.03:
			status_label.text = "PERFECT LAUNCH!"
		else:
			status_label.text = "GOOD LAUNCH!"
	elif _charge < GREEN_MIN:
		status_label.text = "TOO WEAK! (%.0f%%)" % (_charge * 100.0)
	else:
		status_label.text = "TOO MUCH POWER! (%.0f%%)" % (_charge * 100.0)

	meter_area.queue_redraw()

	# Brief pause before next attempt
	_paused = true
	_pause_timer = 1.2


func _reset_for_next() -> void:
	_charge = 0.0
	_launched = false
	_awaiting_press = true
	status_label.text = "Hold SPACE to charge!"
	meter_area.queue_redraw()


func _format_error(err: float) -> String:
	if err >= 1.0:
		return "---"
	var pct: float = err * 100.0
	if pct < 1.0:
		return "PERFECT"
	return "%.1f%% off" % pct


func _on_meter_draw() -> void:
	var area_size: Vector2 = meter_area.size
	var bar_x: float = area_size.x * 0.1
	var bar_w: float = area_size.x * 0.8
	var bar_y: float = area_size.y * 0.2
	var bar_h: float = area_size.y * 0.6

	# Background
	meter_area.draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.15, 0.15, 0.2, 1.0))

	# Red zones (below and above green)
	var green_start_x: float = bar_x + bar_w * GREEN_MIN
	var green_end_x: float = bar_x + bar_w * GREEN_MAX
	meter_area.draw_rect(Rect2(bar_x, bar_y, green_start_x - bar_x, bar_h), Color(0.6, 0.1, 0.1, 0.5))
	meter_area.draw_rect(Rect2(green_end_x, bar_y, bar_x + bar_w - green_end_x, bar_h), Color(0.6, 0.1, 0.1, 0.5))

	# Green zone
	meter_area.draw_rect(Rect2(green_start_x, bar_y, green_end_x - green_start_x, bar_h), Color(0.1, 0.6, 0.1, 0.5))

	# Center line (perfect)
	var center_x: float = bar_x + bar_w * GREEN_CENTER
	meter_area.draw_line(Vector2(center_x, bar_y), Vector2(center_x, bar_y + bar_h), Color(1.0, 1.0, 0.2, 0.8), 2.0)

	# Charge indicator
	if _charging or _launched:
		var indicator_x: float = bar_x + bar_w * _charge
		var indicator_color: Color = Color(1.0, 1.0, 1.0, 1.0)
		if _charge >= GREEN_MIN and _charge <= GREEN_MAX:
			indicator_color = Color(0.2, 1.0, 0.2, 1.0)
		elif _charge >= 0.8:
			indicator_color = Color(1.0, 0.2, 0.2, 1.0)
		meter_area.draw_rect(Rect2(indicator_x - 3, bar_y - 5, 6, bar_h + 10), indicator_color)

	# Border
	meter_area.draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.6, 0.6, 0.7, 1.0), false, 2.0)

	# Labels
	meter_area.draw_string(ThemeDB.fallback_font, Vector2(bar_x, bar_y - 5), "0%", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.7))
	meter_area.draw_string(ThemeDB.fallback_font, Vector2(bar_x + bar_w - 30, bar_y - 5), "100%", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.7))
	meter_area.draw_string(ThemeDB.fallback_font, Vector2(center_x - 20, bar_y + bar_h + 18), "TARGET", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 1.0, 0.2))


func _create_attempt_markers() -> void:
	_attempt_markers.clear()
	for child: Node in attempt_container.get_children():
		child.queue_free()
	for i: int in range(COMPLETION_TARGET):
		var marker: ColorRect = ColorRect.new()
		marker.custom_minimum_size = Vector2(40, 20)
		marker.color = Color(0.3, 0.3, 0.4, 1.0)
		attempt_container.add_child(marker)
		_attempt_markers.append(marker)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
