extends Node

signal loading_finished

var common_assets = {
	"player": "res://scenes/player/player.tscn",
	"playfield": "res://scenes/playfield/playfield.tscn",
	"bullet": "res://scenes/projectiles/bullet/bullet.tscn",
	"rythm_bar": "res://scenes/ui/progress_bar/progress_bar.tscn"
}

var loaded_resources = {}

func start_background_loading():
	print("[game_loader]: Cargando common assets...")
	
	for key in common_assets:
		var ca = common_assets[key]
		ResourceLoader.load_threaded_request(ca)
		print("[game_loader]: Asset " + ca + " cargado.")
		
	print("[game_loadder]: Common assets cargados")
	set_process(true)

func _process(_delta):
	var all_done = true
	start_background_loading()
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
	return loaded_resources.get(key)
	
