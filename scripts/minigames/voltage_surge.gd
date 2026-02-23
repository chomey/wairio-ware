extends MiniGameBase

## Voltage Surge minigame (Survival).
## Hold spacebar to charge a voltage meter. The voltage fluctuates unpredictably.
## Release before it overloads (hits 100%). If it overloads, you're eliminated.
## Each successful charge-and-release cycle scores a round.
## Difficulty increases: fluctuation gets wilder and drain on release gets slower.
## Score = time survived (in tenths of seconds).

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const MAX_VOLTAGE: float = 100.0
const CHARGE_RATE: float = 18.0
const INITIAL_FLUCTUATION: float = 25.0
const FLUCTUATION_INCREMENT: float = 4.0
const DRAIN_RATE: float = 40.0
const DRAIN_DECAY: float = 3.0
const OVERLOAD_THRESHOLD: float = 100.0
const TARGET_ZONE_MIN: float = 60.0
const TARGET_ZONE_MAX: float = 85.0
const ROUND_BONUS_CHARGE: float = 2.0

var _voltage: float = 0.0
var _charging: bool = false
var _fluctuation_strength: float = INITIAL_FLUCTUATION
var _fluctuation_offset: float = 0.0
var _fluctuation_time: float = 0.0
var _round_count: int = 0
var _score: int = 0
var _elapsed_time: float = 0.0
var _eliminated: bool = false
var _draining: bool = false
var _drain_speed: float = DRAIN_RATE
var _round_cleared: bool = false
var _round_clear_timer: float = 0.0


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	_update_score_display()
	instruction_label.text = "Get ready..."
	play_area.draw.connect(_on_play_area_draw)


func _process(delta: float) -> void:
	if not game_active or _eliminated:
		return

	_elapsed_time += delta
	_score = int(_elapsed_time * 10.0)
	_update_score_display()

	# Round clear pause
	if _round_cleared:
		_round_clear_timer -= delta
		if _round_clear_timer <= 0.0:
			_round_cleared = false
			_start_new_round()
		play_area.queue_redraw()
		return

	_fluctuation_time += delta

	if _charging:
		# Charge the voltage with fluctuation
		var base_charge: float = CHARGE_RATE + (_round_count * ROUND_BONUS_CHARGE)
		_fluctuation_offset = sin(_fluctuation_time * 6.0) * _fluctuation_strength * delta
		_fluctuation_offset += sin(_fluctuation_time * 13.7) * _fluctuation_strength * 0.5 * delta
		_voltage += base_charge * delta + _fluctuation_offset

		# Clamp minimum at 0
		_voltage = maxf(_voltage, 0.0)

		# Check overload
		if _voltage >= OVERLOAD_THRESHOLD:
			_voltage = OVERLOAD_THRESHOLD
			_eliminated = true
			instruction_label.text = "OVERLOADED! Eliminated!"
			play_area.queue_redraw()
			mark_completed(_score)
			return

	elif _draining:
		# Voltage drains after release
		_voltage -= _drain_speed * delta
		_drain_speed = maxf(_drain_speed - DRAIN_DECAY * delta, 10.0)

		if _voltage <= 0.0:
			_voltage = 0.0
			_draining = false

	# Check if voltage is in the target zone when released (not charging and not draining)
	# This is handled in input release

	play_area.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _eliminated or _round_cleared:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == KEY_SPACE:
			if key_event.pressed and not key_event.echo:
				_charging = true
				_draining = false
				instruction_label.text = "Charging... Release in GREEN zone!"
				get_viewport().set_input_as_handled()
			elif not key_event.pressed:
				if _charging:
					_charging = false
					# Check if in target zone
					if _voltage >= TARGET_ZONE_MIN and _voltage <= TARGET_ZONE_MAX:
						_round_count += 1
						_round_cleared = true
						_round_clear_timer = 0.6
						instruction_label.text = "Round " + str(_round_count) + " cleared!"
						_fluctuation_strength += FLUCTUATION_INCREMENT
					else:
						_draining = true
						_drain_speed = DRAIN_RATE
						if _voltage < TARGET_ZONE_MIN:
							instruction_label.text = "Too low! Hold longer!"
						else:
							instruction_label.text = "Too high! Release sooner!"
					get_viewport().set_input_as_handled()


func _start_new_round() -> void:
	_voltage = 0.0
	_draining = false
	_charging = false
	instruction_label.text = "Hold SPACE to charge!"


