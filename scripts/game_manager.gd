extends Node

const PORT := 9999
const MAX_PLAYERS := 8
const SERVER_IP := "127.0.0.1"

var is_server := false
var player_name := ""
var players: Dictionary = {}  # id -> { name: String, score: int }

signal players_changed


func _ready() -> void:
	# Check command line args for --server flag
	for arg in OS.get_cmdline_args():
		if arg == "--server":
			is_server = true


func add_player(id: int, pname: String) -> void:
	players[id] = {"name": pname, "score": 0}
	players_changed.emit()


func remove_player(id: int) -> void:
	players.erase(id)
	players_changed.emit()


func get_player_name(id: int) -> String:
	if players.has(id):
		return players[id]["name"]
	return "Unknown"


func add_score(id: int, points: int) -> void:
	if players.has(id):
		players[id]["score"] += points


func get_scores() -> Dictionary:
	return players.duplicate(true)


func reset_scores() -> void:
	for id in players:
		players[id]["score"] = 0


@rpc("any_peer", "reliable")
func register_player_on_server(pname: String) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	add_player(sender_id, pname)
	# Broadcast updated player list to all clients
	for id in players:
		sync_player_list.rpc(id, players[id]["name"])


@rpc("authority", "reliable")
func sync_player_list(id: int, pname: String) -> void:
	if not players.has(id):
		add_player(id, pname)
