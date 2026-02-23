extends MiniGameBase

## Tug of War minigame.
## Mash spacebar to pull a rope marker toward your side.
## Marker drifts toward opponent; race to pull it to your end.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var status_label: Label = %StatusLabel
@onready var rope_bar: ColorRect = %RopeBar
@onready var marker: ColorRect = %Marker
@onready var left_zone: ColorRect = %LeftZone
@onready var right_zone: ColorRect = %RightZone

## Marker position from 0.0 (opponent side) to 1.0 (player side)
var _marker_pos: float = 0.5

## How much each press moves the marker toward player side
const PULL_PER_PRESS: float = 0.025

## Drift speed toward opponent per second (increases over time)
const BASE_DRIFT: float = 0.04
const DRIFT_ACCELERATION: float = 0.005  # Additional drift per second of elapsed time

## Total presses (used as score if time runs out)
var _total_presses: int = 0

## Elapsed time for drift acceleration
var _elapsed: float = 0.0


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	status_label.text = ""
	score_label.text = "Presses: 0"
	_update_visuals()


func _on_game_start() -> void:
	countdown_label.visible = false
	_marker_pos = 0.5
	_total_presses = 0
	_elapsed = 0.0
	score_label.text = "Presses: 0"
	status_label.text = "MASH SPACEBAR TO PULL!"
	_update_visuals()


func _on_game_end() -> void:
	status_label.text = "Time's up! " + str(_total_presses) + " presses!"
	submit_score(_total_presses)


func _process(delta: float) -> void:
	if not game_active:
		return
	_elapsed += delta
	# Drift marker toward opponent side (0.0)
	var current_drift: float = BASE_DRIFT + DRIFT_ACCELERATION * _elapsed
	_marker_pos -= current_drift * delta
	_marker_pos = clampf(_marker_pos, 0.0, 1.0)
	_update_visuals()


func _unhandled_input(event: InputEvent) -> void:
	if not game_active:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
			_total_presses += 1
			_marker_pos += PULL_PER_PRESS
			_marker_pos = clampf(_marker_pos, 0.0, 1.0)
			score_label.text = "Presses: " + str(_total_presses)

			if _marker_pos >= 1.0:
				status_label.text = "YOU WIN! Pulled to your side!"
				_update_visuals()
				mark_completed(_total_presses)
				return

			_update_visuals()


func _update_visuals() -> void:
	var bar_width: float = rope_bar.size.x
	var marker_x: float = bar_width * _marker_pos - marker.size.x * 0.5
	marker.position.x = clampf(marker_x, 0.0, bar_width - marker.size.x)

	# Color marker based on position
	if _marker_pos >= 0.7:
		marker.color = Color(0.2, 0.9, 0.2, 1)  # Green - close to winning
	elif _marker_pos >= 0.4:
		marker.color = Color(1.0, 0.9, 0.2, 1)  # Yellow - middle
	else:
		marker.color = Color(0.9, 0.2, 0.2, 1)  # Red - losing


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
