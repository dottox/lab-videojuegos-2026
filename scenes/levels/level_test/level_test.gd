extends Node2D

@onready var entities: Node2D = $Entities

var player_scene := preload("res://scenes/player/Player.tscn")
var player

func _ready():
	spawn_player()
	player.set_mode("normal")
	center_player()
	await get_tree().create_timer(10).timeout
	player.set_mode("shield")
	center_player()
	await get_tree().create_timer(10).timeout
	player.set_mode("normal")

func center_player():
	player.global_position = get_viewport().get_visible_rect().size / 2.0

func spawn_player():
	player = player_scene.instantiate()
	entities.add_child(player)
