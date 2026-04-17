extends Area2D

var velocity: Vector2
var bullet_size = 2.5
var bullet_color = Color.RED

func _physics_process(delta):
	position += velocity * delta

func _draw():
	draw_circle(Vector2.ZERO, bullet_size, bullet_color)

func set_bullet_velocity(vel: Vector2):
	velocity = vel
	
func set_bullet_size(size: float):
	bullet_size = size
