extends Control

## Lobby UI controller
## Shows connected players, auto-starts when 2+ players are connected.

@onready var player_list: VBoxContainer = $CenterContainer/PlayerList
@onready var back_button: Button = $CenterContainer/BackButton
@onready var status_label: Label = $CenterContainer/StatusLabel

const AUTO_START_DELAY: float = 5.0

var _countdown_active: bool = false
var _countdown_remaining: float = AUTO_START_DELAY


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)

	# Populate the player list with currently connected players
	_refresh_player_list()


func _process(delta: float) -> void:
	if not NetworkManager.is_host():
		return

	if _countdown_active:
		_countdown_remaining -= delta
		status_label.text = "Starting in " + str(ceili(_countdown_remaining)) + "..."
		if _countdown_remaining <= 0.0:
			_countdown_active = false
			GameManager.start_game()
	else:
		_check_auto_start()


func _check_auto_start() -> void:
	if NetworkManager.players.size() >= 2:
		_countdown_active = true
		_countdown_remaining = AUTO_START_DELAY
	else:
		status_label.text = str(NetworkManager.players.size()) + " player(s) connected - need at least 2"


func _on_back_pressed() -> void:
	_countdown_active = false
	GameManager.return_to_menu()


func _on_player_connected(_peer_id: int, _player_name: String) -> void:
	_refresh_player_list()


func _on_player_disconnected(_peer_id: int) -> void:
	_refresh_player_list()
	# Cancel countdown if we drop below 2 players
	if NetworkManager.players.size() < 2:
		_countdown_active = false


func _on_server_disconnected() -> void:
	GameManager.return_to_menu()


func _refresh_player_list() -> void:
	# Remove existing player labels
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
