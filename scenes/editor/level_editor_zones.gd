extends Node2D

# Añade una zona nueva usando el rectángulo por defecto calculado al lado del playfield.
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

func _on_zone_list_selected(index: int) -> void:
	_select_zone(index)

func _on_zone_clicked(zone_node) -> void:
	for i in zones.size():
		if zones[i].get("node") == zone_node:
			_select_zone(i)
			break

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

func _clear_zone_inspector() -> void:
	_set_ui_suppressed(true)
	zone_id_edit.text = ""
	zone_pos_x_spin.value = 0
	zone_pos_y_spin.value = 0
	zone_width_spin.value = 0
	zone_height_spin.value = 0
	_set_ui_suppressed(false)

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

func _refresh_zone_list() -> void:
	var previous = selected_zone_index
	zone_list.clear()
	for zone_data in zones:
		zone_list.add_item(zone_data.get("id", ""))
	if previous >= 0 and previous < zones.size():
		zone_list.select(previous)

func _update_projectile_area_ids(old_id: String, new_id: String) -> void:
	for i in projectiles.size():
		var data = projectiles[i]
		if data.get("area_id") == old_id:
			data["area_id"] = new_id
			projectiles[i] = data

func _clear_projectile_area_for_zone(zone_id: String) -> void:
	for i in projectiles.size():
		var data = projectiles[i]
		if data.get("area_id") == zone_id:
			data["area_id"] = null
			projectiles[i] = data
			_update_projectile_marker(data)
	if selected_projectile_index >= 0 and selected_projectile_index < projectiles.size():
		_highlight_zone_for_area(projectiles[selected_projectile_index].get("area_id"))

func _highlight_zone_for_area(area_id) -> void:
	for zone_data in zones:
		var node = zone_data.get("node")
		if node:
			node.set_highlighted(area_id != null and zone_data.get("id", "") == area_id)

func _clear_zones() -> void:
	for zone_data in zones:
		var node = zone_data.get("node")
		if node:
			node.queue_free()
	zones.clear()
	selected_zone_index = -1
	zone_id_counter = 1
	_refresh_zone_list()

func _recalculate_zone_id_counter() -> void:
	var highest = 0
	for zone_data in zones:
		var zone_id = zone_data.get("id", "")
		if zone_id.begins_with("zone_"):
			var suffix = zone_id.substr(5)
			if suffix.is_valid_int():
				highest = max(highest, int(suffix))
	zone_id_counter = max(highest + 1, zones.size() + 1)

func _get_playfield_bounds() -> Rect2:
	if playfield and playfield.has_method("get_bounds"):
		return playfield.get_bounds()
	var size = Vector2(playfield_width_spin.value, playfield_height_spin.value)
	return Rect2(playfield.global_position - size / 2.0, size)

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
