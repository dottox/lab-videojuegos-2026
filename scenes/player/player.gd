extends CharacterBody2D

#Variables relacionadas a debug
var debug_dash_dir := Vector2.ZERO
var debug_dash_length := 0.0

#Variables relacionadas al state
var current_state
const NormalState = preload("res://scenes/player/states/normal_state.gd")
const ShieldState = preload("res://scenes/player/states/shield_state.gd")

#Variables relacionadas a los sprites/animaciones
@onready var player_sprite: Sprite2D = $Sprite2D

#Variables relacionadas al playfield
var playfield: Area2D

func _ready():
	set_mode("normal")

func _draw():
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

func _physics_process(delta):
	current_state.physics_update(self, delta)

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
