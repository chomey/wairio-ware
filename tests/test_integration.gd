extends Node

## Integration test autoload.
## Does nothing unless launched with: -- --test-host or -- --test-client
## Automates the full game flow: host/join -> lobby (auto-start) -> minigames -> scoreboard (auto-advance) -> end_game.

const TEST_PORT: int = 19876
const TEST_ROUNDS: int = 2
const HOST_LOG: String = "res://test_host.log"
const CLIENT_LOG: String = "res://test_client.log"

var _active: bool = false
var _is_host: bool = false
var _log_path: String = ""
var _last_scene_name: String = ""
var _startup_timer: float = 0.0
var _scene_timer: float = 0.0
var _test_done: bool = false
var _timeout: float = 180.0
var _elapsed: float = 0.0

## Minigame input simulation state
var _minigame_action_timer: float = 0.0
var _sim_started: bool = false
var _dodge_moving_left: bool = true
var _dodge_toggle_timer: float = 0.0
var _rhythm_cooldown: float = 0.0
var _reaction_wait_timer: float = 0.0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for arg: String in args:
		if arg == "--test-host":
			_active = true
			_is_host = true
		elif arg == "--test-client":
			_active = true
			_is_host = false

	if not _active:
		return

	_log_path = HOST_LOG if _is_host else CLIENT_LOG
	_clear_log()
	_log("Test started: " + ("HOST" if _is_host else "CLIENT"))
	_log("PID: " + str(OS.get_process_id()))

	# Override total rounds for faster testing
	GameManager.total_rounds = TEST_ROUNDS

	# Connect to player registry changes
	NetworkManager.player_connected.connect(_on_player_connected)

	# Defer the network setup to ensure main scene is loaded
	call_deferred("_setup_network")


func _setup_network() -> void:
	if _is_host:
		var error: Error = NetworkManager.host_game("TestHost", TEST_PORT)
		if error != OK:
			_log("FAIL: Could not host game: " + error_string(error))
			_exit_fail()
			return
		_log("Hosted game on port " + str(TEST_PORT))
		# Transition to lobby just like main_menu.gd does after hosting
		get_tree().change_scene_to_file("res://scenes/lobby.tscn")
	else:
		# Client waits a moment for host to be ready
		_startup_timer = 1.0


func _on_player_connected(peer_id: int, player_name: String) -> void:
	_log("Player connected: " + player_name + " (id=" + str(peer_id) + ")")


func _process(delta: float) -> void:
	if not _active or _test_done:
		return

	_elapsed += delta
	if _elapsed > _timeout:
		_log("FAIL: Test timed out after " + str(_timeout) + "s")
		_exit_fail()
		return

	# Handle client startup delay
	if not _is_host and _startup_timer > 0.0:
		_startup_timer -= delta
		if _startup_timer <= 0.0:
			_try_join()
		return

	# Detect scene changes and automate actions
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return

	var scene_name: String = current_scene.name
	if scene_name != _last_scene_name:
		_last_scene_name = scene_name
		_scene_timer = 0.0
		_minigame_action_timer = 0.0
		_sim_started = false
		_dodge_toggle_timer = 0.0
		_rhythm_cooldown = 0.0
		_reaction_wait_timer = 0.0
		Input.action_release("ui_left")
		Input.action_release("ui_right")
		_log("Scene changed to: " + scene_name)

	_scene_timer += delta

	# Handle each scene
	if scene_name == "MainMenu":
		pass
	elif scene_name == "Lobby":
		_handle_lobby(delta)
	elif scene_name == "Scoreboard":
		_handle_scoreboard(delta)
	elif scene_name == "EndGame":
		_handle_end_game(delta)
	else:
		_handle_minigame(delta, current_scene)


func _try_join() -> void:
	_log("Attempting to join localhost:" + str(TEST_PORT))
	var error: Error = NetworkManager.join_game("TestClient", "127.0.0.1", TEST_PORT)
	if error != OK:
		_log("FAIL: Could not join game: " + error_string(error))
		_exit_fail()
		return
	_log("Join request sent")
	# Wait for connection_succeeded to trigger scene change to lobby
	NetworkManager.connection_succeeded.connect(_on_client_connected)
	NetworkManager.connection_failed.connect(_on_client_connection_failed)


