extends Node2D
class_name LevelLoader

@onready var entities: Node2D = $entities
@onready var PlayfieldLayer: Node2D = $PlayfieldLayer
@onready var music: AudioStreamPlayer2D = $AudioStreamPlayer2D

#Variables relacionadas al editor
var preview_start_time_ms: float = -1.0

var player
var playfield_scene
var rythm_bar
var bullet_scene
var projectile_scenes: Dictionary = {}
var projectile_asset_keys := {
	"bullet": "bullet",
	"rhythm_note": "rhythm_note",
}

var start_time_ms: float = 0.0
var music_timer: float = 0.0
var music_path := ""
var music_id := ""
var bpm: float = 120.0
var seconds_per_beat := 0.5

var next_projectile_index: int = 0
var projectile_configs: Array[Projectile] = []

var next_phase_index: int = 0
var phase_configs: Array[Phase] = []
var current_phase_type := "bullet_hell_no_rhythm"
var rhythm_active := false
var shield_spawn_margin := 120.0

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

var projectile_pools: Dictionary = {}
var projectile_pool_size: int = 100

var level_path: String
var is_in_editor: bool = false
var game_over := false

var score := 0
var bullet_hell_score_tick_timer := 0.0
var bullet_hell_score_tick_interval := 0.25
var bullet_hell_score_per_tick := 5
var shield_block_score := 75
var rhythm_hit_score := 100

var effects_canvas: CanvasLayer
var background_flash: ColorRect
var low_health_filter: ColorRect
var death_screen: CanvasLayer
var death_score_label: Label
var last_background_beat := -1
var background_flash_timer := 0.0
var background_flash_time := 0.18
var background_flash_alpha := 0.12
var low_health_filter_alpha := 0.0
var max_low_health_filter_alpha := 0.36

func _ready() -> void:
	if level_path:
		load_level(level_path)

func load_level(level_path: String) -> void:
	game_over = false
	score = 0
	bullet_hell_score_tick_timer = 0.0
	last_background_beat = -1
	background_flash_timer = 0.0
	low_health_filter_alpha = 0.0

	GameLoader.start_background_loading()
	await GameLoader.loading_finished
	
	entities.z_index = 100
	PlayfieldLayer.z_index = 10

	bullet_scene = GameLoader.get_asset("bullet")
	projectile_scenes["bullet"] = bullet_scene
	projectile_scenes["rhythm_note"] = GameLoader.get_asset("rhythm_note")
	playfield_scene = GameLoader.get_asset("playfield")
	rythm_bar = GameLoader.get_asset("rythm_bar").instantiate()
	player = GameLoader.get_asset("player").instantiate()
	player.death_started.connect(_on_player_death_started)
	player.died.connect(_on_player_died)
	player.health_changed.connect(_on_player_health_changed)
	player.shield_blocked.connect(_on_player_shield_blocked)


	init_projectile_pools()
	load_level_config(level_path)
	apply_level_config()
	
	spawn_player()
	init_screen_effects()
	init_progress_bar()
	_prepare_projectile_schedule()
	_apply_initial_phase()

	setup_level()
	init_music()


func setup_level() -> void:
	pass


func init_projectile_pools() -> void:
	projectile_pools.clear()

	for projectile_type in projectile_asset_keys.keys():
		projectile_pools[projectile_type] = []
		for i in projectile_pool_size:
			var projectile := _instantiate_projectile(projectile_type)
			if projectile == null:
				continue
			_prepare_projectile_for_pool(projectile, projectile_type)
			_get_projectile_parent(projectile_type).add_child(projectile)
			projectile_pools[projectile_type].append(projectile)


func _instantiate_projectile(projectile_type: String) -> Projectile:
	var normalized_type := Projectile.normalize_type(projectile_type)
	var asset_key: String = projectile_asset_keys.get(normalized_type, "")
	if asset_key == "":
		push_warning("Unknown projectile type: %s" % projectile_type)
		return null

	var scene: PackedScene = projectile_scenes.get(normalized_type)
	if scene == null:
		scene = GameLoader.get_asset(asset_key)
		projectile_scenes[normalized_type] = scene

	if scene == null:
		push_warning("Projectile scene not found for type: %s" % normalized_type)
		return null

	var instance = scene.instantiate()
	if instance is Projectile:
		return instance

	push_warning("Scene for projectile type %s does not extend Projectile" % normalized_type)
	instance.free()
	return null


