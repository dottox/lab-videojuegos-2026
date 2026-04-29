extends Node2D

const ProjectileMarkerScene := preload("res://scenes/editor/projectile_marker.tscn")
const ZoneAreaScene := preload("res://scenes/editor/zone_area.tscn")
const PlayfieldScene := preload("res://scenes/playfield/playfield.tscn")

const PROJECTILE_ENUM_PATHS: Array[String] = [
	"res://scenes/projectiles/bullet/bullet.gd"
]
const PLAYFIELD_ENUM_PATHS: Array[String] = [
	"res://scenes/playfield/playfield.gd"
]

const PROJECTILE_TYPE_ENUM_NAMES: Array[String] = ["ProjectileType", "ProjectileTypes", "Type"]
const PROJECTILE_PATTERN_ENUM_NAMES: Array[String] = ["ProjectilePattern", "ProjectilePatterns", "Pattern"]
const PLAYFIELD_TYPE_ENUM_NAMES: Array[String] = ["PlayfieldType", "PlayfieldTypes", "Type"]
const PROJECTILE_PREVIEW_WINDOW_MS := 10000
const ZONE_DEFAULT_MARGIN := 20.0
const ZONES_PER_ROW := 2

# Prioridad de vista a projectiles sobre playfield y zonas
const Z_INDEX_ZONES := -10
const Z_INDEX_PLAYFIELD := 0
const Z_INDEX_PROJECTILES := 10

# Las 3 layers de Preview 
@onready var playfield_layer: Node2D = $PlayfieldLayer
@onready var zones_layer: Node2D = $ZonesLayer
@onready var projectiles_layer: Node2D = $ProjectilesLayer

@onready var music_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

@onready var preview_toggle_button: Button = $PreviewControls/PreviewToggleButton

# --- TODA LA UI SOBRE ROOT ---
@onready var ui_root: Control = $CanvasLayer/UI/Root

# Todo lo de musica
@onready var load_music_button: Button = $CanvasLayer/UI/Root/TopBar/LoadMusicButton
@onready var music_id_edit: LineEdit = $CanvasLayer/UI/Root/TopBar/MusicIdEdit
@onready var bpm_spin: SpinBox = $CanvasLayer/UI/Root/TopBar/BpmSpin
@onready var play_button: Button = $CanvasLayer/UI/Root/TopBar/PlayButton
@onready var pause_button: Button = $CanvasLayer/UI/Root/TopBar/PauseButton
@onready var step_back_button: Button = $CanvasLayer/UI/Root/TopBar/StepBackButton
@onready var step_forward_button: Button = $CanvasLayer/UI/Root/TopBar/StepForwardButton
@onready var timeline_slider: HSlider = $CanvasLayer/UI/Root/TopBar/TimelineSlider
@onready var time_label: Label = $CanvasLayer/UI/Root/TopBar/TimeLabel

# Todo lo de playfield
@onready var playfield_type_option: OptionButton = $CanvasLayer/UI/Root/Content/PlayfieldPanel/PlayfieldVBox/PlayfieldTypeOption
@onready var playfield_pos_x_spin: SpinBox = $CanvasLayer/UI/Root/Content/PlayfieldPanel/PlayfieldVBox/PlayfieldGrid/PlayfieldPosXSpin
@onready var playfield_pos_y_spin: SpinBox = $CanvasLayer/UI/Root/Content/PlayfieldPanel/PlayfieldVBox/PlayfieldGrid/PlayfieldPosYSpin
@onready var playfield_width_spin: SpinBox = $CanvasLayer/UI/Root/Content/PlayfieldPanel/PlayfieldVBox/PlayfieldGrid/PlayfieldWidthSpin
@onready var playfield_height_spin: SpinBox = $CanvasLayer/UI/Root/Content/PlayfieldPanel/PlayfieldVBox/PlayfieldGrid/PlayfieldHeightSpin

# Todo lo de zonas
@onready var zone_list: ItemList = $CanvasLayer/UI/Root/Content/ZonesPanel/ZonesVBox/ZoneList
@onready var add_zone_button: Button = $CanvasLayer/UI/Root/Content/ZonesPanel/ZonesVBox/ZoneButtons/AddZoneButton
@onready var remove_zone_button: Button = $CanvasLayer/UI/Root/Content/ZonesPanel/ZonesVBox/ZoneButtons/RemoveZoneButton
@onready var zone_id_edit: LineEdit = $CanvasLayer/UI/Root/Content/ZonesPanel/ZonesVBox/ZoneIdEdit
@onready var zone_pos_x_spin: SpinBox = $CanvasLayer/UI/Root/Content/ZonesPanel/ZonesVBox/ZoneGrid/ZonePosXSpin
@onready var zone_pos_y_spin: SpinBox = $CanvasLayer/UI/Root/Content/ZonesPanel/ZonesVBox/ZoneGrid/ZonePosYSpin
@onready var zone_width_spin: SpinBox = $CanvasLayer/UI/Root/Content/ZonesPanel/ZonesVBox/ZoneGrid/ZoneWidthSpin
@onready var zone_height_spin: SpinBox = $CanvasLayer/UI/Root/Content/ZonesPanel/ZonesVBox/ZoneGrid/ZoneHeightSpin

