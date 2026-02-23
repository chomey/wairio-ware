extends Node

signal player_list_changed(players: Dictionary)

# player_id: { "name": String, "score": int }
var players: Dictionary = {}

func register_player(id: int, player_name: String) -> void:
	if multiplayer.is_server():
		players[id] = {"name": player_name, "score": 0}
		player_list_changed.emit(players)
		update_clients.rpc(players)

@rpc("authority", "reliable")
func update_clients(new_players: Dictionary) -> void:
	players = new_players
	player_list_changed.emit(players)
