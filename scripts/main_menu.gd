extends Control

@onready var name_input: LineEdit = $CenterContainer/VBoxContainer/NameInput
@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var settings_panel: Panel = $SettingsPanel


func _ready() -> void:
	play_button.disabled = true
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)


func _on_name_input_text_changed(new_text: String) -> void:
	play_button.disabled = new_text.strip_edges().is_empty()


func _on_play_button_pressed() -> void:
	var player_name := name_input.text.strip_edges()
	if player_name.is_empty():
		return
	GameManager.player_name = player_name
	_start_network()


func _on_settings_button_pressed() -> void:
	settings_panel.visible = true


func _on_back_button_pressed() -> void:
	settings_panel.visible = false


func _start_network() -> void:
	status_label.text = "Connecting..."
	play_button.disabled = true
	settings_button.disabled = true

	if GameManager.is_server:
		var peer := ENetMultiplayerPeer.new()
		var error := peer.create_server(GameManager.PORT, GameManager.MAX_PLAYERS)
		if error != OK:
			status_label.text = "Failed to create server."
			play_button.disabled = false
			settings_button.disabled = false
			return
		multiplayer.multiplayer_peer = peer
		status_label.text = "Server started. Waiting for players..."
		GameManager.add_player(1, GameManager.player_name)
		get_tree().change_scene_to_file("res://scenes/waiting_room.tscn")
	else:
		var peer := ENetMultiplayerPeer.new()
		var error := peer.create_client(GameManager.SERVER_IP, GameManager.PORT)
		if error != OK:
			status_label.text = "Failed to connect."
			play_button.disabled = false
			settings_button.disabled = false
			return
		multiplayer.multiplayer_peer = peer


func _on_connected_to_server() -> void:
	status_label.text = "Connected!"
	GameManager.add_player(multiplayer.get_unique_id(), GameManager.player_name)
	GameManager.register_player_on_server.rpc_id(1, GameManager.player_name)
	get_tree().change_scene_to_file("res://scenes/waiting_room.tscn")


func _on_connection_failed() -> void:
	status_label.text = "Connection failed. Try again."
	play_button.disabled = name_input.text.strip_edges().is_empty()
	settings_button.disabled = false


func _on_peer_connected(id: int) -> void:
	pass


func _on_peer_disconnected(id: int) -> void:
	GameManager.remove_player(id)


func _test_feature() -> void:
	# Verify play button starts disabled
	assert(play_button.disabled == true, "Play button should start disabled")

	# Verify entering a name enables the play button
	name_input.text = "TestPlayer"
	_on_name_input_text_changed("TestPlayer")
	assert(play_button.disabled == false, "Play button should enable with a name")

	# Verify empty name disables the play button
	name_input.text = ""
	_on_name_input_text_changed("")
	assert(play_button.disabled == true, "Play button should disable with empty name")

	# Verify whitespace-only name keeps button disabled
	name_input.text = "   "
	_on_name_input_text_changed("   ")
	assert(play_button.disabled == true, "Play button should disable with whitespace-only name")

	# Verify settings panel starts hidden
	assert(settings_panel.visible == false, "Settings panel should start hidden")

	# Verify settings panel toggles
	_on_settings_button_pressed()
	assert(settings_panel.visible == true, "Settings panel should show after button press")
	_on_back_button_pressed()
	assert(settings_panel.visible == false, "Settings panel should hide after back press")

	# Clean up
	name_input.text = ""
	_on_name_input_text_changed("")
	print("MainMenu._test_feature(): All assertions passed!")
