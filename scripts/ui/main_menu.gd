extends Control

## MainMenu UI controller
## Handles host/join buttons, name + IP input, and connection feedback.

@onready var name_input: LineEdit = $CenterContainer/NameInput
@onready var ip_input: LineEdit = $CenterContainer/IPInput
@onready var host_button: Button = $CenterContainer/HostButton
@onready var join_button: Button = $CenterContainer/JoinButton
@onready var status_label: Label = $CenterContainer/StatusLabel


func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)


func _on_host_pressed() -> void:
	var player_name: String = _get_validated_name()
	if player_name.is_empty():
		return

	status_label.text = "Hosting..."
	_set_buttons_disabled(true)

	var error: Error = NetworkManager.host_game(player_name)
	if error != OK:
		status_label.text = "Failed to host: " + error_string(error)
		_set_buttons_disabled(false)
		return

	# Host goes straight to lobby
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")


func _on_join_pressed() -> void:
	var player_name: String = _get_validated_name()
	if player_name.is_empty():
		return

	var address: String = ip_input.text.strip_edges()
	if address.is_empty():
		status_label.text = "Please enter a host IP address."
		return

	status_label.text = "Connecting to " + address + "..."
	_set_buttons_disabled(true)

	var error: Error = NetworkManager.join_game(player_name, address)
	if error != OK:
		status_label.text = "Failed to join: " + error_string(error)
		_set_buttons_disabled(false)


func _on_connection_succeeded() -> void:
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")


func _on_connection_failed() -> void:
	status_label.text = "Connection failed. Check the IP and try again."
	_set_buttons_disabled(false)


func _get_validated_name() -> String:
	var player_name: String = name_input.text.strip_edges()
	if player_name.is_empty():
		status_label.text = "Please enter a player name."
	return player_name


func _set_buttons_disabled(disabled: bool) -> void:
	host_button.disabled = disabled
	join_button.disabled = disabled
