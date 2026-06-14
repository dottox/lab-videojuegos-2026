extends CanvasLayer

signal rhythm_note_missed

@onready var hud = $Control/RhythmHud

var seconds_per_beat := 0.0
var song_position := 0.0
var music := AudioStreamPlayer2D
var player_target

var last_beat := -1
var pulse_time := 0.15
var pulse_timer := 0.0
var prepare_time := 0.75
var prepare_timer := 0.0
var feedback_time := 0.18
var feedback_timer := 0.0
var feedback_color := Color.WHITE
var rhythm_hit_cooldown_time := 0.12
var rhythm_hit_cooldown_timer := 0.0
var bpm_flash_time := 0.12
var bpm_flash_timer := 0.0
var bpm_flash_color := Color(0.82, 0.9, 1.0)
var last_background_beat := -1

var rhythm_active := false
var hit_window := 18.0
var default_note_speed := 260.0
var active_notes: Array = []
var current_score := 0
var pending_health_current := 1
var pending_health_max := 1
var pending_accuracy := 100.0

func _ready():
	hud.set_score(current_score, false)
	hud.set_health(pending_health_current, pending_health_max)
	hud.set_accuracy(pending_accuracy)
	hud.set_rhythm_active(rhythm_active)

func _process(delta):
	_prune_notes()

	if rhythm_active:
		_process_note_misses()
	_update_next_note_accent()

	if rhythm_hit_cooldown_timer > 0:
		rhythm_hit_cooldown_timer -= delta

	if bpm_flash_timer > 0:
		bpm_flash_timer -= delta

	if prepare_timer > 0:
		prepare_timer -= delta

	if feedback_timer > 0:
		feedback_timer -= delta

	if pulse_timer > 0:
		pulse_timer -= delta
	
	_update_dash_status()
	_update_hud_effects()

func set_bpm(bpm: float):
	seconds_per_beat = 60 / bpm
	last_background_beat = -1

func set_player(player) -> void:
	player_target = player
	if player_target != null and is_instance_valid(player_target):
		set_health(int(player_target.get("vida")), int(player_target.get("max_vida")))
	_update_dash_status()

func set_score(value: int) -> void:
	var increased := value > current_score
	current_score = value
	if _is_hud_ready():
		hud.set_score(current_score, increased)

func set_health(current_health: int, max_health: int) -> void:
	pending_health_current = current_health
	pending_health_max = max_health
	if _is_hud_ready():
		hud.set_health(current_health, max_health)

func set_accuracy(value: float) -> void:
	pending_accuracy = value
	if _is_hud_ready():
		hud.set_accuracy(value)

func set_screen_filters(background_flash_alpha: float, low_health_alpha: float) -> void:
	if _is_hud_ready():
		hud.set_screen_filters(background_flash_alpha, low_health_alpha)

func set_rhythm_active(active: bool, play_prepare: bool = true) -> void:
	if rhythm_active == active:
		return

	rhythm_active = active
	pulse_timer = 0.0
	last_beat = -1

	if rhythm_active and play_prepare:
		prepare_timer = prepare_time
	else:
		prepare_timer = 0.0

	hud.set_rhythm_active(rhythm_active)

	if not rhythm_active:
		clear_notes()
	
func update_song_time(time: float):
	song_position = time
	hud.set_song_position(song_position)

	if seconds_per_beat <= 0:
		return

	var current_beat = int(song_position / seconds_per_beat)

	if current_beat != last_background_beat:
		last_background_beat = current_beat
		trigger_background_pulse()

	if rhythm_active and current_beat != last_beat:
		last_beat = current_beat
		trigger_pulse()

func trigger_pulse():
	pulse_timer = pulse_time

func trigger_background_pulse() -> void:
	bpm_flash_timer = bpm_flash_time

func register_note(note) -> void:
	if note not in active_notes:
		active_notes.append(note)
	_update_next_note_accent()

func clear_notes() -> void:
	for note in active_notes:
		if is_instance_valid(note):
			note.despawn()
	active_notes.clear()

func get_note_spawn_data(config_pos: Vector2, speed: float) -> Dictionary:
	var left: Vector2 = hud.get_lane_left()
	var right: Vector2 = hud.get_lane_right()
	var spawn_left := config_pos.distance_to(left) <= config_pos.distance_to(right)
	var note_speed := speed if speed > 0 else default_note_speed
	var spawn_pos := left if spawn_left else right
	var velocity := Vector2.RIGHT * note_speed if spawn_left else Vector2.LEFT * note_speed

	return {
		"pos": spawn_pos,
		"velocity": velocity,
	}