func _prepare_projectile_for_pool(projectile: Projectile, projectile_type: String) -> void:
	var normalized_type := Projectile.normalize_type(projectile_type)
	projectile.type = normalized_type
	projectile.visible = false
	projectile.monitoring = false
	projectile.monitorable = false
	projectile.on_despawn = Callable(self, "_release_projectile_to_pool").bind(normalized_type)


func _get_projectile_parent(projectile_type: String) -> Node:
	var normalized_type := Projectile.normalize_type(projectile_type)
	if normalized_type == "rhythm_note" and rythm_bar != null:
		return rythm_bar
	return entities


func _get_projectile_from_pool(projectile_type: String) -> Projectile:
	var normalized_type := Projectile.normalize_type(projectile_type)
	if not projectile_asset_keys.has(normalized_type):
		push_warning("Unknown projectile type: %s" % projectile_type)
		return null

	if not projectile_pools.has(normalized_type):
		projectile_pools[normalized_type] = []

	var pool: Array = projectile_pools[normalized_type]
	var projectile: Projectile

	if pool.size() > 0:
		projectile = pool.pop_back()
	else:
		projectile = _instantiate_projectile(normalized_type)
		if projectile == null:
			return null
		_prepare_projectile_for_pool(projectile, normalized_type)
		_get_projectile_parent(normalized_type).add_child(projectile)

	return projectile


func _release_projectile_to_pool(projectile: Projectile, projectile_type: String) -> void:
	var normalized_type := Projectile.normalize_type(projectile_type)
	projectile.reset_state()
	var desired_parent := _get_projectile_parent(normalized_type)
	var parent := projectile.get_parent()
	if parent != desired_parent:
		if parent != null:
			parent.remove_child(projectile)
		desired_parent.add_child(projectile)
	if not projectile_pools.has(normalized_type):
		projectile_pools[normalized_type] = []
	projectile_pools[normalized_type].append(projectile)


func spawn_projectile(projectile_type: String, pos: Vector2, velocity: Vector2) -> Projectile:
	var projectile := _get_projectile_from_pool(projectile_type)
	if projectile == null:
		return null
	projectile.activate(pos, velocity)
	return projectile


func spawn_bullet(pos: Vector2, velocity: Vector2, size: float, color: Variant = Color.RED) -> void:
	var bullet := _get_projectile_from_pool("bullet") as Bullet
	if bullet == null:
		push_warning("Bullet projectile could not be spawned")
		return
	bullet.activate(pos, velocity, size, color)


func load_level_config(level_path: String) -> void:
	level_config = {}
	projectile_configs.clear()
	phase_configs.clear()
	next_projectile_index = 0
	next_phase_index = 0

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
			playfield.set_playfield(data.get("id", ""), _array_to_rect2(data.get("rect")))
			playfield_configs.append(playfield)

		elif section.begins_with("zones_"):
			var zone: ZoneArea = ZoneArea.new()
			var data := _config_section_to_dict(cfg, section)
			zone.set_zone(data.get("id", ""), _array_to_rect2(data.get("rect", [0, 0, 0, 0]), Rect2()))
			zone_configs.append(zone)

		elif section.begins_with("projectiles_"):
			var data := _config_section_to_dict(cfg, section)
			var proj: Projectile = Projectile.new()
			proj.time_ms = int(data.get("time_ms", 0))
			proj.pos = _array_to_vector2(data.get("pos", [0, 0]), Vector2.ZERO)
			proj.speed = float(data.get("speed", 0.0))
			proj.angle = float(data.get("angle_deg", 0.0))
			proj.type = Projectile.normalize_type(str(data.get("type", "bullet")))
			proj.pattern = str(data.get("pattern", ""))
			proj.zone_id = data.get("zone_id", 0)

			if proj.zone_id != 0:
				var zone := _get_zone_from_id(proj.zone_id)
				if zone != null:
					proj.pos = _random_projectile_pos_to_zone_bound(zone)

			projectile_configs.append(proj)

		elif section.begins_with("phases_"):
			var data := _config_section_to_dict(cfg, section)
			var phase := Phase.new()
			phase.time = int(data.get("time_ms", 0))
			phase.type = Phase.normalize_type(str(data.get("type", "bullet_hell_no_rhythm")))
			phase_configs.append(phase)

	projectile_configs.sort_custom(func(a, b): return a.time_ms < b.time_ms)
	phase_configs.sort_custom(func(a, b): return a.time < b.time)

func _config_section_to_dict(cfg: ConfigFile, section: String) -> Dictionary:
	var d: Dictionary = {}
	for key in cfg.get_section_keys(section):
		d[key] = cfg.get_value(section, key)
	return d


