extends Control

@onready var title_label: Label = $CenterContainer/VBoxContainer/Title
@onready var winner_label: Label = $CenterContainer/VBoxContainer/WinnerLabel
@onready var scoreboard: Label = $CenterContainer/VBoxContainer/Scoreboard
@onready var return_button: Button = $CenterContainer/VBoxContainer/ReturnButton


func _ready() -> void:
	# Only host sees the return button; host triggers return for everyone
	return_button.visible = multiplayer.is_server()
	_display_results()


func _display_results() -> void:
	var scores: Dictionary = GameManager.get_scores()
	if scores.is_empty():
		winner_label.text = "No players found."
		scoreboard.text = ""
		return

	# Sort players by score descending
	var sorted_players: Array = []
	for id: int in scores:
		sorted_players.append({"id": id, "name": scores[id]["name"], "score": scores[id]["score"]})
	sorted_players.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])

	# Determine winner (handle ties)
	var top_score: int = sorted_players[0]["score"]
	var winners: Array[String] = []
	for entry: Dictionary in sorted_players:
		if entry["score"] == top_score:
			winners.append(entry["name"])

	if winners.size() == 1:
		winner_label.text = "%s wins!" % winners[0]
	else:
		winner_label.text = "Tie: %s!" % " & ".join(winners)

	# Build scoreboard text
	var text: String = ""
	var rank: int = 1
	for entry: Dictionary in sorted_players:
		text += "#%d  %s — %d pts\n" % [rank, entry["name"], entry["score"]]
		rank += 1
	scoreboard.text = text


func _on_return_button_pressed() -> void:
	if not multiplayer.is_server():
		return
	_return_to_lobby.rpc()


@rpc("authority", "call_local", "reliable")
func _return_to_lobby() -> void:
	GameManager.reset_scores()
	get_tree().change_scene_to_file("res://scenes/waiting_room.tscn")


func _test_feature() -> void:
	# Set up test data
	GameManager.players.clear()
	GameManager.add_player(1, "Alice")
	GameManager.add_player(2, "Bob")
	GameManager.add_player(3, "Charlie")
	GameManager.add_score(1, 90)
	GameManager.add_score(2, 100)
	GameManager.add_score(3, 75)

	_display_results()

	# Bob should be the winner with 100 pts
	assert(winner_label.text == "Bob wins!", "Winner should be Bob, got: %s" % winner_label.text)

	# Scoreboard should list Bob first
	assert(scoreboard.text.begins_with("#1  Bob"), "First place should be Bob, got: %s" % scoreboard.text)
	assert(scoreboard.text.contains("Alice"), "Scoreboard should contain Alice")
	assert(scoreboard.text.contains("Charlie"), "Scoreboard should contain Charlie")

	# Test tie scenario
	GameManager.players.clear()
	GameManager.add_player(1, "Alice")
	GameManager.add_player(2, "Bob")
	GameManager.add_score(1, 80)
	GameManager.add_score(2, 80)

	_display_results()
	assert(winner_label.text.contains("Tie"), "Should show tie, got: %s" % winner_label.text)

	# Clean up
	GameManager.players.clear()
	GameManager.players_changed.emit()
	print("EndGame._test_feature(): All assertions passed!")
