extends Node2D

@export var target: CharacterBody2D

func _ready() -> void:
	visible = GameLoader.debug_draw_enabled
	if not GameLoader.debug_draw_toggled.is_connected(_on_debug_draw_toggled):
		GameLoader.debug_draw_toggled.connect(_on_debug_draw_toggled)


func _draw():
	if not GameLoader.debug_draw_enabled:
		return
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


func _on_debug_draw_toggled(enabled: bool) -> void:
	visible = enabled
	queue_redraw()
