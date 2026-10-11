extends Node2D

var _supply_run := PackedVector2Array([
	Vector2(151, 801),
	Vector2(162, 801),
	Vector2(168, 795),
	Vector2(168, 778),
	Vector2(142, 778),
	Vector2(130, 766),
	Vector2(130, 691),
	Vector2(139, 682),
	Vector2(139, 671),
	Vector2(153, 657),
	Vector2(272, 657),
	Vector2(286, 671),
	Vector2(286, 681),
])

var _supply_branches: Array[PackedVector2Array] = [
	PackedVector2Array([Vector2(130, 696), Vector2(142, 696)]),
	PackedVector2Array([Vector2(130, 749), Vector2(142, 749)]),
]

var _return_run := PackedVector2Array([
	Vector2(42, 680),
	Vector2(51, 680),
	Vector2(56, 685),
	Vector2(56, 791),
	Vector2(69, 804),
	Vector2(82, 804),
])

var _return_branch := PackedVector2Array([
	Vector2(56, 680),
	Vector2(111, 680),
	Vector2(113, 682),
	Vector2(113, 704),
	Vector2(106, 711),
])

const PIPE_SHADOW := Color(0.025, 0.031, 0.034, 0.88)
const PIPE_CASING := Color(0.19, 0.23, 0.23, 1.0)
const PIPE_RIM := Color(0.48, 0.51, 0.48, 1.0)
const WARM_FLUID := Color(0.79, 0.34, 0.11, 1.0)
const COOL_FLUID := Color(0.12, 0.66, 0.68, 1.0)
const WARM_GLINT := Color(1.0, 0.73, 0.39, 0.9)
const COOL_GLINT := Color(0.55, 0.93, 0.9, 0.88)
const FLOW_DASH_SPACING := 20.0
const FLOW_DASH_LENGTH := 6.0
const FLOW_SPEED := 46.0

var _flow_distance := 0.0


func _ready() -> void:
	_create_pipe_collisions()


func _process(delta: float) -> void:
	_flow_distance += delta * FLOW_SPEED
	queue_redraw()


func _draw() -> void:
	_draw_pipe(_supply_run, WARM_FLUID, WARM_GLINT, _flow_distance)
	for index in range(_supply_branches.size()):
		_draw_pipe(_supply_branches[index], WARM_FLUID, WARM_GLINT, _flow_distance + float(index) * 5.0)
	_draw_pipe(_return_run, COOL_FLUID, COOL_GLINT, _flow_distance, true)
	_draw_pipe(_return_branch, COOL_FLUID, COOL_GLINT, _flow_distance + 5.0, true)

	_draw_clamp(Vector2(205, 657), Vector2.UP)
	_draw_clamp(Vector2(245, 657), Vector2.UP)
	_draw_clamp(Vector2(130, 729), Vector2.RIGHT)
	_draw_clamp(Vector2(56, 733), Vector2.RIGHT)
	_draw_clamp(Vector2(56, 772), Vector2.RIGHT)


func _create_pipe_collisions() -> void:
	var body := StaticBody2D.new()
	body.name = "PipeCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	_add_path_collision(body, _supply_run)
	for branch in _supply_branches:
		_add_path_collision(body, branch)
	_add_path_collision(body, _return_run)
	_add_path_collision(body, _return_branch)
	_add_collision_segment(body, Vector2(205, 661.5), Vector2(205, 652.5))
	_add_collision_segment(body, Vector2(245, 661.5), Vector2(245, 652.5))
	_add_collision_segment(body, Vector2(125.5, 729), Vector2(134.5, 729))
	_add_collision_segment(body, Vector2(51.5, 733), Vector2(60.5, 733))
	_add_collision_segment(body, Vector2(51.5, 772), Vector2(60.5, 772))
	add_child(body)


func _add_path_collision(body: StaticBody2D, points: PackedVector2Array) -> void:
	for index in range(points.size() - 1):
		_add_collision_segment(body, points[index], points[index + 1])


func _add_collision_segment(body: StaticBody2D, start: Vector2, end: Vector2) -> void:
	var shape := SegmentShape2D.new()
	shape.a = start
	shape.b = end
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)


func _draw_pipe(points: PackedVector2Array, fluid: Color, glint: Color, flow_phase: float, reverse_flow: bool = false) -> void:
	draw_polyline(points, PIPE_SHADOW, 7.4, true)
	draw_polyline(points, PIPE_CASING, 5.8, true)
	draw_polyline(points, PIPE_RIM, 3.7, true)
	draw_polyline(points, fluid, 1.9, true)
	draw_polyline(_offset_points(points, Vector2(0, -0.8)), glint, 0.7, true)
	_draw_flow(points, glint, flow_phase, reverse_flow)

	for point in points:
		_draw_joint(point, fluid)


func _draw_flow(points: PackedVector2Array, color: Color, flow_phase: float, reverse_flow: bool) -> void:
	var total_length := _path_length(points)
	if total_length <= 0.0:
		return

	var dash_spacing := minf(FLOW_DASH_SPACING, total_length * 0.5)
	var dash_length := minf(FLOW_DASH_LENGTH, dash_spacing * 0.8)
	var dash_start := fposmod(flow_phase, dash_spacing) - dash_length
	while dash_start < total_length:
		var visible_start := maxf(dash_start, 0.0)
		var visible_end := minf(dash_start + dash_length, total_length)
		if visible_end > visible_start:
			var start_distance := total_length - visible_end if reverse_flow else visible_start
			var end_distance := total_length - visible_start if reverse_flow else visible_end
			draw_line(
				_point_at_distance(points, start_distance),
				_point_at_distance(points, end_distance),
				color,
				1.25,
				true
			)
		dash_start += dash_spacing


func _path_length(points: PackedVector2Array) -> float:
	var length := 0.0
	for index in range(points.size() - 1):
		length += points[index].distance_to(points[index + 1])
	return length


func _point_at_distance(points: PackedVector2Array, distance: float) -> Vector2:
	var remaining := distance
	for index in range(points.size() - 1):
		var start := points[index]
		var finish := points[index + 1]
		var segment_length := start.distance_to(finish)
		if remaining <= segment_length:
			return start.lerp(finish, remaining / segment_length)
		remaining -= segment_length
	return points[points.size() - 1]


func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var shifted := PackedVector2Array()
	for point in points:
		shifted.append(point + offset)
	return shifted


func _draw_joint(point: Vector2, fluid: Color) -> void:
	draw_circle(point, 3.8, PIPE_SHADOW)
	draw_circle(point, 2.9, PIPE_RIM)
	draw_circle(point, 1.75, PIPE_CASING)
	draw_circle(point, 0.9, fluid)


func _draw_clamp(point: Vector2, across: Vector2) -> void:
	draw_line(point - across * 4.5, point + across * 4.5, PIPE_SHADOW, 5.2, true)
	draw_line(point - across * 3.2, point + across * 3.2, PIPE_RIM, 2.5, true)
	draw_circle(point, 0.8, WARM_GLINT)
