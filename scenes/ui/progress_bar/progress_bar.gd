extends CanvasLayer

@onready var bar: ColorRect = $Control/base_bar
@onready var beat: ColorRect = $Control/base_bar/bar_beat

var bpm := 0
var beat_duration := 0.5
var beat_timer := 0.0

func _ready():
	pass

func _process(delta):
	beat_timer += delta
	
	if beat_timer > beat_duration:
		beat_timer -= beat_duration
	
	update_beat()

func update_beat():
	beat_duration = 60.0 / bpm
	
	var t = beat_timer / beat_duration

	var width = bar.size.x
	beat.position.x = t * width
	
func set_bpm(number: int):
	bpm = number
