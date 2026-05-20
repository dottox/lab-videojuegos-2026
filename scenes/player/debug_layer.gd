extends Node2D

@export var target: CharacterBody2D

func _draw():
	if target == null:
		return
	
	draw_rect(
		target.get_bounds(),
		Color.CRIMSON,
		false,
		2.0
	)
	draw_rect(
		target.get_bounds(),
		Color(1, 0, 0, 0.3),
		true
	)
