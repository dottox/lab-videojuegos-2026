extends PlayerState

var shield_scene = preload("res://scenes/player/shield.tscn")
var shield

#Variables relacionadas a la mecánica
var shield_distance = 25
var shield_cooldown = 0.0
var cooldown_time = 0.1

#Variables relacionadas a la animacion
var shield_anim_t := 0.0
var shield_anim_speed := 10.0
var shield_target_dir := Vector2.ZERO

var direction := Vector2.ZERO

func enter(player):
	shield = shield_scene.instantiate()
	player.add_child(shield)
	shield.position = Vector2.ZERO
	shield.set_sprite_opacity(1.0)

func exit(player):
	if shield:
		shield.queue_free()
		shield = null

func physics_update(player, delta):

	# cooldown
	if shield_cooldown > 0:
		shield_cooldown -= delta

	direction = get_cardinal_press()

	if can_shield() and direction != Vector2.ZERO:
		start_shielding()

	update_shield(delta)


func start_shielding():
	shield_cooldown = cooldown_time
	shield_anim_t = 0.0
	shield.set_shield_position(direction * shield_distance)

func update_shield(delta):
	var active: bool = shield_cooldown > 0

	if active:
		shield_anim_t = 1
	else:
		shield_anim_t = max(shield_anim_t - delta * shield_anim_speed, 0.0)

	shield.set_sprite_opacity(shield_anim_t)

	if direction == Vector2.ZERO and shield_anim_t == 0:
		shield.set_shield_position(Vector2.ZERO)
		return

func can_shield() -> bool:
	return shield_cooldown <= 0

func get_cardinal_press() -> Vector2:
	if Input.is_action_just_pressed("arriba"):
		return Vector2.UP
	if Input.is_action_just_pressed("abajo"):
		return Vector2.DOWN
	if Input.is_action_just_pressed("derecha"):
		return Vector2.RIGHT
	if Input.is_action_just_pressed("izquierda"):
		return Vector2.LEFT

	return Vector2.ZERO
