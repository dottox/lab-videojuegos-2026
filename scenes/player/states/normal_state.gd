extends PlayerState

#Variables relacionadas al player
var player_speed = 200

#Variables relacionadas al dash
var dash_speed := 5.0
var dash_time := 0.1
var dash_timer := 0.0
var is_dashing := false
var dash_cooldown := 0.0
var dash_cooldown_time := 0.25 #En segundos, ya que utilizamos delta

func physics_update(player, delta):
	
	#Reducir cooldown por cada update/frame
	update_cooldown(delta)
	
	if Input.is_action_just_pressed("dash") && can_dash():
		start_dash(player) 
	
	#Si está dasheando, queremos que termine de dashear.
	if is_dashing:
		update_dash(player, delta)
		return
	
	movement(player)
	if player.playfield:
		clam_to_playfield(player, player.playfield.get_bounds())


func movement(player):
	var direction = Input.get_vector("izquierda", "derecha", "arriba", "abajo")

	player.velocity = direction * player_speed
	player.move_and_slide()
	
func can_dash() -> bool:
	return not is_dashing and dash_cooldown <= 0
	
func start_dash(player):
	is_dashing = true
	dash_timer = dash_time
	dash_cooldown = dash_cooldown_time
	player.velocity *= dash_speed
	
func update_dash(player, delta):
	dash_timer -= delta
	
	if dash_timer <= 0:
		is_dashing = false
		return
	player.move_and_slide()
	
func update_cooldown(delta):
	#print(dash_cooldown)
	if dash_cooldown > 0:
		dash_cooldown -= delta
	
func clam_to_playfield(player, bounds: Rect2):
	var half = player.get_half_size()
	
	player.global_position.x = clamp(
		player.global_position.x,
		bounds.position.x + half.x,
		bounds.end.x - half.x
	)

	player.global_position.y = clamp(
		player.global_position.y,
		bounds.position.y + half.y,
		bounds.end.y - half.y
	)
	
