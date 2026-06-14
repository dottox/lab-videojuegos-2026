extends Node

signal loading_finished
signal debug_draw_toggled(enabled: bool)

const DEBUG_TOGGLE_ACTION := "toggle_debug_draw"
const PAUSE_ACTION := "pause_game"

var common_assets = {
	"player": "res://scenes/player/player.tscn",
	"playfield": "res://scenes/playfield/playfield.tscn",
	"bullet": "res://scenes/projectiles/bullet/bullet.tscn",
	"rhythm_note": "res://scenes/projectiles/rhythm_note/rhythm_note.tscn",
	"rythm_bar": "res://scenes/ui/progress_bar/progress_bar.tscn",
	"main_menu": "res://scenes/ui/menus/main_menu.tscn",
	"level_selector": "res://scenes/ui/menus/level_selector.tscn",
	"level_editor": "res://scenes/level_editor/level_editor.tscn",
	"level_loader": "res://scenes/level_loader/level_loader.tscn",
	"opciones": "res://scenes/ui/menus/options_menu.tscn",
	"creditos": "res://scenes/ui/menus/credits.tscn",
	"pause_overlay": "res://scenes/ui/menus/pause_overlay.tscn",
	"death_overlay": "res://scenes/ui/menus/death_overlay.tscn",
	"level_complete_overlay": "res://scenes/ui/menus/level_complete_overlay.tscn",
}

var loaded_resources = {}
var sync_asset_keys := {
	"rhythm_note": true,
}

var debug_draw_enabled := false

func _ready() -> void:
	_ensure_debug_toggle_action()
	_ensure_pause_action()
	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return

	if event.is_action_pressed(DEBUG_TOGGLE_ACTION):
		set_debug_draw_enabled(not debug_draw_enabled)
		get_viewport().set_input_as_handled()


func set_debug_draw_enabled(enabled: bool) -> void:
	if debug_draw_enabled == enabled:
		return

	debug_draw_enabled = enabled
	debug_draw_toggled.emit(debug_draw_enabled)


func _ensure_debug_toggle_action() -> void:
	_ensure_action_with_key(DEBUG_TOGGLE_ACTION, KEY_QUOTELEFT)


func _ensure_pause_action() -> void:
	_ensure_action_with_key(PAUSE_ACTION, KEY_ESCAPE)


func _ensure_action_with_key(action_name: String, physical_keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var event := InputEventKey.new()
	event.physical_keycode = physical_keycode

	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)
	
func start_background_loading():
	print("[game_loader]: Cargando common assets...")
	
	for key in common_assets:
		var ca = common_assets[key]
		if ca == "":
			continue
		if sync_asset_keys.has(key):
			loaded_resources[key] = load(ca)
			print("[game_loader]: Asset " + ca + " cargado.")
			continue
		ResourceLoader.load_threaded_request(ca)
		print("[game_loader]: Asset " + ca + " cargado.")
		
	print("[game_loader]: Common assets cargados")
	set_process(true)

func _process(_delta):
	var all_done = true
	for key in common_assets:
		if loaded_resources.has(key) or common_assets[key] == "":
			continue
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