func _on_client_connected() -> void:
	_log("Connected to host, transitioning to lobby")
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")


func _on_client_connection_failed() -> void:
	_log("FAIL: Connection to host failed")
	_exit_fail()


func _handle_lobby(_delta: float) -> void:
	# Auto-start is handled by lobby.gd itself
	pass


func _handle_scoreboard(_delta: float) -> void:
	# Auto-advance is handled by scoreboard.gd itself, just log
	if _is_host and _scene_timer < 0.1:
		_log("Scoreboard shown, waiting for auto-advance (round " + str(GameManager.current_round) + "/" + str(GameManager.total_rounds) + ")")


func _handle_end_game(_delta: float) -> void:
	if _scene_timer > 1.0 and not _test_done:
		_test_done = true
		_log("Reached EndGame screen!")
		_log("Final scores: " + str(GameManager.cumulative_scores))
		var winners: Array[int] = GameManager.get_winners()
		_log("Winners: " + str(winners))

		# Validate test results
		var pass_count: int = 0
		var fail_count: int = 0

		# Check 1: cumulative_scores should have 2 players
		if GameManager.cumulative_scores.size() == 2:
			_log("CHECK PASS: 2 players in final scores")
			pass_count += 1
		else:
			_log("CHECK FAIL: Expected 2 players, got " + str(GameManager.cumulative_scores.size()))
			fail_count += 1

		# Check 2: all scores should be > 0
		var all_positive: bool = true
		for pid: int in GameManager.cumulative_scores:
			var score: int = GameManager.cumulative_scores[pid] as int
			if score <= 0:
				all_positive = false
				_log("CHECK FAIL: Player " + str(pid) + " has score " + str(score))
				fail_count += 1
		if all_positive:
			_log("CHECK PASS: All players have positive scores")
			pass_count += 1

		# Check 3: winners should not be empty
		if winners.size() > 0:
			_log("CHECK PASS: Winners determined")
			pass_count += 1
		else:
			_log("CHECK FAIL: No winners")
			fail_count += 1

		# Check 4: completed correct number of rounds
		# Server increments current_round past total_rounds before calling _end_game,
		# but clients only see current_round == total_rounds (set by last _load_minigame RPC).
		if GameManager.current_round >= GameManager.total_rounds:
			_log("CHECK PASS: Completed all " + str(GameManager.total_rounds) + " rounds (current_round=" + str(GameManager.current_round) + ")")
			pass_count += 1
		else:
			_log("CHECK FAIL: Only completed " + str(GameManager.current_round) + " of " + str(GameManager.total_rounds) + " rounds")
			fail_count += 1

		_log("Results: " + str(pass_count) + " passed, " + str(fail_count) + " failed")
		if fail_count == 0:
			_log("TEST PASSED")
			_exit_pass()
		else:
			_log("TEST FAILED")
			_exit_fail()


## ---- Minigame Input Simulation ----

func _handle_minigame(delta: float, current_scene: Node) -> void:
	if not current_scene is MiniGameBase:
		return
	if not current_scene.game_active:
		return

	if not _sim_started:
		_sim_started = true
		_log("Simulating input for: " + current_scene.name)

	var sn: String = current_scene.name
	if sn == "ButtonMasher":
		_sim_button_masher(delta)
	elif sn == "ReactionTime":
		_sim_reaction_time(delta, current_scene)
	elif sn == "QuickMath":
		_sim_quick_math(delta, current_scene)
	elif sn == "TargetClick":
		_sim_target_click(delta, current_scene)
	elif sn == "ColorMatch":
		_sim_color_match(delta, current_scene)
	elif sn == "MemorySequence":
		_sim_memory_sequence(delta, current_scene)
	elif sn == "DodgeFalling":
		_sim_dodge_falling(delta)
	elif sn == "RhythmTap":
		_sim_rhythm_tap(delta, current_scene)


