extends Node2D
class_name LevelLoader

@onready var entities: Node2D = $entities
@onready var music: AudioStreamPlayer2D = $AudioStreamPlayer2D

var player
var playfield
var rythm_bar
var bullet_scene

var start_time_ms: float = 0.0
var music_timer: float = 0.0
var bpm: float = 120.0

var next_projectile_index: int = 0
var projectile_configs: Array[Dictionary] = []

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

func _ready() -> void:
	if level_path:
		load_level(level_path)

func load_level(level_path: String) -> void:
	GameLoader.start_background_loading()
	await GameLoader.loading_finished

	bullet_scene = GameLoader.get_asset("bullet")
	playfield = GameLoader.get_asset("playfield").instantiate()
	rythm_bar = GameLoader.get_asset("rythm_bar").instantiate()
	player = GameLoader.get_asset("player").instantiate()
	player.died.connect(_on_player_died)

	spawn_playfield()
	spawn_player()

	init_bullet_pool()
	load_level_config(level_path)
	apply_level_config()
	_skip_projectiles_before_start_time()

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
	
	print("[level_loader] ", "created bullet pool: ", bullet_pool)


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
	level_config["playfield"] = _config_section_to_dict(cfg, "playfield")

	for section in cfg.get_sections():
		if section.begins_with("projectiles_"):
			projectile_configs.append(_config_section_to_dict(cfg, section))


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

	var playfield_cfg: Dictionary = level_config.get("playfield", {})
	playfield.set_state(str(playfield_cfg["type"]))
	var p = playfield_cfg["position"]
	playfield.global_position = Vector2(float(p[0]), float(p[1]))
	var s = playfield_cfg["size"]
	playfield.set_size(Vector2(float(s[0]), float(s[1])))
		
func _skip_projectiles_before_start_time() -> void:
	while next_projectile_index < projectile_configs.size():
		var projectile := projectile_configs[next_projectile_index]
		var spawn_time := int(projectile.get("time_ms", 0))
		if spawn_time >= start_time_ms:
			break
		next_projectile_index += 1

func spawn_player() -> void:
	entities.add_child(player)
	player.global_position = playfield.global_position
	player.playfield = playfield


func spawn_playfield() -> void:
	entities.add_child(playfield)
	playfield.global_position = (get_viewport().get_visible_rect().size / 2.0) + Vector2(0, 100)


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
		var spawn_time := float(projectile.get("time_ms", 0)) / 1000.0

		if music_timer < spawn_time:
			break

		spawn_pattern_from_config(projectile)
		next_projectile_index += 1


func spawn_pattern_from_config(data: Dictionary) -> void:
	var pattern_name := str(data.get("pattern", "single"))
	BulletPatterns.spawn(pattern_name, self, data)


func _physics_process(delta: float) -> void:
	music_timer = music.get_playback_position()

	if music.playing:
		rythm_bar.update_song_time(music_timer)

	if Input.is_action_just_pressed("hit_debug"):
		print("¡Xilo!: " + str(music_timer))

	process_projectiles()

func _on_player_died():
	GameLoader.load_scene("main_menu") #Habría que definir que ocurre al morir
