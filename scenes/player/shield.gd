extends Area2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

func set_shield_position(direction: Vector2):
	position = direction

func set_shield_position_anim(position: Vector2, anim_time: float):
	position = position.lerp(position, anim_time)

func set_sprite_opacity(opacity: float):
	sprite.modulate.a = opacity
