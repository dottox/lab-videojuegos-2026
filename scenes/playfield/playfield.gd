extends Area2D

#Variables relacionadas al state
var current_state
var NormalState = preload("res://scenes/playfield/states/normal_state.gd")

#Variables relacionadas a la forma
@onready var shape: CollisionShape2D = $CollisionShape2D

func _ready():
	pass

func _draw():
	var rect = shape.shape.get_rect()
	var outer_rect = Rect2(
		rect.position - Vector2(10, 10),
		rect.size + Vector2(20, 20)
	)
	
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
	
func set_size(size: Vector2):
	shape.shape.size = size
	queue_redraw()

func get_bounds() -> Rect2:
	var rect = shape.shape.get_rect()
	return Rect2(global_position + rect.position, rect.size)
