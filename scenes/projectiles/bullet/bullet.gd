extends Projectile
class_name Bullet

@export var sprite_scale := 0.18

# If scissors0.png points right → 0
# If scissors0.png points up → PI / 2
# If scissors0.png points down → -PI / 2
# If scissors0.png points left → PI
@export var rotation_offset := 0.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var bullet_shape: CollisionShape2D = $CollisionShape2D
@onready var debug_layer: Node2D = $DebugLayer
@onready var sprite: Sprite2D = $Sprite2D

const SCISSOR_TEXTURE := preload("res://assets/sprites/scissors/scissors0.png")

var bullet_size: float = 2.5
var bullet_color: Color = Color.WHITE
var direction := Vector2.RIGHT


func _ready() -> void:
	super._ready()

	if debug_layer:
		debug_layer.target = self
		debug_layer.z_index = 999

	if sprite:
		sprite.texture = SCISSOR_TEXTURE
		sprite.centered = true
		sprite.scale = Vector2.ONE * sprite_scale
		sprite.modulate = bullet_color


func activate(
	spawn_pos: Vector2,
	vel: Vector2,
	size: float = 2.5,
	color: Color = Color.WHITE
) -> void:
	super.activate(spawn_pos, vel)

	bullet_size = size

	if color != Color.TRANSPARENT:
		bullet_color = color

	_update_sprite_from_velocity(vel)

	if anim_player:
		anim_player.stop()
		anim_player.play("spawn_flash")

	queue_redraw()


func _update_sprite_from_velocity(vel: Vector2) -> void:
	if not sprite:
		return

	if vel != Vector2.ZERO:
		direction = vel.normalized()

	sprite.texture = SCISSOR_TEXTURE
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.modulate = bullet_color
	sprite.rotation = direction.angle() + rotation_offset
	
func get_bounds() -> Rect2:
	if bullet_shape and bullet_shape.shape:
		var rect := bullet_shape.shape.get_rect()
		return Rect2(bullet_shape.position + rect.position, rect.size)

	if sprite and sprite.texture:
		var size := sprite.texture.get_size() * sprite.scale
		return Rect2(-size * 0.5, size)

	var diameter := bullet_size * 2.0
	return Rect2(Vector2(-bullet_size, -bullet_size), Vector2(diameter, diameter))
