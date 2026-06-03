extends Area2D
class_name Playfield

var NormalState = preload("res://scenes/playfield/states/normal_state.gd")
signal clicked(playfield)

var id: int = 0
var rect := Rect2(Vector2.ZERO, Vector2(500, 500))

var current_state

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	set_state("normal")
	_refresh()

func _draw():
	var outer_rect := rect.grow(10)
	draw_rect(outer_rect, Color.WHITE)
	draw_rect(rect, Color.BLACK)

func _physics_process(delta):
	current_state.physics_update(self, delta)

func change_state(new_state):
	if current_state:
		current_state.exit(self)

	current_state = new_state
	current_state.enter(self)

func set_state(state: String):
	match state:
		"normal":
			change_state(NormalState.new())

func set_size(nsize: Vector2):
	rect.size = nsize
	_refresh()

func set_playfield(n_id: int, n_rect: Rect2) -> void:
	id = n_id
	rect = n_rect
	_refresh()

func get_bounds() -> Rect2:
	return rect

func get_center() -> Vector2:
	return rect.position + rect.size / 2.0
	
func _refresh() -> void:
	if not is_inside_tree() or collision_shape == null:
		return

	var shape := collision_shape.shape
	if shape == null or not shape is RectangleShape2D:
		shape = RectangleShape2D.new()
		collision_shape.shape = shape

	shape.size = rect.size
	collision_shape.position = rect.size / 2.0
	queue_redraw()
