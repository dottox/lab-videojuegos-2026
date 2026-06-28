extends CanvasLayer

const ICON_SCENES := {
	"move": preload("res://scenes/ui/tutorial/tutorial_icon_move.tscn"),
	"dash": preload("res://scenes/ui/tutorial/tutorial_icon_dash.tscn"),
	"shield": preload("res://scenes/ui/tutorial/tutorial_icon_shield.tscn"),
	"hit": preload("res://scenes/ui/tutorial/tutorial_icon_hit.tscn"),
	"bullet": preload("res://scenes/ui/tutorial/tutorial_icon_bullet.tscn"),
	"rhythm": preload("res://scenes/ui/tutorial/tutorial_icon_rhythm.tscn"),
}

@onready var panel: PanelContainer = $Root/Panel
@onready var icon_slot: CenterContainer = $Root/Panel/Margin/Row/IconSlot
@onready var title_label: Label = $Root/Panel/Margin/Row/Text/Title
@onready var body_label: Label = $Root/Panel/Margin/Row/Text/Body

var current_icon: Node

func _ready() -> void:
	hide_hint()


func show_hint(data: Dictionary) -> void:
	title_label.text = str(data.get("title", ""))
	body_label.text = str(data.get("body", ""))
	_set_icon(str(data.get("icon", "")))
	visible = true
	panel.modulate.a = 1.0


func hide_hint() -> void:
	visible = false


func _set_icon(icon_name: String) -> void:
	if current_icon != null and is_instance_valid(current_icon):
		current_icon.queue_free()
		current_icon = null

	var icon_scene := ICON_SCENES.get(icon_name) as PackedScene
	if icon_scene == null:
		return

	current_icon = icon_scene.instantiate()
	var icon_control := current_icon as Control
	if icon_control != null:
		icon_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_slot.add_child(current_icon)
