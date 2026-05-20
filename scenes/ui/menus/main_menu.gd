extends Control

@onready var jugar: Button = $CenterContainer/VBoxContainer/Jugar
@onready var opciones: Button = $CenterContainer/VBoxContainer/Opciones
@onready var creditos: Button = $CenterContainer/VBoxContainer/Creditos
@onready var salir: Button = $CenterContainer/VBoxContainer/Salir
@onready var editor: Button = $CenterContainer/VBoxContainer/Editor


func _ready():
	GameLoader.start_background_loading()
	jugar.pressed.connect(_on_play_pressed)
	editor.pressed.connect(_on_editor_pressed)
	opciones.pressed.connect(_on_options_pressed)
	creditos.pressed.connect(_on_credits_pressed)
	salir.pressed.connect(_on_quit_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_play_pressed():
	GameLoader.load_scene("level_selector")

func _on_editor_pressed():
	GameLoader.load_scene("level_editor")
	
func _on_options_pressed():
	GameLoader.load_scene("opciones")
	
func _on_credits_pressed():
	GameLoader.load_scene("creditos")
	
func _on_quit_pressed():
	get_tree().quit()
	
