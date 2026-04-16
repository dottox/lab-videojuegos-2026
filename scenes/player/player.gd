extends CharacterBody2D

var current_state
const NormalState = preload("res://scenes/player/states/normal_state.gd")
const ShieldState = preload("res://scenes/player/states/shield_state.gd")

func _ready():
	set_mode("normal")

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
