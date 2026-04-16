extends PlayerState

#Variables relacionadas al escudo
var shield_scene = preload("res://scenes/player/states/shield.tscn")
var shield
var shield_distance = 25

func enter(player):
	shield = shield_scene.instantiate()
	player.add_child(shield)
	shield.position = Vector2(0, shield_distance)

func exit(player):
	if shield:
		shield.queue_free()
		shield = null

func physics_update(player, delta):
	shield_movement()


func shield_movement():
	var direction = Input.get_vector("izquierda","derecha","arriba","abajo")

	if direction == Vector2.ZERO:
		return

	if abs(direction.x) > abs(direction.y):
		shield.position = Vector2(sign(direction.x) * shield_distance, 0)
	else:
		shield.position = Vector2(0, sign(direction.y) * shield_distance)
