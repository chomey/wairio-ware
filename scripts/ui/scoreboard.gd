extends Control

## Scoreboard UI controller
## Shows round scores, cumulative scores, auto-advances after countdown.

@onready var title_label: Label = $CenterContainer/TitleLabel
@onready var round_label: Label = $CenterContainer/RoundLabel
@onready var score_list: VBoxContainer = $CenterContainer/ScoreList

const AUTO_ADVANCE_DELAY: float = 5.0

var _countdown_remaining: float = AUTO_ADVANCE_DELAY


func _ready() -> void:
	round_label.text = "Round " + str(GameManager.current_round) + " / " + str(GameManager.total_rounds)
	_populate_scores()


func _process(delta: float) -> void:
	if not NetworkManager.is_host():
		return

	_countdown_remaining -= delta
	round_label.text = "Round " + str(GameManager.current_round) + " / " + str(GameManager.total_rounds) + "  (Next in " + str(ceili(_countdown_remaining)) + ")"
	if _countdown_remaining <= 0.0:
		_countdown_remaining = 999.0  # Prevent re-triggering
		GameManager.advance_round()


func _populate_scores() -> void:
	# Clear existing rows
	for child: Node in score_list.get_children():
		child.queue_free()

	# Sort players by cumulative score descending
	var sorted_ids: Array = GameManager.cumulative_scores.keys()
	sorted_ids.sort_custom(func(a: int, b: int) -> bool:
		return (GameManager.cumulative_scores[a] as int) > (GameManager.cumulative_scores[b] as int)
	)

	for peer_id: int in sorted_ids:
		var player_name: String = NetworkManager.get_player_name(peer_id)
		if player_name == "":
			player_name = "Player " + str(peer_id)

		var round_pts: int = 0
		if GameManager.round_points.has(peer_id):
			round_pts = GameManager.round_points[peer_id] as int

		var total_pts: int = GameManager.cumulative_scores[peer_id] as int

		var row: HBoxContainer = HBoxContainer.new()

		var name_label: Label = Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text = player_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(name_label)

		var round_label_item: Label = Label.new()
		round_label_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		round_label_item.text = "+" + str(round_pts)
		round_label_item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(round_label_item)

		var total_label: Label = Label.new()
		total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		total_label.text = str(total_pts)
		total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(total_label)

		score_list.add_child(row)