func apply_level_config() -> void:
	var meta: Dictionary = level_config.get("meta", {})
	music_id = str(meta.get("music_id", ""))
	music_path = str(meta.get("music_path", ""))
	bpm = float(meta.get("bpm", bpm))
	seconds_per_beat = 60.0 / bpm if bpm > 0.0 else 0.0
	start_time_ms = int(meta.get("start_time_ms", 0))
	start_time_ms = int(meta.get("start_time_ms", 0))

	#Si se ejecuta a través de preview, que empiece desde el tiempo que estás editando.
	if preview_start_time_ms >= 0:
		start_time_ms = preview_start_time_ms
	
	music_timer = start_time_ms / 1000.0
	
	if playfield_configs.is_empty():
		return
	var playfield_data
	var playfield: Playfield
	
	while next_playfield_index < playfield_configs.size():
		playfield_data = playfield_configs[next_playfield_index]
		PlayfieldLayer.add_child(playfield_data)
		next_playfield_index += 1

		
func _prepare_projectile_schedule() -> void:
	projectile_configs.sort_custom(func(a, b): return _get_projectile_spawn_time_ms(a) < _get_projectile_spawn_time_ms(b))
	_skip_projectiles_before_start_time()


func _skip_projectiles_before_start_time() -> void:
	var remaining_projectiles: Array[Projectile] = []
	for projectile in projectile_configs:
		if _should_keep_projectile_after_start_time(projectile):
			remaining_projectiles.append(projectile)

	projectile_configs = remaining_projectiles
	next_projectile_index = 0


func _should_keep_projectile_after_start_time(projectile: Projectile) -> bool:
	if Projectile.normalize_type(projectile.type) == "rhythm_note":
		return projectile.time_ms >= start_time_ms

	return _get_projectile_spawn_time_ms(projectile) >= start_time_ms


func _get_projectile_spawn_time_ms(projectile: Projectile) -> float:
	if Projectile.normalize_type(projectile.type) == "rhythm_note" and rythm_bar != null:
		return float(projectile.time_ms) - rythm_bar.get_note_travel_time_ms(projectile.pos, projectile.speed)

	return float(projectile.time_ms)

func spawn_player() -> void:
	entities.add_child(player)
	player.playfield = playfield_configs[0]
	player.global_position = playfield_configs[0].get_center()


func init_screen_effects() -> void:
	effects_canvas = CanvasLayer.new()
	effects_canvas.name = "ScreenEffects"
	effects_canvas.layer = 1
	add_child(effects_canvas)

	background_flash = ColorRect.new()
	background_flash.name = "BackgroundFlash"
	background_flash.color = Color(0.55, 0.75, 1.0, 0.0)
	background_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_make_full_screen_rect(background_flash)
	effects_canvas.add_child(background_flash)

	low_health_filter = ColorRect.new()
	low_health_filter.name = "LowHealthFilter"
	low_health_filter.color = Color(1.0, 0.0, 0.0, 0.0)
	low_health_filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_make_full_screen_rect(low_health_filter)
	effects_canvas.add_child(low_health_filter)


func init_progress_bar() -> void:
	rythm_bar.layer = 2
	entities.add_child(rythm_bar)
	rythm_bar.set_bpm(bpm)
	rythm_bar.set_player(player)
	rythm_bar.set_score(score)


func _make_full_screen_rect(rect: ColorRect) -> void:
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.offset_left = 0.0
	rect.offset_top = 0.0
	rect.offset_right = 0.0
	rect.offset_bottom = 0.0


func _apply_initial_phase() -> void:
	var phase_to_apply := "bullet_hell_no_rhythm"

	while next_phase_index < phase_configs.size():
		var phase := phase_configs[next_phase_index]
		if phase.time > start_time_ms:
			break
		phase_to_apply = phase.type
		next_phase_index += 1

	_apply_phase(phase_to_apply, phase_to_apply != "bullet_hell_no_rhythm")


func process_phases() -> void:
	while next_phase_index < phase_configs.size():
		var phase := phase_configs[next_phase_index]
		var phase_time := float(phase.time) / 1000.0

		if music_timer < phase_time:
			break

		_apply_phase(phase.type, true)
		next_phase_index += 1


