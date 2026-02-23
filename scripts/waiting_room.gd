extends Control

@onready var player_count_label: Label = $CenterContainer/VBoxContainer/PlayerCount
@onready var player_list: VBoxContainer = $CenterContainer/VBoxContainer/PlayerList
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton


func _ready() -> void:
	GameManager.players_changed.connect(_update_player_list)
	# Only the server (host) can start the game
	start_button.visible = multiplayer.is_server()
	_update_player_list()


func _update_player_list() -> void:
	# Clear existing entries
	for child in player_list.get_children():
		child.queue_free()

	var count := GameManager.players.size()
	player_count_label.text = "Players: %d" % count

	for id in GameManager.players:
		var label := Label.new()
		label.text = GameManager.players[id]["name"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)
		player_list.add_child(label)


func _on_start_button_pressed() -> void:
	if not multiplayer.is_server():
		return
	_go_to_game.rpc()


func _on_cancel_button_pressed() -> void:
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	GameManager.players.clear()
	GameManager.players_changed.emit()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


@rpc("authority", "call_local", "reliable")
func _go_to_game() -> void:
	GameManager.reset_scores()
	get_tree().change_scene_to_file("res://scenes/timer_game.tscn")
