extends Node

signal loading_finished

var common_assets = {
	"player": "res://scenes/player/player.tscn",
	"playfield": "res://scenes/playfield/playfield.tscn",
	"bullet": "res://scenes/projectiles/bullet/bullet.tscn",
	"rythm_bar": "res://scenes/ui/progress_bar/progress_bar.tscn",
	"main_menu": "res://scenes/ui/menus/main_menu.tscn",
	"level_selector": "res://scenes/ui/menus/level_selector.tscn",
	"level_editor": "res://scenes/level_editor/level_editor.tscn",
	"level_loader": "res://scenes/levels/level_loader.tscn",
	"opciones": "",
	"creditos": "",
}

var loaded_resources = {}

func start_background_loading():
	print("[game_loader]: Cargando common assets...")
	
	for key in common_assets:
		var ca = common_assets[key]
		ResourceLoader.load_threaded_request(ca)
		print("[game_loader]: Asset " + ca + " cargado.")
		
	print("[game_loader]: Common assets cargados")
	set_process(true)

func _process(_delta):
	var all_done = true
	for key in common_assets:
		var status = ResourceLoader.load_threaded_get_status(common_assets[key])
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			loaded_resources[key] = ResourceLoader.load_threaded_get(common_assets[key])
			print("[game_loader] added " + key + " to loaded resources")
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			all_done = false
			
	if all_done:
		set_process(false)
		loading_finished.emit()

func get_asset(key: String) -> PackedScene:
	var res = loaded_resources.get(key)
	if res == null:
		print("[game_loader] asking for a non-existant key: ", key)
	return res
	
func load_scene(key: String):
	var scene: PackedScene = get_asset(key)
	
	if scene == null:
		push_error("[GameLoader] Escena no encontrada: " + key)
		return
	
	print("[GameLoader] Cambiando a:", key)

	get_tree().change_scene_to_packed(scene)
	
func load_level(level_name: String):
	var level_loader_scene: PackedScene = get_asset("level_loader")
	if level_loader_scene == null:
		push_error("[GameLoader] level_loader no encontrado")
		return

	var loader_scene = level_loader_scene.instantiate()
	loader_scene.level_path = level_name

	var tree = get_tree()
	tree.root.add_child(loader_scene)

	if tree.current_scene:
		tree.current_scene.queue_free()

	tree.current_scene = loader_scene