func _sim_spacebar_press() -> void:
	var down: InputEventKey = InputEventKey.new()
	down.keycode = KEY_SPACE
	down.pressed = true
	down.echo = false
	Input.parse_input_event(down)
	var up: InputEventKey = InputEventKey.new()
	up.keycode = KEY_SPACE
	up.pressed = false
	up.echo = false
	Input.parse_input_event(up)


func _sim_button_masher(delta: float) -> void:
	_minigame_action_timer += delta
	if _minigame_action_timer >= 0.15:
		_minigame_action_timer = 0.0
		_sim_spacebar_press()


func _sim_reaction_time(delta: float, scene: Node) -> void:
	# Wait for signal to show, then wait a tiny bit and press
	if scene._has_reacted or scene._false_start:
		return
	if scene._signal_shown:
		_reaction_wait_timer += delta
		if _reaction_wait_timer >= 0.1:
			_reaction_wait_timer = 0.0
			_sim_spacebar_press()
	else:
		_reaction_wait_timer = 0.0


func _sim_quick_math(delta: float, scene: Node) -> void:
	_minigame_action_timer += delta
	if _minigame_action_timer >= 0.3:
		_minigame_action_timer = 0.0
		var input: LineEdit = scene.answer_input
		input.text = str(scene._correct_answer)
		input.text_submitted.emit(input.text)


func _sim_target_click(delta: float, scene: Node) -> void:
	_minigame_action_timer += delta
	if _minigame_action_timer >= 0.2:
		_minigame_action_timer = 0.0
		scene.target_button.pressed.emit()


func _sim_color_match(delta: float, scene: Node) -> void:
	_minigame_action_timer += delta
	if _minigame_action_timer >= 0.3:
		_minigame_action_timer = 0.0
		if scene._current_is_match:
			scene.match_button.pressed.emit()
		else:
			scene.no_match_button.pressed.emit()


func _sim_memory_sequence(delta: float, scene: Node) -> void:
	if scene._showing_sequence:
		return
	_minigame_action_timer += delta
	if _minigame_action_timer >= 0.3:
		_minigame_action_timer = 0.0
		if scene._player_index < scene._sequence.size():
			var panel_idx: int = scene._sequence[scene._player_index]
			if panel_idx < scene._panels.size():
				scene._panels[panel_idx].pressed.emit()


func _sim_dodge_falling(delta: float) -> void:
	_dodge_toggle_timer += delta
	if _dodge_toggle_timer >= 1.0:
		_dodge_toggle_timer = 0.0
		if _dodge_moving_left:
			Input.action_release("ui_left")
			Input.action_press("ui_right")
		else:
			Input.action_release("ui_right")
			Input.action_press("ui_left")
		_dodge_moving_left = not _dodge_moving_left


func _sim_rhythm_tap(delta: float, scene: Node) -> void:
	_rhythm_cooldown -= delta
	if _rhythm_cooldown > 0.0:
		return
	if scene._active_beats.is_empty():
		return
	# Find closest beat to current elapsed time
	var best_diff: float = 999.0
	for beat_time: float in scene._active_beats:
		var diff: float = absf(beat_time - scene._elapsed)
		if diff < best_diff:
			best_diff = diff
	# Press when within the good window
	if best_diff <= 0.15:
		_sim_spacebar_press()
		_rhythm_cooldown = 0.3


func _clear_log() -> void:
	var file: FileAccess = FileAccess.open(_log_path, FileAccess.WRITE)
	if file != null:
		file.store_string("")
		file.close()


func _log(message: String) -> void:
	var timestamp: String = "%.3f" % _elapsed
	var line: String = "[" + timestamp + "] " + message
	print(("HOST" if _is_host else "CLIENT") + ": " + line)
	var file: FileAccess = FileAccess.open(_log_path, FileAccess.WRITE_READ)
	if file != null:
		file.seek_end()
		file.store_line(line)
		file.close()


func _exit_pass() -> void:
	_log("Exiting with code 0")
	# Give a moment for logs to flush
	await get_tree().create_timer(0.5).timeout
	get_tree().quit(0)


func _exit_fail() -> void:
	_log("Exiting with code 1")
	await get_tree().create_timer(0.5).timeout
	get_tree().quit(1)
