extends Node2D

const LevelEditorState = preload("res://scenes/level_editor/level_editor_state.gd")
const LevelEditorZones = preload("res://scenes/level_editor/level_editor_zones.gd")
const LevelEditorProjectiles = preload("res://scenes/level_editor/level_editor_projectiles.gd")
const LevelEditorPhases = preload("res://scenes/level_editor/level_editor_phases.gd")
const LevelEditorIO = preload("res://scenes/level_editor/level_editor_io.gd")

const LevelLoader = preload("res://scenes/level_loader/level_loader.gd")

const ProjectileMarkerScene := preload("res://scenes/level_editor/projectile_marker.tscn")
const ZoneAreaScene := preload("res://scenes/zone/zone_area.tscn")
const PlayfieldScene := preload("res://scenes/playfield/playfield.tscn")
const LivePreviewScene := preload("res://scenes/level_loader/level_loader.tscn")

const PROJECTILE_ENUM_PATHS: Array[String] = [
	"res://scenes/projectiles/bullet/bullet.gd"
]
const PLAYFIELD_ENUM_PATHS: Array[String] = [
	"res://scenes/playfield/playfield.gd"
]
const PROJECTILE_PATTERN_ENUM_PATH: String = "res://scenes/projectiles/bullet/bullet_patterns.gd"
const PHASE_TYPES_ENUM_PATH: String = "res://scenes/phase/phase.gd"

const PROJECTILE_PREVIEW_WINDOW_MS := 2000
const ZONE_DEFAULT_MARGIN := 20.0
const ZONES_PER_ROW := 2

const Z_INDEX_ZONES := -10
const Z_INDEX_PLAYFIELD := 0
const Z_INDEX_PROJECTILES := 10

const PREVIEW_EXPORT_PATH := "res://level_preview.cfg"

@onready var playfields_layer: Node2D = $PlayfieldsLayer
@onready var zones_layer: Node2D = $ZonesLayer
@onready var projectiles_layer: Node2D = $ProjectilesLayer
@onready var live_preview_layer: Node2D = $LivePreviewLayer
@onready var music_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var preview_toggle_button: Button = $PreviewControls/PreviewToggleButton
@onready var live_preview_button: Button = $PreviewControls/LivePreviewButton
@onready var ui_root: Control = $CanvasLayer/UI/Root
@onready var ui_content: Control = $CanvasLayer/UI/Root/Content
@onready var ui_bottom_bar: Control = $CanvasLayer/UI/Root/BottomBar

@onready var exit_button: Button = $CanvasLayer/UI/Root/TopBar/ExitButton
@onready var load_music_button: Button = $CanvasLayer/UI/Root/TopBar/LoadMusicButton
@onready var music_id_edit: LineEdit = $CanvasLayer/UI/Root/TopBar/MusicIdEdit
@onready var bpm_spin: SpinBox = $CanvasLayer/UI/Root/TopBar/BpmSpin
@onready var play_button: Button = $CanvasLayer/UI/Root/TopBar/PlayButton
@onready var pause_button: Button = $CanvasLayer/UI/Root/TopBar/PauseButton
@onready var step_back_button: Button = $CanvasLayer/UI/Root/TopBar/StepBackButton
@onready var step_forward_button: Button = $CanvasLayer/UI/Root/TopBar/StepForwardButton
@onready var timeline_slider: HSlider = $CanvasLayer/UI/Root/TopBar/TimelineSlider
@onready var time_label: Label = $CanvasLayer/UI/Root/TopBar/TimeLabel

@onready var playfield_list: ItemList = $CanvasLayer/UI/Root/Content/PPSeparator/PlayfieldPanel/PlayfieldVBox/PlayfieldList
@onready var add_playfield_button: Button = $CanvasLayer/UI/Root/Content/PPSeparator/PlayfieldPanel/PlayfieldVBox/PlayfieldButtons/AddPlayfieldButton
@onready var remove_playfield_button: Button = $CanvasLayer/UI/Root/Content/PPSeparator/PlayfieldPanel/PlayfieldVBox/PlayfieldButtons/RemovePlayfieldButton
@onready var playfield_pos_x_spin: SpinBox = $CanvasLayer/UI/Root/Content/PPSeparator/PlayfieldPanel/PlayfieldVBox/PlayfieldGrid/PlayfieldPosXSpin
@onready var playfield_pos_y_spin: SpinBox = $CanvasLayer/UI/Root/Content/PPSeparator/PlayfieldPanel/PlayfieldVBox/PlayfieldGrid/PlayfieldPosYSpin
@onready var playfield_width_spin: SpinBox = $CanvasLayer/UI/Root/Content/PPSeparator/PlayfieldPanel/PlayfieldVBox/PlayfieldGrid/PlayfieldWidthSpin
@onready var playfield_height_spin: SpinBox = $CanvasLayer/UI/Root/Content/PPSeparator/PlayfieldPanel/PlayfieldVBox/PlayfieldGrid/PlayfieldHeightSpin

