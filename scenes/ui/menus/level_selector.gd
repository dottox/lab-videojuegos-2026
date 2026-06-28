extends Control

@onready var level_list = $CenterContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/LevelsList
@onready var regresar: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/Regresar

const LEVELS_PATH = "res://levels/"
const DEFAULT_LEVEL_ORDER := 1000

func _ready():
	generate_level_buttons()
	GameLoader.install_menu_button_sfx(self)
	regresar.pressed.connect(_on_back_pressed)

func generate_level_buttons():
	var dir = DirAccess.open(LEVELS_PATH)

	if dir == null:
		push_error("No se pudo abrir carpeta de niveles")
		return

	dir.list_dir_begin()

	var levels := []
	var level_name = dir.get_next()
	while level_name != "":
		if not dir.current_is_dir() and level_name.get_extension().to_lower() == "cfg":
			levels.append(_read_level_entry(level_name))
		level_name = dir.get_next()

	dir.list_dir_end()

	levels.sort_custom(func(a, b):
		var order_a := int(a.get("order", DEFAULT_LEVEL_ORDER))
		var order_b := int(b.get("order", DEFAULT_LEVEL_ORDER))
		if order_a == order_b:
			return str(a.get("display_name", "")) < str(b.get("display_name", ""))
		return order_a < order_b
	)

	for level_entry in levels:
		create_level_button(level_entry)
	

func _read_level_entry(level_name: String) -> Dictionary:
	var level_path := LEVELS_PATH + level_name
	var display_name := level_name.get_basename().replace("_", " ").capitalize()
	var order := DEFAULT_LEVEL_ORDER

	var config := ConfigFile.new()
	if config.load(level_path) == OK:
		var meta_name := str(config.get_value("meta", "display_name", "")).strip_edges()
		if meta_name != "":
			display_name = meta_name
		order = int(config.get_value("meta", "order", order))

	return {
		"display_name": display_name,
		"order": order,
		"path": level_path,
	}


func create_level_button(level_entry: Dictionary):
	var button = Button.new()

	button.text = str(level_entry.get("display_name", ""))
	var level_path := str(level_entry.get("path", ""))

	button.pressed.connect(
		func():
			GameLoader.load_level(level_path)
	)

	level_list.add_child(button)

func _on_back_pressed():
	GameLoader.load_scene("main_menu")
