extends CanvasLayer

@onready var bar: ColorRect = $Control/base_bar
@onready var beat: ColorRect = $Control/base_bar/bar_beat

var seconds_per_beat := 0.0
var song_position := 0.0
var music := AudioStreamPlayer2D

var last_beat := -1
var pulse_time := 0.15
var pulse_timer := 0.0

var base_scale := Vector2.ONE
var pulse_scale := Vector2(1.25, 1.25)

func _ready():
	bar.size = Vector2(800, 30)
	bar.set_position(Vector2((get_window().size.x / 2) - (bar.size.x / 2), 25))
	#Con esto centramos el scale para utilizarlo luego
	beat.set_size(Vector2(bar.size.x * 0.015, bar.size.y + (bar.size.y * 0.5)))
	beat.set_position(Vector2((bar.size.x / 2) - (beat.size.x / 2), (bar.size.y / 2) - (beat.size.y / 2)))
	beat.pivot_offset = beat.size / 2

func _process(delta):
	
	if pulse_timer > 0:
		print((60 / seconds_per_beat))
		pulse_timer -= delta

		var t = pulse_timer / pulse_time
		beat.scale = base_scale.lerp(pulse_scale, t)
	else:
		beat.scale = base_scale

func set_bpm(bpm: float):
	print(bpm)
	seconds_per_beat = 60 / bpm
	
func update_song_time(time: float):
	song_position = time

	var current_beat = int(song_position / seconds_per_beat)

	if current_beat != last_beat:
		last_beat = current_beat
		trigger_pulse()

func trigger_pulse():
	pulse_timer = pulse_time
