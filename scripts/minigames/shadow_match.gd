extends MiniGameBase

## Shadow Match minigame.
## A silhouette (dark shape) is shown at the top.
## Player picks the matching shape from 4 options below.
## Race to 10 correct matches.
## Score = number of correct matches within 10 seconds.

@onready var title_label: Label = %TitleLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var silhouette_area: Control = %SilhouetteArea
@onready var choices_container: HBoxContainer = %ChoicesContainer

const COMPLETION_TARGET: int = 10
const NUM_CHOICES: int = 4

## Shape types: each is drawn differently
## 0=circle, 1=square, 2=triangle, 3=diamond, 4=star, 5=cross, 6=pentagon, 7=hexagon, 8=arrow, 9=heart
const SHAPE_NAMES: Array[String] = [
	"circle", "square", "triangle", "diamond", "star",
	"cross", "pentagon", "hexagon", "arrow", "heart"
]
const SHAPE_COUNT: int = 10

var _score: int = 0
var _correct_shape: int = -1
var _correct_index: int = -1
var _silhouette_shape: int = -1

## Colors for the colored shape options
const OPTION_COLORS: Array[Color] = [
	Color(0.2, 0.6, 1.0),  # blue
	Color(1.0, 0.3, 0.3),  # red
	Color(0.3, 0.9, 0.3),  # green
	Color(1.0, 0.8, 0.2),  # yellow
]


func _ready() -> void:
	super._ready()
	countdown_tick.connect(_on_countdown_tick)
	countdown_finished.connect(_on_countdown_finished)
	game_timer_tick.connect(_on_game_timer_tick)
	game_timer_finished.connect(_on_game_timer_finished_signal)
	silhouette_area.draw.connect(_on_silhouette_area_draw)
	instruction_label.text = "Get ready..."
	_update_score_display()


func _on_game_start() -> void:
	_score = 0
	_update_score_display()
	instruction_label.text = "CLICK THE MATCHING SHAPE!"
	countdown_label.visible = false
	_generate_round()


func _on_game_end() -> void:
	instruction_label.text = "Time's up!"
	submit_score(_score)


func _generate_round() -> void:
	# Pick a correct shape
	_correct_shape = randi() % SHAPE_COUNT
	_silhouette_shape = _correct_shape

	# Pick 3 different distractor shapes
	var shapes: Array[int] = [_correct_shape]
	while shapes.size() < NUM_CHOICES:
		var s: int = randi() % SHAPE_COUNT
		if s not in shapes:
			shapes.append(s)

	# Shuffle and find correct index
	shapes.shuffle()
	_correct_index = shapes.find(_correct_shape)

	# Update silhouette display
	silhouette_area.queue_redraw()

	# Rebuild choice buttons
	_rebuild_choices(shapes)


func _rebuild_choices(shapes: Array[int]) -> void:
	for child: Node in choices_container.get_children():
		child.queue_free()

	for i: int in range(shapes.size()):
		var panel: Panel = Panel.new()
		panel.custom_minimum_size = Vector2(100, 100)
		var stylebox: StyleBoxFlat = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.2, 0.22, 0.28)
		stylebox.corner_radius_top_left = 6
		stylebox.corner_radius_top_right = 6
		stylebox.corner_radius_bottom_left = 6
		stylebox.corner_radius_bottom_right = 6
		panel.add_theme_stylebox_override("panel", stylebox)

		var draw_control: Control = Control.new()
		draw_control.set_anchors_preset(Control.PRESET_FULL_RECT)
		var shape_idx: int = shapes[i]
		var color: Color = OPTION_COLORS[i]
		draw_control.draw.connect(_draw_shape.bind(draw_control, shape_idx, color))
		panel.add_child(draw_control)

		var btn: Button = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var idx: int = i
		btn.pressed.connect(_on_choice_clicked.bind(idx))
		panel.add_child(btn)

		choices_container.add_child(panel)