# Todo lo de projectiles
@onready var projectile_list: ItemList = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileList
@onready var add_projecctile_button: Button = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileButtons/AddProjectileButton
@onready var delete_projectile_button: Button = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileButtons/DeleteProjectileButton
@onready var projectile_time_spin: SpinBox = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileGrid/ProjectileTimeSpin
@onready var projectile_pos_x_spin: SpinBox = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileGrid/ProjectilePosXSpin
@onready var projectile_pos_y_spin: SpinBox = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileGrid/ProjectilePosYSpin
@onready var projectile_speed_spin: SpinBox = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileGrid/ProjectileSpeedSpin
@onready var projectile_angle_spin: SpinBox = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileGrid/ProjectileAngleSpin
@onready var projectile_type_option: OptionButton = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileGrid/ProjectileTypeOption
@onready var projectile_pattern_option: OptionButton = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileGrid/ProjectilePatternOption
@onready var projectile_area_option: OptionButton = $CanvasLayer/UI/Root/Content/ProjectilesPanel/ProjectilesVBox/ProjectileGrid/ProjectileAreaOption

# Botones fila de abajo
@onready var export_button: Button = $CanvasLayer/UI/Root/BottomBar/ExportButton
@onready var import_button: Button = $CanvasLayer/UI/Root/BottomBar/ImportButton
@onready var status_label: Label = $CanvasLayer/UI/Root/BottomBar/StatusLabel

@onready var music_file_dialog: FileDialog = $CanvasLayer/MusicFileDialog
@onready var export_dialog: FileDialog = $CanvasLayer/ExportDialog
@onready var import_dialog: FileDialog = $CanvasLayer/ImportDialog

var playfield
var projectile_types: Array[String] = []
var projectile_patterns: Array[String] = []
var playfield_types: Array[String] = []

var zones: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []

var selected_zone_index := -1
var selected_projectile_index := -1
var zone_id_counter := 1

var current_time_ms := 0
var music_length_ms := 0
var music_id := ""
var music_path := ""
var playfield_type := "normal"
var suppress_ui := false
var is_playing := false
var preview_mode := false

func _ready() -> void:
	_setup_layers()
	_init_playfield()
	_load_enums()
	_setup_option_buttons()
	_setup_ui()
	_update_timeline_range()
	_update_status("Ready")

# Checking constantly
func _process(_delta: float) -> void:
	# setting current time whenever music is not paused
	if is_playing and music_player.playing and not music_player.stream_paused:
		var playback_position = music_player.get_playback_position()
		if music_length_ms > 0:
			playback_position = clamp(playback_position, 0.0, music_length_ms / 1000.0)
		else:
			playback_position = max(playback_position, 0.0)
		var new_time = int(playback_position * 1000.0)
		if new_time != current_time_ms:
			_set_current_time_ms(new_time, false)
	# set is_playing to false when the music.player stops
	elif is_playing and not music_player.playing:
		is_playing = false

# TODO: Not working, also projectiles must be created outside playfield
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if playfield and playfield.has_method("get_bounds"):
			var mouse_pos = get_global_mouse_position()
			if playfield.get_bounds().has_point(mouse_pos):
				_create_projectile_at(mouse_pos)

# Sets Z Index to layers
func _setup_layers() -> void:
	zones_layer.z_index = Z_INDEX_ZONES
	playfield_layer.z_index = Z_INDEX_PLAYFIELD
	projectiles_layer.z_index = Z_INDEX_PROJECTILES

# Init a playfield
# TODO: add playfield creation
func _init_playfield() -> void:
	playfield = PlayfieldScene.instantiate()
	playfield_layer.add_child(playfield)
	var viewport_center = get_viewport().get_visible_rect().size / 2.0
	playfield.global_position = viewport_center + Vector2(0, 100)
	playfield_pos_x_spin.value = playfield.global_position.x
	playfield_pos_y_spin.value = playfield.global_position.y
	if playfield.has_method("set_state"):
		playfield.set_state(playfield_type)
	if playfield.has_method("set_size"):
		playfield.set_size(Vector2(playfield_width_spin.value, playfield_height_spin.value))
	playfield.visible = false

# --------------------------
# TODO: Check if all of this works, we don't have enums rn
func _load_enums() -> void:
	projectile_types = _load_enum_values(PROJECTILE_ENUM_PATHS, PROJECTILE_TYPE_ENUM_NAMES)
	if projectile_types.is_empty():
		projectile_types = ["basic"]
	projectile_patterns = _load_enum_values(PROJECTILE_ENUM_PATHS, PROJECTILE_PATTERN_ENUM_NAMES)
	playfield_types = _load_enum_values(PLAYFIELD_ENUM_PATHS, PLAYFIELD_TYPE_ENUM_NAMES)
	if playfield_types.is_empty():
		playfield_types = ["normal"]
	playfield_type = playfield_types[0]

func _load_enum_values(paths: Array[String], enum_type_names: Array[String]) -> Array[String]:
	for path in paths:
		if ResourceLoader.exists(path):
			var script_resource = load(path)
			if script_resource and script_resource is Script:
				var constants = script_resource.get_script_constant_map()
				for enum_name in enum_type_names:
					if constants.has(enum_name) and constants[enum_name] is Dictionary:
						var values = constants[enum_name].keys()
						values.sort()
						return values
	return []
# --------------------------

# Load the items from the enums to the UI
func _setup_option_buttons() -> void:
	playfield_type_option.clear()
	for option in playfield_types:
		playfield_type_option.add_item(option)
	playfield_type_option.select(0)

	projectile_type_option.clear()
	for option in projectile_types:
		projectile_type_option.add_item(option)
	projectile_type_option.select(0)

	projectile_pattern_option.clear()
	projectile_pattern_option.add_item("None")
	for option in projectile_patterns:
		projectile_pattern_option.add_item(option)
	projectile_pattern_option.select(0)

	_update_area_options()

