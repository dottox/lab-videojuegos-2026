extends Node2D

@onready var entities: Node2D = $Entities

var player_scene := preload("res://scenes/player/Player.tscn")
var player

var playfield_scene := preload("res://scenes/playfield/playfield.tscn")
var playfield

func _ready():
	spawn_playfield()
	spawn_player()
	

func spawn_player():
	player = player_scene.instantiate()
	entities.add_child(player)
	player.set_mode("shield")
	player.global_position = playfield.global_position
	player.playfield = playfield

	
func spawn_playfield():
	playfield = playfield_scene.instantiate()
	entities.add_child(playfield)
	playfield.set_state("normal")
	playfield.global_position = (get_viewport().get_visible_rect().size / 2.0) + Vector2(0, 100)
	
