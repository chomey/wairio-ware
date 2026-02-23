extends Node

## GameManager autoload
## Handles game state, scores, round progression, minigame registry, and scene transitions.
## Server-authoritative: only the server calculates rankings and awards points.

signal round_started(round_number: int, minigame_name: String)
signal round_ended()
signal game_ended()
signal scores_updated()

## Registry of minigames: name -> scene path
var MINIGAME_REGISTRY: Dictionary = {}

## Number of rounds per game
var total_rounds: int = 5

## Current round (1-indexed)
var current_round: int = 0

## Cumulative scores: peer_id -> total points
var cumulative_scores: Dictionary = {}

## Current round raw scores: peer_id -> raw score from minigame
var round_raw_scores: Dictionary = {}

## Current round ranking points: peer_id -> points awarded this round
var round_points: Dictionary = {}

## Order of minigames for this game session (shuffled)
var _minigame_order: Array[String] = []

## Whether a game session is active
var _game_active: bool = false

## Optional forced minigame list (display names). When non-empty, start_game() uses this instead of shuffling.
var forced_minigames: Array[String] = []


func _ready() -> void:
	register_minigame("Button Masher", "res://scenes/minigames/button_masher.tscn")
	register_minigame("Reaction Time", "res://scenes/minigames/reaction_time.tscn")
	register_minigame("Quick Math", "res://scenes/minigames/quick_math.tscn")
	register_minigame("Target Click", "res://scenes/minigames/target_click.tscn")
	register_minigame("Color Match", "res://scenes/minigames/color_match.tscn")
	register_minigame("Memory Sequence", "res://scenes/minigames/memory_sequence.tscn")
	register_minigame("Dodge Falling", "res://scenes/minigames/dodge_falling.tscn")
	register_minigame("Rhythm Tap", "res://scenes/minigames/rhythm_tap.tscn")
	register_minigame("Type Racer", "res://scenes/minigames/type_racer.tscn")
	register_minigame("Arrow Storm", "res://scenes/minigames/arrow_storm.tscn")
	register_minigame("Copy Cat", "res://scenes/minigames/copy_cat.tscn")
	register_minigame("Direction Dash", "res://scenes/minigames/direction_dash.tscn")
	register_minigame("Odd One Out", "res://scenes/minigames/odd_one_out.tscn")
	register_minigame("Number Sort", "res://scenes/minigames/number_sort.tscn")
	register_minigame("Speed Spell", "res://scenes/minigames/speed_spell.tscn")
	register_minigame("Pattern Match", "res://scenes/minigames/pattern_match.tscn")
	register_minigame("Counting", "res://scenes/minigames/counting.tscn")
	register_minigame("Bomb Defuse", "res://scenes/minigames/bomb_defuse.tscn")
	register_minigame("Safe Cracker", "res://scenes/minigames/safe_cracker.tscn")
	register_minigame("Word Scramble", "res://scenes/minigames/word_scramble.tscn")
	register_minigame("Morse Decode", "res://scenes/minigames/morse_decode.tscn")
	register_minigame("Pixel Painter", "res://scenes/minigames/pixel_painter.tscn")
	register_minigame("Rapid Toggle", "res://scenes/minigames/rapid_toggle.tscn")
	register_minigame("Chain Reaction", "res://scenes/minigames/chain_reaction.tscn")
	register_minigame("Shopping Cart", "res://scenes/minigames/shopping_cart.tscn")
	register_minigame("Binary Convert", "res://scenes/minigames/binary_convert.tscn")
	register_minigame("Color Mixer", "res://scenes/minigames/color_mixer.tscn")
	register_minigame("Maze Solver", "res://scenes/minigames/maze_solver.tscn")
	register_minigame("Path Tracer", "res://scenes/minigames/path_tracer.tscn")
	register_minigame("Equation Builder", "res://scenes/minigames/equation_builder.tscn")
	register_minigame("Balancing Act", "res://scenes/minigames/balancing_act.tscn")
	register_minigame("Floor is Lava", "res://scenes/minigames/floor_is_lava.tscn")
	register_minigame("Gravity Flip", "res://scenes/minigames/gravity_flip.tscn")
	register_minigame("Shrinking Arena", "res://scenes/minigames/shrinking_arena.tscn")
	register_minigame("Hot Potato", "res://scenes/minigames/hot_potato.tscn")
	register_minigame("Tightrope Walk", "res://scenes/minigames/tightrope_walk.tscn")
	register_minigame("Rising Water", "res://scenes/minigames/rising_water.tscn")
	register_minigame("Minefield", "res://scenes/minigames/minefield.tscn")
	register_minigame("Asteroid Dodge", "res://scenes/minigames/asteroid_dodge.tscn")
	register_minigame("Conveyor Chaos", "res://scenes/minigames/conveyor_chaos.tscn")
	register_minigame("Laser Dodge", "res://scenes/minigames/laser_dodge.tscn")
	register_minigame("Simon Says", "res://scenes/minigames/simon_says.tscn")
	register_minigame("Whack-a-Mole", "res://scenes/minigames/whack_a_mole.tscn")
	register_minigame("Fruit Catcher", "res://scenes/minigames/fruit_catcher.tscn")
	register_minigame("Treasure Dig", "res://scenes/minigames/treasure_dig.tscn")
	register_minigame("Light Switch", "res://scenes/minigames/light_switch.tscn")
	register_minigame("Ice Breaker", "res://scenes/minigames/ice_breaker.tscn")
	register_minigame("Bubble Pop", "res://scenes/minigames/bubble_pop.tscn")
	register_minigame("Mirror Draw", "res://scenes/minigames/mirror_draw.tscn")
	register_minigame("Rotation Lock", "res://scenes/minigames/rotation_lock.tscn")
	register_minigame("Word Chain", "res://scenes/minigames/word_chain.tscn")
	register_minigame("Number Crunch", "res://scenes/minigames/number_crunch.tscn")
	register_minigame("Pipe Connect", "res://scenes/minigames/pipe_connect.tscn")
	register_minigame("Falling Letters", "res://scenes/minigames/falling_letters.tscn")
	register_minigame("Color Flood", "res://scenes/minigames/color_flood.tscn")
	register_minigame("Spot the Diff", "res://scenes/minigames/spot_the_diff.tscn")
	register_minigame("Conveyor Sort", "res://scenes/minigames/conveyor_sort.tscn")
	register_minigame("Hex Match", "res://scenes/minigames/hex_match.tscn")
	register_minigame("Countdown Catch", "res://scenes/minigames/countdown_catch.tscn")
	register_minigame("Signal Flag", "res://scenes/minigames/signal_flag.tscn")
	register_minigame("Speed Clicker", "res://scenes/minigames/speed_clicker.tscn")
	register_minigame("Digit Span", "res://scenes/minigames/digit_span.tscn")
	register_minigame("Block Breaker", "res://scenes/minigames/block_breaker.tscn")
	register_minigame("Tug of War", "res://scenes/minigames/tug_of_war.tscn")
	register_minigame("Anagram Solve", "res://scenes/minigames/anagram_solve.tscn")
	register_minigame("Math Sign", "res://scenes/minigames/math_sign.tscn")
	register_minigame("Photo Memory", "res://scenes/minigames/photo_memory.tscn")
	register_minigame("Greater Than", "res://scenes/minigames/greater_than.tscn")
	register_minigame("Shadow Match", "res://scenes/minigames/shadow_match.tscn")
	register_minigame("Stack Tower", "res://scenes/minigames/stack_tower.tscn")
	register_minigame("Cliff Hanger", "res://scenes/minigames/cliff_hanger.tscn")
	register_minigame("Voltage Surge", "res://scenes/minigames/voltage_surge.tscn")
	register_minigame("Wrecking Ball", "res://scenes/minigames/wrecking_ball.tscn")
	register_minigame("Gravity Well", "res://scenes/minigames/gravity_well.tscn")
	register_minigame("Thermal Rise", "res://scenes/minigames/thermal_rise.tscn")
	register_minigame("Rail Grind", "res://scenes/minigames/rail_grind.tscn")
	register_minigame("Wind Runner", "res://scenes/minigames/wind_runner.tscn")
	register_minigame("Pinball Bounce", "res://scenes/minigames/pinball_bounce.tscn")


