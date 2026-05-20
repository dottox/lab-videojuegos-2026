extends RefCounted
class_name LevelEditorZones

var editor: Node2D

# Initializes the zones manager with the editor instance it operates on.
func initialize(p_editor: Node2D) -> void:
	editor = p_editor

# Adds a new zone using the current default size and selects it.
func _on_add_zone_pressed() -> void:
	var zone_id = "zone_%d" % editor.state.zone_id_counter
	editor.state.zone_id_counter += 1
	var size = Vector2(editor.zone_width_spin.value, editor.zone_height_spin.value)
	var rect = _default_zone_rect(size)
	var zone_node = editor.ZoneAreaScene.instantiate()
	editor.zones_layer.add_child(zone_node)
	zone_node.set_zone(zone_id, rect)
	zone_node.clicked.connect(editor._on_zone_clicked)
	editor.state.zones.append({"id": zone_id, "rect": rect, "node": zone_node})
	refresh_zone_list()
	editor._update_area_options()
	_select_zone(editor.state.zones.size() - 1)

# Removes the currently selected zone and clears any projectile references to it.
func _on_remove_zone_pressed() -> void:
	if editor.state.selected_zone_index < 0 or editor.state.selected_zone_index >= editor.state.zones.size():
		return
	var zone_data = editor.state.zones[editor.state.selected_zone_index]
	var zone_id = zone_data.get("id", "")
	var node = zone_data.get("node")
	if node:
		node.queue_free()
	editor.state.zones.remove_at(editor.state.selected_zone_index)
	editor.state.selected_zone_index = -1
	refresh_zone_list()
	editor._update_area_options()
	_clear_zone_inspector()
	_clear_projectile_area_for_zone(zone_id)

# Handles selection from the zone list UI.
func _on_zone_list_selected(index: int) -> void:
	_select_zone(index)

# Selects a zone when its node is clicked in the scene.
func _on_zone_clicked(zone_node) -> void:
	for i in editor.state.zones.size():
		if editor.state.zones[i].get("node") == zone_node:
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
	var zone_data = editor.state.zones[index]
	var rect: Rect2 = zone_data["rect"]
	editor._set_ui_suppressed(true)
	editor.zone_id_edit.text = zone_data.get("id", "")
	editor.zone_pos_x_spin.value = rect.position.x
	editor.zone_pos_y_spin.value = rect.position.y
	editor.zone_width_spin.value = rect.size.x
	editor.zone_height_spin.value = rect.size.y
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

# Updates the selected zone ID and propagates the change to dependent projectiles.
func _on_zone_id_changed(text: String) -> void:
	if editor.state.suppress_ui:
		return
	if editor.state.selected_zone_index < 0 or editor.state.selected_zone_index >= editor.state.zones.size():
		return
	var zone_data = editor.state.zones[editor.state.selected_zone_index]
	var old_id = zone_data.get("id", "")
	zone_data["id"] = text
	editor.state.zones[editor.state.selected_zone_index] = zone_data
	var node = zone_data.get("node")
	if node:
		node.set_zone(text, zone_data.get("rect", Rect2()))
	refresh_zone_list()
	editor._update_area_options()
	_update_projectile_area_ids(old_id, text)

# Updates the selected zone position and refreshes its node.
func _on_zone_position_changed(_value: float) -> void:
	if editor.state.suppress_ui:
		return
	if editor.state.selected_zone_index < 0 or editor.state.selected_zone_index >= editor.state.zones.size():
		return
	var zone_data = editor.state.zones[editor.state.selected_zone_index]
	var rect: Rect2 = zone_data["rect"]
	rect.position = Vector2(editor.zone_pos_x_spin.value, editor.zone_pos_y_spin.value)
	zone_data["rect"] = rect
	editor.state.zones[editor.state.selected_zone_index] = zone_data
	var node = zone_data.get("node")
	if node:
		node.set_zone(zone_data.get("id", ""), rect)

