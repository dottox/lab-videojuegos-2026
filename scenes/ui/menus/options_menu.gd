extends Control

signal back_requested

@onready var volume_slider: HSlider = $CenterContainer/Panel/MarginContainer/VBoxContainer/VolumeRow/VolumeSlider
@onready var volume_percent_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/VolumeRow/VolumePercentLabel
@onready var back_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/BackButton

var return_to_main_menu_on_back := true
var _updating_slider := false

func _ready() -> void:
	GameLoader.install_menu_button_sfx(self)
	volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	back_button.pressed.connect(_on_back_pressed)

	if not GameSettings.music_volume_changed.is_connected(_on_music_volume_changed):
		GameSettings.music_volume_changed.connect(_on_music_volume_changed)

	_set_slider_value(GameSettings.get_music_volume_percent())
	back_button.grab_focus()


func set_return_to_main_menu_on_back(enabled: bool) -> void:
	return_to_main_menu_on_back = enabled


func _set_slider_value(volume_percent: float) -> void:
	_updating_slider = true
	volume_slider.value = volume_percent
	_updating_slider = false
	_update_volume_percent_label(volume_percent)


func _update_volume_percent_label(volume_percent: float) -> void:
	volume_percent_label.text = "%d%%" % roundi(volume_percent)


func _on_volume_slider_value_changed(value: float) -> void:
	_update_volume_percent_label(value)
	if _updating_slider:
		return

	GameSettings.set_music_volume_percent(value)


func _on_music_volume_changed(volume_percent: float) -> void:
	_set_slider_value(volume_percent)


func _on_back_pressed() -> void:
	if return_to_main_menu_on_back:
		GameLoader.load_scene("main_menu")
	else:
		back_requested.emit()
