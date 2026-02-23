extends MiniGameBase

## Sinking Ship minigame (Survival).
## Ship fills with water as leaks appear. Click leaks to plug them.
## Too many leaks = water rises faster. Ship sinks (water full) = eliminated.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const WATER_RISE_BASE: float = 3.0  # % per second base rise
const WATER_RISE_PER_LEAK: float = 4.0  # extra % per active leak per second
const WATER_DRAIN_PER_PLUG: float = 2.0  # % drained when plugging a leak
const LEAK_SPAWN_INTERVAL_INITIAL: float = 3.0
const LEAK_SPAWN_INTERVAL_MIN: float = 1.0
const MAX_LEAKS: int = 8
const LEAK_RADIUS: float = 14.0
const SHIP_MARGIN: float = 20.0

var _water_level: float = 0.0  # 0 to 100
var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _spawn_timer: float = 1.5

# Leaks: {x, y, age} - positions on the ship hull (left/right/bottom walls)
var _leaks: Array[Dictionary] = []


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	_update_score_display()
	instruction_label.text = "Get ready..."
	play_area.draw.connect(_on_play_area_draw)
	play_area.gui_input.connect(_on_play_area_input)


func _process(delta: float) -> void:
	if not game_active or _eliminated:
		return

	_elapsed_time += delta
	_score = int(_elapsed_time * 10.0)
	_update_score_display()

	# Water rises based on number of active leaks
	var active_leaks: int = _leaks.size()
	var rise_rate: float = WATER_RISE_BASE + float(active_leaks) * WATER_RISE_PER_LEAK
	_water_level += rise_rate * delta

	# Age leaks
	for leak: Dictionary in _leaks:
		leak["age"] = (leak["age"] as float) + delta

	# Spawn new leaks
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _leaks.size() < MAX_LEAKS:
		_spawn_leak()
		var interval: float = maxf(LEAK_SPAWN_INTERVAL_INITIAL - _elapsed_time * 0.2, LEAK_SPAWN_INTERVAL_MIN)
		_spawn_timer = interval

	# Check sinking
	if _water_level >= 100.0:
		_water_level = 100.0
		_eliminated = true
		instruction_label.text = "Ship sank! Eliminated!"
		play_area.queue_redraw()
		mark_completed(_score)
		return

	play_area.queue_redraw()


func _spawn_leak() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y

	# Ship hull bounds (inside margins)
	var hull_left: float = SHIP_MARGIN
	var hull_right: float = pw - SHIP_MARGIN
	var hull_top: float = ph * 0.2
	var hull_bottom: float = ph - SHIP_MARGIN

	var x: float
	var y: float
	var attempts: int = 0

	while attempts < 20:
		# Leaks appear on the hull walls (left, right, bottom)
		var side: int = randi() % 3
		match side:
			0:  # Left wall
				x = hull_left + randf_range(5.0, 30.0)
				y = randf_range(hull_top + 20.0, hull_bottom - 20.0)
			1:  # Right wall
				x = hull_right - randf_range(5.0, 30.0)
				y = randf_range(hull_top + 20.0, hull_bottom - 20.0)
			_:  # Bottom
				x = randf_range(hull_left + 30.0, hull_right - 30.0)
				y = hull_bottom - randf_range(5.0, 30.0)

		# Check not too close to existing leaks
		var too_close: bool = false
		for leak: Dictionary in _leaks:
			var dx: float = (leak["x"] as float) - x
			var dy: float = (leak["y"] as float) - y
			if sqrt(dx * dx + dy * dy) < LEAK_RADIUS * 2.5:
				too_close = true
				break

		if not too_close:
			break
		attempts += 1

	_leaks.append({"x": x, "y": y, "age": 0.0})


func _on_play_area_input(event: InputEvent) -> void:
	if not game_active or _eliminated:
		return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_try_plug_leak(mb.position)


func _try_plug_leak(click_pos: Vector2) -> void:
	var best_idx: int = -1
	var best_dist: float = LEAK_RADIUS * 1.5

	for i: int in range(_leaks.size()):
		var leak: Dictionary = _leaks[i]
		var lx: float = leak["x"] as float
		var ly: float = leak["y"] as float
		var dx: float = lx - click_pos.x
		var dy: float = ly - click_pos.y
		var dist: float = sqrt(dx * dx + dy * dy)
		if dist < best_dist:
			best_dist = dist
			best_idx = i

	if best_idx >= 0:
		_leaks.remove_at(best_idx)
		# Plugging a leak drains some water
		_water_level = maxf(0.0, _water_level - WATER_DRAIN_PER_PLUG)
		play_area.queue_redraw()


