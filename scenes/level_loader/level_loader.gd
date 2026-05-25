extends Node2D
class_name LevelLoader

@onready var entities: Node2D = $entities
@onready var PlayfieldLayer: Node2D = $PlayfieldLayer
@onready var music: AudioStreamPlayer2D = $AudioStreamPlayer2D

var player
var playfield_scene
var rythm_bar
var bullet_scene

var start_time_ms: float = 0.0
var music_timer: float = 0.0
var bpm: float = 120.0

var next_projectile_index: int = 0
var projectile_configs: Array[Bullet] = []

var next_playfield_index: int = 0
var playfield_configs: Array[Playfield] = []

var zone_configs: Array[ZoneArea] = []

var synth: Array[int] = []
var xilo: Array[int] = []
var clap: Array[int] = []

var spawn_clap_area1: Rect2 = Rect2()
var spawn_clap_area2: Rect2 = Rect2()
var bullet_clap_speed: int = 200
var bullets_per_clap: int = 16
var bullet_size: int = 5

var level_config: Dictionary = {}

var bullet_pool: Array[Bullet] = []
var bullet_pool_size: int = 100

var level_path: String
var is_in_editor: bool = false

func _ready() -> void:
	if level_path:
		load_level(level_path)

func load_level(level_path: String) -> void:
	GameLoader.start_background_loading()
	await GameLoader.loading_finished
	
	entities.z_index = 100
	PlayfieldLayer.z_index = 10

	bullet_scene = GameLoader.get_asset("bullet")
	playfield_scene = GameLoader.get_asset("playfield")
	rythm_bar = GameLoader.get_asset("rythm_bar").instantiate()
	player = GameLoader.get_asset("player").instantiate()
	player.died.connect(_on_player_died)


	init_bullet_pool()
	load_level_config(level_path)
	apply_level_config()
	_skip_projectiles_before_start_time()
	
	spawn_player()

	setup_level()
	init_progress_bar()
	init_music()


func setup_level() -> void:
	pass


func init_bullet_pool() -> void:
	bullet_pool.clear()

	for i in bullet_pool_size:
		var bullet: Bullet = bullet_scene.instantiate()
		bullet.visible = false
		bullet.monitoring = false
		bullet.monitorable = false
		bullet.on_despawn = Callable(self, "_release_bullet_to_pool")
		entities.add_child(bullet)
		bullet_pool.append(bullet)
	
	#print("[level_loader] ", "created bullet pool: ", bullet_pool)


func _get_bullet_from_pool() -> Bullet:
	var bullet: Bullet

	if bullet_pool.size() > 0:
		bullet = bullet_pool.pop_back()
	else:
		bullet = bullet_scene.instantiate()
		bullet.on_despawn = Callable(self, "_release_bullet_to_pool")
		entities.add_child(bullet)

	return bullet


func _release_bullet_to_pool(bullet: Bullet) -> void:
	bullet.reset_state()
	if bullet.get_parent() != entities:
		entities.add_child(bullet)
	bullet_pool.append(bullet)


func spawn_bullet(pos: Vector2, velocity: Vector2, size: float, color: Variant = Color.RED) -> void:
	var bullet: Bullet = _get_bullet_from_pool()
	bullet.activate(pos, velocity, size, color)


func load_level_config(level_path: String) -> void:
	level_config = {}
	projectile_configs.clear()
	next_projectile_index = 0

	if not FileAccess.file_exists(level_path):
		push_warning("Level config not found: %s" % level_path)
		return

	parse_level_cfg(level_path)

func parse_level_cfg(path: String) -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(path)
	if err != OK:
		push_warning("Failed to load level config: %s" % path)
		return

	level_config["meta"] = _config_section_to_dict(cfg, "meta")

	for section in cfg.get_sections():
		if section.begins_with("playfields_"):
			var playfield: Playfield = playfield_scene.instantiate()
			var data := _config_section_to_dict(cfg, section)
			PlayfieldLayer.add_child(playfield)
			playfield.set_playfield(data.get("id", ""), _array_to_rect2(data.get("rect", [0, 0, 0, 0]), Rect2()))
			playfield_configs.append(playfield)

		elif section.begins_with("zones_"):
			var zone: ZoneArea = ZoneArea.new()
			var data := _config_section_to_dict(cfg, section)
			zone.set_zone(data.get("id", ""), _array_to_rect2(data.get("rect", [0, 0, 0, 0]), Rect2()))
			zone_configs.append(zone)

		elif section.begins_with("projectiles_"):
			var data := _config_section_to_dict(cfg, section)
			var proj: Bullet = Bullet.new()
			proj.time_ms = int(data.get("time_ms", 0))
			proj.pos = _array_to_vector2(data.get("pos", [0, 0]), Vector2.ZERO)
			proj.speed = float(data.get("speed", 0.0))
			proj.angle = float(data.get("angle_deg", 0.0))
			proj.type = str(data.get("type", ""))
			proj.pattern = str(data.get("pattern", ""))
			proj.zone_id = data.get("zone_id", 0)

			if proj.zone_id != 0:
				var zone := _get_zone_from_id(proj.zone_id)
				if zone != null:
					proj.pos = _random_projectile_pos_to_zone_bound(zone)

			projectile_configs.append(proj)