func _apply_phase(phase_type: String, play_prepare: bool) -> void:
	var normalized_type := Phase.normalize_type(phase_type)
	current_phase_type = normalized_type
	rhythm_active = Phase.is_rhythm_phase(normalized_type)

	if Phase.is_shield_phase(normalized_type):
		player.set_mode("shield")
		_pin_player_to_playfield_center()
	else:
		player.set_mode("normal")

	rythm_bar.set_rhythm_active(rhythm_active, play_prepare)


func _pin_player_to_playfield_center() -> void:
	if player.playfield:
		player.global_position = player.playfield.get_center()


func init_music() -> void:
	_load_music_from_level_config()
	music.bus = "Analyzer"
	AudioAnalyzer.register_music(music)
	music.play(start_time_ms / 1000.0)
	music.seek(start_time_ms / 1000.0)
	music_timer = start_time_ms / 1000.0


func _load_music_from_level_config() -> void:
	var resolved_music_path := _resolve_music_path()
	if resolved_music_path == "":
		return

	var stream = load(resolved_music_path)
	if stream is AudioStream:
		music.stream = stream
	else:
		push_warning("Level music could not be loaded: %s" % resolved_music_path)


func _resolve_music_path() -> String:
	if music_path != "":
		if ResourceLoader.exists(music_path) or FileAccess.file_exists(music_path):
			return music_path
		push_warning("Level music path does not exist: %s" % music_path)

	if music_id.begins_with("res://") and (ResourceLoader.exists(music_id) or FileAccess.file_exists(music_id)):
		return music_id

	var asset_music_path := "res://assets/audio/%s.mp3" % music_id
	if music_id != "" and (ResourceLoader.exists(asset_music_path) or FileAccess.file_exists(asset_music_path)):
		return asset_music_path

	return ""

func process_projectiles() -> void:
	while next_projectile_index < projectile_configs.size():
		var projectile := projectile_configs[next_projectile_index]
		var spawn_time := _get_projectile_spawn_time_ms(projectile) / 1000.0

		if music_timer < spawn_time:
			break
		
		spawn_pattern_from_config(projectile)
		next_projectile_index += 1


func spawn_pattern_from_config(proj: Projectile) -> void:
	match proj.type:
		"bullet":
			if Phase.is_shield_phase(current_phase_type):
				_spawn_shield_bullet_from_config(proj)
				return
			var pattern_name := proj.pattern
			BulletPatterns.spawn(pattern_name, self, proj)
		"rhythm_note":
			_spawn_rhythm_note_from_config(proj)
		_:
			push_warning("Unknown projectile type: %s" % proj.type)


func _spawn_shield_bullet_from_config(proj: Projectile) -> void:
	var playfield := player.playfield as Playfield
	if playfield == null:
		return

	var spawn_pos := _get_nearest_shield_spawn_anchor(proj.pos, playfield.get_bounds())
	var center := playfield.get_center()
	var speed: float = proj.speed if proj.speed > 0 else bullet_clap_speed
	var velocity: Vector2 = spawn_pos.direction_to(center) * speed
	spawn_bullet(spawn_pos, velocity, bullet_size, Color.RED)


func _get_nearest_shield_spawn_anchor(config_pos: Vector2, rect: Rect2) -> Vector2:
	var x: float = clamp(config_pos.x, rect.position.x, rect.end.x)
	var y: float = clamp(config_pos.y, rect.position.y, rect.end.y)
	var anchors := [
		Vector2(x, rect.position.y - shield_spawn_margin),
		Vector2(x, rect.end.y + shield_spawn_margin),
		Vector2(rect.position.x - shield_spawn_margin, y),
		Vector2(rect.end.x + shield_spawn_margin, y),
	]

	var nearest: Vector2 = anchors[0]
	var nearest_distance := config_pos.distance_squared_to(nearest)

	for anchor in anchors:
		var distance: float = config_pos.distance_squared_to(anchor)
		if distance < nearest_distance:
			nearest = anchor
			nearest_distance = distance

	return nearest


func _spawn_rhythm_note_from_config(proj: Projectile) -> void:
	var note := _get_projectile_from_pool("rhythm_note")
	if note == null:
		push_warning("Rhythm note projectile could not be spawned")
		return

	var spawn_data: Dictionary = rythm_bar.get_note_spawn_data(proj.pos, proj.speed)
	var spawn_time := _get_projectile_spawn_time_ms(proj) / 1000.0
	var elapsed_since_spawn: float = max(music_timer - spawn_time, 0.0)
	var base_spawn_pos: Vector2 = spawn_data["pos"]
	var velocity: Vector2 = spawn_data["velocity"]
	var spawn_pos := base_spawn_pos + velocity * elapsed_since_spawn
	note.activate(spawn_pos, velocity)
	rythm_bar.register_note(note)