func _draw_shape(ctrl: Control, shape_idx: int, color: Color) -> void:
	var size: Vector2 = ctrl.size
	var center: Vector2 = size / 2.0
	var radius: float = minf(size.x, size.y) * 0.35

	match shape_idx:
		0:  # circle
			ctrl.draw_circle(center, radius, color)
		1:  # square
			var rect: Rect2 = Rect2(center - Vector2(radius, radius), Vector2(radius * 2, radius * 2))
			ctrl.draw_rect(rect, color)
		2:  # triangle
			var points: PackedVector2Array = PackedVector2Array([
				Vector2(center.x, center.y - radius),
				Vector2(center.x - radius, center.y + radius),
				Vector2(center.x + radius, center.y + radius),
			])
			ctrl.draw_colored_polygon(points, color)
		3:  # diamond
			var points: PackedVector2Array = PackedVector2Array([
				Vector2(center.x, center.y - radius),
				Vector2(center.x + radius, center.y),
				Vector2(center.x, center.y + radius),
				Vector2(center.x - radius, center.y),
			])
			ctrl.draw_colored_polygon(points, color)
		4:  # star (5-pointed)
			_draw_star(ctrl, center, radius, color)
		5:  # cross
			var w: float = radius * 0.4
			var points: PackedVector2Array = PackedVector2Array([
				Vector2(center.x - w, center.y - radius),
				Vector2(center.x + w, center.y - radius),
				Vector2(center.x + w, center.y - w),
				Vector2(center.x + radius, center.y - w),
				Vector2(center.x + radius, center.y + w),
				Vector2(center.x + w, center.y + w),
				Vector2(center.x + w, center.y + radius),
				Vector2(center.x - w, center.y + radius),
				Vector2(center.x - w, center.y + w),
				Vector2(center.x - radius, center.y + w),
				Vector2(center.x - radius, center.y - w),
				Vector2(center.x - w, center.y - w),
			])
			ctrl.draw_colored_polygon(points, color)
		6:  # pentagon
			_draw_regular_polygon(ctrl, center, radius, 5, color)
		7:  # hexagon
			_draw_regular_polygon(ctrl, center, radius, 6, color)
		8:  # arrow (pointing right)
			var hw: float = radius * 0.4
			var points: PackedVector2Array = PackedVector2Array([
				Vector2(center.x - radius, center.y - hw),
				Vector2(center.x, center.y - hw),
				Vector2(center.x, center.y - radius),
				Vector2(center.x + radius, center.y),
				Vector2(center.x, center.y + radius),
				Vector2(center.x, center.y + hw),
				Vector2(center.x - radius, center.y + hw),
			])
			ctrl.draw_colored_polygon(points, color)
		9:  # heart
			_draw_heart(ctrl, center, radius, color)


func _draw_star(ctrl: Control, center: Vector2, radius: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var inner_radius: float = radius * 0.4
	for i: int in range(10):
		var angle: float = (PI / 2.0) + (PI * 2.0 * float(i) / 10.0)
		var r: float = radius if i % 2 == 0 else inner_radius
		points.append(center + Vector2(cos(angle), -sin(angle)) * r)
	ctrl.draw_colored_polygon(points, color)


func _draw_regular_polygon(ctrl: Control, center: Vector2, radius: float, sides: int, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(sides):
		var angle: float = (PI / 2.0) + (PI * 2.0 * float(i) / float(sides))
		points.append(center + Vector2(cos(angle), -sin(angle)) * radius)
	ctrl.draw_colored_polygon(points, color)


func _draw_heart(ctrl: Control, center: Vector2, radius: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	# Simple heart shape using parametric curve
	for i: int in range(30):
		var t: float = PI * 2.0 * float(i) / 30.0
		var x: float = 16.0 * pow(sin(t), 3)
		var y: float = -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(center + Vector2(x, y) * (radius / 16.0))
	ctrl.draw_colored_polygon(points, color)


func _on_choice_clicked(index: int) -> void:
	if not game_active:
		return

	if index == _correct_index:
		_score += 1
		_update_score_display()
		if _score >= COMPLETION_TARGET:
			mark_completed(_score)
			return
		_generate_round()
	else:
		instruction_label.text = "WRONG! Try again..."
		var timer: SceneTreeTimer = get_tree().create_timer(0.5)
		timer.timeout.connect(func() -> void:
			if game_active:
				instruction_label.text = "CLICK THE MATCHING SHAPE!"
		)


func _update_score_display() -> void:
	score_label.text = "Matched: " + str(_score) + " / " + str(COMPLETION_TARGET)


func _on_silhouette_area_draw() -> void:
	if _silhouette_shape < 0:
		return
	var size: Vector2 = silhouette_area.size
	var center: Vector2 = size / 2.0
	var radius: float = minf(size.x, size.y) * 0.35
	var shadow_color: Color = Color(0.08, 0.08, 0.08)
	_draw_shape(silhouette_area, _silhouette_shape, shadow_color)


func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.visible = true
	countdown_label.text = str(seconds_left)


func _on_countdown_finished() -> void:
	countdown_label.text = "GO!"


func _on_game_timer_tick(seconds_left: float) -> void:
	timer_label.text = "Time: " + str(snappedi(seconds_left * 10, 1) / 10.0)


func _on_game_timer_finished_signal() -> void:
	timer_label.text = "Time: 0.0"
