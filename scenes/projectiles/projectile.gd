extends Area2D
class_name Projectile

const TYPES := {
	"bullet": true,
	"rhythm_note": true,
}

const TYPE_ALIASES := {
	"basic": "bullet",
	"normal": "bullet",
	"rythm_note": "rhythm_note",
	"note": "rhythm_note",
}

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var time_ms: int
var pos: Vector2 = Vector2.ZERO
var speed: float = 200.0
var angle: float = 0.0
var type: String = "bullet"
var pattern: String = "single"
var zone_id: int = 0

var velocity: Vector2 = Vector2.ZERO
var on_despawn: Callable = Callable()
var active: bool = false
var _base_scale := Vector2.ONE
var _base_modulate := Color.WHITE
var _feedback_tween: Tween

static func normalize_type(raw_type: String) -> String:
	var normalized := raw_type.strip_edges().to_lower()
	if normalized == "":
		return "bullet"
	return TYPE_ALIASES.get(normalized, normalized)

static func is_known_type(raw_type: String) -> bool:
	return TYPES.has(normalize_type(raw_type))

func _ready() -> void:
	_base_scale = scale
	_base_modulate = modulate
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not active:
		return

	position += velocity * delta

	if not _is_on_screen():
		despawn()

func activate(spawn_pos: Vector2, vel: Vector2) -> void:
	if _feedback_tween != null:
		_feedback_tween.kill()
	scale = _base_scale
	modulate = _base_modulate
	global_position = spawn_pos
	velocity = vel
	active = true
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	queue_redraw()

func reset_state() -> void:
	if _feedback_tween != null:
		_feedback_tween.kill()
	active = false
	velocity = Vector2.ZERO
	visible = false
	scale = _base_scale
	modulate = _base_modulate
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	position = Vector2.ZERO

func despawn() -> void:
	if not active:
		return

	reset_state()
	_return_to_pool()

func play_player_hit_feedback() -> void:
	_resolve_with_feedback(Color(1.0, 0.25, 0.2, 1.0), 1.9, 0.18)

func play_shield_block_feedback() -> void:
	_resolve_with_feedback(Color(0.25, 0.9, 1.0, 1.0), 1.7, 0.16)

func _resolve_with_feedback(color: Color, scale_multiplier: float, duration: float) -> void:
	if not active:
		return

	active = false
	velocity = Vector2.ZERO
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	if _feedback_tween != null:
		_feedback_tween.kill()
	_feedback_tween = create_tween()
	_feedback_tween.set_parallel(true)
	_feedback_tween.tween_property(self, "scale", _base_scale * scale_multiplier, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(self, "modulate", Color(color.r, color.g, color.b, 0.0), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_feedback_tween.finished.connect(_finish_feedback)

func _finish_feedback() -> void:
	reset_state()
	_return_to_pool()

func _return_to_pool() -> void:
	if on_despawn.is_valid():
		on_despawn.call(self)

func get_bounds() -> Rect2:
	if collision_shape == null or collision_shape.shape == null:
		return Rect2(Vector2.ZERO, Vector2.ZERO)

	var shape_rect := collision_shape.shape.get_rect()
	return Rect2(collision_shape.position + shape_rect.position, shape_rect.size)

func _is_on_screen() -> bool:
	var viewport_rect := get_viewport().get_visible_rect()
	return viewport_rect.grow(100.0).has_point(global_position)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.receive_hit()
		play_player_hit_feedback()