func _physics_process(delta: float) -> void:
	music_timer = music.get_playback_position()
	_update_screen_effects(delta)

	if game_over:
		return

	if music.playing:
		rythm_bar.update_song_time(music_timer)
		_process_bullet_hell_score(delta)

	process_phases()

	if Input.is_action_just_pressed("rhythm_hit"):
		if rythm_bar.judge_hit():
			_add_score(rhythm_hit_score)

	process_projectiles()


func _update_screen_effects(delta: float) -> void:
	if music.playing and seconds_per_beat > 0.0 and not game_over:
		var current_beat := int(music_timer / seconds_per_beat)
		if current_beat != last_background_beat:
			last_background_beat = current_beat
			_trigger_background_flash()

	if background_flash_timer > 0.0:
		background_flash_timer = max(background_flash_timer - delta, 0.0)

	if background_flash != null:
		var flash_t := background_flash_timer / background_flash_time if background_flash_time > 0.0 else 0.0
		var flash_color := background_flash.color
		flash_color.a = background_flash_alpha * flash_t
		background_flash.color = flash_color

	if low_health_filter != null:
		var filter_color := low_health_filter.color
		filter_color.a = low_health_filter_alpha
		low_health_filter.color = filter_color


func _trigger_background_flash() -> void:
	background_flash_timer = background_flash_time


func _process_bullet_hell_score(delta: float) -> void:
	if not current_phase_type.begins_with("bullet_hell"):
		bullet_hell_score_tick_timer = 0.0
		return

	bullet_hell_score_tick_timer += delta
	while bullet_hell_score_tick_timer >= bullet_hell_score_tick_interval:
		bullet_hell_score_tick_timer -= bullet_hell_score_tick_interval
		_add_score(bullet_hell_score_per_tick)


func _add_score(points: int) -> void:
	if points <= 0 or game_over:
		return

	score += points
	if rythm_bar != null and is_instance_valid(rythm_bar):
		rythm_bar.set_score(score)


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

func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if max_health <= 0 or current_health > max_health * 0.5:
		low_health_filter_alpha = 0.0
		return

	var health_ratio := float(current_health) / float(max_health)
	var danger_t: float = clamp((0.5 - health_ratio) / 0.4, 0.0, 1.0)
	low_health_filter_alpha = danger_t * max_low_health_filter_alpha


func _on_player_shield_blocked(_projectile) -> void:
	_add_score(shield_block_score)


func _on_player_death_started() -> void:
	game_over = true
	music.stop()
	_deactivate_projectiles()

	if rythm_bar != null and is_instance_valid(rythm_bar):
		rythm_bar.clear_notes()


func _on_player_died() -> void:
	if not game_over:
		_on_player_death_started()

	if is_in_editor:
		return

	_show_death_screen()


func _deactivate_projectiles() -> void:
	for child in entities.get_children():
		if child is Projectile:
			child.reset_state()

	if rythm_bar == null or not is_instance_valid(rythm_bar):
		return

	for child in rythm_bar.get_children():
		if child is Projectile:
			child.reset_state()


func _show_death_screen() -> void:
	if death_screen != null and is_instance_valid(death_screen):
		return

	death_screen = CanvasLayer.new()
	death_screen.name = "DeathScreen"
	death_screen.layer = 10
	add_child(death_screen)

	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.0, 0.0, 0.72)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_make_full_screen_rect(overlay)
	death_screen.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_screen.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 260)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.22, 0.18, 1.0))
	layout.add_child(title)

	death_score_label = Label.new()
	death_score_label.text = "Final Score: %06d" % score
	death_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_score_label.add_theme_font_size_override("font_size", 24)
	layout.add_child(death_score_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	layout.add_child(spacer)

	var play_again := Button.new()
	play_again.text = "Play Again"
	play_again.custom_minimum_size = Vector2(260, 44)
	play_again.pressed.connect(_on_play_again_pressed)
	layout.add_child(play_again)

	var back_to_menu := Button.new()
	back_to_menu.text = "Back to Menu"
	back_to_menu.custom_minimum_size = Vector2(260, 44)
	back_to_menu.pressed.connect(_on_back_to_menu_pressed)
	layout.add_child(back_to_menu)

	play_again.grab_focus()


func _on_play_again_pressed() -> void:
	GameLoader.load_level(level_path)


func _on_back_to_menu_pressed() -> void:
	GameLoader.load_scene("main_menu")

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
