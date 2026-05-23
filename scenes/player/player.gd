extends CharacterBody2D

#Variables relacionada a eventos
signal died

#Variables comunes entre estados
var vida := 10

#Variables relacionadas a debug
var debug_dash_dir := Vector2.ZERO
var debug_dash_length := 0.0

#Variables relacionadas al state
var current_state
const NormalState = preload("res://scenes/player/states/normal_state.gd")
const ShieldState = preload("res://scenes/player/states/shield_state.gd")

#Variables relacionadas a los sprites/animaciones
@onready var player_sprite: Sprite2D = $Sprite2D
@onready var player_shape: CollisionShape2D = $CollisionShape2D
@onready var debug_layer: Node2D = $DebugLayer

#Variables relacionadas al playfield
var playfield: Area2D

func _ready():
	debug_layer.target = self
	debug_layer.z_index = 999
	add_to_group("player") #Defino un grupo 'player' para las colisiones
	set_mode("normal")

func _draw():
	debug_normal_mode()

func _physics_process(delta):
	if vida <= 0:
		_on_death()
	
	current_state.physics_update(self, delta)
	queue_redraw()

func change_state(new_state):
	if current_state:
		current_state.exit(self)

	current_state = new_state
	current_state.enter(self)

func set_mode(mode: String):
	match mode:
		"normal":
			change_state(NormalState.new())
		"shield":
			change_state(ShieldState.new())
			
func get_half_size() -> Vector2:
	return player_sprite.texture.get_size() * player_sprite.scale * 0.5
	
func debug_normal_mode():
	if debug_dash_dir == Vector2.ZERO:
		return

	var final_point = debug_dash_dir * debug_dash_length
	var half = get_half_size()
	var debug_dash = Rect2(
		final_point.x - half.x,
		final_point.y - half.y,
		half.x * 2,
		half.y * 2
	)
	
	draw_rect(
		debug_dash,
		Color.CADET_BLUE
		)
		
	draw_line(
		Vector2.ZERO,
		final_point,
		Color.RED,
		2
	)

func get_bounds() -> Rect2:
	var rect := player_shape.shape.get_rect()

	# posición del CollisionShape relativa al Player
	var local_pos := player_shape.position + rect.position
	
	return Rect2(local_pos, rect.size)

func receive_hit():
	vida -= 1
	print(vida)

func _on_death():
	died.emit()
	queue_free() #BORRA al jugador
