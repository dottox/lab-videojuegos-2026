extends Area2D
class_name Bullet

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var bullet_shape: CollisionShape2D = $CollisionShape2D
@onready var debug_layer: Node2D = $DebugLayer

var time_ms: int
var pos: Vector2 = Vector2.ZERO
var speed: float = 200
var angle: int = 0 
var type: String = "normal"
var pattern: String = "single"
var zone_id: int

var velocity: Vector2 = Vector2.ZERO
var bullet_size: float = 2.5
var bullet_color: Color = Color.RED
var on_despawn: Callable = Callable()
var active: bool = false

func _ready() -> void:
	if debug_layer:
		debug_layer.target = self
		debug_layer.z_index = 999
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:	
	if not active:
		return
	position += velocity * delta

	if not _is_on_screen():
		#print("[bullet] ", self, " not in screen, despawning...")
		despawn()


func _draw() -> void:
	draw_circle(Vector2.ZERO, bullet_size, bullet_color)


func activate(pos: Vector2, vel: Vector2, size: float, color: Color = Color.RED) -> void:
	#print("[bullet] ", self, " activating...")
	global_position = pos
	velocity = vel
	bullet_size = size
	bullet_color = color
	active = true
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	
	if anim_player:
		anim_player.stop()
		anim_player.play("spawn_flash")
	
	queue_redraw()


func reset_state() -> void:
	active = false
	velocity = Vector2.ZERO
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	position = Vector2.ZERO


func despawn() -> void:
	if not active:
		return
		
	reset_state()
	on_despawn.call(self)


func _is_on_screen() -> bool:
	var viewport_rect := get_viewport().get_visible_rect()
	return viewport_rect.grow(100.0).has_point(global_position)

func get_bounds() -> Rect2:
	var shape := bullet_shape.shape as CircleShape2D
	
	var diametro := bullet_size * 2
	
	var top_left := Vector2(bullet_shape.position - Vector2(bullet_size, bullet_size))
	var down_right := Vector2(diametro, diametro)
	
	return Rect2(top_left, down_right)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.receive_hit() #Esto le indica al jugador que recibió un hit
		despawn()
