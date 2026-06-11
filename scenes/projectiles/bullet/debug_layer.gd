extends Node2D

@onready var target: Projectile = $".."


func _draw():
	if target == null:
		return
	
	draw_rect(
		target.get_bounds(),
		Color.YELLOW,
		false,
		2.0
	)
	draw_rect(
		target.get_bounds(),
		Color(1.0, 1.0, 0.0, 0.302),
		true
	)
