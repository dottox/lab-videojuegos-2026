extends Projectile
class_name Bullet

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var bullet_shape: CollisionShape2D = $CollisionShape2D
@onready var debug_layer: Node2D = $DebugLayer

var bullet_size: float = 2.5
var bullet_color: Color = Color.RED

func _ready() -> void:
	super._ready()
	if debug_layer:
		debug_layer.target = self
		debug_layer.z_index = 999

func _draw() -> void:
	draw_circle(Vector2.ZERO, bullet_size, bullet_color)


func activate(spawn_pos: Vector2, vel: Vector2, size: float = 2.5, color: Color = Color.RED) -> void:
	super.activate(spawn_pos, vel)
	bullet_size = size
	bullet_color = color
	
	if anim_player:
		anim_player.stop()
		anim_player.play("spawn_flash")
	
	queue_redraw()


func get_bounds() -> Rect2:
	var diametro := bullet_size * 2
	var top_left := Vector2(bullet_shape.position - Vector2(bullet_size, bullet_size))
	var down_right := Vector2(diametro, diametro)
	
	return Rect2(top_left, down_right)