# Connect all the buttons to their functions
func _setup_ui() -> void:
	# Music buttons
	load_music_button.pressed.connect(_on_load_music_pressed)
	play_button.pressed.connect(_on_play_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	step_back_button.pressed.connect(_on_step_back_pressed)

	music_id_edit.text_changed.connect(_on_music_id_changed)
	bpm_spin.value_changed.connect(_on_bpm_changed)
	timeline_slider.value_changed.connect(_on_timeline_changed)
	
	# Preview button
	preview_toggle_button.pressed.connect(_on_preview_toggle_pressed)

	# Playfield buttons
	playfield_type_option.item_selected.connect(_on_playfield_type_selected)
	playfield_pos_x_spin.value_changed.connect(_on_playfield_position_changed)
	playfield_pos_y_spin.value_changed.connect(_on_playfield_position_changed)
	playfield_width_spin.value_changed.connect(_on_playfield_size_changed)
	playfield_height_spin.value_changed.connect(_on_playfield_size_changed)

	# Zone buttons
	add_zone_button.pressed.connect(_on_add_zone_pressed)
	remove_zone_button.pressed.connect(_on_remove_zone_pressed)
	zone_list.item_selected.connect(_on_zone_list_selected)
	zone_id_edit.text_changed.connect(_on_zone_id_changed)
	zone_pos_x_spin.value_changed.connect(_on_zone_position_changed)
	zone_pos_y_spin.value_changed.connect(_on_zone_position_changed)
	zone_width_spin.value_changed.connect(_on_zone_size_changed)
	zone_height_spin.value_changed.connect(_on_zone_size_changed)

	# Projectiles buttons
	projectile_list.item_selected.connect(_on_projectile_list_selected)
	delete_projectile_button.pressed.connect(_on_delete_projectile_pressed)
	projectile_time_spin.value_changed.connect(_on_projectile_time_changed)
	projectile_pos_x_spin.value_changed.connect(_on_projectile_position_changed)
	projectile_pos_y_spin.value_changed.connect(_on_projectile_position_changed)
	projectile_speed_spin.value_changed.connect(_on_projectile_speed_changed)
	projectile_angle_spin.value_changed.connect(_on_projectile_angle_changed)
	projectile_type_option.item_selected.connect(_on_projectile_type_selected)
	projectile_pattern_option.item_selected.connect(_on_projectile_pattern_selected)
	projectile_area_option.item_selected.connect(_on_projectile_area_selected)

	# Import/Export buttons
	export_button.pressed.connect(_on_export_pressed)
	import_button.pressed.connect(_on_import_pressed)

	# Dialogs for import/export and music
	music_file_dialog.file_selected.connect(_on_music_file_selected)
	export_dialog.file_selected.connect(_on_export_file_selected)
	import_dialog.file_selected.connect(_on_import_file_selected)

# ------ All the functions for the buttons ------

# Opens the dialog to select music
func _on_load_music_pressed() -> void:
	music_file_dialog.popup_centered_ratio(0.6)

# Load the music from the path
func _on_music_file_selected(path: String) -> void:
	music_path = path
	var stream = load(path)
	if stream and stream is AudioStream:
		music_player.stream = stream
		music_length_ms = int(stream.get_length() * 1000.0)
		music_id = path.get_file().get_basename()
		music_id_edit.text = music_id
		_update_timeline_range()
		_update_status("Loaded music: %s" % music_id)
	else:
		_update_status("Invalid audio stream")

# Play the music
func _on_play_pressed() -> void:
	if music_player.stream == null:
		_update_status("Load a music file first")
		return
	if not music_player.playing:
		music_player.play(current_time_ms / 1000.0)
		music_player.stream_paused = false
		is_playing = true
	elif music_player.stream_paused:
		music_player.stream_paused = false
		is_playing = true

# Pause the music
func _on_pause_pressed() -> void:
	if music_player.playing:
		music_player.stream_paused = true
		is_playing = false

# Backwards the music 10ms
func _on_step_back_pressed() -> void:
	_set_current_time_ms(current_time_ms - 10, true)

# Forwards the music 10ms
func _on_step_forward_pressed() -> void:
	_set_current_time_ms(current_time_ms + 10, true)

# Go to any time in timeline
func _on_timeline_changed(value: float) -> void:
	if suppress_ui:
		return
	_set_current_time_ms(int(value), true)

# Function to go to any time in the timeline, helper of the above.
func _set_current_time_ms(value: int, seek_audio: bool) -> void:
	var max_value = int(timeline_slider.max_value)
	current_time_ms = clamp(value, 0, max_value)
	_set_ui_suppressed(true)
	timeline_slider.value = current_time_ms
	time_label.text = _format_time(current_time_ms)
	_set_ui_suppressed(false)
	if seek_audio and music_player.stream:
		music_player.seek(current_time_ms / 1000.0)
	_update_projectile_visibility()

# Format time for the timeline
func _format_time(value_ms: int) -> String:
	var total_seconds = value_ms / 1000.0
	var minutes = int(total_seconds / 60.0)
	var seconds = int(total_seconds) % 60
	var milliseconds = value_ms % 1000
	return "%d:%02d.%03d" % [minutes, seconds, milliseconds]

# Change the music id
func _on_music_id_changed(text: String) -> void:
	music_id = text

# TODO: we need this?
func _on_bpm_changed(_value: float) -> void:
	pass

# Change playfield's type
func _on_playfield_type_selected(index: int) -> void:
	playfield_type = playfield_type_option.get_item_text(index)
	if playfield and playfield.has_method("set_state"):
		playfield.set_state(playfield_type)

# Change playfield's position
func _on_playfield_position_changed(_value: float) -> void:
	if playfield:
		playfield.global_position = Vector2(playfield_pos_x_spin.value, playfield_pos_y_spin.value)

# Change playfield's size
func _on_playfield_size_changed(_value: float) -> void:
	if playfield and playfield.has_method("set_size"):
		playfield.set_size(Vector2(playfield_width_spin.value, playfield_height_spin.value))

# Add new zone
func _on_add_zone_pressed() -> void:
	var zone_id = "zone_%d" % zone_id_counter
	zone_id_counter += 1
	var size = Vector2(zone_width_spin.value, zone_height_spin.value)
	var rect = _default_zone_rect(size)
	var zone_node = ZoneAreaScene.instantiate()
	zones_layer.add_child(zone_node)
	zone_node.set_zone(zone_id, rect)
	zone_node.clicked.connect(_on_zone_clicked)
	zones.append({"id": zone_id, "rect": rect, "node": zone_node})
	_refresh_zone_list()
	_update_area_options()
	_select_zone(zones.size() - 1)

# Remove a zone
func _on_remove_zone_pressed() -> void:
	if selected_zone_index < 0 or selected_zone_index >= zones.size():
		return
	var zone_data = zones[selected_zone_index]
	var zone_id = zone_data.get("id", "")
	var node = zone_data.get("node")
	if node:
		node.queue_free()
	zones.remove_at(selected_zone_index)
	selected_zone_index = -1
	_refresh_zone_list()
	_update_area_options()
	_clear_zone_inspector()
	_clear_projectile_area_for_zone(zone_id)

# Click on zone from the list to select
func _on_zone_list_selected(index: int) -> void:
	_select_zone(index)

# Click on zone from the preview to select
func _on_zone_clicked(zone_node) -> void:
	for i in zones.size():
		if zones[i].get("node") == zone_node:
			_select_zone(i)
			break

# Select zone. Helper
func _select_zone(index: int) -> void:
	if index < 0:
		selected_zone_index = -1
		zone_list.deselect_all()
		_clear_zone_inspector()
		return
	if index >= zones.size():
		return
	selected_zone_index = index
	zone_list.select(index)
	var zone_data = zones[index]
	var rect: Rect2 = zone_data["rect"]
	_set_ui_suppressed(true)
	zone_id_edit.text = zone_data.get("id", "")
	zone_pos_x_spin.value = rect.position.x
	zone_pos_y_spin.value = rect.position.y
	zone_width_spin.value = rect.size.x
	zone_height_spin.value = rect.size.y
	_set_ui_suppressed(false)

# Clear the values from the zone UI
func _clear_zone_inspector() -> void:
	_set_ui_suppressed(true)
	zone_id_edit.text = ""
	zone_pos_x_spin.value = 0
	zone_pos_y_spin.value = 0
	zone_width_spin.value = 0
	zone_height_spin.value = 0
	_set_ui_suppressed(false)

# Edit zone id
func _on_zone_id_changed(text: String) -> void:
	if suppress_ui:
		return
	if selected_zone_index < 0 or selected_zone_index >= zones.size():
		return
	var zone_data = zones[selected_zone_index]
	var old_id = zone_data.get("id", "")
	zone_data["id"] = text
	zones[selected_zone_index] = zone_data
	var node = zone_data.get("node")
	if node:
		node.set_zone(text, zone_data.get("rect", Rect2()))
	_refresh_zone_list()
	_update_area_options()
	_update_projectile_area_ids(old_id, text)

# Edit zone position
func _on_zone_position_changed(_value: float) -> void:
	if suppress_ui:
		return
	if selected_zone_index < 0 or selected_zone_index >= zones.size():
		return
	var zone_data = zones[selected_zone_index]
	var rect: Rect2 = zone_data["rect"]
	rect.position = Vector2(zone_pos_x_spin.value, zone_pos_y_spin.value)
	zone_data["rect"] = rect
	zones[selected_zone_index] = zone_data
	var node = zone_data.get("node")
	if node:
		node.set_zone(zone_data.get("id", ""), rect)

# Edit zone size
func _on_zone_size_changed(_value: float) -> void:
	if suppress_ui:
		return
	if selected_zone_index < 0 or selected_zone_index >= zones.size():
		return
	var zone_data = zones[selected_zone_index]
	var rect: Rect2 = zone_data["rect"]
	rect.size = Vector2(zone_width_spin.value, zone_height_spin.value)
	zone_data["rect"] = rect
	zones[selected_zone_index] = zone_data
	var node = zone_data.get("node")
	if node:
		node.set_zone(zone_data.get("id", ""), rect)

# Refresh list
func _refresh_zone_list() -> void:
	var previous = selected_zone_index
	zone_list.clear()
	for zone_data in zones:
		zone_list.add_item(zone_data.get("id", ""))
	if previous >= 0 and previous < zones.size():
		zone_list.select(previous)

# Create Projectile
func _create_projectile_at(position: Vector2) -> void:
	var marker = ProjectileMarkerScene.instantiate()
	projectiles_layer.add_child(marker)
	marker.global_position = position
	marker.clicked.connect(_on_projectile_marker_clicked)
	var projectile_type = projectile_types[0] if projectile_types.size() > 0 else "basic"
	var data = {
		"time_ms": current_time_ms,
		"pos": position,
		"speed": projectile_speed_spin.value,
		"angle_deg": projectile_angle_spin.value,
		"type": projectile_type,
		"pattern": null,
		"area_id": null,
		"node": marker
	}
	projectiles.append(data)
	_update_projectile_marker(data)
	_refresh_projectile_list()
	_update_projectile_visibility()
	_select_projectile(projectiles.size() - 1)

# Select projectile in preview
func _on_projectile_marker_clicked(marker) -> void:
	for i in projectiles.size():
		if projectiles[i].get("node") == marker:
			_select_projectile(i)
			break

# Select projectile in list UI
func _on_projectile_list_selected(index: int) -> void:
	_select_projectile(index)

# Select projectile. Helper
func _select_projectile(index: int) -> void:
	if index < 0:
		selected_projectile_index = -1
		projectile_list.deselect_all()
		for data in projectiles:
			var marker = data.get("node")
			if marker:
				marker.set_selected(false)
		_clear_projectile_inspector()
		_highlight_zone_for_area(null)
		return
	if index >= projectiles.size():
		return
	selected_projectile_index = index
	projectile_list.select(index)
	for i in projectiles.size():
		var node = projectiles[i].get("node")
		if node:
			node.set_selected(i == index)
	var data = projectiles[index]
	_set_ui_suppressed(true)
	projectile_time_spin.value = data.get("time_ms", 0)
	var pos: Vector2 = data.get("pos", Vector2.ZERO)
	projectile_pos_x_spin.value = pos.x
	projectile_pos_y_spin.value = pos.y
	projectile_speed_spin.value = data.get("speed", 0)
	projectile_angle_spin.value = data.get("angle_deg", 0)
	_set_option_button_value(projectile_type_option, data.get("type", ""))
	if data.get("pattern") == null:
		projectile_pattern_option.select(0)
	else:
		_set_option_button_value(projectile_pattern_option, data.get("pattern"))
	var area_id = data.get("area_id")
	if area_id == null:
		projectile_area_option.select(0)
	else:
		_set_option_button_value(projectile_area_option, area_id)
	_set_ui_suppressed(false)
	_highlight_zone_for_area(area_id)

# Delete selected projectile
func _on_delete_projectile_pressed() -> void:
	if selected_projectile_index < 0 or selected_projectile_index >= projectiles.size():
		return
	var data = projectiles[selected_projectile_index]
	var node = data.get("node")
	if node:
		node.queue_free()
	projectiles.remove_at(selected_projectile_index)
	selected_projectile_index = -1
	_refresh_projectile_list()
	_clear_projectile_inspector()

# Clear the projectile's properties from the UI
func _clear_projectile_inspector() -> void:
	_set_ui_suppressed(true)
	projectile_time_spin.value = 0
	projectile_pos_x_spin.value = 0
	projectile_pos_y_spin.value = 0
	projectile_speed_spin.value = 0
	projectile_angle_spin.value = 0
	projectile_type_option.select(0)
	projectile_pattern_option.select(0)
	projectile_area_option.select(0)
	_set_ui_suppressed(false)

# ------------
# TODO: Merge all of this functs
# Change time of a projectile
func _on_projectile_time_changed(value: float) -> void:
	if suppress_ui:
		return
	if selected_projectile_index < 0 or selected_projectile_index >= projectiles.size():
		return
	var data = projectiles[selected_projectile_index]
	data["time_ms"] = int(value)
	projectiles[selected_projectile_index] = data
	_refresh_projectile_list()
	_update_projectile_visibility()

# Cchange position of a projectile
func _on_projectile_position_changed(_value: float) -> void:
	if suppress_ui:
		return
	if selected_projectile_index < 0 or selected_projectile_index >= projectiles.size():
		return
	var data = projectiles[selected_projectile_index]
	var pos = Vector2(projectile_pos_x_spin.value, projectile_pos_y_spin.value)
	data["pos"] = pos
	projectiles[selected_projectile_index] = data
	var node = data.get("node")
	if node:
		node.global_position = pos

# Change speed of a projectile
func _on_projectile_speed_changed(value: float) -> void:
	if suppress_ui:
		return
	if selected_projectile_index < 0 or selected_projectile_index >= projectiles.size():
		return
	var data = projectiles[selected_projectile_index]
	data["speed"] = value
	projectiles[selected_projectile_index] = data

# Change angle of a projectile
func _on_projectile_angle_changed(value: float) -> void:
	if suppress_ui:
		return
	if selected_projectile_index < 0 or selected_projectile_index >= projectiles.size():
		return
	var data = projectiles[selected_projectile_index]
	data["angle_deg"] = value
	projectiles[selected_projectile_index] = data

# Change type of a projectile
func _on_projectile_type_selected(index: int) -> void:
	if suppress_ui:
		return
	if selected_projectile_index < 0 or selected_projectile_index >= projectiles.size():
		return
	var data = projectiles[selected_projectile_index]
	data["type"] = projectile_type_option.get_item_text(index)
	projectiles[selected_projectile_index] = data
	_refresh_projectile_list()

func _on_projectile_pattern_selected(index: int) -> void:
	if suppress_ui:
		return
	if selected_projectile_index < 0 or selected_projectile_index >= projectiles.size():
		return
	var data = projectiles[selected_projectile_index]
	if index == 0:
		data["pattern"] = null
	else:
		data["pattern"] = projectile_pattern_option.get_item_text(index)
	projectiles[selected_projectile_index] = data

func _on_projectile_area_selected(index: int) -> void:
	if suppress_ui:
		return
	if selected_projectile_index < 0 or selected_projectile_index >= projectiles.size():
		return
	var data = projectiles[selected_projectile_index]
	if index == 0:
		data["area_id"] = null
	else:
		data["area_id"] = projectile_area_option.get_item_text(index)
	projectiles[selected_projectile_index] = data
	_update_projectile_marker(data)
	_highlight_zone_for_area(data.get("area_id"))
# ------------

# Refresh projectile list in UI
func _refresh_projectile_list() -> void:
	var previous = selected_projectile_index
	projectile_list.clear()
	for data in projectiles:
		projectile_list.add_item("%s @ %dms" % [data.get("type", ""), data.get("time_ms", 0)])
	if previous >= 0 and previous < projectiles.size():
		projectile_list.select(previous)
	_update_timeline_range()
	_update_projectile_visibility()

# Update the projectile marker
func _update_projectile_marker(data: Dictionary) -> void:
	var node = data.get("node")
	if node:
		node.set_spawn_in_area(data.get("area_id") != null)
		node.set_angle(float(data.get("angle_deg", 0.0)))

# IDK
func _set_option_button_value(button: OptionButton, value: String) -> void:
	for i in button.item_count:
		if button.get_item_text(i) == value:
			button.select(i)
			return
	push_warning("Unknown option value added to UI: %s" % value)
	button.add_item(value)
	button.select(button.item_count - 1)

# IDK
func _update_area_options() -> void:
	var selected_area_id = null
	if selected_projectile_index >= 0 and selected_projectile_index < projectiles.size():
		selected_area_id = projectiles[selected_projectile_index].get("area_id")
	projectile_area_option.clear()
	projectile_area_option.add_item("None")
	for zone_data in zones:
		projectile_area_option.add_item(zone_data.get("id", ""))
	if selected_area_id != null:
		for i in projectile_area_option.item_count:
			if projectile_area_option.get_item_text(i) == selected_area_id:
				projectile_area_option.select(i)
				return
	projectile_area_option.select(0)

# Update projectile area, prob can be better
func _update_projectile_area_ids(old_id: String, new_id: String) -> void:
	for i in projectiles.size():
		var data = projectiles[i]
		if data.get("area_id") == old_id:
			data["area_id"] = new_id
			projectiles[i] = data

# IDK
func _clear_projectile_area_for_zone(zone_id: String) -> void:
	for i in projectiles.size():
		var data = projectiles[i]
		if data.get("area_id") == zone_id:
			data["area_id"] = null
			projectiles[i] = data
			_update_projectile_marker(data)
	if selected_projectile_index >= 0 and selected_projectile_index < projectiles.size():
		_highlight_zone_for_area(projectiles[selected_projectile_index].get("area_id"))

# IDK
func _update_timeline_range() -> void:
	var max_time = music_length_ms
	for data in projectiles:
		max_time = max(max_time, int(data.get("time_ms", 0)))
	timeline_slider.max_value = max(max_time, 1000)
	projectile_time_spin.max_value = timeline_slider.max_value
	_set_current_time_ms(current_time_ms, false)

# Update status
func _update_status(text: String) -> void:
	status_label.text = text

# Lock for the UI
func _set_ui_suppressed(value: bool) -> void:
	suppress_ui = value

# Open dialog for export
func _on_export_pressed() -> void:
	export_dialog.popup_centered_ratio(0.6)

# Open dialog for import
func _on_import_pressed() -> void:
	import_dialog.popup_centered_ratio(0.6)

# Logic to exporting level
func _on_export_file_selected(path: String) -> void:
	var data = _build_level_data()
	var yaml_text = _serialize_yaml(data)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(yaml_text)
		file.close()
		_update_status("Exported: %s" % path.get_file())
	else:
		_update_status("Failed to export")

# Logic to importing level
func _on_import_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_update_status("Failed to import")
		return
	var content = file.get_as_text()
	file.close()
	var data = _parse_yaml(content)
	_apply_level_data(data)
	_update_status("Imported: %s" % path.get_file())

# Parser to export level data to yaml
func _build_level_data() -> Dictionary:
	var playfield_pos = playfield.global_position if playfield else Vector2.ZERO
	var playfield_size = Vector2(playfield_width_spin.value, playfield_height_spin.value)
	var areas: Array = []
	for zone_data in zones:
		var rect: Rect2 = zone_data.get("rect", Rect2())
		areas.append({
			"id": zone_data.get("id", ""),
			"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
		})
	var projectile_data: Array = []
	for data in projectiles:
		var pos: Vector2 = data.get("pos", Vector2.ZERO)
		projectile_data.append({
			"time_ms": int(data.get("time_ms", 0)),
			"pos": [pos.x, pos.y],
			"speed": data.get("speed", 0.0),
			"angle_deg": data.get("angle_deg", 0.0),
			"type": data.get("type", ""),
			"pattern": data.get("pattern"),
			"area_id": data.get("area_id")
		})
	var result = {
		"music_id": music_id,
		"music_path": music_path,
		"bpm": bpm_spin.value,
		"playfield": {
			"type": playfield_type,
			"position": [playfield_pos.x, playfield_pos.y],
			"size": [playfield_size.x, playfield_size.y]
		},
		"areas": areas,
		"projectiles": projectile_data
	}
	return result

# Parser to apply level data to editor
func _apply_level_data(data: Dictionary) -> void:
	music_id = data.get("music_id", "")
	music_path = data.get("music_path", "")
	_set_ui_suppressed(true)
	music_id_edit.text = music_id
	bpm_spin.value = float(data.get("bpm", bpm_spin.value))
	_set_ui_suppressed(false)

	if data.has("playfield"):
		var pf = data.get("playfield", {})
		playfield_type = pf.get("type", playfield_type)
		_set_option_button_value(playfield_type_option, playfield_type)
		var position = _array_to_vector2(pf.get("position"), playfield.global_position)
		var size = _array_to_vector2(pf.get("size"), Vector2(playfield_width_spin.value, playfield_height_spin.value))
		playfield_pos_x_spin.value = position.x
		playfield_pos_y_spin.value = position.y
		playfield_width_spin.value = size.x
		playfield_height_spin.value = size.y
		_on_playfield_position_changed(0)
		_on_playfield_size_changed(0)

	_clear_zones()
	var areas = data.get("areas", [])
	for area in areas:
		var rect_array = area.get("rect", [])
		var rect = _array_to_rect2(rect_array, Rect2())
		var zone_node = ZoneAreaScene.instantiate()
		zones_layer.add_child(zone_node)
		zone_node.set_zone(area.get("id", ""), rect)
		zone_node.clicked.connect(_on_zone_clicked)
		zones.append({"id": area.get("id", ""), "rect": rect, "node": zone_node})
	_recalculate_zone_id_counter()
	_refresh_zone_list()
	_update_area_options()

	_clear_projectiles()
	var projectile_entries = data.get("projectiles", [])
	for entry in projectile_entries:
		var marker = ProjectileMarkerScene.instantiate()
		projectiles_layer.add_child(marker)
		marker.clicked.connect(_on_projectile_marker_clicked)
		var pos = _array_to_vector2(entry.get("pos"), Vector2.ZERO)
		marker.global_position = pos
		var projectile_data = {
			"time_ms": int(entry.get("time_ms", 0)),
			"pos": pos,
			"speed": entry.get("speed", 0.0),
			"angle_deg": entry.get("angle_deg", 0.0),
			"type": entry.get("type", projectile_types[0] if projectile_types.size() > 0 else "basic"),
			"pattern": entry.get("pattern"),
			"area_id": entry.get("area_id"),
			"node": marker
		}
		projectiles.append(projectile_data)
		_update_projectile_marker(projectile_data)
	_refresh_projectile_list()
	_update_projectile_visibility()

	_load_music_from_data()
	_update_timeline_range()
	_select_projectile(-1)
	_select_zone(-1)

# Loader for the music
func _load_music_from_data() -> void:
	if music_path != "" and ResourceLoader.exists(music_path):
		var stream = load(music_path)
		if stream and stream is AudioStream:
			music_player.stream = stream
			music_length_ms = int(stream.get_length() * 1000.0)
			return
	if music_id.begins_with("res://") and ResourceLoader.exists(music_id):
		var stream = load(music_id)
		if stream and stream is AudioStream:
			music_player.stream = stream
			music_length_ms = int(stream.get_length() * 1000.0)

# Clear all zones
func _clear_zones() -> void:
	for zone_data in zones:
		var node = zone_data.get("node")
		if node:
			node.queue_free()
	zones.clear()
	selected_zone_index = -1
	zone_id_counter = 1
	_refresh_zone_list()

# Recalculate id-counter for zone
func _recalculate_zone_id_counter() -> void:
	var highest = 0
	for zone_data in zones:
		var zone_id = zone_data.get("id", "")
		if zone_id.begins_with("zone_"):
			var suffix = zone_id.substr(5)
			if suffix.is_valid_int():
				highest = max(highest, int(suffix))
	zone_id_counter = max(highest + 1, zones.size() + 1)

# Clear all projectiles
func _clear_projectiles() -> void:
	for data in projectiles:
		var node = data.get("node")
		if node:
			node.queue_free()
	projectiles.clear()
	selected_projectile_index = -1
	_refresh_projectile_list()

# Update visibility of projectiles
func _update_projectile_visibility() -> void:
	for data in projectiles:
		var node = data.get("node")
		if node:
			var projectile_time = int(data.get("time_ms", 0))
			node.visible = abs(projectile_time - current_time_ms) <= PROJECTILE_PREVIEW_WINDOW_MS

# Higlight zone
func _highlight_zone_for_area(area_id) -> void:
	for zone_data in zones:
		var node = zone_data.get("node")
		if node:
			node.set_highlighted(area_id != null and zone_data.get("id", "") == area_id)

# Get borders for playfield
func _get_playfield_bounds() -> Rect2:
	if playfield and playfield.has_method("get_bounds"):
		return playfield.get_bounds()
	var size = Vector2(playfield_width_spin.value, playfield_height_spin.value)
	return Rect2(playfield.global_position - size / 2.0, size)

# IDK
func _default_zone_rect(size: Vector2) -> Rect2:
	var bounds = _get_playfield_bounds()
	var index = zones.size()
	var column = index % ZONES_PER_ROW
	var row = index / ZONES_PER_ROW
	var position = Vector2(
		bounds.position.x - size.x - ZONE_DEFAULT_MARGIN - (column * (size.x + ZONE_DEFAULT_MARGIN)),
		bounds.position.y + row * (size.y + ZONE_DEFAULT_MARGIN)
	)
	return Rect2(position, size)

# Change between preview and editor mode
func _on_preview_toggle_pressed() -> void:
	preview_mode = not preview_mode
	ui_root.visible = not preview_mode
	playfield.visible = preview_mode
	preview_toggle_button.text = "Editor" if preview_mode else "Preview"

# Parse the data dict to yaml
func _serialize_yaml(data: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("music_id: %s" % _yaml_value(data.get("music_id")))
	if data.get("music_path", "") != "":
		lines.append("music_path: %s" % _yaml_value(data.get("music_path")))
	lines.append("bpm: %s" % _yaml_value(data.get("bpm")))
	lines.append("playfield:")
	var playfield_data = data.get("playfield", {})
	lines.append("  type: %s" % _yaml_value(playfield_data.get("type")))
	lines.append("  position: %s" % _yaml_value(playfield_data.get("position")))
	lines.append("  size: %s" % _yaml_value(playfield_data.get("size")))
	lines.append("areas:")
	for area in data.get("areas", []):
		lines.append("  - id: %s" % _yaml_value(area.get("id")))
		lines.append("    rect: %s" % _yaml_value(area.get("rect")))
	lines.append("projectiles:")
	for projectile in data.get("projectiles", []):
		lines.append("  - time_ms: %s" % _yaml_value(projectile.get("time_ms")))
		lines.append("    pos: %s" % _yaml_value(projectile.get("pos")))
		lines.append("    speed: %s" % _yaml_value(projectile.get("speed")))
		lines.append("    angle_deg: %s" % _yaml_value(projectile.get("angle_deg")))
		lines.append("    type: %s" % _yaml_value(projectile.get("type")))
		lines.append("    pattern: %s" % _yaml_value(projectile.get("pattern")))
		lines.append("    area_id: %s" % _yaml_value(projectile.get("area_id")))
	return "\n".join(lines) + "\n"

# Convert value into a yaml value
func _yaml_value(value: Variant) -> String:
	if value == null:
		return "null"
	match typeof(value):
		TYPE_BOOL:
			return "true" if value else "false"
		TYPE_INT, TYPE_FLOAT:
			return str(value)
		TYPE_STRING:
			return "\"%s\"" % String(value).c_escape()
		TYPE_ARRAY:
			return _yaml_array(value)
		_:
			return "\"%s\"" % String(value).c_escape()

# Convert array into yaml array
func _yaml_array(values: Array) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(_yaml_value(value))
	return "[%s]" % ", ".join(parts)

# Parse yaml into a dictionary
func _parse_yaml(text: String) -> Dictionary:
	var data: Dictionary = {}
	var lines = text.split("\n")
	var current_section = ""
	var list_name = ""
	var current_item: Dictionary = {}
	for line in lines:
		var trimmed = line.strip_edges()
		if trimmed == "" or trimmed.begins_with("#"):
			continue
		var indent = line.length() - line.strip_edges(true, false).length()
		if indent == 0:
			if list_name != "" and not current_item.is_empty():
				data[list_name].append(current_item)
				current_item = {}
			list_name = ""
			current_section = ""
			if trimmed.ends_with(":"):
				var key = trimmed.trim_suffix(":")
				if key in ["areas", "projectiles"]:
					list_name = key
					data[key] = []
				else:
					current_section = key
					data[key] = {}
			else:
				var parts = trimmed.split(":", false, 1) # allow_empty=false skips empty strings
				if parts.size() == 2:
					data[parts[0].strip_edges()] = _parse_scalar(parts[1].strip_edges())
		else:
			if list_name != "":
				if trimmed.begins_with("- "):
					if not current_item.is_empty():
						data[list_name].append(current_item)
					current_item = {}
					var rest = trimmed.substr(2)
					if rest != "":
						var parts = rest.split(":", false, 1)
						if parts.size() == 2:
							current_item[parts[0].strip_edges()] = _parse_scalar(parts[1].strip_edges())
				else:
					var parts = trimmed.split(":", false, 1)
					if parts.size() == 2:
						current_item[parts[0].strip_edges()] = _parse_scalar(parts[1].strip_edges())
			elif current_section != "":
				var parts = trimmed.split(":", false, 1)
				if parts.size() == 2:
					data[current_section][parts[0].strip_edges()] = _parse_scalar(parts[1].strip_edges())
	if list_name != "" and not current_item.is_empty():
		data[list_name].append(current_item)
	return data

# Parse scalar into a value
func _parse_scalar(value: String) -> Variant:
	if value == "null":
		return null
	if value == "true":
		return true
	if value == "false":
		return false
	if value.begins_with("[") and value.ends_with("]"):
		var inner = value.substr(1, value.length() - 2).strip_edges()
		if inner == "":
			return []
		var parts = inner.split(",", false)
		var result: Array = []
		for part in parts:
			result.append(_parse_scalar(part.strip_edges()))
		return result
	if value.begins_with("\"") and value.ends_with("\"") and value.length() >= 2:
		return value.substr(1, value.length() - 2).c_unescape()
	if value.is_valid_int():
		return int(value)
	if value.is_valid_float():
		return float(value)
	return value

# Array to vector
func _array_to_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback

# Array to rectangle
func _array_to_rect2(value: Variant, fallback: Rect2) -> Rect2:
	if value is Array and value.size() >= 4:
		return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	return fallback
