extends Node

signal music_volume_changed(volume_percent: float)

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "audio"
const MUSIC_VOLUME_KEY := "music_volume_percent"
const MUSIC_BUS_NAME := "Analyzer"
const MIN_VOLUME_DB := -80.0

var music_volume_percent := 100.0

func _ready() -> void:
	load_settings()
	apply_music_volume()


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		return

	music_volume_percent = clampf(
		float(config.get_value(SETTINGS_SECTION, MUSIC_VOLUME_KEY, music_volume_percent)),
		0.0,
		100.0
	)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SETTINGS_SECTION, MUSIC_VOLUME_KEY, music_volume_percent)
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_warning("No se pudo guardar la configuracion: %s" % SETTINGS_PATH)


func set_music_volume_percent(volume_percent: float, save_changes := true) -> void:
	var clamped_volume := clampf(volume_percent, 0.0, 100.0)
	if is_equal_approx(music_volume_percent, clamped_volume):
		return

	music_volume_percent = clamped_volume
	apply_music_volume()
	music_volume_changed.emit(music_volume_percent)

	if save_changes:
		save_settings()


func get_music_volume_percent() -> float:
	return music_volume_percent


func apply_music_volume() -> void:
	var bus_index := AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if bus_index == -1:
		return

	var linear_volume := music_volume_percent / 100.0
	var volume_db := MIN_VOLUME_DB if linear_volume <= 0.0 else linear_to_db(linear_volume)
	AudioServer.set_bus_volume_db(bus_index, volume_db)
