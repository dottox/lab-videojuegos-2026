extends Projectile
class_name RhythmNote

var note_size := Vector2(6.0, 42.0)
var note_color := Color(0.2, 0.95, 1.0)
var normal_color := Color(0.2, 0.95, 1.0)
var accent_color := Color(1.0, 0.9, 0.25)
var direction_sign := 1.0
var accented := false
var _accent_tween: Tween

func _ready() -> void:
	super._ready()
	collision_layer = 0
	collision_mask = 0

func _draw() -> void:
	var rect := Rect2(-note_size * 0.5, note_size)
	draw_rect(rect, note_color, true)

func activate(spawn_pos: Vector2, vel: Vector2) -> void:
	set_accented(false)
	super.activate(spawn_pos, vel)
	direction_sign = sign(vel.x)
	if direction_sign == 0:
		direction_sign = 1.0
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	queue_redraw()

func reset_state() -> void:
	set_accented(false)
	super.reset_state()

func set_accented(value: bool) -> void:
	if accented == value:
		return

	accented = value
	note_color = accent_color if accented else normal_color

	if _accent_tween != null:
		_accent_tween.kill()
		_accent_tween = null

	if accented:
		_accent_tween = create_tween()
		_accent_tween.set_loops()
		_accent_tween.tween_property(self, "scale", Vector2(1.35, 1.08), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_accent_tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	else:
		scale = Vector2.ONE

	queue_redraw()

func play_rhythm_hit_feedback() -> void:
	set_accented(false)
	note_color = Color(0.25, 1.0, 0.35)
	queue_redraw()
	_resolve_with_feedback(Color(0.25, 1.0, 0.35, 1.0), 2.0, 0.18)

func play_rhythm_miss_feedback() -> void:
	set_accented(false)
	note_color = Color(1.0, 0.2, 0.2)
	queue_redraw()
	_resolve_with_feedback(Color(1.0, 0.2, 0.2, 1.0), 1.55, 0.2)

func is_in_hit_window(center_x: float, hit_window: float) -> bool:
	return abs(global_position.x - center_x) <= hit_window

func has_missed(center_x: float, hit_window: float) -> bool:
	if direction_sign > 0:
		return global_position.x > center_x + hit_window
	return global_position.x < center_x - hit_window

func get_bounds() -> Rect2:
	return Rect2(-note_size * 0.5, note_size)

func _on_body_entered(_body: Node) -> void:
	pass
