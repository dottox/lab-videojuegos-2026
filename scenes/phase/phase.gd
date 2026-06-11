class_name Phase

const TYPES := {
	"bullet_hell_no_rhythm": true,
	"bullet_hell_rhythm": true,
	"shield_no_rhythm": true,
	"shield_rhythm": true,
}

const TYPE_ALIASES := {
	"bullet_hell": "bullet_hell_no_rhythm",
	"rythm": "bullet_hell_rhythm",
	"rhythm": "bullet_hell_rhythm",
	"bullet_hell_no_rythm": "bullet_hell_no_rhythm",
	"bullet_hell_rythm": "bullet_hell_rhythm",
	"shield_no_rythm": "shield_no_rhythm",
	"shield_rythm": "shield_rhythm",
}

var type: String
var time: int 

static func normalize_type(raw_type: String) -> String:
	var normalized := raw_type.strip_edges().to_lower()
	if normalized == "":
		return "bullet_hell_no_rhythm"
	return TYPE_ALIASES.get(normalized, normalized)

static func is_known_type(raw_type: String) -> bool:
	return TYPES.has(normalize_type(raw_type))

static func is_shield_phase(raw_type: String) -> bool:
	return normalize_type(raw_type).begins_with("shield")

static func is_rhythm_phase(raw_type: String) -> bool:
	var normalized := normalize_type(raw_type)
	return normalized.ends_with("_rhythm") and not normalized.ends_with("_no_rhythm")

func set_type(new_type: String) -> void:
	var normalized := normalize_type(new_type)
	if normalized not in TYPES.keys():
		print("[phase]: ", new_type, " not found in ", TYPES.keys())
		return
	else:
		type = normalized
		
func set_time(new_time: int) -> void:
	time = new_time
