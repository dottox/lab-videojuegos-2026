extends Area2D

signal blocked(projectile)

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var is_blocking := false
var _block_feedback_tween: Tween
var _sprite_base_scale := Vector2.ONE
var _sprite_base_modulate := Color.WHITE

func _ready() -> void:
	_sprite_base_scale = sprite.scale
	_sprite_base_modulate = sprite.modulate
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func set_shield_position(direction: Vector2):
	position = direction

func set_shield_position_anim(position: Vector2, anim_time: float):
	position = position.lerp(position, anim_time)

func set_sprite_opacity(opacity: float):
	sprite.modulate.a = opacity

func set_blocking(value: bool) -> void:
	is_blocking = value

func play_block_feedback() -> void:
	if _block_feedback_tween != null:
		_block_feedback_tween.kill()

	sprite.scale = _sprite_base_scale * 1.35
	sprite.modulate = Color(0.25, 0.9, 1.0, sprite.modulate.a)

	_block_feedback_tween = create_tween()
	_block_feedback_tween.set_parallel(true)
	_block_feedback_tween.tween_property(sprite, "scale", _sprite_base_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_block_feedback_tween.tween_property(sprite, "modulate", Color(_sprite_base_modulate.r, _sprite_base_modulate.g, _sprite_base_modulate.b, sprite.modulate.a), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_area_entered(area: Area2D) -> void:
	if not is_blocking:
		return
	var projectile_type := str(area.get("type")).strip_edges().to_lower()
	if area.has_method("play_shield_block_feedback") and projectile_type in ["bullet", "basic", "normal"]:
		play_block_feedback()
		area.play_shield_block_feedback()
		blocked.emit(area)