@onready var phase_list: ItemList = $CanvasLayer/UI/Root/Content/PPSeparator/Phase/PhaseVBox/PhaseList
@onready var add_phase_button: Button = $CanvasLayer/UI/Root/Content/PPSeparator/Phase/PhaseVBox/PhaseButtons/AddPhaseButton
@onready var remove_phase_button: Button = $CanvasLayer/UI/Root/Content/PPSeparator/Phase/PhaseVBox/PhaseButtons/RemovePhaseButton
@onready var phase_type_option: OptionButton = $CanvasLayer/UI/Root/Content/PPSeparator/Phase/PhaseVBox/PhaseGrid/PhaseTypeOption
@onready var phase_time_spin: SpinBox = $CanvasLayer/UI/Root/Content/PPSeparator/Phase/PhaseVBox/PhaseGrid/PhaseTimeSpin

@onready var zone_list: ItemList = $CanvasLayer/UI/Root/Content/ZonesPanel/ZonesVBox/ZoneList
@onready var add_zone_button: Button = $CanvasLayer/UI/Root/Content/ZonesPanel/ZonesVBox/ZoneButtons/AddZoneButton
@onready var remove_zone_button: Button = $CanvasLayer/UI/Root/Content/ZonesPanel/ZonesVBox/ZoneButtons/RemoveZoneButton
@onready var zone_id_edit: LineEdit = $CanvasLayer/UI/Root/Content/ZonesPanel/ZonesVBox/ZoneIdEdit
@onready var zone_pos_x_spin: SpinBox = $CanvasLayer/UI/Root/Content/ZonesPanel/ZonesVBox/ZoneGrid/ZonePosXSpin
@onready var zone_pos_y_spin: SpinBox = $CanvasLayer/UI/Root/Content/ZonesPanel/ZonesVBox/ZoneGrid/ZonePosYSpin
@onready var zone_width_spin: SpinBox = $CanvasLayer/UI/Root/Content/ZonesPanel/ZonesVBox/ZoneGrid/ZoneWidthSpin
@onready var zone_height_spin: SpinBox = $CanvasLayer/UI/Root/Content/ZonesPanel/ZonesVBox/ZoneGrid/ZoneHeightSpin

@onready var projectile_list: ItemList = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileList
@onready var delete_projectile_button: Button = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileButtons/DeleteProjectileButton
@onready var projectile_time_spin: SpinBox = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileGrid/ProjectileTimeSpin
@onready var projectile_pos_x_spin: SpinBox = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileGrid/ProjectilePosXSpin
@onready var projectile_pos_y_spin: SpinBox = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileGrid/ProjectilePosYSpin
@onready var projectile_speed_spin: SpinBox = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileGrid/ProjectileSpeedSpin
@onready var projectile_angle_spin: SpinBox = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileGrid/ProjectileAngleSpin
@onready var projectile_type_option: OptionButton = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileGrid/ProjectileTypeOption
@onready var projectile_pattern_option: OptionButton = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileGrid/ProjectilePatternOption
@onready var projectile_area_option: OptionButton = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileGrid/ProjectileAreaOption

@onready var export_button: Button = $CanvasLayer/UI/Root/BottomBar/ExportButton
@onready var import_button: Button = $CanvasLayer/UI/Root/BottomBar/ImportButton
@onready var status_label: Label = $CanvasLayer/UI/Root/BottomBar/StatusLabel

@onready var music_file_dialog: FileDialog = $CanvasLayer/MusicFileDialog
@onready var export_dialog: FileDialog = $CanvasLayer/ExportDialog
@onready var import_dialog: FileDialog = $CanvasLayer/ImportDialog

var playfield
var state := LevelEditorState.new()
var live_preview

var zones_component: LevelEditorZones
var projectiles_component: LevelEditorProjectiles
var playfields_component: LevelEditorPlayfields
var phases_component: LevelEditorPhases
var io_component: LevelEditorIO
var level_loader_component: LevelLoader