## Start a new game session. Called by host only.
func start_game() -> void:
	if not multiplayer.is_server():
		return

	current_round = 0
	cumulative_scores.clear()
	round_raw_scores.clear()
	round_points.clear()
	_game_active = true

	# Initialize scores for all connected players
	for peer_id: int in NetworkManager.players:
		cumulative_scores[peer_id] = 0

	# Build minigame order: use forced list if provided, otherwise shuffle
	_minigame_order.clear()
	if forced_minigames.size() > 0:
		for mg_name: String in forced_minigames:
			_minigame_order.append(mg_name)
		total_rounds = _minigame_order.size()
	else:
		var available: Array = MINIGAME_REGISTRY.keys()
		available.shuffle()
		# If we have fewer minigames than rounds, cycle through them
		while _minigame_order.size() < total_rounds:
			for mg_name: String in available:
				_minigame_order.append(mg_name)
				if _minigame_order.size() >= total_rounds:
					break

	# Tell all clients to start and advance to first round
	_sync_game_start.rpc(total_rounds, _minigame_order)
	advance_round()


## Advance to the next round. Called by host only.
func advance_round() -> void:
	if not multiplayer.is_server():
		return

	current_round += 1

	if current_round > total_rounds:
		_end_game()
		return

	round_raw_scores.clear()
	round_points.clear()

	var minigame_name: String = _minigame_order[current_round - 1]
	var scene_path: String = MINIGAME_REGISTRY[minigame_name]

	_load_minigame.rpc(current_round, minigame_name, scene_path)