func _config_section_to_dict(cfg: ConfigFile, section: String) -> Dictionary:
	var d: Dictionary = {}
	for key in cfg.get_section_keys(section):
		d[key] = cfg.get_value(section, key)
	return d


func apply_level_config() -> void:
	var meta: Dictionary = level_config.get("meta", {})
	bpm = float(meta.get("bpm", bpm))
	start_time_ms = int(meta.get("start_time_ms", 0))
	music_timer = start_time_ms / 1000.0
	
	if playfield_configs.is_empty():
		return
	var playfield_data := playfield_configs[next_playfield_index]
	var playfield: Playfield = playfield_scene.instantiate()
	
	PlayfieldLayer.add_child(playfield)
	playfield.set_playfield(playfield_data["id"], _array_to_rect2(playfield_data["rect"]))
	next_playfield_index += 1
	
	player.playfield = playfield
	player.global_position = playfield.get_center()

	while next_playfield_index < playfield_configs.size():
		playfield_data = playfield_configs[next_playfield_index]
		playfield = playfield_scene.instantiate()
		PlayfieldLayer.add_child(playfield)
		playfield.set_playfield(playfield_data["id"], _array_to_rect2(playfield_data["rect"]))
		next_playfield_index += 1

		
func _skip_projectiles_before_start_time() -> void:
	while next_projectile_index < projectile_configs.size():
		var projectile := projectile_configs[next_projectile_index]
		var spawn_time := projectile.time_ms
		if spawn_time >= start_time_ms:
			break
		next_projectile_index += 1

func spawn_player() -> void:
	entities.add_child(player)
	player.playfield = playfield_configs[0]
	player.global_position = playfield_configs[0].get_center()


func init_progress_bar() -> void:
	entities.add_child(rythm_bar)
	rythm_bar.set_bpm(bpm)


func init_music() -> void:
	music.bus = "Analyzer"
	AudioAnalyzer.register_music(music)
	music.play(start_time_ms / 1000.0)
	music.seek(start_time_ms / 1000.0)
	music_timer = start_time_ms / 1000.0

func process_projectiles() -> void:
	while next_projectile_index < projectile_configs.size():
		var projectile := projectile_configs[next_projectile_index]
		var spawn_time := float(projectile.time_ms) / 1000.0

		if music_timer < spawn_time:
			break
		
		spawn_pattern_from_config(projectile)
		next_projectile_index += 1


func spawn_pattern_from_config(proj: Bullet) -> void:
	var pattern_name := proj.pattern
	BulletPatterns.spawn(pattern_name, self, proj)


func _physics_process(delta: float) -> void:
	music_timer = music.get_playback_position()

	if music.playing:
		rythm_bar.update_song_time(music_timer)

	if Input.is_action_just_pressed("hit_debug"):
		_change_player_to_next_playfield()

	process_projectiles()

func _change_player_to_next_playfield() -> void:
	var current_playfield = player.playfield
	for entity in PlayfieldLayer.get_children():
		if entity is Playfield and entity != current_playfield:
			player.playfield = entity
			player.global_position = entity.get_center()
			return
	push_warning("No se encontro otra playfield")

# Converts an array-like value into a Rect2, or returns the fallback.
func _array_to_rect2(value: Variant, fallback: Rect2 = Rect2()) -> Rect2:
	if value is Array and value.size() >= 4:
		return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	return fallback

func _on_player_died():
	if not is_in_editor:
		GameLoader.load_scene("main_menu") #Habría que definir que ocurre al morir

func _get_zone_from_id(zone_id: int) -> ZoneArea:
	for zone in zone_configs:
		if zone.id == zone_id:
			return zone
	return null
		
func _random_projectile_pos_to_zone_bound(zone: ZoneArea) -> Vector2:
	var rect := zone.rect
	var x := randi_range(int(rect.position.x), int(rect.position.x + rect.size.x))
	var y := randi_range(int(rect.position.y), int(rect.position.y + rect.size.y))
	return Vector2(x, y)

# Converts an array-like value into a Vector2, or returns the fallback.
func _array_to_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback
