extends Control

@export var lane_left_ratio := 0.19
@export var lane_right_ratio := 0.754
@export var lane_top_ratio := 0.43
@export var lane_bottom_ratio := 0.67

@onready var hud_bar: TextureRect = $HudBar
@onready var heart_count_label: Label = $HudBar/HeartCountLabel
@onready var score_label: Label = $ScoreLabel
@onready var accuracy_label: Label = $AccuracyLabel
@onready var dash_cooldown_circle: ColorRect = $HudBar/DashCooldownCircle
@onready var dash_cooldown_label: Label = $HudBar/DashCooldownCircle/CooldownLabel
@onready var dash_disabled_filter: ColorRect = $HudBar/DashDisabledFilter
@onready var hud_background_flash: ColorRect = $HudBackgroundFlash
@onready var hud_low_health_filter: ColorRect = $HudLowHealthFilter

var health_current := 1
var health_max := 1
var score := 0
var accuracy := 100.0
var dash_cooldown := 0.0
var dash_cooldown_time := 0.0
var rhythm_active := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_health()
	_refresh_score()
	_refresh_accuracy()
	_refresh_dash()


func set_song_position(_value: float) -> void:
	pass


func set_rhythm_active(value: bool) -> void:
	rhythm_active = value


func set_score(value: int, _increased: bool) -> void:
	score = value
	_refresh_score()


func set_accuracy(value: float) -> void:
	accuracy = clamp(value, 0.0, 100.0)
	_refresh_accuracy()


func set_health(current_health: int, max_health: int) -> void:
	health_current = max(current_health, 0)
	health_max = max(max_health, 1)
	_refresh_health()


func set_dash_status(cooldown: float, cooldown_time: float) -> void:
	dash_cooldown = max(cooldown, 0.0)
	dash_cooldown_time = max(cooldown_time, 0.0)
	_refresh_dash()


func set_effects(_pulse: float, _prepare: float, _bpm_flash: float, _feedback: float, _hit_color: Color) -> void:
	pass


func set_screen_filters(background_flash_alpha: float, low_health_alpha: float) -> void:
	if hud_background_flash != null:
		var flash_color := hud_background_flash.color
		flash_color.a = clamp(background_flash_alpha, 0.0, 1.0)
		hud_background_flash.color = flash_color

	if hud_low_health_filter != null:
		var health_color := hud_low_health_filter.color
		health_color.a = clamp(low_health_alpha, 0.0, 1.0)
		hud_low_health_filter.color = health_color


func get_lane_rect() -> Rect2:
	var rect := hud_bar.get_global_rect()
	return Rect2(
		rect.position + Vector2(rect.size.x * lane_left_ratio, rect.size.y * lane_top_ratio),
		Vector2(
			rect.size.x * (lane_right_ratio - lane_left_ratio),
			rect.size.y * (lane_bottom_ratio - lane_top_ratio)
		)
	)


func get_lane_center_x() -> float:
	return get_lane_rect().get_center().x


func get_lane_left() -> Vector2:
	var lane := get_lane_rect()
	return Vector2(lane.position.x, lane.get_center().y)


func get_lane_right() -> Vector2:
	var lane := get_lane_rect()
	return Vector2(lane.end.x, lane.get_center().y)


func _refresh_health() -> void:
	if heart_count_label == null:
		return
	heart_count_label.text = "%d" % health_current


func _refresh_score() -> void:
	if score_label == null:
		return
	score_label.text = "%05d" % score


func _refresh_accuracy() -> void:
	if accuracy_label == null:
		return
	accuracy_label.text = "%.1f%%" % accuracy


func _refresh_dash() -> void:
	var ready := dash_cooldown <= 0.001 or dash_cooldown_time <= 0.0
	var fill_amount := 1.0
	if dash_cooldown_time > 0.0:
		fill_amount = 1.0 - clamp(dash_cooldown / dash_cooldown_time, 0.0, 1.0)

	if dash_cooldown_circle != null and dash_cooldown_circle.material is ShaderMaterial:
		dash_cooldown_circle.material.set_shader_parameter("progress", fill_amount)

	if dash_cooldown_label != null:
		dash_cooldown_label.text = "OK" if ready else "%.1f" % dash_cooldown

	if dash_disabled_filter != null:
		dash_disabled_filter.visible = not ready
