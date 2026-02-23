extends Node

# Claude: Implement the scoring logic here first
func calculate_score(target_time: float, actual_time: float) -> float:
	var diff = abs(target_time - actual_time)
	# Logic: 100 points max, 10 points deducted per second off
	return max(0.0, 100.0 - (diff * 10.0))

func _run_ralph_check() -> void:
	var score = calculate_score(5.0, 5.1)
	print("TEST: Target 5s, Actual 5.1s. Expected Score ~99. Result: ", score)
	assert(score > 90, "Scoring logic is too harsh!")
