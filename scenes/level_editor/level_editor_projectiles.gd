extends RefCounted
class_name LevelEditorProjectiles

var editor: Node2D

# Initializes the projectile manager with the editor instance it operates on.
func initialize(p_editor: Node2D) -> void:
	editor = p_editor

# Creates a new projectile marker and stores its data at the given position.
func create_projectile_at(position: Vector2) -> void:
	var marker = editor.ProjectileMarkerScene.instantiate()
	editor.projectiles_layer.add_child(marker)
	marker.global_position = position
	marker.clicked.connect(editor._on_projectile_marker_clicked)
	
	marker.time_ms = editor.state.current_time_ms
	marker.pos = position
	marker.speed = editor.projectile_speed_spin.value
	marker.angle = editor.projectile_angle_spin.value
	marker.pattern = "single"
	marker.zone_id = 0
	marker.type = "basic"
	
	editor.state.projectiles.append(marker)
	update_projectile_marker(marker)
	refresh_projectile_list()
	update_projectile_visibility()
	select_projectile(editor.state.projectiles.size() - 1)

# Selects a projectile when its marker is clicked in the scene.
func _on_projectile_marker_clicked(marker) -> void:
	for i in editor.state.projectiles.size():
		if editor.state.projectiles[i] == marker:
			select_projectile(i)
			break

# Handles selection changes from the projectile list UI.
func _on_projectile_list_selected(index: int) -> void:
	select_projectile(index)

# Selects a projectile by index and syncs the inspector/UI state.
func select_projectile(index: int) -> void:
	if index < 0:
		editor.state.selected_projectile_index = -1
		editor.projectile_list.deselect_all()
		for proj in editor.state.projectiles:
			proj.set_selected(false)
		clear_projectile_inspector()
		editor.zones_component.highlight_zone_for_area(0)
		return
	if index >= editor.state.projectiles.size():
		return
	editor.state.selected_projectile_index = index
	editor.projectile_list.select(index)
	for i in editor.state.projectiles.size():
		var proj = editor.state.projectiles[i]
		proj.set_selected(i == index)
	
	var proj_at_current_index = editor.state.projectiles[index]
	editor._set_ui_suppressed(true)
	editor.projectile_time_spin.value = proj_at_current_index.time_ms
	var pos: Vector2 = proj_at_current_index.pos
	editor.projectile_pos_x_spin.value = pos.x
	editor.projectile_pos_y_spin.value = pos.y
	editor.projectile_speed_spin.value = proj_at_current_index.speed
	editor.projectile_angle_spin.value = proj_at_current_index.angle
	editor._set_option_button_value(editor.projectile_type_option, proj_at_current_index.type)
	editor._set_option_button_value(editor.projectile_pattern_option, proj_at_current_index.pattern)
	var zone_id = proj_at_current_index.zone_id
	if zone_id == null:
		editor.projectile_area_option.select(0)
	else:
		editor._set_option_button_value(editor.projectile_area_option, str(zone_id))
		editor.zones_component.highlight_zone_for_area(zone_id)
	editor._set_ui_suppressed(false)

# Deletes the currently selected projectile if the selection is valid.
func _on_delete_projectile_pressed() -> void:
	if editor.state.selected_projectile_index < 0 or editor.state.selected_projectile_index >= editor.state.projectiles.size():
		return
	var proj = editor.state.projectiles[editor.state.selected_projectile_index]
	proj.queue_free()
	editor.state.projectiles.remove_at(editor.state.selected_projectile_index)
	editor.state.selected_projectile_index = -1
	refresh_projectile_list()
	clear_projectile_inspector()

# Clears the projectile inspector fields and resets selection controls.
func clear_projectile_inspector() -> void:
	editor._set_ui_suppressed(true)
	editor.projectile_time_spin.value = 0
	editor.projectile_pos_x_spin.value = 0
	editor.projectile_pos_y_spin.value = 0
	editor.projectile_speed_spin.value = 0
	editor.projectile_angle_spin.value = 0
	editor.projectile_type_option.select(0)
	editor.projectile_pattern_option.select(0)
	editor.projectile_area_option.select(0)
	editor._set_ui_suppressed(false)