func _on_play_area_draw() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y

	# Ship hull bounds
	var hull_left: float = SHIP_MARGIN
	var hull_right: float = pw - SHIP_MARGIN
	var hull_top: float = ph * 0.2
	var hull_bottom: float = ph - SHIP_MARGIN

	# Draw ocean background
	play_area.draw_rect(Rect2(0.0, 0.0, pw, ph), Color(0.05, 0.1, 0.2, 1.0))

	# Draw ship hull (wooden color)
	var hull_rect: Rect2 = Rect2(hull_left, hull_top, hull_right - hull_left, hull_bottom - hull_top)
	play_area.draw_rect(hull_rect, Color(0.35, 0.22, 0.1, 1.0))
	play_area.draw_rect(hull_rect, Color(0.5, 0.35, 0.15, 1.0), false, 3.0)

	# Draw horizontal planks
	var plank_spacing: float = 35.0
	var y: float = hull_top + plank_spacing
	while y < hull_bottom:
		play_area.draw_line(Vector2(hull_left, y), Vector2(hull_right, y), Color(0.45, 0.3, 0.12, 0.4), 1.0)
		y += plank_spacing

	# Draw water inside the ship
	var water_height: float = (hull_bottom - hull_top) * (_water_level / 100.0)
	if water_height > 0.0:
		var water_top: float = hull_bottom - water_height
		var water_color: Color
		if _water_level < 50.0:
			water_color = Color(0.1, 0.3, 0.7, 0.6)
		elif _water_level < 75.0:
			water_color = Color(0.2, 0.35, 0.6, 0.7)
		else:
			water_color = Color(0.3, 0.2, 0.5, 0.8)
		play_area.draw_rect(Rect2(hull_left + 2.0, water_top, hull_right - hull_left - 4.0, water_height), water_color)

		# Draw wave effect on water surface
		var wave_y: float = water_top
		for wx: int in range(int(hull_left) + 5, int(hull_right) - 5, 12):
			var wave_offset: float = sin(float(wx) * 0.1 + _elapsed_time * 3.0) * 3.0
			play_area.draw_circle(Vector2(float(wx), wave_y + wave_offset), 4.0, Color(0.2, 0.4, 0.8, 0.5))

	# Draw leaks (blue/cyan circles with spray effect)
	for leak: Dictionary in _leaks:
		var lx: float = leak["x"] as float
		var ly: float = leak["y"] as float
		var age: float = leak["age"] as float

		# Pulsing effect
		var pulse: float = 1.0 + sin(age * 6.0) * 0.2
		var r: float = LEAK_RADIUS * pulse

		# Outer glow
		play_area.draw_circle(Vector2(lx, ly), r + 4.0, Color(0.2, 0.5, 0.9, 0.3))
		# Main leak
		play_area.draw_circle(Vector2(lx, ly), r, Color(0.3, 0.6, 1.0, 0.8))
		# Inner bright spot
		play_area.draw_circle(Vector2(lx, ly), r * 0.4, Color(0.6, 0.8, 1.0, 0.9))

		# Spray lines
		for s: int in range(3):
			var spray_angle: float = age * 4.0 + float(s) * TAU / 3.0
			var spray_len: float = r * 1.5
			var sx: float = lx + cos(spray_angle) * spray_len
			var sy: float = ly + sin(spray_angle) * spray_len
			play_area.draw_line(Vector2(lx, ly), Vector2(sx, sy), Color(0.4, 0.7, 1.0, 0.4), 1.5)

	# Water level bar on the side
	var bar_x: float = pw - 12.0
	var bar_top: float = hull_top
	var bar_height: float = hull_bottom - hull_top
	play_area.draw_rect(Rect2(bar_x, bar_top, 8.0, bar_height), Color(0.2, 0.2, 0.2, 0.5))
	var fill_height: float = bar_height * (_water_level / 100.0)
	var bar_color: Color
	if _water_level < 40.0:
		bar_color = Color(0.2, 0.6, 0.9, 0.8)
	elif _water_level < 70.0:
		bar_color = Color(0.9, 0.7, 0.2, 0.8)
	else:
		bar_color = Color(0.9, 0.2, 0.2, 0.8)
	play_area.draw_rect(Rect2(bar_x, bar_top + bar_height - fill_height, 8.0, fill_height), bar_color)

	# Leak count
	var info_text: String = "Leaks: " + str(_leaks.size()) + "  Water: " + str(int(_water_level)) + "%"
	play_area.draw_string(ThemeDB.fallback_font, Vector2(hull_left + 10.0, hull_top - 5.0), info_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.9))


func _on_game_start() -> void:
	_water_level = 0.0
	_elapsed_time = 0.0
	_score = 0
	_eliminated = false
	_spawn_timer = 2.0
	_leaks.clear()
	_update_score_display()
	instruction_label.text = "Click leaks to plug them!"
	countdown_label.visible = false
	play_area.queue_redraw()


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! Ship survived!"
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Water: " + str(int(_water_level)) + "%"


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
