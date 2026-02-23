extends Node

## NetworkManager autoload
## Handles hosting, joining, disconnecting, and player registry with RPC sync.

signal player_connected(peer_id: int, player_name: String)
signal player_disconnected(peer_id: int)
signal connection_failed()
signal connection_succeeded()
signal server_disconnected()

const DEFAULT_PORT: int = 9999
const MAX_PLAYERS: int = 8

## Player registry: peer_id -> player_name
var players: Dictionary = {}
var local_player_name: String = ""

var _peer: ENetMultiplayerPeer = null


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host_game(player_name: String, port: int = DEFAULT_PORT) -> Error:
	local_player_name = player_name
	_peer = ENetMultiplayerPeer.new()
	var error: Error = _peer.create_server(port, MAX_PLAYERS)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = _peer
	# Register the host in the player registry
	players[1] = player_name
	player_connected.emit(1, player_name)
	return OK


func join_game(player_name: String, address: String, port: int = DEFAULT_PORT) -> Error:
	local_player_name = player_name
	_peer = ENetMultiplayerPeer.new()
	var error: Error = _peer.create_client(address, port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = _peer
	return OK


func disconnect_game() -> void:
	if _peer != null:
		multiplayer.multiplayer_peer = null
		_peer = null
	players.clear()


func is_host() -> bool:
	return multiplayer.multiplayer_peer != null and multiplayer.is_server()


func get_player_name(peer_id: int) -> String:
	if players.has(peer_id):
		return players[peer_id]
	return ""


func get_player_ids() -> Array:
	return players.keys()


## Called on all peers when a new peer connects
func _on_peer_connected(id: int) -> void:
	# When a new peer connects, send them our name
	_register_player.rpc_id(id, local_player_name)


## Called on all peers when a peer disconnects
func _on_peer_disconnected(id: int) -> void:
	if players.has(id):
		players.erase(id)
		player_disconnected.emit(id)


## Called on clients when they successfully connect to the server
func _on_connected_to_server() -> void:
	var my_id: int = multiplayer.get_unique_id()
	# Send our name to all peers
	_register_player.rpc(local_player_name)
	# Also register ourselves locally
	players[my_id] = local_player_name
	connection_succeeded.emit()


## Called on clients when connection to server fails
func _on_connection_failed() -> void:
	disconnect_game()
	connection_failed.emit()


## Called on clients when server disconnects
func _on_server_disconnected() -> void:
	disconnect_game()
	server_disconnected.emit()


@rpc("any_peer", "reliable")
func _register_player(player_name: String) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	players[sender_id] = player_name
	player_connected.emit(sender_id, player_name)

	# If we're the server, send the full player list to the new peer
	if multiplayer.is_server():
		_sync_player_list.rpc_id(sender_id, players)


@rpc("authority", "reliable")
func _sync_player_list(player_list: Dictionary) -> void:
	for id: int in player_list:
		if not players.has(id):
			players[id] = player_list[id]
			player_connected.emit(id, player_list[id])
