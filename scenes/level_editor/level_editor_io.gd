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
		var pf: Playfield = editor.state.playfields[i]
		var section := "playfields_%d" % i
		config.set_value(section, "id", pf.id)
		config.set_value(section, "rect", _rect2_to_array(pf.rect))

	# Zones in a stable order.
	for i in editor.state.zones.size():
		var zone: ZoneArea = editor.state.zones[i]
		var section := "zones_%d" % i
		config.set_value(section, "id", zone.id)
		config.set_value(section, "rect", _rect2_to_array(zone.rect))

	# Projectiles in a stable order.
	_sort_projectile_list_by_time()
	for i in editor.state.projectiles.size():
		var proj: Projectile = editor.state.projectiles[i]
		var section := "projectiles_%d" % i
		config.set_value(section, "time_ms", int(proj.time_ms))
		config.set_value(section, "pos", _vector2_to_array(proj.pos))
		config.set_value(section, "speed", float(proj.speed))
		config.set_value(section, "angle_deg", float(proj.angle))
		config.set_value(section, "type", Projectile.normalize_type(proj.type))
		config.set_value(section, "pattern", proj.pattern)
		config.set_value(section, "zone_id", proj.zone_id)
		
	for i in editor.state.phases.size():
		var ph: Phase = editor.state.phases[i]
		var section := "phases_%d" % i
		config.set_value(section, "time_ms", int(ph.time))
		config.set_value(section, "type", Phase.normalize_type(ph.type))

# Restores editor state from a ConfigFile.
func _read_level_config(config: ConfigFile) -> void:
	editor.state.music_id = str(config.get_value("meta", "music_id", ""))
	editor.state.music_path = _resolve_path(str(config.get_value("meta", "music_path", "")))
	editor._set_ui_suppressed(true)
	editor.music_id_edit.text = editor.state.music_id
	editor.bpm_spin.value = float(config.get_value("meta", "bpm", editor.bpm_spin.value))
	editor._set_ui_suppressed(false)

	editor.playfields_component.clear_playfields()
	var playfield_sections := _sorted_sections_with_prefix(config, "playfields_")
	for section in playfield_sections:
		var id: int = config.get_value(section, "id", "")
		var rect := _array_to_rect2(config.get_value(section, "rect", [0, 0, 0, 0]), Rect2())
		var playfield_node = editor.PlayfieldScene.instantiate()
		editor.playfields_layer.add_child(playfield_node)
		playfield_node.set_playfield(id, rect)
		playfield_node.clicked.connect(editor._on_playfield_clicked)
		editor.state.playfields.append(playfield_node)

	editor.playfields_component.recalculate_playfield_id_counter()
	editor.playfields_component.refresh_playfields_list()

	editor.zones_component.clear_zones()
	var zone_sections := _sorted_sections_with_prefix(config, "zones_")
	for section in zone_sections:
		var id: int = config.get_value(section, "id", "")
		var rect := _array_to_rect2(config.get_value(section, "rect", [0, 0, 0, 0]), Rect2())
		var zone_node = editor.ZoneAreaScene.instantiate()
		editor.zones_layer.add_child(zone_node)
		zone_node.set_zone(id, rect)
		zone_node.clicked.connect(editor._on_zone_clicked)
		editor.state.zones.append(zone_node)

	editor.zones_component.recalculate_zone_id_counter()
	editor.zones_component.refresh_zone_list()
	editor._update_area_options()

	editor.projectiles_component.clear_projectiles()
	var projectile_sections := _sorted_sections_with_prefix(config, "projectiles_")
	projectile_sections.sort_custom(func(a: String, b: String) -> bool:
		return int(config.get_value(a, "time_ms", 0)) < int(config.get_value(b, "time_ms", 0))
	)
	for section in projectile_sections:
		var time_ms := int(config.get_value(section, "time_ms", 0))
		var pos := _array_to_vector2(config.get_value(section, "pos", [0, 0]), Vector2.ZERO)
		var speed := float(config.get_value(section, "speed", 0.0))
		var angle_deg := float(config.get_value(section, "angle_deg", 0.0))
		var projectile_type := str(config.get_value(section, "type", editor.state.projectile_types[0] if editor.state.projectile_types.size() > 0 else "bullet"))
		var pattern = config.get_value(section, "pattern", "")
		var zone_id = config.get_value(section, "zone_id", 0)

		var marker = editor.ProjectileMarkerScene.instantiate()
		editor.projectiles_layer.add_child(marker)
		marker.clicked.connect(editor._on_projectile_marker_clicked)
		marker.time_ms = time_ms
		marker.global_position = pos
		marker.pos = pos
		marker.speed = speed
		marker.angle = angle_deg
		marker.pattern = pattern
		marker.zone_id = zone_id
		marker.type = Projectile.normalize_type(projectile_type)
		
		editor.state.projectiles.append(marker)
		editor.projectiles_component.update_projectile_marker(marker)

	editor.projectiles_component.refresh_projectile_list()
	editor.projectiles_component.update_projectile_visibility()
	
	editor.phases_component.clear_phases()
	var phase_sections := _sorted_sections_with_prefix(config, "phases_")
	for section in phase_sections:
		var time_ms: int = int(config.get_value(section, "time_ms", 0))
		var type: String = config.get_value(section, "type", "bullet_hell_no_rhythm")
		
		var phase: Phase = Phase.new()
		phase.time = time_ms
		phase.type = Phase.normalize_type(type)
		
		editor.state.phases.append(phase)
	editor.phases_component.refresh_phases_list()

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

func _sort_projectile_list_by_time() -> void:
	editor.state.projectiles.sort_custom(func(a, b):
		return a.time_ms < b.time_ms
	)
