class_name Phase

const TYPES := {
	"bullet_hell": true,
	"rythm": true,
}

var type: String
var time: int 

func set_type(type: String) -> void:
	if type not in TYPES.keys():
		print("[phase]: ", type, " not found in ", TYPES.keys())
		return
	else:
		type = type
		
func set_time(time: int) -> void:
	time = time