# Inicializa los componentes y prepara el editor.
func _ready() -> void:
	playfields_component = LevelEditorPlayfields.new()
	playfields_component.initialize(self)
	
	phases_component = LevelEditorPhases.new()
	phases_component.initialize(self)
	
	zones_component = LevelEditorZones.new()
	zones_component.initialize(self)

	projectiles_component = LevelEditorProjectiles.new()
	projectiles_component.initialize(self)

	io_component = LevelEditorIO.new()
	io_component.initialize(self)

	set_process_unhandled_input(true)
	_setup_layers()
	#_init_playfield()
	_load_enums()
	_setup_option_buttons()
	_setup_ui()
	_update_timeline_range()
	_update_status("Ready")

# Sincroniza el tiempo de reproducción con el audio mientras está activo.
func _process(_delta: float) -> void:
	if state.is_playing and music_player.playing and not music_player.stream_paused:
		var playback_position = music_player.get_playback_position()
		if state.music_length_ms > 0:
			playback_position = clamp(playback_position, 0.0, state.music_length_ms / 1000.0)
		else:
			playback_position = max(playback_position, 0.0)
		var new_time = int(playback_position * 1000.0)
		if new_time != state.current_time_ms:
			_set_current_time_ms(new_time, false)
	elif state.is_playing and not music_player.playing:
		state.is_playing = false

# Permite crear proyectiles con click dentro del playfield.
func _input(event: InputEvent) -> void:
	if !(state.preview_mode):
		return
	
	# SHIFT: Mover proyectiles
	# CTRL: Crear proyectiles
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_SHIFT:
				state.dragging_projectile = true
				_select_projectile_close_to_mouse()
				_move_selected_projectile_to_mouse()
			if event.keycode == KEY_CTRL and not state.dragging_projectile:
				print("InputEvent: Creating projectile...")
				projectiles_component.create_projectile_at(get_global_mouse_position())
		else:
			state.dragging_projectile = false
	
	if event is InputEventMouseMotion and state.dragging_projectile:
		_move_selected_projectile_to_mouse()

func _select_projectile_close_to_mouse(max_radius: float = 64.0) -> void:
	if state.projectiles.is_empty():
		return

	var mouse_pos := get_global_mouse_position()
	var closest_index := -1
	var closest_dist := max_radius

	for i in range(state.projectiles.size()):
		var proj = state.projectiles[i]
		if proj == null or not proj.visible:
			continue

		var dist := mouse_pos.distance_to(proj.pos)
		if dist <= closest_dist:
			closest_dist = dist
			closest_index = i

	if closest_index != -1:
		projectiles_component.select_projectile(closest_index)

func _move_selected_projectile_to_mouse() -> void:
	if state.selected_projectile_index < 0 or state.selected_projectile_index >= state.projectiles.size():
		return
	var data = state.projectiles[state.selected_projectile_index]
	var pos = get_global_mouse_position()
	data["pos"] = pos
	state.projectiles[state.selected_projectile_index] = data
	projectile_pos_x_spin.value = pos.x
	projectile_pos_y_spin.value = pos.y
	var node = data.get("node")
	if node:
		node.global_position = pos
		
# Define la prioridad visual de cada capa.
func _setup_layers() -> void:
	zones_layer.z_index = Z_INDEX_ZONES
	playfields_layer.z_index = Z_INDEX_PLAYFIELD
	projectiles_layer.z_index = Z_INDEX_PROJECTILES

# Crea e inicializa el playfield del editor.
func _init_playfield() -> void:
	playfield = PlayfieldScene.instantiate()
	playfields_layer.add_child(playfield)
	var viewport_center = get_viewport().get_visible_rect().size / 2.0
	playfield.global_position = viewport_center + Vector2(0, 100)
	playfield_pos_x_spin.value = playfield.global_position.x
	playfield_pos_y_spin.value = playfield.global_position.y
	playfield.set_state(state.playfield_type)
	playfield.set_size(Vector2(playfield_width_spin.value, playfield_height_spin.value))
	playfield.visible = false


# Carga enums desde scripts para poblar los OptionButton.
func _load_enums() -> void:
	#state.projectile_types = _load_enum_values(PROJECTILE_ENUM_PATHS, PROJECTILE_TYPE_ENUM_NAMES)
	if state.projectile_types.is_empty():
		state.projectile_types = ["basic"]
	state.projectile_patterns = _load_enum_values(PROJECTILE_PATTERN_ENUM_PATH, "PATTERNS")
	#state.playfield_types = _load_enum_values(PLAYFIELD_ENUM_PATHS, PLAYFIELD_TYPE_ENUM_NAMES)
	if state.playfield_types.is_empty():
		state.playfield_types = ["normal"]
	state.playfield_type = state.playfield_types[0]
	
	state.phase_types = _load_enum_values(PHASE_TYPES_ENUM_PATH, "TYPES")

