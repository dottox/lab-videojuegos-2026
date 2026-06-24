extends Control

@onready var credits_list: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/CreditsList
@onready var funny_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/FunnyLabel
@onready var back_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/BackButton

var scroll_speed := -50.0
var t := 0.0

func _ready() -> void:
	GameLoader.install_menu_button_sfx(self)
	back_button.pressed.connect(_on_back_pressed)
	credits_list.position.y = 220.0

func _process(delta: float) -> void:
	t += delta
	credits_list.position.y -= scroll_speed * delta
	funny_label.rotation = sin(t * 2.0) * 0.02
	funny_label.scale = Vector2.ONE + Vector2.ONE * (sin(t * 4.0) * 0.05)

	if credits_list.position.y > 220.0:
		credits_list.position.y = -100.0

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")
