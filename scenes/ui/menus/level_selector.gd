extends Control

@onready var level_list = $ScrollContainer/VBoxContainer
@onready var regresar: Button = $ScrollContainer/VBoxContainer/Regresar

const LEVELS_PATH = "res://scenes/levels/"

func _ready():
	generate_level_buttons()
	regresar.pressed.connect(_on_back_pressed)

func generate_level_buttons():
	var dir = DirAccess.open(LEVELS_PATH)

	if dir == null:
		push_error("No se pudo abrir carpeta de niveles")
		return

	dir.list_dir_begin()

	var folder_name = dir.get_next()

	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			create_level_button(folder_name)

		folder_name = dir.get_next()

	dir.list_dir_end()
	
func create_level_button(level_dir):
	var button = Button.new()

	button.text = level_dir.capitalize()

	var level_scene_path = LEVELS_PATH + level_dir + "/" + level_dir + ".tscn"

	button.pressed.connect(
		func():
			on_level_selected(level_dir)
	)

	level_list.add_child(button)

func on_level_selected(path):
	GameLoader.load_scene(path)

func _on_back_pressed():
	GameLoader.load_scene("main_menu")
