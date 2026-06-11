extends Node
class_name BulletPatterns

const PATTERNS := {
	"single": true,
	"circle": true,
}


static func spawn(pattern_name: String, loader: LevelLoader, bullet: Projectile) -> void:
	match pattern_name:
		"single":
			single(loader, bullet)
		"circle":
			circle(loader, bullet)
		_:
			push_warning("Unknown bullet pattern: %s" % pattern_name)
			single(loader, bullet)


static func single(loader: LevelLoader, b: Projectile) -> void:
	var size := loader.bullet_size
	var color := Color.RED

	loader.spawn_bullet(b.pos, Vector2.RIGHT.rotated(deg_to_rad(b.angle)) * b.speed, size, color)


static func circle(loader: LevelLoader, b: Projectile) -> void:
	var count := 8
	var size := loader.bullet_size
	var color := Color.RED
	var start_angle := deg_to_rad(b.angle)

	for i in count:
		var angle := start_angle + TAU * float(i) / float(count)
		var direction := Vector2.RIGHT.rotated(angle)
		loader.spawn_bullet(b.pos, direction * b.speed, size, color)


static func _get_pos(data: Dictionary) -> Vector2:
	var pos_data = data.get("pos", [0.0, 0.0])
	return Vector2(float(pos_data[0]), float(pos_data[1]))


static func _get_velocity(data: Dictionary) -> Vector2:
	var speed := float(data.get("speed", 0.0))
	var angle_deg := float(data.get("angle_deg", 0.0))
	var direction := Vector2.RIGHT.rotated(deg_to_rad(angle_deg))
	return direction * speed
