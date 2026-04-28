extends Area2D
class_name ProjectileMarker

signal clicked(marker)

@export var radius: float = 6.0
var selected := false
var spawn_in_area := false
var angle_deg := 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_refresh_shape()

func _refresh_shape() -> void:
	var shape = collision_shape.shape
	if shape == null or not shape is CircleShape2D:
		shape = CircleShape2D.new()
		collision_shape.shape = shape
	shape.radius = radius
	queue_redraw()

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()

func set_spawn_in_area(value: bool) -> void:
	spawn_in_area = value
	queue_redraw()

func set_angle(value: float) -> void:
	angle_deg = value
	queue_redraw()

func _draw() -> void:
	var color := Color(1.0, 0.3, 0.3)
	if spawn_in_area:
		color = Color(0.3, 0.8, 1.0)
	if selected:
		color = Color(1.0, 0.9, 0.2)
	draw_circle(Vector2.ZERO, radius, color)
	if selected:
		var direction = Vector2.RIGHT.rotated(deg_to_rad(angle_deg))
		var length = radius * 3.5
		var tip = direction * length
		draw_line(Vector2.ZERO, tip, color, 2.0)
		draw_circle(tip, radius * 0.5, color)

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(self)
