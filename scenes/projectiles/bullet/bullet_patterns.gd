extends Node
class_name BulletPatterns

const PATTERNS := {
	"single": true,
	"circle": true,
}


static func spawn(pattern_name: String, loader: LevelLoader, data: Dictionary) -> void:
	match pattern_name:
		"single":
			single(loader, data)
		"circle":
			circle(loader, data)
		_:
			push_warning("Unknown bullet pattern: %s" % pattern_name)
			single(loader, data)


static func single(loader: LevelLoader, data: Dictionary) -> void:
	var pos := _get_pos(data)
	var velocity := _get_velocity(data)
	var size := float(data.get("size", loader.bullet_size))
	var color: Variant = data.get("color", Color.RED)

	loader.spawn_bullet(pos, velocity, size, color)


static func circle(loader: LevelLoader, data: Dictionary) -> void:
	var pos := _get_pos(data)
	var count := int(data.get("count", 8))
	var speed := float(data.get("speed", 200.0))
	var size := float(data.get("size", loader.bullet_size))
	var color: Variant = data.get("color", Color.RED)

	for i in count:
		var angle := TAU * float(i) / float(count)
		var direction := Vector2.RIGHT.rotated(angle)
		loader.spawn_bullet(pos, direction * speed, size, color)


static func _get_pos(data: Dictionary) -> Vector2:
	var pos_data = data.get("pos", [0.0, 0.0])
	return Vector2(float(pos_data[0]), float(pos_data[1]))


static func _get_velocity(data: Dictionary) -> Vector2:
	var speed := float(data.get("speed", 0.0))
	var angle_deg := float(data.get("angle_deg", 0.0))
	var direction := Vector2.RIGHT.rotated(deg_to_rad(angle_deg))
	return direction * speed