## Called by MiniGameBase when a player submits their score
func submit_player_score(peer_id: int, raw_score: int) -> void:
	if not multiplayer.is_server():
		return

	round_raw_scores[peer_id] = raw_score

	var total_players: int = cumulative_scores.size()
	var submitted_count: int = round_raw_scores.size()

	# Check if all players have submitted
	if submitted_count >= total_players:
		_calculate_round_results()
		return

	# Check if N-1 players have submitted -> force end for remaining player(s)
	if submitted_count >= total_players - 1 and total_players >= 2:
		_force_minigame_end()


## Force end the current minigame for all peers.
## Called when N-1 players have submitted scores.
func _force_minigame_end() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene is MiniGameBase:
		current_scene.force_end_game.rpc()


## Calculate rankings and award points. Server only.
func _calculate_round_results() -> void:
	var player_count: int = cumulative_scores.size()
	round_points.clear()

	# Sort players by raw score descending
	var sorted_players: Array = round_raw_scores.keys()
	sorted_players.sort_custom(func(a: int, b: int) -> bool:
		return round_raw_scores[a] > round_raw_scores[b]
	)

	# Award points: 1st = N pts, 2nd = N-1, etc. Ties share higher value.
	var rank: int = 1
	var i: int = 0
	while i < sorted_players.size():
		# Find all players tied at this score
		var tie_group: Array[int] = [sorted_players[i]]
		var current_score: int = round_raw_scores[sorted_players[i]]
		var j: int = i + 1
		while j < sorted_players.size() and round_raw_scores[sorted_players[j]] == current_score:
			tie_group.append(sorted_players[j])
			j += 1

		# All tied players get points for the highest rank in the group
		var points: int = player_count - rank + 1
		for pid: int in tie_group:
			round_points[pid] = points
			cumulative_scores[pid] += points

		rank += tie_group.size()
		i = j

	# Send results to all clients
	_sync_round_results.rpc(round_raw_scores, round_points, cumulative_scores)

	# Transition to scoreboard
	_load_scoreboard.rpc()


## End the game. Server only.
func _end_game() -> void:
	_game_active = false
	_load_end_game.rpc()


## Register a minigame in the registry
func register_minigame(minigame_name: String, scene_path: String) -> void:
	MINIGAME_REGISTRY[minigame_name] = scene_path


## Get the winner(s) - players with highest cumulative score
func get_winners() -> Array[int]:
	var max_score: int = 0
	for pid: int in cumulative_scores:
		var score: int = cumulative_scores[pid] as int
		if score > max_score:
			max_score = score

	var winners: Array[int] = []
	for pid: int in cumulative_scores:
		var score: int = cumulative_scores[pid] as int
		if score == max_score:
			winners.append(pid)
	return winners


## Check if the game is still active
func is_game_active() -> bool:
	return _game_active


# ---- RPCs ----

@rpc("authority", "reliable")
func _sync_game_start(rounds: int, minigame_order: Array) -> void:
	total_rounds = rounds
	_minigame_order.clear()
	for name: String in minigame_order:
		_minigame_order.append(name)
	current_round = 0
	cumulative_scores.clear()
	round_raw_scores.clear()
	round_points.clear()
	_game_active = true

	# Initialize scores for all connected players
	for peer_id: int in NetworkManager.players:
		cumulative_scores[peer_id] = 0


@rpc("authority", "call_local", "reliable")
func _load_minigame(round_number: int, minigame_name: String, scene_path: String) -> void:
	current_round = round_number
	round_raw_scores.clear()
	round_points.clear()
	round_started.emit(round_number, minigame_name)
	get_tree().change_scene_to_file(scene_path)


@rpc("authority", "call_local", "reliable")
func _sync_round_results(raw_scores: Dictionary, points: Dictionary, cumulative: Dictionary) -> void:
	round_raw_scores = raw_scores
	round_points = points
	cumulative_scores = cumulative
	round_ended.emit()
	scores_updated.emit()


@rpc("authority", "call_local", "reliable")
func _load_scoreboard() -> void:
	get_tree().change_scene_to_file("res://scenes/scoreboard.tscn")


@rpc("authority", "call_local", "reliable")
func _load_end_game() -> void:
	_game_active = false
	game_ended.emit()
	get_tree().change_scene_to_file("res://scenes/end_game.tscn")


## Return to main menu (can be called by any peer locally)
func return_to_menu() -> void:
	_game_active = false
	current_round = 0
	cumulative_scores.clear()
	round_raw_scores.clear()
	round_points.clear()
	_minigame_order.clear()
	forced_minigames.clear()
	NetworkManager.disconnect_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
