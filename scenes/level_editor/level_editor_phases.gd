extends RefCounted
class_name LevelEditorPhases

var editor: Node2D

# Initializes the phases manager with the editor instance it operates on.
func initialize(p_editor: Node2D) -> void:
	editor = p_editor

func _on_phase_list_selected(index: int) -> void:
	_select_phase(index)
	
# Selects a phase by index and syncs the inspector/UI state.
func _select_phase(index: int) -> void:
	if index < 0:
		editor.state.selected_phase_index = -1
		editor.phase_list.deselect_all()
		clear_phase_inspector()
		return
	if index >= editor.state.phases.size():
		return
	editor.state.selected_phase_index = index
	editor.phase_list.select(index)
	var ph = editor.state.phases[index]
	editor._set_ui_suppressed(true)
	editor._set_option_button_value(editor.phase_type_option, ph.type)
	editor.phase_time_spin.value = ph.time
	editor._set_ui_suppressed(false)

func clear_phase_inspector() -> void:
	editor._set_ui_suppressed(true)
	editor.phase_type_option.select(0)
	editor.phase_time_spin.value = 0
	editor._set_ui_suppressed(false)

func _on_add_phase_pressed() -> void:
	var phase_id = editor.state.phase_id_counter
	editor.state.phase_id_counter += 1
	
	var new_phase = Phase.new()
	new_phase.type = "bullet_hell_no_rhythm"
	new_phase.time = editor.phase_time_spin.value
	editor.state.phases.append(new_phase)
	
	refresh_phases_list()
	_select_phase(editor.state.phases.size() - 1)
	
func _on_remove_phase_pressed() -> void:
	if editor.state.selected_phase_index < 0 or editor.state.selected_phase_index >= editor.state.phases.size():
		return
	
	var selected_ph = editor.state.phases[editor.state.selected_phase_index]
	
	editor.state.phases.remove_at(editor.state.selected_phase_index)
	editor.state.selected_phase_index = -1
	refresh_phases_list()
	clear_phase_inspector()
	
func refresh_phases_list() -> void:
	var previous = editor.state.selected_phase_index
	editor.phase_list.clear()
	for ph in editor.state.phases:
		editor.phase_list.add_item("%s @ %d" % [ph.type,ph.time])
	if previous >= 0 and previous < editor.state.phases.size():
		editor.phase_list.select(previous)
	editor._update_timeline_range()
		
func _on_phase_type_selected(index: int) -> void:
	if editor.state.selected_phase_index < 0 or editor.state.selected_phase_index >= editor.state.phases.size():
		return
	var current_phase = editor.state.phases[editor.state.selected_phase_index]
	current_phase.type = Phase.normalize_type(editor.phase_type_option.get_item_text(index))
	refresh_phases_list()

func _on_phase_time_changed(value: int) -> void:
	if editor.state.selected_phase_index < 0 or editor.state.selected_phase_index >= editor.state.phases.size():
		return
	var current_phase = editor.state.phases[editor.state.selected_phase_index]
	current_phase.time = value
	refresh_phases_list()
	
func clear_phases() -> void:
	editor.state.phases.clear()
	editor.state.selected_phase_index = -1
	refresh_phases_list()
