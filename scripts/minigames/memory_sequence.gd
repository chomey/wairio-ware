extends MiniGameBase

## Memory Sequence minigame.
## Colored panels flash in a sequence. Player must repeat the sequence
## by clicking panels in the correct order. Each success adds one more
## to the sequence. Score = longest sequence completed within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var panel_0: Button = %Panel0
@onready var panel_1: Button = %Panel1
@onready var panel_2: Button = %Panel2
@onready var panel_3: Button = %Panel3

var _score: int = 0
var _sequence: Array[int] = []
var _player_index: int = 0
var _showing_sequence: bool = false
var _show_step: int = 0
var _panels: Array[Button] = []

const PANEL_COLORS: Array[Color] = [
	Color(0.8, 0.2, 0.2),  # Red
	Color(0.2, 0.6, 0.2),  # Green
	Color(0.2, 0.3, 0.8),  # Blue
	Color(0.8, 0.7, 0.1),  # Yellow
]

const PANEL_DIM_COLORS: Array[Color] = [
	Color(0.4, 0.1, 0.1),  # Dim Red
	Color(0.1, 0.3, 0.1),  # Dim Green
	Color(0.1, 0.15, 0.4), # Dim Blue
	Color(0.4, 0.35, 0.05),# Dim Yellow
]

var _flash_timer: Timer = null
var _pause_timer: Timer = null


func _ready() -> void:
	super._ready()
	_panels = [panel_0, panel_1, panel_2, panel_3]

	for i: int in range(4):
		var idx: int = i
		_panels[i].pressed.connect(func() -> void: _on_panel_pressed(idx))
		_set_panel_dim(i)

	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)

	_flash_timer = Timer.new()
	_flash_timer.wait_time = 0.5
	_flash_timer.one_shot = true
	_flash_timer.timeout.connect(_on_flash_timer_timeout)
	add_child(_flash_timer)

	_pause_timer = Timer.new()
	_pause_timer.wait_time = 0.3
	_pause_timer.one_shot = true
	_pause_timer.timeout.connect(_on_pause_timer_timeout)
	add_child(_pause_timer)

	_set_panels_disabled(true)
	_update_score_display()
	instruction_label.text = "Get ready..."


func _on_game_start() -> void:
	_score = 0
	_sequence.clear()
	_player_index = 0
	_update_score_display()
	countdown_label.visible = false
	_add_to_sequence_and_show()


func _on_game_end() -> void:
	instruction_label.text = "Time's up! Sequence length: " + str(_score)
	_set_panels_disabled(true)
	_showing_sequence = false
	submit_score(_score)


func _add_to_sequence_and_show() -> void:
	_sequence.append(randi() % 4)
	_player_index = 0
	_showing_sequence = true
	_show_step = 0
	_set_panels_disabled(true)
	instruction_label.text = "Watch the sequence..."
	_dim_all_panels()
	# Small pause before showing
	_pause_timer.wait_time = 0.5
	_pause_timer.start()


func _on_pause_timer_timeout() -> void:
	if not game_active:
		return
	if _showing_sequence:
		_show_next_in_sequence()


func _show_next_in_sequence() -> void:
	if not game_active:
		return
	if _show_step >= _sequence.size():
		# Done showing - player's turn
		_showing_sequence = false
		_set_panels_disabled(false)
		instruction_label.text = "Your turn! Repeat the sequence."
		return

	var panel_idx: int = _sequence[_show_step]
	_set_panel_lit(panel_idx)
	_flash_timer.start()


func _on_flash_timer_timeout() -> void:
	if not game_active:
		return
	# Dim the panel that was lit
	if _show_step < _sequence.size():
		var panel_idx: int = _sequence[_show_step]
		_set_panel_dim(panel_idx)
	_show_step += 1
	# Brief pause between flashes
	_pause_timer.wait_time = 0.2
	_pause_timer.start()


func _on_panel_pressed(panel_idx: int) -> void:
	if not game_active or _showing_sequence:
		return

	# Flash the pressed panel briefly
	_set_panel_lit(panel_idx)
	await get_tree().create_timer(0.15).timeout
	if is_inside_tree():
		_set_panel_dim(panel_idx)

	if panel_idx == _sequence[_player_index]:
		_player_index += 1
		if _player_index >= _sequence.size():
			# Completed the sequence
			_score = _sequence.size()
			_update_score_display()
			instruction_label.text = "Correct! Length: " + str(_score)
			_set_panels_disabled(true)
			# Add next item after a brief pause
			await get_tree().create_timer(0.5).timeout
			if game_active and is_inside_tree():
				_add_to_sequence_and_show()
	else:
		# Wrong panel - restart with new sequence
		instruction_label.text = "Wrong! Starting over..."
		_set_panels_disabled(true)
		_sequence.clear()
		await get_tree().create_timer(0.7).timeout
		if game_active and is_inside_tree():
			_add_to_sequence_and_show()


func _set_panel_lit(idx: int) -> void:
	_panels[idx].add_theme_color_override("font_color", Color.WHITE)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_COLORS[idx]
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_panels[idx].add_theme_stylebox_override("normal", style)
	_panels[idx].add_theme_stylebox_override("hover", style)
	_panels[idx].add_theme_stylebox_override("pressed", style)


func _set_panel_dim(idx: int) -> void:
	_panels[idx].add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_DIM_COLORS[idx]
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_panels[idx].add_theme_stylebox_override("normal", style)
	_panels[idx].add_theme_stylebox_override("hover", style)
	_panels[idx].add_theme_stylebox_override("pressed", style)


func _dim_all_panels() -> void:
	for i: int in range(4):
		_set_panel_dim(i)


func _set_panels_disabled(disabled: bool) -> void:
	for panel: Button in _panels:
		panel.disabled = disabled


func _update_score_display() -> void:
	score_label.text = "Score: " + str(_score)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
