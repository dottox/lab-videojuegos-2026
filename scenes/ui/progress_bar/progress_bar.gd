extends CanvasLayer

@onready var bar: ColorRect = $Control/base_bar
@onready var beat: ColorRect = $Control/base_bar/bar_beat
@onready var score_label: Label = $Control/ScoreLabel

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

var base_scale := Vector2.ONE
var pulse_scale := Vector2(1.25, 1.25)
var rhythm_active := false
var hit_window := 18.0
var default_note_speed := 260.0
var active_notes: Array = []
var current_score := 0
var _score_tween: Tween

func _ready():
	bar.size = Vector2(800, 30)
	bar.set_position(Vector2((get_window().size.x / 2) - (bar.size.x / 2), 25))
	#Con esto centramos el scale para utilizarlo luego
	beat.set_size(Vector2(bar.size.x * 0.015, bar.size.y + (bar.size.y * 0.5)))
	beat.set_position(Vector2((bar.size.x / 2) - (beat.size.x / 2), (bar.size.y / 2) - (beat.size.y / 2)))
	beat.pivot_offset = beat.size / 2
	score_label.size = Vector2(bar.size.x, 30)
	score_label.position = Vector2(bar.position.x, bar.position.y + bar.size.y + 8.0)
	score_label.pivot_offset = score_label.size / 2.0
	score_label.text = _format_score(current_score)

func _process(delta):
	_prune_notes()

	if rhythm_active:
		_process_note_misses()
	_update_next_note_accent()

	if rhythm_hit_cooldown_timer > 0:
		rhythm_hit_cooldown_timer -= delta

	var bar_color := Color.WHITE
	if bpm_flash_timer > 0:
		bpm_flash_timer -= delta
		var bpm_flash_t = bpm_flash_timer / bpm_flash_time
		bar_color = bar_color.lerp(bpm_flash_color, bpm_flash_t * 0.16)

	if prepare_timer > 0:
		prepare_timer -= delta
		var prepare_t = prepare_timer / prepare_time
		bar_color = bar_color.lerp(Color(0.25, 0.95, 1.0), prepare_t)

	if feedback_timer > 0:
		feedback_timer -= delta
		var feedback_t = feedback_timer / feedback_time
		bar_color = bar_color.lerp(feedback_color, feedback_t * 0.45)

	bar.modulate = bar_color

	if pulse_timer > 0:
		pulse_timer -= delta

		var t = pulse_timer / pulse_time
		beat.scale = base_scale.lerp(pulse_scale, t)
	else:
		beat.scale = base_scale

func set_bpm(bpm: float):
	seconds_per_beat = 60 / bpm
	last_background_beat = -1

func set_player(player) -> void:
	player_target = player

func set_score(value: int) -> void:
	var increased := value > current_score
	current_score = value
	score_label.text = _format_score(current_score)

	if increased:
		_play_score_increase_feedback()

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

	if not rhythm_active:
		clear_notes()
	
func update_song_time(time: float):
	song_position = time

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

func _format_score(value: int) -> String:
	return "Score: %06d" % value

func _play_score_increase_feedback() -> void:
	if _score_tween != null:
		_score_tween.kill()

	score_label.scale = Vector2(1.12, 1.12)
	score_label.modulate = Color(1.0, 0.9, 0.35, 1.0)

	_score_tween = create_tween()
	_score_tween.set_parallel(true)
	_score_tween.tween_property(score_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_score_tween.tween_property(score_label, "modulate", Color.WHITE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

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
	var bar_rect := bar.get_global_rect()
	var center_y := bar_rect.position.y + bar_rect.size.y / 2.0
	var left := Vector2(bar_rect.position.x, center_y)
	var right := Vector2(bar_rect.position.x + bar_rect.size.x, center_y)
	var spawn_left := config_pos.distance_to(left) <= config_pos.distance_to(right)
	var note_speed := speed if speed > 0 else default_note_speed
	var spawn_pos := left if spawn_left else right
	var velocity := Vector2.RIGHT * note_speed if spawn_left else Vector2.LEFT * note_speed

	return {
		"pos": spawn_pos,
		"velocity": velocity,
	}

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
	var bar_rect := bar.get_global_rect()
	return bar_rect.position.x + bar_rect.size.x / 2.0

func _damage_player() -> void:
	if player_target != null and is_instance_valid(player_target):
		player_target.receive_hit()

func _prune_notes() -> void:
	for note in active_notes.duplicate():
		if not is_instance_valid(note) or not note.active:
			active_notes.erase(note)
