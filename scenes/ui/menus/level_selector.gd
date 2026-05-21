extends Control

@onready var level_list = $CenterContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/LevelsList
@onready var regresar: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/Regresar

const LEVELS_PATH = "res://levels/"

func _ready():
	generate_level_buttons()
	regresar.pressed.connect(_on_back_pressed)

func generate_level_buttons():
	var dir = DirAccess.open(LEVELS_PATH)

	if dir == null:
		push_error("No se pudo abrir carpeta de niveles")
		return

	dir.list_dir_begin()

	var level_name = dir.get_next()
	while level_name != "":
		create_level_button(level_name)
		level_name = dir.get_next()

	dir.list_dir_end()
	
func create_level_button(level_name):
	var button = Button.new()

	button.text = level_name.capitalize().left(-4)
	
	var level_path = LEVELS_PATH + level_name

	button.pressed.connect(
		func():
			GameLoader.load_level(level_path)
	)

	level_list.add_child(button)

func _on_back_pressed():
	GameLoader.load_scene("main_menu")
