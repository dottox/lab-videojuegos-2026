extends Control

@onready var jugar: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/Jugar
@onready var tutorial: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/Tutorial
@onready var opciones: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/Opciones
@onready var creditos: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/Creditos
@onready var salir: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/Salir
@onready var editor: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/Editor
@onready var spawn_timer: Timer = $SpawnTimer
@onready var bullet_container: Node2D = $BulletContainer

var bullet_scene = preload("res://scenes/projectiles/bullet/bullet.tscn")

var level_loader

func _ready():
	GameLoader.install_menu_button_sfx(self)
	GameLoader.start_background_loading()
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	jugar.pressed.connect(_on_play_pressed)
	tutorial.pressed.connect(_on_tutorial_pressed)
	editor.pressed.connect(_on_editor_pressed)
	opciones.pressed.connect(_on_options_pressed)
	creditos.pressed.connect(_on_credits_pressed)
	salir.pressed.connect(_on_quit_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_spawn_timer_timeout() -> void:
	var pos := Vector2(
		randf_range(-100.0, get_viewport_rect().size.x + 100.0),
		randf_range(-100.0, get_viewport_rect().size.y + 100.0)
	)

	var count := randi_range(6, 14)
	var speed := randf_range(60.0, 180.0)

	var size := randf_range(1.5, 4.0)
	var color := Color(randf(), randf(), randf(), 1.0)

	for i in count:
		var angle := TAU * float(i) / float(count)
		var dir := Vector2.RIGHT.rotated(angle + randf_range(-0.2, 0.2))
		var bullet: Bullet = bullet_scene.instantiate()
		bullet.on_despawn = Callable(self, "_release_bullet")
		bullet_container.add_child(bullet)
		bullet.activate(pos, dir*speed, size, color)

func _release_bullet(bullet: Bullet) -> void:
	bullet.queue_free()
		
func _on_play_pressed():
	GameLoader.load_scene("level_selector")

func _on_tutorial_pressed():
	GameLoader.load_scene("tutorial_intro")

func _on_editor_pressed():
	GameLoader.load_scene("level_editor")
	
func _on_options_pressed():
	GameLoader.load_scene("opciones")
	
func _on_credits_pressed():
	GameLoader.load_scene("creditos")
	
func _on_quit_pressed():
	get_tree().quit()
	