# Intenta leer un enum desde un script y devolver sus claves ordenadas.
func _load_enum_values(path: String, enum_type_name: String) -> Array:
	if ResourceLoader.exists(path):
		var script_resource = load(path)
		if script_resource and script_resource is Script:
			var constants = script_resource.get_script_constant_map()
			if constants.has(enum_type_name) and constants[enum_type_name] is Dictionary:
				var values: Array[String] = []
				for key in constants[enum_type_name].keys():
					values.append(str(key))
				values.sort()
				return values
	print(["[level_editor] ", enum_type_name, " not loaded for any reason..."])
	return []

# Rellena los dropdowns con los valores cargados.
func _setup_option_buttons() -> void:
	#playfield_type_option.clear()
	#for option in state.playfield_types:
	#	playfield_type_option.add_item(option)
	#playfield_type_option.select(0)

	projectile_type_option.clear()
	for option in state.projectile_types:
		projectile_type_option.add_item(option)
	projectile_type_option.select(0)

	projectile_pattern_option.clear()
	projectile_pattern_option.add_item("None")
	for option in state.projectile_patterns:
		projectile_pattern_option.add_item(option)
	projectile_pattern_option.select(0)
	
	phase_type_option.clear()
	for option in state.phase_types:
		phase_type_option.add_item(option)
	phase_type_option.select(0)

	_update_area_options()

