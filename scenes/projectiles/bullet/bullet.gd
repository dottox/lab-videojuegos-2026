extends Area2D
class_name Bullet

var velocity: Vector2 = Vector2.ZERO
var bullet_size: float = 2.5
var bullet_color: Color = Color.RED

var on_despawn: Callable = Callable()
var active: bool = false


func _physics_process(delta: float) -> void:
	if not active:
		return
	position += velocity * delta

	if not _is_on_screen():
		print("[bullet] ", self, " not in screen, despawning...")
		despawn()


func _draw() -> void:
	draw_circle(Vector2.ZERO, bullet_size, bullet_color)


func activate(pos: Vector2, vel: Vector2, size: float, color: Color = Color.RED) -> void:
	print("[bullet] ", self, " activating...")
	global_position = pos
	velocity = vel
	bullet_size = size
	bullet_color = color
	active = true
	visible = true
	monitoring = true
	monitorable = true
	queue_redraw()


func reset_state() -> void:
	active = false
	velocity = Vector2.ZERO
	visible = false
	monitoring = false
	monitorable = false


func despawn() -> void:
	if not active:
		return
		
	reset_state()
	on_despawn.call(self)


func _is_on_screen() -> bool:
	var viewport_rect := get_viewport().get_visible_rect()
	return viewport_rect.grow(100.0).has_point(global_position)
