extends Control

@onready var title_label: Label = $CenterContainer/VBoxContainer/Title
@onready var instructions_label: Label = $CenterContainer/VBoxContainer/Instructions
@onready var target_label: Label = $CenterContainer/VBoxContainer/TargetLabel
@onready var timer_display: Label = $CenterContainer/VBoxContainer/TimerDisplay
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var result_label: Label = $CenterContainer/VBoxContainer/ResultLabel

enum GameState { WAITING, COUNTDOWN, PLAYING, FINISHED }

var state: GameState = GameState.WAITING
var target_time: float = 0.0
var hold_time: float = 0.0
var is_holding: bool = false

# Server collects results: peer_id -> hold_time
var player_results: Dictionary = {}
var results_received: int = 0


func _ready() -> void:
	result_label.visible = false
	timer_display.text = "0.00s"
	status_label.text = "Waiting for game to start..."

	if multiplayer.is_server():
		# Server picks a random target between 3 and 10 seconds
		target_time = snappedf(randf_range(3.0, 10.0), 0.1)
		# Small delay so all clients are ready, then broadcast target
		await get_tree().create_timer(0.5).timeout
		_start_round.rpc(target_time)


func _process(delta: float) -> void:
	if state == GameState.PLAYING and is_holding:
		hold_time += delta
		timer_display.text = "%.2fs" % hold_time


func _input(event: InputEvent) -> void:
	if state != GameState.PLAYING:
		return

	if event is InputEventKey and event.keycode == KEY_SPACE:
		if event.pressed and not is_holding:
			is_holding = true
			hold_time = 0.0
			status_label.text = "Holding... release when you think it's time!"
		elif not event.pressed and is_holding:
			is_holding = false
			state = GameState.FINISHED
			status_label.text = "Released! Waiting for results..."
			timer_display.text = "%.2fs" % hold_time
			# Send result to server
			_submit_result.rpc_id(1, hold_time)


@rpc("authority", "call_local", "reliable")
func _start_round(t_time: float) -> void:
	target_time = t_time
	target_label.text = "Target: %.1fs" % target_time
	instructions_label.text = "Hold SPACE for exactly %.1f seconds!" % target_time
	status_label.text = "Press and hold SPACE to start!"
	timer_display.text = "0.00s"
	hold_time = 0.0
	is_holding = false
	result_label.visible = false
	state = GameState.PLAYING


@rpc("any_peer", "reliable")
func _submit_result(actual_time: float) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1  # Local server call
	player_results[sender_id] = actual_time
	results_received += 1

	# Check if all players have submitted
	if results_received >= GameManager.players.size():
		_calculate_and_broadcast_scores()


func _calculate_and_broadcast_scores() -> void:
	var score_data: Dictionary = {}  # id -> { score, actual_time }
	for id: int in player_results:
		var actual: float = player_results[id]
		var score: int = _calculate_score(target_time, actual)
		GameManager.add_score(id, score)
		score_data[id] = {"score": score, "actual_time": actual}

	_show_results.rpc(score_data, target_time)


static func _calculate_score(target: float, actual: float) -> int:
	var diff: float = absf(target - actual)
	# 100 points max, lose 10 points per second of difference, min 0
	return clampi(roundi(100.0 - diff * 10.0), 0, 100)


@rpc("authority", "call_local", "reliable")
func _show_results(score_data: Dictionary, t_time: float) -> void:
	state = GameState.FINISHED
	result_label.visible = true
	status_label.text = "Round complete!"

	var text: String = ""
	for id: int in score_data:
		var pname: String = GameManager.get_player_name(id)
		var actual: float = score_data[id]["actual_time"]
		var score: int = score_data[id]["score"]
		var diff: float = absf(t_time - actual)
		text += "%s: %.2fs (off by %.2fs) — %d pts\n" % [pname, actual, diff, score]

	result_label.text = text

	# After 4 seconds, go to end game screen
	await get_tree().create_timer(4.0).timeout
	if multiplayer.is_server():
		_go_to_end_game.rpc()


@rpc("authority", "call_local", "reliable")
func _go_to_end_game() -> void:
	get_tree().change_scene_to_file("res://scenes/end_game.tscn")


func _test_feature() -> void:
	# Test score calculation
	var score_perfect: int = _calculate_score(5.0, 5.0)
	assert(score_perfect == 100, "Perfect score should be 100, got %d" % score_perfect)

	var score_1s_off: int = _calculate_score(5.0, 6.0)
	assert(score_1s_off == 90, "1s off should be 90, got %d" % score_1s_off)

	var score_5s_off: int = _calculate_score(5.0, 10.0)
	assert(score_5s_off == 50, "5s off should be 50, got %d" % score_5s_off)

	var score_10s_off: int = _calculate_score(5.0, 15.0)
	assert(score_10s_off == 0, "10s+ off should be 0, got %d" % score_10s_off)

	# Test initial UI state
	assert(result_label.visible == false, "Result label should start hidden")
	assert(state == GameState.WAITING, "State should start as WAITING")

	# Simulate a round start
	_start_round(5.0)
	assert(state == GameState.PLAYING, "State should be PLAYING after round start")
	assert(target_time == 5.0, "Target time should be 5.0")
	assert(target_label.text == "Target: 5.0s", "Target label should show 5.0s")

	print("TimerGame._test_feature(): All assertions passed!")