# Conecta señales de UI con sus handlers.
func _setup_ui() -> void:
	exit_button.pressed.connect(_on_exit_button_pressed)
	load_music_button.pressed.connect(_on_load_music_pressed)
	play_button.pressed.connect(_on_play_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	step_back_button.pressed.connect(_on_step_back_pressed)
	step_forward_button.pressed.connect(_on_step_forward_pressed)

	music_id_edit.text_changed.connect(_on_music_id_changed)
	bpm_spin.value_changed.connect(_on_bpm_changed)
	timeline_slider.value_changed.connect(_on_timeline_changed)
	preview_toggle_button.pressed.connect(_on_preview_toggle_pressed)

	playfield_list.item_selected.connect(playfields_component._on_playfield_list_selected)
	add_playfield_button.pressed.connect(playfields_component._on_add_playfield_pressed)
	remove_playfield_button.pressed.connect(playfields_component._on_remove_playfield_pressed)
	playfield_pos_x_spin.value_changed.connect(playfields_component._on_playfield_position_changed)
	playfield_pos_y_spin.value_changed.connect(playfields_component._on_playfield_position_changed)
	playfield_width_spin.value_changed.connect(playfields_component._on_playfield_size_changed)
	playfield_height_spin.value_changed.connect(playfields_component._on_playfield_size_changed)

	phase_list.item_selected.connect(phases_component._on_phase_list_selected)
	add_phase_button.pressed.connect(phases_component._on_add_phase_pressed)
	remove_phase_button.pressed.connect(phases_component._on_remove_phase_pressed)
	phase_type_option.item_selected.connect(phases_component._on_phase_type_selected)
	phase_time_spin.value_changed.connect(phases_component._on_phase_time_changed)

	add_zone_button.pressed.connect(zones_component._on_add_zone_pressed)
	remove_zone_button.pressed.connect(zones_component._on_remove_zone_pressed)
	zone_list.item_selected.connect(zones_component._on_zone_list_selected)
	zone_pos_x_spin.value_changed.connect(zones_component._on_zone_position_changed)
	zone_pos_y_spin.value_changed.connect(zones_component._on_zone_position_changed)
	zone_width_spin.value_changed.connect(zones_component._on_zone_size_changed)
	zone_height_spin.value_changed.connect(zones_component._on_zone_size_changed)

	projectile_list.item_selected.connect(projectiles_component._on_projectile_list_selected)
	delete_projectile_button.pressed.connect(projectiles_component._on_delete_projectile_pressed)
	projectile_time_spin.value_changed.connect(projectiles_component._on_projectile_time_changed)
	projectile_pos_x_spin.value_changed.connect(projectiles_component._on_projectile_position_changed)
	projectile_pos_y_spin.value_changed.connect(projectiles_component._on_projectile_position_changed)
	projectile_speed_spin.value_changed.connect(projectiles_component._on_projectile_speed_changed)
	projectile_angle_spin.value_changed.connect(projectiles_component._on_projectile_angle_changed)
	projectile_type_option.item_selected.connect(projectiles_component._on_projectile_type_selected)
	projectile_pattern_option.item_selected.connect(projectiles_component._on_projectile_pattern_selected)
	projectile_area_option.item_selected.connect(projectiles_component._on_projectile_area_selected)

	export_button.pressed.connect(_on_export_pressed)
	import_button.pressed.connect(_on_import_pressed)
	live_preview_button.pressed.connect(_on_live_preview_pressed)

	music_file_dialog.file_selected.connect(_on_music_file_selected)
	export_dialog.file_selected.connect(io_component._on_export_file_selected)
	import_dialog.file_selected.connect(io_component._on_import_file_selected)

func _on_exit_button_pressed() -> void:
	GameLoader.load_scene("main_menu")

# Abre el selector de música.
func _on_load_music_pressed() -> void:
	music_file_dialog.popup_centered_ratio(0.6)

# Carga una música desde disco y actualiza duración e id.
func _on_music_file_selected(path: String) -> void:
	state.music_path = path
	var stream = load(path)
	if stream and stream is AudioStream:
		music_player.stream = stream
		state.music_length_ms = int(stream.get_length() * 1000.0)
		state.music_id = path.get_file().get_basename()
		music_id_edit.text = state.music_id
		_update_timeline_range()
		_update_status("Loaded music: %s" % state.music_id)
	else:
		_update_status("Invalid audio stream")

# Reproduce el audio desde el tiempo actual.
func _on_play_pressed() -> void:
	if music_player.stream == null:
		_update_status("Load a music file first")
		return
	if not music_player.playing:
		music_player.play(state.current_time_ms / 1000.0)
		music_player.stream_paused = false
		state.is_playing = true
	elif music_player.stream_paused:
		music_player.stream_paused = false
		state.is_playing = true

# Pausa la reproducción actual.
func _on_pause_pressed() -> void:
	if music_player.playing:
		music_player.stream_paused = true
		state.is_playing = false

# Mueve el tiempo 10 ms hacia atrás.
func _on_step_back_pressed() -> void:
	_set_current_time_ms(state.current_time_ms - 10, true)

# Mueve el tiempo 10 ms hacia adelante.
func _on_step_forward_pressed() -> void:
	_set_current_time_ms(state.current_time_ms + 10, true)

# Reacciona al cambio manual de la timeline.
func _on_timeline_changed(value: float) -> void:
	if state.suppress_ui:
		return
	_set_current_time_ms(int(value), true)

# Cambia el tiempo actual y actualiza UI/audio.
func _set_current_time_ms(value: int, seek_audio: bool) -> void:
	var max_value = int(timeline_slider.max_value)
	state.current_time_ms = clamp(value, 0, max_value)
	_set_ui_suppressed(true)
	timeline_slider.value = state.current_time_ms
	time_label.text = _format_time(state.current_time_ms)
	_set_ui_suppressed(false)
	if seek_audio and music_player.stream:
		music_player.seek(state.current_time_ms / 1000.0)
	projectiles_component.update_projectile_visibility()

# Convierte milisegundos a un string legible.
func _format_time(value_ms: int) -> String:
	var total_seconds = value_ms / 1000.0
	var minutes = int(total_seconds / 60.0)
	var seconds = int(total_seconds) % 60
	var milliseconds = value_ms % 1000
	return "%d:%02d.%03d" % [minutes, seconds, milliseconds]

# Cambia el id de música del editor.
func _on_music_id_changed(text: String) -> void:
	state.music_id = text

# Placeholder del BPM.
func _on_bpm_changed(_value: float) -> void:
	pass


# Abre el diálogo de exportación.
func _on_export_pressed() -> void:
	export_dialog.popup_centered_ratio(0.6)

# Abre el diálogo de importación.
func _on_import_pressed() -> void:
	import_dialog.popup_centered_ratio(0.6)
	
# Exporta el estado actual a un archivo temporal y recarga el LevelLoader.
func _on_live_preview_pressed() -> void:
	if io_component == null:
		return

	# If live preview is already running, stop it and restore the editor UI.
	if state.live_preview:
		state.live_preview = false

		if is_instance_valid(level_loader_component):
			level_loader_component.queue_free()
			level_loader_component = null

		if is_instance_valid(live_preview):
			live_preview.queue_free()
			live_preview = null

		ui_root.visible = true
		preview_toggle_button.visible = true
		projectiles_layer.visible = true
		playfields_layer.visible = true
		
		return
		
	# Start live preview.
	io_component.export_preview_to_path(PREVIEW_EXPORT_PATH)
	
	ui_root.visible = false
	preview_toggle_button.visible = false
	projectiles_layer.visible = false
	playfields_layer.visible = false

	level_loader_component = LivePreviewScene.instantiate()
	level_loader_component.start_time_ms = state.current_time_ms
	live_preview_layer.add_child(level_loader_component)
	level_loader_component.is_in_editor = true
	level_loader_component.load_level(PREVIEW_EXPORT_PATH)
	
	_update_status("Preview exported")
	state.live_preview = true

# Alterna entre modo edición y modo preview.
func _on_preview_toggle_pressed() -> void:
	state.preview_mode = not state.preview_mode
	ui_content.visible = not state.preview_mode
	ui_bottom_bar.visible = not state.preview_mode
	#playfield.visible = state.preview_mode
	preview_toggle_button.text = "Editor" if state.preview_mode else "Preview"

# Ajusta el rango de la timeline según música y proyectiles.
func _update_timeline_range() -> void:
	var max_time = state.music_length_ms
	for proj in state.projectiles:
		max_time = max(max_time, proj.time_ms)
	timeline_slider.max_value = max(max_time, 1000)
	projectile_time_spin.max_value = timeline_slider.max_value
	_set_current_time_ms(state.current_time_ms, false)

# Escribe un estado simple en el label inferior.
func _update_status(text: String) -> void:
	status_label.text = text

# Bloquea o desbloquea la señalización de UI para evitar loops.
func _set_ui_suppressed(value: bool) -> void:
	state.suppress_ui = value

# Busca un texto exacto dentro de un OptionButton.
func _set_option_button_value(button: OptionButton, value: String) -> void:
	for i in button.item_count:
		if button.get_item_text(i) == value:
			button.select(i)
			return
	push_warning("Unknown option value added to UI: %s" % value)
	button.add_item(value)
	button.select(button.item_count - 1)

# Reconstruye las opciones de área disponibles para proyectiles.
func _update_area_options() -> void:
	var selected_zone_id = null
	if state.selected_projectile_index >= 0 and state.selected_projectile_index < state.projectiles.size():
		selected_zone_id = state.projectiles[state.selected_projectile_index].get("zone_id")
	projectile_area_option.clear()
	projectile_area_option.add_item("None")
	for zone in state.zones:
		projectile_area_option.add_item(str(zone.id))
	if selected_zone_id != null:
		for i in range(projectile_area_option.item_count):
			if projectile_area_option.get_item_text(i) == str(selected_zone_id):
				projectile_area_option.select(i)
				return
	projectile_area_option.select(0)

func _on_zone_clicked(zone_node) -> void:
	zones_component._on_zone_clicked(zone_node)
	
func _on_playfield_clicked(playfield_node) -> void:
	playfields_component._on_playfield_clicked(playfield_node)


# Wrapper para limpiar el inspector del proyectil.
func _clear_projectile_inspector() -> void:
	projectiles_component.clear_projectile_inspector()

# Wrapper para refrescar la lista de proyectiles.
func _refresh_projectile_list() -> void:
	projectiles_component.refresh_projectile_list()

# Wrapper para actualizar el marker visual de un proyectil.
func _update_projectile_marker(proj: Bullet) -> void:
	projectiles_component.update_projectile_marker(proj)

# Wrapper para actualizar la visibilidad de proyectiles.
func _update_projectile_visibility() -> void:
	projectiles_component.update_projectile_visibility()

# Wrapper para limpiar zonas.
func _clear_zones() -> void:
	zones_component.clear_zones()

# Wrapper para recalcular el contador de zonas.
func _recalculate_zone_id_counter() -> void:
	zones_component.recalculate_zone_id_counter()

# Wrapper para refrescar la lista de zonas.
func _refresh_zone_list() -> void:
	zones_component.refresh_zone_list()

# Wrapper para limpiar proyectiles.
func _clear_projectiles() -> void:
	projectiles_component.clear_projectiles()

# Wrapper para resaltar la zona de un área.
func _highlight_zone_for_area(zone_id) -> void:
	zones_component.highlight_zone_for_area(zone_id)

# Wrapper para reenviar el click de un marker al componente.
func _on_projectile_marker_clicked(marker) -> void:
	projectiles_component._on_projectile_marker_clicked(marker)
