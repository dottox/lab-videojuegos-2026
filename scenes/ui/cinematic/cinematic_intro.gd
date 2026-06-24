extends Control

const NEXT_SFX_PATH := "res://assets/sfx/cinematic_next.mp3"

const CINEMATIC_PAGES := [
	{
		"image": "res://assets/sprites/cinematic/cinematic0.png",
		"text": "Magaveja come tranquila y sonriente bajo las estrellas...\nLa magia para mantener su pelo sedoso e infinito requiere de mucha energía...",
	},
	{
		"image": "res://assets/sprites/cinematic/cinematic1.png",
		"text": "El rumor de la lana infinita se expandió tanto que llegó hasta el espacio...\nY vinieron a por ella...",
	},
	{
		"image": "res://assets/sprites/cinematic/cinematic2.png",
		"text": "Magaveja deberá ser buena esquivando tijeras...\nLo hará al ritmo de la música del espacio...\n— Los aliens escuchan la 90.3 FM —",
	},
]

@onready var image: TextureRect = $Image
@onready var text_panel: PanelContainer = $TextPanel
@onready var story_text: Label = $TextPanel/MarginContainer/StoryText
@onready var next_audio: AudioStreamPlayer = $NextAudio

var page_index := 0
var showing_text := false

func _ready() -> void:
	_load_next_sound()
	set_process_input(true)
	_show_page(0)


func _input(event: InputEvent) -> void:
	if _is_advance_event(event):
		get_viewport().set_input_as_handled()
		_advance()


func _show_page(index: int) -> void:
	page_index = index
	showing_text = false

	var page: Dictionary = CINEMATIC_PAGES[page_index]
	image.texture = load(String(page["image"]))
	story_text.text = String(page["text"])
	text_panel.visible = false


func _advance() -> void:
	_play_next_sound()

	if not showing_text:
		showing_text = true
		text_panel.visible = true
		return

	if page_index < CINEMATIC_PAGES.size() - 1:
		_show_page(page_index + 1)
		return

	GameLoader.load_scene("main_menu")


func _is_advance_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT

	if event is InputEventScreenTouch:
		return event.pressed

	return false


func _load_next_sound() -> void:
	if ResourceLoader.exists(NEXT_SFX_PATH):
		next_audio.stream = load(NEXT_SFX_PATH)


func _play_next_sound() -> void:
	if next_audio.stream != null:
		next_audio.play()