# Updates the selected zone size and refreshes its node.
func _on_zone_size_changed(_value: float) -> void:
	if editor.state.suppress_ui:
		return
	if editor.state.selected_zone_index < 0 or editor.state.selected_zone_index >= editor.state.zones.size():
		return
	var zone_data = editor.state.zones[editor.state.selected_zone_index]
	var rect: Rect2 = zone_data["rect"]
	rect.size = Vector2(editor.zone_width_spin.value, editor.zone_height_spin.value)
	zone_data["rect"] = rect
	editor.state.zones[editor.state.selected_zone_index] = zone_data
	var node = zone_data.get("node")
	if node:
		node.set_zone(zone_data.get("id", ""), rect)

# Rebuilds the zone list UI while preserving the current selection when possible.
func refresh_zone_list() -> void:
	var previous = editor.state.selected_zone_index
	editor.zone_list.clear()
	for zone_data in editor.state.zones:
		editor.zone_list.add_item(zone_data.get("id", ""))
	if previous >= 0 and previous < editor.state.zones.size():
		editor.zone_list.select(previous)

# Renames projectile area IDs that reference an old zone ID.
func _update_projectile_area_ids(old_id: String, new_id: String) -> void:
	for i in editor.state.projectiles.size():
		var data = editor.state.projectiles[i]
		if data.get("area_id") == old_id:
			data["area_id"] = new_id
			editor.state.projectiles[i] = data

# Clears projectile area references for a deleted zone and refreshes affected markers.
func _clear_projectile_area_for_zone(zone_id: String) -> void:
	for i in editor.state.projectiles.size():
		var data = editor.state.projectiles[i]
		if data.get("area_id") == zone_id:
			data["area_id"] = null
			editor.state.projectiles[i] = data
			editor.projectiles_component.update_projectile_marker(data)
	if editor.state.selected_projectile_index >= 0 and editor.state.selected_projectile_index < editor.state.projectiles.size():
		editor._highlight_zone_for_area(editor.state.projectiles[editor.state.selected_projectile_index].get("area_id"))

# Toggles highlight on zones based on the selected area ID.
func highlight_zone_for_area(area_id) -> void:
	for zone_data in editor.state.zones:
		var node = zone_data.get("node")
		if node:
			node.set_highlighted(area_id != null and zone_data.get("id", "") == area_id)

# Frees all zone nodes and resets zone-related editor state.
func clear_zones() -> void:
	for zone_data in editor.state.zones:
		var node = zone_data.get("node")
		if node:
			node.queue_free()
	editor.state.zones.clear()
	editor.state.selected_zone_index = -1
	editor.state.zone_id_counter = 1
	refresh_zone_list()

# Recomputes the next zone ID counter from existing zone IDs.
func recalculate_zone_id_counter() -> void:
	var highest = 0
	for zone_data in editor.state.zones:
		var zone_id = zone_data.get("id", "")
		if zone_id.begins_with("zone_"):
			var suffix = zone_id.substr(5)
			if suffix.is_valid_int():
				highest = max(highest, int(suffix))
	editor.state.zone_id_counter = max(highest + 1, editor.state.zones.size() + 1)

# Returns the playfield bounds, falling back to the current playfield size if needed.
func _get_playfield_bounds() -> Rect2:
	if editor.playfield and editor.playfield.has_method("get_bounds"):
		return editor.playfield.get_bounds()
	var size = Vector2(editor.playfield_width_spin.value, editor.playfield_height_spin.value)
	return Rect2(editor.playfield.global_position - size / 2.0, size)

# Computes a default zone rectangle based on the playfield and existing zone count.
func _default_zone_rect(size: Vector2) -> Rect2:
	var bounds = _get_playfield_bounds()
	var index = editor.state.zones.size()
	var column = index % editor.ZONES_PER_ROW
	var row = index / editor.ZONES_PER_ROW
	var position = Vector2(
		bounds.position.x - size.x - editor.ZONE_DEFAULT_MARGIN - (column * (size.x + editor.ZONE_DEFAULT_MARGIN)),
		bounds.position.y + row * (size.y + editor.ZONE_DEFAULT_MARGIN)
	)
	return Rect2(position, size)