func _on_play_area_draw() -> void:
	var pw: float = play_area.size.x
	var ph: float = play_area.size.y

	# Draw voltage meter bar (vertical)
	var bar_width: float = 60.0
	var bar_height: float = ph * 0.75
	var bar_x: float = (pw - bar_width) * 0.5
	var bar_y: float = ph * 0.08

	# Background
	play_area.draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color(0.12, 0.12, 0.18, 1.0))

	# Overload zone (above target)
	var overload_top: float = bar_y
	var overload_height: float = bar_height * (1.0 - TARGET_ZONE_MAX / MAX_VOLTAGE)
	play_area.draw_rect(Rect2(bar_x, overload_top, bar_width, overload_height), Color(0.4, 0.05, 0.05, 0.6))

	# Target zone (green)
	var target_top: float = bar_y + bar_height * (1.0 - TARGET_ZONE_MAX / MAX_VOLTAGE)
	var target_bot: float = bar_y + bar_height * (1.0 - TARGET_ZONE_MIN / MAX_VOLTAGE)
	play_area.draw_rect(Rect2(bar_x, target_top, bar_width, target_bot - target_top), Color(0.1, 0.4, 0.1, 0.6))

	# Below target zone (dim)
	play_area.draw_rect(Rect2(bar_x, target_bot, bar_width, bar_y + bar_height - target_bot), Color(0.08, 0.08, 0.12, 0.6))

	# Voltage fill
	var fill_ratio: float = clampf(_voltage / MAX_VOLTAGE, 0.0, 1.0)
	var fill_height: float = bar_height * fill_ratio
	var fill_y: float = bar_y + bar_height - fill_height

	var fill_color: Color
	if _voltage < TARGET_ZONE_MIN:
		fill_color = Color(0.3, 0.5, 0.9, 0.9)
	elif _voltage <= TARGET_ZONE_MAX:
		fill_color = Color(0.2, 0.9, 0.3, 0.9)
	else:
		fill_color = Color(0.9, 0.2, 0.1, 0.9)

	if fill_height > 0.0:
		play_area.draw_rect(Rect2(bar_x + 2.0, fill_y, bar_width - 4.0, fill_height), fill_color)

	# Voltage level line
	if _voltage > 0.0:
		play_area.draw_line(Vector2(bar_x - 8.0, fill_y), Vector2(bar_x + bar_width + 8.0, fill_y), Color(1.0, 1.0, 1.0, 0.8), 2.0)

	# Border
	play_area.draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color(0.5, 0.5, 0.6, 0.8), false, 2.0)

	# Labels
	play_area.draw_string(ThemeDB.fallback_font, Vector2(bar_x + bar_width + 14.0, target_top + 14.0), "GREEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.3, 0.8, 0.3))
	play_area.draw_string(ThemeDB.fallback_font, Vector2(bar_x + bar_width + 14.0, overload_top + 14.0), "DANGER", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.9, 0.3, 0.3))
	play_area.draw_string(ThemeDB.fallback_font, Vector2(bar_x + bar_width + 14.0, bar_y + bar_height - 4.0), "0%", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.6, 0.6))

	# Voltage percentage text
	var pct_text: String = str(int(_voltage)) + "%"
	play_area.draw_string(ThemeDB.fallback_font, Vector2(bar_x - 45.0, fill_y + 5.0 if _voltage > 5.0 else bar_y + bar_height - 4.0), pct_text, HORIZONTAL_ALIGNMENT_RIGHT, 40, 14, Color(1.0, 1.0, 1.0))

	# Charging indicator
	if _charging:
		var pulse: float = absf(sin(_fluctuation_time * 4.0))
		var indicator_color: Color = Color(1.0, 1.0, 0.3, 0.3 + pulse * 0.4)
		play_area.draw_rect(Rect2(bar_x - 4.0, bar_y - 4.0, bar_width + 8.0, bar_height + 8.0), indicator_color, false, 3.0)

	# Round counter display
	var round_text: String = "Rounds: " + str(_round_count)
	play_area.draw_string(ThemeDB.fallback_font, Vector2(pw * 0.5 - 30.0, ph - 10.0), round_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.8, 0.8, 0.8))


func _on_game_start() -> void:
	_voltage = 0.0
	_charging = false
	_draining = false
	_fluctuation_strength = INITIAL_FLUCTUATION
	_fluctuation_time = 0.0
	_round_count = 0
	_elapsed_time = 0.0
	_score = 0
	_eliminated = false
	_round_cleared = false
	_round_clear_timer = 0.0
	_update_score_display()
	instruction_label.text = "Hold SPACE to charge!"
	countdown_label.visible = false
	play_area.queue_redraw()


func _on_game_end() -> void:
	if not _eliminated:
		instruction_label.text = "Time's up! Survived!"
		submit_score(_score)


func _update_score_display() -> void:
	score_label.text = "Rounds: " + str(_round_count)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
