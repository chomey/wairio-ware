extends Control

## EndGame UI controller
## Shows final standings, winner display, and auto-returns to menu.

@onready var winner_label: Label = $CenterContainer/WinnerLabel
@onready var standings_list: VBoxContainer = $CenterContainer/StandingsList
@onready var menu_button: Button = $CenterContainer/MenuButton

const AUTO_RETURN_DELAY: float = 10.0

var _countdown_remaining: float = AUTO_RETURN_DELAY
var _returned: bool = false


func _ready() -> void:
	menu_button.pressed.connect(_on_menu_pressed)
	_display_winner()
	_populate_standings()


func _process(delta: float) -> void:
	if _returned:
		return

	_countdown_remaining -= delta
	menu_button.text = "Return to Menu (" + str(ceili(_countdown_remaining)) + ")"
	if _countdown_remaining <= 0.0:
		_returned = true
		GameManager.return_to_menu()


func _on_menu_pressed() -> void:
	if _returned:
		return
	_returned = true
	GameManager.return_to_menu()


func _display_winner() -> void:
	var winners: Array[int] = GameManager.get_winners()
	if winners.size() == 0:
		winner_label.text = "No winner!"
		return

	var names: PackedStringArray = PackedStringArray()
	for pid: int in winners:
		var pname: String = NetworkManager.get_player_name(pid)
		if pname == "":
			pname = "Player " + str(pid)
		names.append(pname)

	if winners.size() == 1:
		winner_label.text = names[0] + " Wins!"
	else:
		winner_label.text = " & ".join(names) + " Tie!"


func _populate_standings() -> void:
	for child: Node in standings_list.get_children():
		child.queue_free()

	# Sort players by cumulative score descending
	var sorted_ids: Array = GameManager.cumulative_scores.keys()
	sorted_ids.sort_custom(func(a: int, b: int) -> bool:
		return (GameManager.cumulative_scores[a] as int) > (GameManager.cumulative_scores[b] as int)
	)

	var rank: int = 0
	var last_score: int = -1
	for i: int in range(sorted_ids.size()):
		var peer_id: int = sorted_ids[i]
		var total_pts: int = GameManager.cumulative_scores[peer_id] as int

		if total_pts != last_score:
			rank = i + 1
			last_score = total_pts

		var player_name: String = NetworkManager.get_player_name(peer_id)
		if player_name == "":
			player_name = "Player " + str(peer_id)

		var row: HBoxContainer = HBoxContainer.new()

		var rank_label: Label = Label.new()
		rank_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rank_label.text = "#" + str(rank)
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(rank_label)

		var name_label: Label = Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text = player_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(name_label)

		var score_label: Label = Label.new()
		score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		score_label.text = str(total_pts) + " pts"
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(score_label)

		standings_list.add_child(row)
