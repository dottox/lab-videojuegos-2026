extends RefCounted
class_name LevelEditorZones

var editor: Node2D

# Initializes the zones manager with the editor instance it operates on.
func initialize(p_editor: Node2D) -> void:
	editor = p_editor

# Adds a new zone using the current default size and selects it.
func _on_add_zone_pressed() -> void:
	var zone_id = editor.state.zone_id_counter
	editor.state.zone_id_counter += 1
	
	var size = Vector2(editor.zone_width_spin.value, editor.zone_height_spin.value)
	var rect = _default_zone_rect(size)
	
	var new_node = editor.ZoneAreaScene.instantiate()
	editor.zones_layer.add_child(new_node)
	new_node.set_zone(zone_id, rect)
	new_node.clicked.connect(editor._on_zone_clicked)
	editor.state.zones.append(new_node)
	
	refresh_zone_list()
	editor._update_area_options()
	_select_zone(editor.state.zones.size() - 1)

# Removes the currently selected zone and clears any projectile references to it.
func _on_remove_zone_pressed() -> void:
	if editor.state.selected_zone_index < 0 or editor.state.selected_zone_index >= editor.state.zones.size():
		return
	var current_zone = editor.state.zones[editor.state.selected_zone_index]
	current_zone.queue_free()
	
	editor.state.zones.remove_at(editor.state.selected_zone_index)
	editor.state.selected_zone_index = -1
	
	refresh_zone_list()
	editor._update_area_options()
	_clear_zone_inspector()
	_clear_projectile_area_for_zone(current_zone.id)

# Handles selection from the zone list UI.
func _on_zone_list_selected(index: int) -> void:
	_select_zone(index)

# Selects a zone when its node is clicked in the scene.
func _on_zone_clicked(zone_node) -> void:
	for i in editor.state.zones.size():
		if editor.state.zones[i] == zone_node:
			_select_zone(i)
			break

# Selects a zone by index and syncs the inspector fields.
func _select_zone(index: int) -> void:
	if index < 0:
		editor.state.selected_zone_index = -1
		editor.zone_list.deselect_all()
		_clear_zone_inspector()
		return
	if index >= editor.state.zones.size():
		return
	editor.state.selected_zone_index = index
	editor.zone_list.select(index)
	
	var selected_zone = editor.state.zones[index]
	editor._set_ui_suppressed(true)
	editor.zone_id_edit.text = str(selected_zone.id)
	editor.zone_pos_x_spin.value = selected_zone.rect.position.x
	editor.zone_pos_y_spin.value = selected_zone.rect.position.y
	editor.zone_width_spin.value = selected_zone.rect.size.x
	editor.zone_height_spin.value = selected_zone.rect.size.y
	editor._set_ui_suppressed(false)

# Clears the zone inspector fields and resets them to defaults.
func _clear_zone_inspector() -> void:
	editor._set_ui_suppressed(true)
	editor.zone_id_edit.text = ""
	editor.zone_pos_x_spin.value = 0
	editor.zone_pos_y_spin.value = 0
	editor.zone_width_spin.value = 0
	editor.zone_height_spin.value = 0
	editor._set_ui_suppressed(false)

# Updates the selected zone position and refreshes its node.
func _on_zone_position_changed(_value: float) -> void:
	if editor.state.suppress_ui:
		return
	if editor.state.selected_zone_index < 0 or editor.state.selected_zone_index >= editor.state.zones.size():
		return
	var current_zone = editor.state.zones[editor.state.selected_zone_index]
	current_zone.rect.position = Vector2(editor.zone_pos_x_spin.value, editor.zone_pos_y_spin.value)
	current_zone.set_zone(current_zone.id, current_zone.rect)

# Updates the selected zone size and refreshes its node.
func _on_zone_size_changed(_value: float) -> void:
	if editor.state.suppress_ui:
		return
	if editor.state.selected_zone_index < 0 or editor.state.selected_zone_index >= editor.state.zones.size():
		return
	var current_zone = editor.state.zones[editor.state.selected_zone_index]
	current_zone.rect.size = Vector2(editor.zone_width_spin.value, editor.zone_height_spin.value)
	current_zone.set_zone(current_zone.id, current_zone.rect)

# Rebuilds the zone list UI while preserving the current selection when possible.
func refresh_zone_list() -> void:
	var previous = editor.state.selected_zone_index
	editor.zone_list.clear()
	for zone in editor.state.zones:
		editor.zone_list.add_item("Zone #%d" % zone.id)
	if previous >= 0 and previous < editor.state.zones.size():
		editor.zone_list.select(previous)

# Renames projectile area IDs that reference an old zone ID.
#func _update_projectile_zone_ids(old_id: int, new_id: int) -> void:

# Clears projectile area references for a deleted zone and refreshes affected markers.
func _clear_projectile_area_for_zone(zone_id: int) -> void:
	for i in editor.state.projectiles.size():
		var proj = editor.state.projectiles[i]
		if proj.zone_id == zone_id:
			proj.zone_id == 0
			editor.projectiles_component.update_projectile_marker(proj)
	if editor.state.selected_projectile_index >= 0 and editor.state.selected_projectile_index < editor.state.projectiles.size():
		highlight_zone_for_area(editor.state.projectiles[editor.state.selected_projectile_index].zone_id)

# Toggles highlight on zones based on the selected area ID.
func highlight_zone_for_area(zone_id: int) -> void:
	for zone in editor.state.zones:
		zone.set_highlighted(zone_id != null and zone.id == zone_id)

# Frees all zone nodes and resets zone-related editor state.
func clear_zones() -> void:
	for zone in editor.state.zones:
		zone.queue_free()
	editor.state.zones.clear()
	editor.state.selected_zone_index = -1
	editor.state.zone_id_counter = 1
	refresh_zone_list()

# Recomputes the next zone ID counter from existing zone IDs.
func recalculate_zone_id_counter() -> void:
	var highest = 0
	for zone in editor.state.zones:
		highest = max(highest, zone.id)
	editor.state.zone_id_counter = max(highest + 1, editor.state.zones.size() + 1)

# Computes a default zone rectangle based on the playfield and existing zone count.
func _default_zone_rect(size: Vector2) -> Rect2:
	var bounds = Rect2(300, 300, 200, 200)
	var index = editor.state.zones.size()
	var column = index % editor.ZONES_PER_ROW
	var row = index / editor.ZONES_PER_ROW
	var position = Vector2(
		bounds.position.x - size.x - editor.ZONE_DEFAULT_MARGIN - (column * (size.x + editor.ZONE_DEFAULT_MARGIN)),
		bounds.position.y + row * (size.y + editor.ZONE_DEFAULT_MARGIN)
	)
	return Rect2(position, size)
