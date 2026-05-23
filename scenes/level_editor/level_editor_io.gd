extends RefCounted
class_name LevelEditorIO

var editor: Node2D

# Initializes the IO helper with the editor instance it operates on.
func initialize(p_editor: Node2D) -> void:
	editor = p_editor

# Handles the export file dialog result and saves the current level to disk.
func _on_export_file_selected(path: String) -> void:
	var config := ConfigFile.new()
	_write_level_config(config)

	var err := config.save(path)
	if err == OK:
		editor._update_status("Exported: %s" % path.get_file())
	else:
		editor._update_status("Failed to export")

# Handles the import file dialog result and loads a level from disk.
func _on_import_file_selected(path: String) -> void:
	var config := ConfigFile.new()
	var err := config.load(path)
	if err != OK:
		editor._update_status("Failed to import")
		return

	_read_level_config(config)
	editor._update_status("Imported: %s" % path.get_file())

# Exports the current level state to a temp preview file.
func export_preview_to_path(path: String) -> void:
	var config := ConfigFile.new()
	_write_level_config(config)
	var err := config.save(path)
	if err != OK:
		editor._update_status("Failed to export preview")
	else:
		editor._update_status("Preview exported: %s" % path.get_file())

# Serializes the current editor state into a ConfigFile.
func _write_level_config(config: ConfigFile) -> void:
	# Meta: keep this section small and readable.
	config.set_value("meta", "music_id", editor.state.music_id)
	config.set_value("meta", "music_path", _make_relative_if_possible(editor.state.music_path))
	config.set_value("meta", "bpm", editor.bpm_spin.value)
	config.set_value("meta", "start_time_ms", editor.state.current_time_ms)

	# Playfield first because it's the spatial base for zones/projectiles.
	for i in editor.state.playfields.size():
		var playfield_data: Dictionary = editor.state.playfields[i]
		var section := "playfields_%d" % i
		config.set_value(section, "id", playfield_data.get("id", ""))
		config.set_value(section, "rect", _rect2_to_array(playfield_data.get("rect", Rect2())))

	# Zones in a stable order.
	for i in editor.state.zones.size():
		var zone_data: Dictionary = editor.state.zones[i]
		var section := "areas_%d" % i
		config.set_value(section, "id", zone_data.get("id", ""))
		config.set_value(section, "rect", _rect2_to_array(zone_data.get("rect", Rect2())))

	# Projectiles in a stable order.
	for i in editor.state.projectiles.size():
		var projectile_data: Dictionary = editor.state.projectiles[i]
		var section := "projectiles_%d" % i
		config.set_value(section, "time_ms", int(projectile_data.get("time_ms", 0)))
		config.set_value(section, "pos", _vector2_to_array(projectile_data.get("pos", Vector2.ZERO)))
		config.set_value(section, "speed", float(projectile_data.get("speed", 0.0)))
		config.set_value(section, "angle_deg", float(projectile_data.get("angle_deg", 0.0)))
		config.set_value(section, "type", projectile_data.get("type", ""))
		config.set_value(section, "pattern", projectile_data.get("pattern"))
		config.set_value(section, "area_id", projectile_data.get("area_id"))

