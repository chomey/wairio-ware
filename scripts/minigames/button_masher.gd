extends MiniGameBase

## Button Masher minigame.
## Players mash the spacebar as fast as possible during 10 seconds.
## Score = total number of presses.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var press_count_label: Label = %PressCountLabel
@onready var instruction_label: Label = %InstructionLabel

var _press_count: int = 0


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	_update_press_display()
	instruction_label.text = "Get ready..."


func _unhandled_input(event: InputEvent) -> void:
	if not game_active:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
			_press_count += 1
			_update_press_display()


func _on_game_start() -> void:
	_press_count = 0
	_update_press_display()
	instruction_label.text = "MASH SPACEBAR!"
	countdown_label.visible = false


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_press_count)


func _update_press_display() -> void:
	press_count_label.text = str(_press_count)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
