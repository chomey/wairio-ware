extends MiniGameBase

## Equation Builder minigame.
## Given a target number and available numbers, type an equation that equals the target.
## Race to 5 correct equations. Score = number of correct equations.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var target_label: Label = %TargetLabel
@onready var numbers_label: Label = %NumbersLabel
@onready var answer_input: LineEdit = %AnswerInput
@onready var feedback_label: Label = %FeedbackLabel
@onready var score_label: Label = %ScoreLabel
@onready var hint_label: Label = %HintLabel

const COMPLETION_TARGET: int = 5

var _correct_count: int = 0
var _target_value: int = 0
var _available_numbers: Array[int] = []
var _solution_hint: String = ""


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	answer_input.text_submitted.connect(_on_answer_submitted)
	target_label.text = ""
	numbers_label.text = ""
	feedback_label.text = ""
	hint_label.text = "Use +, -, * with the given numbers"
	score_label.text = "Correct: 0"
	answer_input.editable = false
	answer_input.placeholder_text = "Type equation + Enter"


func _on_game_start() -> void:
	countdown_label.visible = false
	_correct_count = 0
	score_label.text = "Correct: 0"
	answer_input.editable = true
	answer_input.grab_focus()
	_generate_puzzle()


func _on_game_end() -> void:
	answer_input.editable = false
	feedback_label.text = "Time's up! You got " + str(_correct_count) + " correct!"
	submit_score(_correct_count)


func _generate_puzzle() -> void:
	_available_numbers.clear()

	# Randomly choose puzzle type: 2-operand or 3-operand
	var use_three: bool = randi_range(0, 2) == 0  # ~33% chance of 3 operands

	if use_three:
		_generate_three_operand()
	else:
		_generate_two_operand()

	# Display
	var nums_str: String = ""
	for i: int in range(_available_numbers.size()):
		if i > 0:
			nums_str += ", "
		nums_str += str(_available_numbers[i])

	target_label.text = "Target: " + str(_target_value)
	numbers_label.text = "Numbers: " + nums_str
	hint_label.text = "Use +, -, * with these numbers"
	answer_input.text = ""
	answer_input.grab_focus()


func _generate_two_operand() -> void:
	var op: int = randi_range(0, 2)
	var a: int = 0
	var b: int = 0

	if op == 0:
		# Addition: a + b
		a = randi_range(2, 30)
		b = randi_range(2, 30)
		_target_value = a + b
		_solution_hint = str(a) + "+" + str(b)
	elif op == 1:
		# Subtraction: a - b (ensure positive result)
		a = randi_range(10, 40)
		b = randi_range(1, a - 1)
		_target_value = a - b
		_solution_hint = str(a) + "-" + str(b)
	else:
		# Multiplication: a * b
		a = randi_range(2, 12)
		b = randi_range(2, 12)
		_target_value = a * b
		_solution_hint = str(a) + "*" + str(b)

	_available_numbers.append(a)
	_available_numbers.append(b)
	_available_numbers.shuffle()


func _generate_three_operand() -> void:
	# Pick two operations and three numbers
	var op1: int = randi_range(0, 1)  # 0=add, 1=multiply
	var op2: int = randi_range(0, 1)

	var a: int = randi_range(2, 10)
	var b: int = randi_range(2, 10)
	var c: int = randi_range(2, 10)

	# Build with standard operator precedence: a op1 b op2 c
	# For simplicity, use add + add or add + sub patterns
	if op1 == 0 and op2 == 0:
		_target_value = a + b + c
		_solution_hint = str(a) + "+" + str(b) + "+" + str(c)
	elif op1 == 0 and op2 == 1:
		# a + b * c
		_target_value = a + b * c
		_solution_hint = str(a) + "+" + str(b) + "*" + str(c)
	elif op1 == 1 and op2 == 0:
		# a * b + c
		_target_value = a * b + c
		_solution_hint = str(a) + "*" + str(b) + "+" + str(c)
	else:
		# a * b * c
		a = randi_range(2, 5)
		b = randi_range(2, 5)
		c = randi_range(2, 5)
		_target_value = a * b * c
		_solution_hint = str(a) + "*" + str(b) + "*" + str(c)

	_available_numbers.append(a)
	_available_numbers.append(b)
	_available_numbers.append(c)
	_available_numbers.shuffle()


func _on_answer_submitted(text: String) -> void:
	if not game_active:
		return

	var stripped: String = text.strip_edges()
	if stripped.is_empty():
		return

	var result: int = _evaluate_expression(stripped)
	if result == _target_value:
		_correct_count += 1
		feedback_label.text = "Correct! " + stripped + " = " + str(_target_value)
		score_label.text = "Correct: " + str(_correct_count)
		if _correct_count >= COMPLETION_TARGET:
			mark_completed(_correct_count)
			return
		_generate_puzzle()
	else:
		if result == -99999:
			feedback_label.text = "Invalid expression! Try again."
		else:
			feedback_label.text = "Wrong! " + stripped + " = " + str(result) + ", not " + str(_target_value)
		answer_input.text = ""
		answer_input.grab_focus()


## Simple expression evaluator supporting +, -, * with standard precedence.
## Returns -99999 on parse error.
func _evaluate_expression(expr: String) -> int:
	# Remove all spaces
	var clean: String = expr.replace(" ", "")
	if clean.is_empty():
		return -99999

	# Tokenize into numbers and operators
	var tokens: Array[String] = []
	var current_num: String = ""
	for i: int in range(clean.length()):
		var ch: String = clean[i]
		if ch == "+" or ch == "-" or ch == "*":
			# Handle negative numbers at start or after operator
			if current_num.is_empty() and ch == "-":
				current_num += ch
				continue
			if current_num.is_empty():
				return -99999
			tokens.append(current_num)
			tokens.append(ch)
			current_num = ""
		elif ch >= "0" and ch <= "9":
			current_num += ch
		else:
			return -99999  # Invalid character

	if current_num.is_empty():
		return -99999
	tokens.append(current_num)

	# Validate: should alternate number, op, number, op, ...
	if tokens.size() < 1 or tokens.size() % 2 == 0:
		return -99999

	# Parse into number and operator arrays
	var numbers: Array[int] = []
	var operators: Array[String] = []
	for i: int in range(tokens.size()):
		if i % 2 == 0:
			if not tokens[i].is_valid_int():
				return -99999
			numbers.append(tokens[i].to_int())
		else:
			operators.append(tokens[i])

	# Apply operator precedence: handle * first
	var nums_after_mult: Array[int] = [numbers[0]]
	var ops_after_mult: Array[String] = []
	for i: int in range(operators.size()):
		if operators[i] == "*":
			var prev: int = nums_after_mult[nums_after_mult.size() - 1]
			nums_after_mult[nums_after_mult.size() - 1] = prev * numbers[i + 1]
		else:
			nums_after_mult.append(numbers[i + 1])
			ops_after_mult.append(operators[i])

	# Now handle + and - left to right
	var result: int = nums_after_mult[0]
	for i: int in range(ops_after_mult.size()):
		if ops_after_mult[i] == "+":
			result += nums_after_mult[i + 1]
		elif ops_after_mult[i] == "-":
			result -= nums_after_mult[i + 1]

	return result


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
