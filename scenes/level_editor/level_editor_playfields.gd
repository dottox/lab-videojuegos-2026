extends RefCounted
class_name LevelEditorPlayfields

var editor: Node2D

# Initializes the playfield manager with the editor instance it operates on.
func initialize(p_editor: Node2D) -> void:
	editor = p_editor

# Rebuilds the playfield list UI and restores the previous selection when possible.
func refresh_playfields_list() -> void:
	var previous = editor.state.selected_playfield_index
	editor.playfield_list.clear()
	for data in editor.state.playfields:
		editor.playfield_list.add_item(data.get("id", "n/a"))
	if previous >= 0 and previous < editor.state.playfields.size():
		editor.playfield_list.select(previous)

func _on_playfield_list_selected(index: int) -> void:
	_select_playfield(index)

# Selects a playfield by index and syncs the inspector/UI state.
func _select_playfield(index: int) -> void:
	if index < 0:
		editor.state.selected_playfield_index = -1
		editor.playfield_list.deselect_all()
		clear_playfield_inspector()
		return
	if index >= editor.state.playfields.size():
		return
	editor.state.selected_playfield_index = index
	editor.playfield_list.select(index)
	var playfield_data = editor.state.playfields[index]
	var rect: Rect2 = playfield_data["rect"]
	editor._set_ui_suppressed(true)
	editor.playfield_pos_x_spin.value = rect.position.x
	editor.playfield_pos_y_spin.value = rect.position.y
	editor.playfield_width_spin.value = rect.size.x
	editor.playfield_height_spin.value = rect.size.y
	editor._set_ui_suppressed(false)

# Frees all playfield nodes and resets playfield-related editor state.
func clear_playfields() -> void:
	for playfield_data in editor.state.playfields:
		var node = playfield_data.get("node")
		if node:
			node.queue_free()
	editor.state.playfields.clear()
	editor.state.selected_playfield_index = -1
	editor.state.playfield_id_counter = 1
	refresh_playfields_list()

# Adds a new playfield using the current default size and selects it.
func _on_add_playfield_pressed() -> void:
	var playfield_id = "playfield_%d" % editor.state.playfield_id_counter
	editor.state.playfield_id_counter += 1
	var size = Vector2(editor.playfield_width_spin.value, editor.playfield_height_spin.value)
	var position = Vector2(editor.playfield_pos_x_spin.value, editor.playfield_pos_y_spin.value)
	var rect = Rect2(position, size)
	var playfield_node = editor.PlayfieldScene.instantiate()
	editor.playfields_layer.add_child(playfield_node)
	playfield_node.set_playfield(playfield_id, rect)
	playfield_node.clicked.connect(editor._on_playfield_clicked)
	editor.state.playfields.append({"id": playfield_id, "rect": rect, "node": playfield_node})
	refresh_playfields_list()
	_select_playfield(editor.state.playfields.size() - 1)

# Removes the currently selected playfield and clears any projectile references to it.
func _on_remove_playfield_pressed() -> void:
	if editor.state.selected_playfield_index < 0 or editor.state.selected_playfield_index >= editor.state.playfields.size():
		return
	var playfield_data = editor.state.playfields[editor.state.selected_playfield_index]
	var playfield_id = playfield_data.get("id", "")
	var node = playfield_data.get("node")
	if node:
		node.queue_free()
	editor.state.playfields.remove_at(editor.state.selected_playfield_index)
	editor.state.selected_playfield_index = -1
	refresh_playfields_list()
	clear_playfield_inspector()

# Selects a playfield when its node is clicked in the scene.
func _on_playfield_clicked(playfield_node) -> void:
	for i in editor.state.playfields.size():
		if editor.state.playfields[i].get("node") == playfield_node:
			_select_playfield(i)
			break

# Cambia el tipo de playfield activo.
#func _on_playfield_type_selected(index: int) -> void:
	#state.playfield_type = playfield_type_option.get_item_text(index)
#	if playfield and playfield.has_method("set_state"):
#		playfield.set_state(state.playfield_type)

# Updates the selected playfield size and refreshes its node.
func _on_playfield_size_changed(_value: float) -> void:
	if editor.state.suppress_ui:
		return
	if editor.state.selected_playfield_index < 0 or editor.state.selected_playfield_index >= editor.state.playfields.size():
		return
	var playfield_data = editor.state.playfields[editor.state.selected_playfield_index]
	var rect: Rect2 = playfield_data["rect"]
	rect.size = Vector2(editor.playfield_width_spin.value, editor.playfield_height_spin.value)
	playfield_data["rect"] = rect
	editor.state.playfields[editor.state.selected_playfield_index] = playfield_data
	var node = playfield_data.get("node")
	if node:
		node.set_playfield(playfield_data.get("id", ""), rect)
		
# Updates the selected playfield position and refreshes its node.
func _on_playfield_position_changed(_value: float) -> void:
	if editor.state.suppress_ui:
		return
	if editor.state.selected_playfield_index < 0 or editor.state.selected_playfield_index >= editor.state.playfields.size():
		return
	var playfield_data = editor.state.playfields[editor.state.selected_playfield_index]
	var rect: Rect2 = playfield_data["rect"]
	rect.position = Vector2(editor.playfield_pos_x_spin.value, editor.playfield_pos_y_spin.value)
	playfield_data["rect"] = rect
	editor.state.playfields[editor.state.selected_playfield_index] = playfield_data
	var node = playfield_data.get("node")
	if node:
		node.set_playfield(playfield_data.get("id", ""), rect)
		
func clear_playfield_inspector() -> void:
	editor._set_ui_suppressed(true)
	editor.playfield_pos_x_spin.value = 0
	editor.playfield_pos_y_spin.value = 0
	editor.playfield_width_spin.value = 0
	editor.playfield_height_spin.value = 0
	editor._set_ui_suppressed(false)

func recalculate_playfield_id_counter() -> void:
	var highest = 0
	for playfield_data in editor.state.playfields:
		var playfield_id = playfield_data.get("id", "")
		if playfield_id.begins_with("playfield_"):
			var suffix = playfield_id.substr(5)
			if suffix.is_valid_int():
				highest = max(highest, int(suffix))
	editor.state.playfield_id_counter = max(highest + 1, editor.state.playfields.size() + 1)
