extends MiniGameBase

## Rotation Lock minigame.
## A pointer rotates around a dial. Press spacebar when the pointer aligns with the target zone.
## Race to hit 10 targets.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var status_label: Label = %StatusLabel
@onready var dial_area: Control = %DialArea

const COMPLETION_TARGET: int = 10
const DIAL_RADIUS: float = 120.0
const POINTER_LENGTH: float = 100.0
const TARGET_ARC_DEGREES: float = 30.0  # Gets narrower over time
const MIN_TARGET_ARC: float = 15.0

var _targets_hit: int = 0
var _pointer_angle: float = 0.0  # In degrees, 0 = top, clockwise
var _rotation_speed: float = 180.0  # Degrees per second
var _target_angle: float = 0.0  # Center of the target zone in degrees
var _waiting_for_next: bool = false
var _wait_timer: float = 0.0


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	status_label.text = ""
	score_label.text = "Targets: 0 / " + str(COMPLETION_TARGET)
	dial_area.draw.connect(_on_dial_draw)
	_setup_target()


func _on_game_start() -> void:
	countdown_label.visible = false
	_targets_hit = 0
	_pointer_angle = 0.0
	_rotation_speed = 180.0
	_waiting_for_next = false
	score_label.text = "Targets: 0 / " + str(COMPLETION_TARGET)
	status_label.text = "Press SPACE when pointer hits the target!"
	_setup_target()
	dial_area.queue_redraw()


func _on_game_end() -> void:
	status_label.text = "Time's up! Hit " + str(_targets_hit) + " targets!"
	submit_score(_targets_hit)


func _process(delta: float) -> void:
	if not game_active:
		return

	if _waiting_for_next:
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_waiting_for_next = false
			_setup_target()
			status_label.text = "Press SPACE when pointer hits the target!"
		dial_area.queue_redraw()
		return

	# Rotate pointer
	_pointer_angle += _rotation_speed * delta
	if _pointer_angle >= 360.0:
		_pointer_angle -= 360.0

	dial_area.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not game_active or _waiting_for_next:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
			_check_alignment()


func _check_alignment() -> void:
	var half_arc: float = _get_current_arc() / 2.0
	var angle_diff: float = _angle_difference(_pointer_angle, _target_angle)

	if absf(angle_diff) <= half_arc:
		# Hit!
		_targets_hit += 1
		score_label.text = "Targets: " + str(_targets_hit) + " / " + str(COMPLETION_TARGET)

		if _targets_hit >= COMPLETION_TARGET:
			status_label.text = "ALL TARGETS HIT!"
			mark_completed(_targets_hit)
			return

		# Speed up and brief pause
		_rotation_speed += 12.0
		_waiting_for_next = true
		_wait_timer = 0.3
		status_label.text = "HIT! Target " + str(_targets_hit) + "!"
	else:
		# Miss - brief penalty pause
		_waiting_for_next = true
		_wait_timer = 0.4
		status_label.text = "MISS! Try again..."


func _setup_target() -> void:
	_target_angle = randf_range(0.0, 360.0)


func _get_current_arc() -> float:
	var progress: float = float(_targets_hit) / float(COMPLETION_TARGET)
	return lerpf(TARGET_ARC_DEGREES, MIN_TARGET_ARC, progress)


func _angle_difference(a: float, b: float) -> float:
	var diff: float = fmod(a - b + 540.0, 360.0) - 180.0
	return diff


func _on_dial_draw() -> void:
	var center: Vector2 = dial_area.size / 2.0

	# Draw dial background circle
	dial_area.draw_circle(center, DIAL_RADIUS, Color(0.15, 0.15, 0.25, 1.0))
	dial_area.draw_arc(center, DIAL_RADIUS, 0.0, TAU, 64, Color(0.4, 0.4, 0.5, 1.0), 2.0)

	# Draw target zone arc
	var arc_half: float = deg_to_rad(_get_current_arc() / 2.0)
	var target_rad: float = deg_to_rad(_target_angle - 90.0)  # -90 because 0 = top
	var arc_start: float = target_rad - arc_half
	var arc_end: float = target_rad + arc_half

	# Draw target zone as filled segments
	var arc_segments: int = 16
	var arc_step: float = (arc_end - arc_start) / float(arc_segments)
	for i: int in range(arc_segments):
		var a1: float = arc_start + arc_step * float(i)
		var a2: float = arc_start + arc_step * float(i + 1)
		var p1: Vector2 = center + Vector2(cos(a1), sin(a1)) * (DIAL_RADIUS - 20.0)
		var p2: Vector2 = center + Vector2(cos(a2), sin(a2)) * (DIAL_RADIUS - 20.0)
		var p3: Vector2 = center + Vector2(cos(a2), sin(a2)) * DIAL_RADIUS
		var p4: Vector2 = center + Vector2(cos(a1), sin(a1)) * DIAL_RADIUS
		var points: PackedVector2Array = PackedVector2Array([p1, p2, p3, p4])
		var colors: PackedColorArray = PackedColorArray([Color(0.2, 0.8, 0.2, 0.6), Color(0.2, 0.8, 0.2, 0.6), Color(0.2, 0.8, 0.2, 0.6), Color(0.2, 0.8, 0.2, 0.6)])
		dial_area.draw_polygon(points, colors)

	# Draw pointer line
	var pointer_rad: float = deg_to_rad(_pointer_angle - 90.0)
	var pointer_end: Vector2 = center + Vector2(cos(pointer_rad), sin(pointer_rad)) * POINTER_LENGTH
	dial_area.draw_line(center, pointer_end, Color(1.0, 0.3, 0.3, 1.0), 3.0)

	# Draw pointer tip
	dial_area.draw_circle(pointer_end, 5.0, Color(1.0, 0.3, 0.3, 1.0))

	# Draw center dot
	dial_area.draw_circle(center, 6.0, Color(0.8, 0.8, 0.8, 1.0))


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
