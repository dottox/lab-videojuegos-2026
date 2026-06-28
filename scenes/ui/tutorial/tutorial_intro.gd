extends Control

const TUTORIAL_LEVEL_PATH := "res://levels/tutorial.cfg"
const INPUT_DELAY := 1.25

@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/Layout/Title
@onready var modes_content: VBoxContainer = $CenterContainer/Panel/MarginContainer/Layout/ModesContent
@onready var controls_content: VBoxContainer = $CenterContainer/Panel/MarginContainer/Layout/ControlsContent
@onready var continue_label: Label = $CenterContainer/Panel/MarginContainer/Layout/ContinueLabel
@onready var delay_timer: Timer = $DelayTimer

var screen_index := 0
var can_continue := false

var titles := [
	"Modos de juego",
	"Controles",
]

func _ready() -> void:
	delay_timer.wait_time = INPUT_DELAY
	delay_timer.one_shot = true
	delay_timer.timeout.connect(_on_delay_timer_timeout)
	set_process_unhandled_input(true)
	_show_screen(0)

func _unhandled_input(event: InputEvent) -> void:
	if not can_continue:
		return

	if _is_continue_event(event):
		get_viewport().set_input_as_handled()
		_advance()

func _show_screen(index: int) -> void:
	screen_index = index
	can_continue = false
	title_label.text = titles[screen_index]
	modes_content.visible = screen_index == 0
	controls_content.visible = screen_index == 1
	continue_label.text = "..."
	delay_timer.start()

func _advance() -> void:
	if screen_index < titles.size() - 1:
		_show_screen(screen_index + 1)
		return
	GameLoader.load_level(TUTORIAL_LEVEL_PATH)


func _is_continue_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return event.pressed
	return false

func _on_delay_timer_timeout() -> void:
	can_continue = true
	continue_label.text = "Presiona cualquier tecla para continuar"
