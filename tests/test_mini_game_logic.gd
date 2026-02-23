extends Node

# Tests for the TimerGame scoring logic

func calculate_score(target_time: float, actual_time: float) -> int:
	var diff: float = absf(target_time - actual_time)
	return clampi(roundi(100.0 - diff * 10.0), 0, 100)


func _run_ralph_check() -> void:
	# Perfect timing
	var score_perfect: int = calculate_score(5.0, 5.0)
	assert(score_perfect == 100, "Perfect should be 100")
	print("TEST: Perfect score = ", score_perfect)

	# Slightly off
	var score_close: int = calculate_score(5.0, 5.1)
	assert(score_close == 99, "0.1s off should be 99")
	print("TEST: 0.1s off score = ", score_close)

	# 1 second off
	var score_1s: int = calculate_score(5.0, 6.0)
	assert(score_1s == 90, "1s off should be 90")
	print("TEST: 1s off score = ", score_1s)

	# Way off — should clamp to 0
	var score_far: int = calculate_score(3.0, 15.0)
	assert(score_far == 0, "12s off should be 0")
	print("TEST: 12s off score = ", score_far)

	# Edge: target at boundaries
	var score_min: int = calculate_score(3.0, 3.0)
	assert(score_min == 100, "Perfect at min target should be 100")

	var score_max: int = calculate_score(10.0, 10.0)
	assert(score_max == 100, "Perfect at max target should be 100")

	print("All mini game logic tests passed!")
