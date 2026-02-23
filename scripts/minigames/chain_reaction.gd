extends MiniGameBase

## Chain Reaction minigame.
## Click to place expanding circles that trigger nearby targets.
## Targets are scattered across the play area.
## When an expanding circle touches a target, that target also expands.
## Race to clear 30 targets total.
## Score = number of targets cleared within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var play_area: Control = %PlayArea

const COMPLETION_TARGET: int = 30
const TARGETS_PER_ROUND: int = 12
const TARGET_RADIUS: float = 15.0
const EXPAND_SPEED: float = 80.0
const MAX_EXPAND_RADIUS: float = 60.0

var _score: int = 0
var _targets: Array[Dictionary] = []
var _explosions: Array[Dictionary] = []
var _click_allowed: bool = true
var _round_active: bool = false


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	instruction_label.text = "Get ready..."
	_update_score_display()
	play_area.draw.connect(_on_play_area_draw)


func _on_game_start() -> void:
	_score = 0
	_update_score_display()
	instruction_label.text = "CLICK TO START A CHAIN REACTION!"
	countdown_label.visible = false
	_spawn_targets()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	_round_active = false
	submit_score(_score)


func _spawn_targets() -> void:
	_targets.clear()
	_explosions.clear()
	_click_allowed = true
	_round_active = true
	var area_size: Vector2 = play_area.size
	for i: int in range(TARGETS_PER_ROUND):
		var pos: Vector2 = Vector2(
			randf_range(TARGET_RADIUS, area_size.x - TARGET_RADIUS),
			randf_range(TARGET_RADIUS, area_size.y - TARGET_RADIUS)
		)
		_targets.append({
			"pos": pos,
			"triggered": false,
			"radius": 0.0,
		})
	play_area.queue_redraw()


func _input(event: InputEvent) -> void:
	if not game_active:
		return
	if not _click_allowed:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var local_pos: Vector2 = play_area.get_local_mouse_position()
			var area_size: Vector2 = play_area.size
			if local_pos.x >= 0.0 and local_pos.x <= area_size.x and local_pos.y >= 0.0 and local_pos.y <= area_size.y:
				_start_explosion(local_pos)
				_click_allowed = false


func _start_explosion(pos: Vector2) -> void:
	_explosions.append({
		"pos": pos,
		"radius": 1.0,
		"expanding": true,
	})
	# Check if click directly hits any target
	for target: Dictionary in _targets:
		if not target["triggered"]:
			var dist: float = (target["pos"] as Vector2).distance_to(pos)
			if dist <= TARGET_RADIUS:
				_trigger_target(target)


func _trigger_target(target: Dictionary) -> void:
	if target["triggered"]:
		return
	target["triggered"] = true
	target["radius"] = 1.0
	_explosions.append({
		"pos": target["pos"],
		"radius": 1.0,
		"expanding": true,
	})
	_score += 1
	_update_score_display()

	if _score >= COMPLETION_TARGET:
		mark_completed(_score)


func _process(delta: float) -> void:
	if not game_active:
		if _round_active:
			play_area.queue_redraw()
		return

	var any_active: bool = false
	for explosion: Dictionary in _explosions:
		if explosion["expanding"]:
			explosion["radius"] = (explosion["radius"] as float) + EXPAND_SPEED * delta
			if (explosion["radius"] as float) >= MAX_EXPAND_RADIUS:
				explosion["expanding"] = false
			else:
				any_active = true

			# Check chain triggers
			for target: Dictionary in _targets:
				if not target["triggered"]:
					var dist: float = (target["pos"] as Vector2).distance_to(explosion["pos"] as Vector2)
					if dist <= (explosion["radius"] as float) + TARGET_RADIUS:
						_trigger_target(target)

	# If all explosions done, spawn new round of targets
	if not any_active and _explosions.size() > 0:
		_explosions.clear()
		_spawn_targets()

	play_area.queue_redraw()


func _on_play_area_draw() -> void:
	# Draw background
	play_area.draw_rect(Rect2(Vector2.ZERO, play_area.size), Color(0.1, 0.12, 0.18))

	# Draw targets
	for target: Dictionary in _targets:
		if not target["triggered"]:
			play_area.draw_circle(target["pos"] as Vector2, TARGET_RADIUS, Color(0.9, 0.3, 0.3))
		else:
			play_area.draw_circle(target["pos"] as Vector2, TARGET_RADIUS, Color(0.3, 0.8, 0.3, 0.4))

	# Draw explosions
	for explosion: Dictionary in _explosions:
		var r: float = explosion["radius"] as float
		var alpha: float = 1.0 - r / MAX_EXPAND_RADIUS
		if alpha > 0.0:
			play_area.draw_circle(explosion["pos"] as Vector2, r, Color(1.0, 0.8, 0.2, alpha * 0.5))
			play_area.draw_arc(explosion["pos"] as Vector2, r, 0.0, TAU, 32, Color(1.0, 0.9, 0.3, alpha), 2.0)


func _update_score_display() -> void:
	score_label.text = "Cleared: " + str(_score) + " / " + str(COMPLETION_TARGET)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