# Updates the selected projectile's time and refreshes list/visibility.
func _on_projectile_time_changed(value: float) -> void:
	if editor.state.suppress_ui:
		return
	if editor.state.selected_projectile_index < 0 or editor.state.selected_projectile_index >= editor.state.projectiles.size():
		return
	var proj = editor.state.projectiles[editor.state.selected_projectile_index]
	proj.time_ms = value
	refresh_projectile_list()
	update_projectile_visibility()

# Updates the selected projectile's position and marker transform.
func _on_projectile_position_changed(_value: float) -> void:
	if editor.state.suppress_ui:
		return
	if editor.state.selected_projectile_index < 0 or editor.state.selected_projectile_index >= editor.state.projectiles.size():
		return
	var proj = editor.state.projectiles[editor.state.selected_projectile_index]
	var pos = Vector2(editor.projectile_pos_x_spin.value, editor.projectile_pos_y_spin.value)
	proj.pos = pos
	proj.global_position = pos

# Updates the selected projectile's speed.
func _on_projectile_speed_changed(value: float) -> void:
	if editor.state.suppress_ui:
		return
	if editor.state.selected_projectile_index < 0 or editor.state.selected_projectile_index >= editor.state.projectiles.size():
		return
	var proj = editor.state.projectiles[editor.state.selected_projectile_index]
	proj.speed = value

# Updates the selected projectile's angle.
func _on_projectile_angle_changed(value: float) -> void:
	if editor.state.suppress_ui:
		return
	if editor.state.selected_projectile_index < 0 or editor.state.selected_projectile_index >= editor.state.projectiles.size():
		return
	var proj = editor.state.projectiles[editor.state.selected_projectile_index]
	proj.angle = value
	update_projectile_marker(proj)

# Updates the selected projectile type from the option button.
func _on_projectile_type_selected(index: int) -> void:
	if editor.state.suppress_ui:
		return
	if editor.state.selected_projectile_index < 0 or editor.state.selected_projectile_index >= editor.state.projectiles.size():
		return
	var proj = editor.state.projectiles[editor.state.selected_projectile_index]
	proj.type = editor.projectile_type_option.get_item_text(index)
	refresh_projectile_list()

# Updates the selected projectile pattern, or clears it when index is 0.
func _on_projectile_pattern_selected(index: int) -> void:
	if editor.state.suppress_ui:
		return
	if editor.state.selected_projectile_index < 0 or editor.state.selected_projectile_index >= editor.state.projectiles.size():
		return
	var proj = editor.state.projectiles[editor.state.selected_projectile_index]
	if index == 0:
		proj.pattern = "single"
	else:
		proj.pattern = editor.projectile_pattern_option.get_item_text(index)

# Updates the selected projectile's target area and refreshes its marker.
func _on_projectile_area_selected(index: int) -> void:
	if editor.state.suppress_ui:
		return
	if editor.state.selected_projectile_index < 0 or editor.state.selected_projectile_index >= editor.state.projectiles.size():
		return
	var proj = editor.state.projectiles[editor.state.selected_projectile_index]
	if index == 0:
		proj.zone_id = 0
	else:
		proj.zone_id = editor.projectile_area_option.get_item_text(index)
		editor.zones_component.highlight_zone_for_area(proj.zone_id)
	update_projectile_marker(proj)

# Rebuilds the projectile list UI and restores the previous selection when possible.
func refresh_projectile_list() -> void:
	var previous = editor.state.selected_projectile_index
	editor.projectile_list.clear()
	for proj in editor.state.projectiles:
		editor.projectile_list.add_item("%s @ %dms" % [proj.type, proj.time_ms])
	if previous >= 0 and previous < editor.state.projectiles.size():
		editor.projectile_list.select(previous)
	editor._update_timeline_range()
	update_projectile_visibility()

# Applies marker-specific state such as area spawn mode and angle.
func update_projectile_marker(proj: Bullet) -> void:
	proj.set_spawn_in_area(proj.zone_id != null)
	proj.set_angle(proj.angle)

# Frees all projectile nodes and clears projectile state.
func clear_projectiles() -> void:
	for proj in editor.state.projectiles:
		proj.queue_free()
	editor.state.projectiles.clear()
	editor.state.selected_projectile_index = -1
	refresh_projectile_list()

# Updates projectile marker visibility based on the current timeline time.
func update_projectile_visibility() -> void:
	for proj in editor.state.projectiles:
		var projectile_time = proj.time_ms
		proj.visible = abs(projectile_time - editor.state.current_time_ms) <= editor.PROJECTILE_PREVIEW_WINDOW_MS
