extends CharacterBody2D

const speed = 300
const dashValue = 10
var dashCooldown = 0
var dashCooldownTime = 2 * 60 #Hacemos * 60, debido a que godot maneja 60 cuadros por segundo.

func resetCooldowns():
	if dashCooldown > 0:
		dashCooldown = dashCooldown - 1

func get_input():
	#direction values: izquierda (-1,0), derecha (1,0), arriba(0,-1), abajo(0,1)
	var direction = Input.get_vector("izquierda","derecha","arriba","abajo")
	velocity = direction * speed
	
	if Input.is_action_just_pressed("dash") && dashCooldown <= 0:
		#Aumentar Speed 
		velocity *= dashValue 
		dashCooldown = dashCooldownTime
	
func _physics_process(delta):
	resetCooldowns()
	get_input()
	move_and_slide()
