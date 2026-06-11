extends CharacterBody2D

#Variables relacionada a eventos
signal died
signal death_started
signal health_changed(current_health: int, max_health: int)
signal shield_blocked(projectile)

#Variables comunes entre estados
var max_vida := 10
var vida := max_vida
var is_dead := false

#Variables relacionadas a debug
var debug_dash_dir := Vector2.ZERO
var debug_dash_length := 0.0


#Variables relacionadas al state
var current_state
var current_mode := ""
const NormalState = preload("res://scenes/player/states/normal_state.gd")
const ShieldState = preload("res://scenes/player/states/shield_state.gd")

#Variables relacionadas a los sprites/animaciones
@onready var player_sprite: Sprite2D = $Sprite2D
@onready var player_shape: CollisionShape2D = $CollisionShape2D
@onready var debug_layer: Node2D = $DebugLayer
var _hit_feedback_tween: Tween
var _player_sprite_base_scale := Vector2.ONE
var _player_sprite_base_modulate := Color.WHITE

#Variables relacionadas al playfield
var playfield: Area2D

func _ready():
	vida = max_vida
	_player_sprite_base_scale = player_sprite.scale
	_player_sprite_base_modulate = player_sprite.modulate
	debug_layer.target = self
	debug_layer.z_index = 999
	add_to_group("player")
	if not GameLoader.debug_draw_toggled.is_connected(_on_debug_draw_toggled):
		GameLoader.debug_draw_toggled.connect(_on_debug_draw_toggled)
	set_mode("normal")
	health_changed.emit(vida, max_vida)

func _draw():
	if not GameLoader.debug_draw_enabled:
		return
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


func _on_debug_draw_toggled(_enabled: bool) -> void:
	queue_redraw()

func _physics_process(delta):
	if is_dead:
		return
	
	current_state.physics_update(self, delta)
	queue_redraw()

func change_state(new_state):
	if current_state:
		current_state.exit(self)

	current_state = new_state
	current_state.enter(self)

func set_mode(mode: String):
	if current_mode == mode:
		return

	match mode:
		"normal":
			change_state(NormalState.new())
		"shield":
			change_state(ShieldState.new())
		_:
			return
	current_mode = mode
			
func get_half_size() -> Vector2:
	return player_sprite.texture.get_size() * player_sprite.scale * 0.5


func get_bounds() -> Rect2:
	var rect := player_shape.shape.get_rect()

	# posición del CollisionShape relativa al Player
	var local_pos := player_shape.position + rect.position
	
	return Rect2(local_pos, rect.size)

func receive_hit():
	if is_dead:
		return

	vida = max(vida - 1, 0)
	health_changed.emit(vida, max_vida)
	play_hit_feedback()

	if vida <= 0:
		_on_death()

func play_hit_feedback() -> void:
	if _hit_feedback_tween != null:
		_hit_feedback_tween.kill()

	player_sprite.scale = _player_sprite_base_scale * 1.22
	player_sprite.modulate = Color(1.0, 0.25, 0.25, 1.0)

	_hit_feedback_tween = create_tween()
	_hit_feedback_tween.set_parallel(true)
	_hit_feedback_tween.tween_property(player_sprite, "scale", _player_sprite_base_scale, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hit_feedback_tween.tween_property(player_sprite, "modulate", _player_sprite_base_modulate, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_shield_blocked(projectile) -> void:
	shield_blocked.emit(projectile)

func _on_death() -> void:
	if is_dead:
		return

	is_dead = true
	death_started.emit()
	velocity = Vector2.ZERO
	player_shape.set_deferred("disabled", true)
	if current_state:
		current_state.exit(self)
		current_state = null

	if _hit_feedback_tween != null:
		_hit_feedback_tween.kill()

	var death_tween := create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(player_sprite, "scale", _player_sprite_base_scale * 2.1, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	death_tween.tween_property(player_sprite, "rotation", player_sprite.rotation + TAU, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	death_tween.tween_property(player_sprite, "modulate", Color(1.0, 0.15, 0.1, 0.0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await death_tween.finished
	died.emit()
	queue_free() #BORRA al jugador