# Restores editor state from a ConfigFile.
func _read_level_config(config: ConfigFile) -> void:
	editor.state.music_id = str(config.get_value("meta", "music_id", ""))
	editor.state.music_path = _resolve_path(str(config.get_value("meta", "music_path", "")))
	editor._set_ui_suppressed(true)
	editor.music_id_edit.text = editor.state.music_id
	editor.bpm_spin.value = float(config.get_value("meta", "bpm", editor.bpm_spin.value))
	editor._set_ui_suppressed(false)

	editor.playfields_component.clear.playfields()
	var playfield_sections := _sorted_sections_with_prefix(config, "playfields_")
	for section in playfield_sections:
		var id := str(config.get_value(section, "id", ""))
		var rect := _array_to_rect2(config.get_value(section, "rect", [0, 0, 0, 0]), Rect2())
		var playfield_node = editor.PlayfieldScene.instantiate()
		editor.playfields_layer.add_child(playfield_node)
		playfield_node.set_playfield(id, rect)
		playfield_node.clicked.connect(editor._on_playfield_clicked)
		editor.state.playfields.append({"id": id, "rect": rect, "node": playfield_node})

	editor.playfields_component.recalculate_playfield_id_counter()
	editor.playfields_component.refresh_playfield_list()

	editor.zones_component.clear_zones()
	var zone_sections := _sorted_sections_with_prefix(config, "areas_")
	for section in zone_sections:
		var id := str(config.get_value(section, "id", ""))
		var rect := _array_to_rect2(config.get_value(section, "rect", [0, 0, 0, 0]), Rect2())
		var zone_node = editor.ZoneAreaScene.instantiate()
		editor.zones_layer.add_child(zone_node)
		zone_node.set_zone(id, rect)
		zone_node.clicked.connect(editor._on_zone_clicked)
		editor.state.zones.append({"id": id, "rect": rect, "node": zone_node})

	editor.zones_component.recalculate_zone_id_counter()
	editor.zones_component.refresh_zone_list()
	editor._update_area_options()

	editor.projectiles_component.clear_projectiles()
	var projectile_sections := _sorted_sections_with_prefix(config, "projectiles_")
	for section in projectile_sections:
		var time_ms := int(config.get_value(section, "time_ms", 0))
		var pos := _array_to_vector2(config.get_value(section, "pos", [0, 0]), Vector2.ZERO)
		var speed := float(config.get_value(section, "speed", 0.0))
		var angle_deg := float(config.get_value(section, "angle_deg", 0.0))
		var projectile_type := str(config.get_value(section, "type", editor.state.projectile_types[0] if editor.state.projectile_types.size() > 0 else "basic"))
		var pattern = config.get_value(section, "pattern", null)
		var area_id = config.get_value(section, "area_id", null)

		var marker = editor.ProjectileMarkerScene.instantiate()
		editor.projectiles_layer.add_child(marker)
		marker.clicked.connect(editor._on_projectile_marker_clicked)
		marker.global_position = pos

		var projectile_data := {
			"time_ms": time_ms,
			"pos": pos,
			"speed": speed,
			"angle_deg": angle_deg,
			"type": projectile_type,
			"pattern": pattern,
			"area_id": area_id,
			"node": marker
		}
		editor.state.projectiles.append(projectile_data)
		editor.projectiles_component.update_projectile_marker(projectile_data)

	editor.projectiles_component.refresh_projectile_list()
	editor.projectiles_component.update_projectile_visibility()

	_load_music_from_data()
	editor._update_timeline_range()
	editor.projectiles_component.select_projectile(-1)
	editor.zones_component._select_zone(-1)

# Loads the music resource referenced by the imported data, if available.
func _load_music_from_data() -> void:
	if editor.state.music_path != "" and ResourceLoader.exists(editor.state.music_path):
		var stream = load(editor.state.music_path)
		if stream and stream is AudioStream:
			editor.music_player.stream = stream
			editor.state.music_length_ms = int(stream.get_length() * 1000.0)
			return
	if editor.state.music_id.begins_with("res://") and ResourceLoader.exists(editor.state.music_id):
		var stream = load(editor.state.music_id)
		if stream and stream is AudioStream:
			editor.music_player.stream = stream
			editor.state.music_length_ms = int(stream.get_length() * 1000.0)

# Converts a Vector2 into an Array for ConfigFile storage.
func _vector2_to_array(value: Vector2) -> Array:
	return [value.x, value.y]

# Converts a Rect2 into an Array for ConfigFile storage.
func _rect2_to_array(value: Rect2) -> Array:
	return [value.position.x, value.position.y, value.size.x, value.size.y]

# Converts an array-like value into a Vector2, or returns the fallback.
func _array_to_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback

# Converts an array-like value into a Rect2, or returns the fallback.
func _array_to_rect2(value: Variant, fallback: Rect2) -> Rect2:
	if value is Array and value.size() >= 4:
		return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	return fallback

# Returns config sections whose names start with the given prefix, sorted for stable loading.
func _sorted_sections_with_prefix(config: ConfigFile, prefix: String) -> Array[String]:
	var sections: Array[String] = []
	for section in config.get_sections():
		if section.begins_with(prefix):
			sections.append(section)
	sections.sort()
	return sections

# Tries to convert an absolute path to a project-relative path when possible.
func _make_relative_if_possible(path: String) -> String:
	if path == "":
		return ""
	if path.begins_with("res://"):
		return path
	if path.begins_with("user://"):
		return path
	if path.contains("/"):
		var project_dir := ProjectSettings.globalize_path("res://")
		if path.begins_with(project_dir):
			return "res://" + path.substr(project_dir.length())
	return path

# Normalizes imported paths, keeping res:// and user:// as-is.
func _resolve_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return path
	return path