func get_note_travel_time_ms(config_pos: Vector2, speed: float) -> float:
	var spawn_data := get_note_spawn_data(config_pos, speed)
	var spawn_pos: Vector2 = spawn_data["pos"]
	var velocity: Vector2 = spawn_data["velocity"]
	var note_speed: float = velocity.length()
	if note_speed <= 0.0:
		return 0.0

	var distance: float = abs(spawn_pos.x - _get_center_x())
	return distance / note_speed * 1000.0

func judge_hit() -> bool:
	if not rhythm_active:
		return false

	if rhythm_hit_cooldown_timer > 0:
		return false

	rhythm_hit_cooldown_timer = rhythm_hit_cooldown_time
	_prune_notes()
	var note = _get_closest_note_to_center()

	if note == null:
		return false

	if note.is_in_hit_window(_get_center_x(), hit_window):
		active_notes.erase(note)
		note.play_rhythm_hit_feedback()
		play_hit_feedback()
		trigger_pulse()
		_update_next_note_accent()
		return true

	return false

func _process_note_misses() -> void:
	var center_x := _get_center_x()
	for note in active_notes.duplicate():
		if not is_instance_valid(note) or not note.active:
			active_notes.erase(note)
			continue
		if note.has_missed(center_x, hit_window):
			active_notes.erase(note)
			note.play_rhythm_miss_feedback()
			play_miss_feedback()
			rhythm_note_missed.emit()
			_damage_player()
	_update_next_note_accent()

func play_hit_feedback() -> void:
	_flash_bar(Color(0.35, 1.0, 0.35))

func play_miss_feedback() -> void:
	_flash_bar(Color(1.0, 0.25, 0.25))

func _flash_bar(color: Color) -> void:
	feedback_color = color
	feedback_timer = feedback_time

func _update_next_note_accent() -> void:
	var next_note = _get_closest_note_to_center()
	for note in active_notes:
		if is_instance_valid(note) and note.has_method("set_accented"):
			note.set_accented(note == next_note)

func _get_closest_note_to_center():
	var center_x := _get_center_x()
	var closest = null
	var closest_distance := INF

	for note in active_notes:
		if not is_instance_valid(note) or not note.active:
			continue

		var distance: float = abs(note.global_position.x - center_x)
		if distance < closest_distance:
			closest = note
			closest_distance = distance

	return closest

func _get_center_x() -> float:
	return hud.get_lane_center_x()

func _damage_player() -> void:
	if player_target != null and is_instance_valid(player_target):
		player_target.receive_hit()

func _prune_notes() -> void:
	for note in active_notes.duplicate():
		if not is_instance_valid(note) or not note.active:
			active_notes.erase(note)

func _update_dash_status() -> void:
	if not _is_hud_ready():
		return

	if player_target == null or not is_instance_valid(player_target):
		hud.set_dash_status(0.0, 0.0)
		return

	var state = player_target.get("current_state")
	if state == null:
		hud.set_dash_status(0.0, 0.0)
		return

	var cooldown_value = state.get("dash_cooldown")
	var cooldown_time_value = state.get("dash_cooldown_time")
	if cooldown_value == null or cooldown_time_value == null:
		hud.set_dash_status(0.0, 0.0)
		return

	var cooldown := float(cooldown_value)
	var cooldown_time := float(cooldown_time_value)
	hud.set_dash_status(cooldown, cooldown_time)

func _update_hud_effects() -> void:
	if not _is_hud_ready():
		return

	var pulse_t := pulse_timer / pulse_time if pulse_time > 0.0 else 0.0
	var prepare_t := prepare_timer / prepare_time if prepare_time > 0.0 else 0.0
	var bpm_flash_t := bpm_flash_timer / bpm_flash_time if bpm_flash_time > 0.0 else 0.0
	var feedback_t := feedback_timer / feedback_time if feedback_time > 0.0 else 0.0
	hud.set_effects(pulse_t, prepare_t, bpm_flash_t, feedback_t, feedback_color)

func _is_hud_ready() -> bool:
	return hud != null and is_instance_valid(hud)
