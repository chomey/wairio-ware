extends Control

## Lobby UI controller
## Shows connected players, host-only start button, and back button.

@onready var player_list: VBoxContainer = $CenterContainer/PlayerList
@onready var start_button: Button = $CenterContainer/StartButton
@onready var back_button: Button = $CenterContainer/BackButton
@onready var status_label: Label = $CenterContainer/StatusLabel


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)

	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)

	# Only the host can start the game
	start_button.visible = NetworkManager.is_host()

	# Populate the player list with currently connected players
	_refresh_player_list()


func _on_start_pressed() -> void:
	if not NetworkManager.is_host():
		return

	if NetworkManager.players.size() < 2:
		status_label.text = "Need at least 2 players to start."
		return

	GameManager.start_game()


func _on_back_pressed() -> void:
	GameManager.return_to_menu()


func _on_player_connected(_peer_id: int, _player_name: String) -> void:
	_refresh_player_list()


func _on_player_disconnected(_peer_id: int) -> void:
	_refresh_player_list()


func _on_server_disconnected() -> void:
	GameManager.return_to_menu()


func _refresh_player_list() -> void:
	# Remove existing player labels (keep the header)
	for child: Node in player_list.get_children():
		child.queue_free()

	for peer_id: int in NetworkManager.players:
		var player_name: String = NetworkManager.players[peer_id]
		var label: Label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		if peer_id == 1:
			label.text = player_name + " (Host)"
		else:
			label.text = player_name

		player_list.add_child(label)

	status_label.text = str(NetworkManager.players.size()) + " player(s) connected"
