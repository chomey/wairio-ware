extends MiniGameBase

## Treasure Dig minigame.
## Mash spacebar to dig through layers of dirt.
## Each layer requires increasing presses. Race to reach depth 10.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var status_label: Label = %StatusLabel
@onready var depth_bar: ColorRect = %DepthBar
@onready var depth_fill: ColorRect = %DepthFill
@onready var layer_progress: ColorRect = %LayerProgress

const COMPLETION_TARGET: int = 10
const BASE_PRESSES_PER_LAYER: int = 5
const PRESS_INCREMENT: int = 2  # Each layer needs 2 more presses

var _depth: int = 0
var _layer_presses: int = 0
var _presses_needed: int = BASE_PRESSES_PER_LAYER
var _total_presses: int = 0


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	status_label.text = ""
	score_label.text = "Depth: 0 / " + str(COMPLETION_TARGET)
	_update_visuals()


func _on_game_start() -> void:
	countdown_label.visible = false
	_depth = 0
	_layer_presses = 0
	_presses_needed = BASE_PRESSES_PER_LAYER
	_total_presses = 0
	score_label.text = "Depth: 0 / " + str(COMPLETION_TARGET)
	status_label.text = "MASH SPACEBAR TO DIG!"
	_update_visuals()


func _on_game_end() -> void:
	status_label.text = "Time's up! Reached depth " + str(_depth) + "!"
	submit_score(_depth)


func _unhandled_input(event: InputEvent) -> void:
	if not game_active:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
			_total_presses += 1
			_layer_presses += 1

			if _layer_presses >= _presses_needed:
				_depth += 1
				_layer_presses = 0
				_presses_needed = BASE_PRESSES_PER_LAYER + _depth * PRESS_INCREMENT
				score_label.text = "Depth: " + str(_depth) + " / " + str(COMPLETION_TARGET)

				if _depth >= COMPLETION_TARGET:
					status_label.text = "TREASURE FOUND!"
					_update_visuals()
					mark_completed(_depth)
					return

				status_label.text = "Layer " + str(_depth + 1) + " - Dig harder!"

			_update_visuals()


func _update_visuals() -> void:
	# Update depth fill bar (overall progress)
	var depth_ratio: float = float(_depth) / float(COMPLETION_TARGET)
	var bar_height: float = depth_bar.size.y
	depth_fill.size.y = bar_height * depth_ratio
	depth_fill.position.y = bar_height - depth_fill.size.y

	# Color shifts from brown (surface) to gold (treasure)
	depth_fill.color = Color(0.6 + 0.4 * depth_ratio, 0.4 + 0.4 * depth_ratio, 0.1)

	# Update layer progress bar
	if _presses_needed > 0:
		var layer_ratio: float = float(_layer_presses) / float(_presses_needed)
		layer_progress.size.x = depth_bar.size.x * layer_ratio
	else:
		layer_progress.size.x = 0.0


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
