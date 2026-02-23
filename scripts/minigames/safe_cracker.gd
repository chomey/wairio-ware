extends MiniGameBase

## Safe Cracker minigame.
## Guess a 3-digit code. After each guess, each digit gets feedback:
## HIT = correct digit correct position, CLOSE = correct digit wrong position, MISS = wrong digit.
## Score = number of codes cracked. Race to 3.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var code_label: Label = %CodeLabel
@onready var guess_input: LineEdit = %GuessInput
@onready var feedback_label: Label = %FeedbackLabel
@onready var history_label: Label = %HistoryLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel

const COMPLETION_TARGET: int = 3
const CODE_LENGTH: int = 3

var _codes_cracked: int = 0
var _secret_code: Array[int] = []
var _guess_history: Array[String] = []
var _waiting_for_input: bool = false


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	guess_input.text_submitted.connect(_on_guess_submitted)
	guess_input.editable = false
	feedback_label.text = ""
	history_label.text = ""
	score_label.text = "Cracked: 0 / " + str(COMPLETION_TARGET)
	code_label.text = "? ? ?"
	instruction_label.text = "Type a 3-digit number and press Enter"


func _on_game_start() -> void:
	countdown_label.visible = false
	_codes_cracked = 0
	score_label.text = "Cracked: 0 / " + str(COMPLETION_TARGET)
	_generate_code()
	guess_input.editable = true
	guess_input.grab_focus()


func _on_game_end() -> void:
	_waiting_for_input = false
	guess_input.editable = false
	feedback_label.text = "Time's up! You cracked " + str(_codes_cracked) + " codes!"
	submit_score(_codes_cracked)


func _generate_code() -> void:
	_secret_code.clear()
	for i: int in range(CODE_LENGTH):
		_secret_code.append(randi_range(0, 9))
	_guess_history.clear()
	history_label.text = ""
	code_label.text = "? ? ?"
	feedback_label.text = "New safe! Guess the " + str(CODE_LENGTH) + "-digit code."
	_waiting_for_input = true
	guess_input.text = ""
	guess_input.grab_focus()


func _on_guess_submitted(text: String) -> void:
	if not game_active or not _waiting_for_input:
		return

	# Validate input: must be exactly CODE_LENGTH digits
	var trimmed: String = text.strip_edges()
	if trimmed.length() != CODE_LENGTH:
		feedback_label.text = "Enter exactly " + str(CODE_LENGTH) + " digits!"
		guess_input.text = ""
		guess_input.grab_focus()
		return

	if not trimmed.is_valid_int():
		feedback_label.text = "Digits only (0-9)!"
		guess_input.text = ""
		guess_input.grab_focus()
		return

	# Parse guess digits
	var guess_digits: Array[int] = []
	for i: int in range(CODE_LENGTH):
		guess_digits.append(int(trimmed[i]))

	# Evaluate guess
	var result: String = _evaluate_guess(guess_digits)

	# Add to history
	_guess_history.append(trimmed + "  " + result)
	_update_history_display()

	# Check if cracked
	var all_hit: bool = true
	for i: int in range(CODE_LENGTH):
		if guess_digits[i] != _secret_code[i]:
			all_hit = false
			break

	guess_input.text = ""

	if all_hit:
		_waiting_for_input = false
		_codes_cracked += 1
		score_label.text = "Cracked: " + str(_codes_cracked) + " / " + str(COMPLETION_TARGET)
		var code_display: String = ""
		for i: int in range(CODE_LENGTH):
			if i > 0:
				code_display += " "
			code_display += trimmed[i]
		code_label.text = code_display
		feedback_label.text = "CRACKED!"
		if _codes_cracked >= COMPLETION_TARGET:
			mark_completed(_codes_cracked)
			return
		# Short delay then generate next code
		await get_tree().create_timer(0.5).timeout
		if game_active:
			_generate_code()
	else:
		feedback_label.text = result
		guess_input.grab_focus()


func _evaluate_guess(guess: Array[int]) -> String:
	var results: Array[String] = []
	# Track which secret digits have been matched (for CLOSE detection)
	var secret_used: Array[bool] = []
	var guess_used: Array[bool] = []
	for i: int in range(CODE_LENGTH):
		secret_used.append(false)
		guess_used.append(false)

	# First pass: find HITs (correct digit, correct position)
	for i: int in range(CODE_LENGTH):
		results.append("")
		if guess[i] == _secret_code[i]:
			results[i] = "HIT"
			secret_used[i] = true
			guess_used[i] = true

	# Second pass: find CLOSEs (correct digit, wrong position)
	for i: int in range(CODE_LENGTH):
		if guess_used[i]:
			continue
		for j: int in range(CODE_LENGTH):
			if secret_used[j]:
				continue
			if guess[i] == _secret_code[j]:
				results[i] = "CLOSE"
				secret_used[j] = true
				guess_used[i] = true
				break

	# Remaining are MISSes
	for i: int in range(CODE_LENGTH):
		if results[i] == "":
			results[i] = "MISS"

	# Format: "digit:RESULT | digit:RESULT | digit:RESULT"
	var output: String = ""
	for i: int in range(CODE_LENGTH):
		if i > 0:
			output += " | "
		output += str(guess[i]) + ":" + results[i]
	return output


func _update_history_display() -> void:
	# Show last 5 guesses
	var start_idx: int = maxi(0, _guess_history.size() - 5)
	var display: String = ""
	for i: int in range(start_idx, _guess_history.size()):
		if display != "":
			display += "\n"
		display += _guess_history[i]
	history_label.text = display


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
