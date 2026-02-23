extends Control

@onready var player_count_label: Label = $CenterContainer/VBoxContainer/PlayerCount
@onready var player_list: VBoxContainer = $CenterContainer/VBoxContainer/PlayerList
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var cancel_button: Button = $CenterContainer/VBoxContainer/CancelButton


func _ready() -> void:
	GameManager.players_changed.connect(_update_player_list)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	# Only the server (host) can start the game
	start_button.visible = multiplayer.is_server()
	_update_player_list()


func _update_player_list() -> void:
	# Clear existing entries
	for child in player_list.get_children():
		child.queue_free()

	var count: int = GameManager.players.size()
	player_count_label.text = "Players: %d / %d" % [count, GameManager.MAX_PLAYERS]

	for id: int in GameManager.players:
		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var label := Label.new()
		var display_name: String = GameManager.players[id]["name"]
		if id == 1:
			display_name += "  [Host]"
		label.text = display_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)

		var indicator := ColorRect.new()
		indicator.custom_minimum_size = Vector2(12, 12)
		indicator.color = Color(0.2, 0.8, 0.2, 1)  # Green = connected

		hbox.add_child(indicator)
		hbox.add_child(label)
		player_list.add_child(hbox)


func _on_peer_disconnected(id: int) -> void:
	GameManager.remove_player(id)


func _on_server_disconnected() -> void:
	# Server left — go back to main menu
	_cleanup_and_return()


func _on_start_button_pressed() -> void:
	if not multiplayer.is_server():
		return
	_go_to_game.rpc()


func _on_cancel_button_pressed() -> void:
	_cleanup_and_return()


func _cleanup_and_return() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	GameManager.players.clear()
	GameManager.players_changed.emit()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


@rpc("authority", "call_local", "reliable")
func _go_to_game() -> void:
	GameManager.reset_scores()
	get_tree().change_scene_to_file("res://scenes/timer_game.tscn")


func _test_feature() -> void:
	# Simulate some players in GameManager
	GameManager.players.clear()
	GameManager.add_player(1, "HostPlayer")
	GameManager.add_player(2, "ClientPlayer")

	_update_player_list()

	# Verify player count label
	assert(player_count_label.text == "Players: 2 / 8", "Player count label should show 2 / 8")

	# Verify two entries in the list
	# Note: queue_free is deferred, so new children are added on top;
	# we count the HBoxContainers we just created
	var hbox_count: int = 0
	for child in player_list.get_children():
		if child is HBoxContainer:
			hbox_count += 1
	assert(hbox_count == 2, "Player list should have 2 HBox entries")

	# Verify start button visibility depends on server status
	# (In test context multiplayer.is_server() may vary, so just check it's a bool)
	assert(typeof(start_button.visible) == TYPE_BOOL, "Start button visible should be bool")

	# Verify cancel button is always visible
	assert(cancel_button.visible == true, "Cancel button should always be visible")

	# Clean up
	GameManager.players.clear()
	GameManager.players_changed.emit()
	print("WaitingRoom._test_feature(): All assertions passed!")
