extends Area2D
class_name ZoneArea

signal clicked(zone)

@export var zone_id: String = "zone"
var size := Vector2(150, 100)
var highlighted := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var id_label: Label = $Label

func _ready() -> void:
	_refresh()

func set_zone(id: String, rect: Rect2) -> void:
	zone_id = id
	global_position = rect.position
	size = rect.size
	_refresh()

func get_rect() -> Rect2:
	return Rect2(global_position, size)

func set_highlighted(value: bool) -> void:
	highlighted = value
	queue_redraw()

func _refresh() -> void:
	id_label.text = zone_id
	id_label.position = Vector2(4, 4)
	var shape = collision_shape.shape
	if shape == null or not shape is RectangleShape2D:
		shape = RectangleShape2D.new()
		collision_shape.shape = shape
	shape.size = size
	collision_shape.position = size / 2.0
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var fill_color = Color(0.2, 0.9, 0.8, 0.15)
	var outline_color = Color(0.2, 0.9, 0.8, 0.8)
	if highlighted:
		fill_color = Color(1.0, 0.8, 0.2, 0.18)
		outline_color = Color(1.0, 0.8, 0.2, 0.95)
	draw_rect(rect, fill_color, true)
	draw_rect(rect, outline_color, false, 2)

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(self)
