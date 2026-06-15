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
var background_canvas: CanvasLayer
var gameplay_background: ColorRect
var background_flash: ColorRect
var low_health_filter: ColorRect
var death_screen: CanvasLayer
var death_score_label: Label
var death_accuracy_label: Label
var level_complete_screen: CanvasLayer
var level_complete_score_label: Label
var level_complete_accuracy_label: Label
var pause_canvas: CanvasLayer
var pause_menu_panel: Control
var pause_options_screen: Control
var pause_resume_button: Button
var pause_options_button: Button
var pause_back_to_menu_button: Button
var last_background_beat := -1
var background_flash_timer := 0.0
var background_flash_time := 0.18
var background_flash_alpha := 0.07
var low_health_filter_alpha := 0.0
var max_low_health_filter_alpha := 0.26
var is_level_paused := false
var level_completed := false
var accuracy_correct_count := 0
var accuracy_error_count := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if level_path:
		load_level(level_path)

func load_level(level_path: String) -> void:
	game_over = false
	level_completed = false
	score = 0
	accuracy_correct_count = 0
	accuracy_error_count = 0
	bullet_hell_score_tick_timer = 0.0
	last_background_beat = -1
	background_flash_timer = 0.0
	low_health_filter_alpha = 0.0
	is_level_paused = false
	get_tree().paused = false

	GameLoader.start_background_loading()
	await GameLoader.loading_finished
	
	entities.process_mode = Node.PROCESS_MODE_PAUSABLE
	entities.z_index = 100
	PlayfieldLayer.process_mode = Node.PROCESS_MODE_PAUSABLE
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
	_create_pause_overlay()
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
	projectile.on_evaded = Callable(self, "_on_projectile_evaded").bind(normalized_type)
	projectile.on_player_hit = Callable(self, "_on_projectile_hit_player").bind(normalized_type)


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
	_bind_background_nodes()
	_bind_screen_effect_nodes()


func _bind_background_nodes() -> void:
	background_canvas = get_node_or_null("GameplayBackground") as CanvasLayer
	if background_canvas == null:
		push_warning("GameplayBackground node is missing")
		return

	gameplay_background = background_canvas.get_node_or_null("BlackBackground") as ColorRect
	if gameplay_background == null:
		push_warning("BlackBackground node is missing")
		return

	gameplay_background.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _bind_screen_effect_nodes() -> void:
	effects_canvas = get_node_or_null("ScreenEffects") as CanvasLayer
	if effects_canvas == null:
		push_warning("ScreenEffects node is missing")
		return

	background_flash = effects_canvas.get_node_or_null("BackgroundFlash") as ColorRect
	if background_flash == null:
		push_warning("BackgroundFlash node is missing")
	else:
		background_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

	low_health_filter = effects_canvas.get_node_or_null("LowHealthFilter") as ColorRect
	if low_health_filter == null:
		push_warning("LowHealthFilter node is missing")
	else:
		low_health_filter.mouse_filter = Control.MOUSE_FILTER_IGNORE


func init_progress_bar() -> void:
	rythm_bar.layer = 2
	entities.add_child(rythm_bar)
	rythm_bar.set_bpm(bpm)
	rythm_bar.set_player(player)
	rythm_bar.set_score(score)
	rythm_bar.set_accuracy(_get_accuracy_percent())
	_update_hud_screen_filters()
	if not rythm_bar.rhythm_note_missed.is_connected(_on_rhythm_note_missed):
		rythm_bar.rhythm_note_missed.connect(_on_rhythm_note_missed)


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
	if not music.finished.is_connected(_on_music_finished):
		music.finished.connect(_on_music_finished)
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
	if is_level_paused:
		return

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
			_register_accuracy_result(true)
			_add_score(rhythm_hit_score)

	process_projectiles()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return

	if event.is_action_pressed(GameLoader.PAUSE_ACTION):
		if game_over or is_in_editor:
			return

		if is_level_paused:
			if pause_options_screen != null and is_instance_valid(pause_options_screen) and pause_options_screen.visible:
				_show_pause_main_menu()
			else:
				_resume_level()
		else:
			_pause_level()

		get_viewport().set_input_as_handled()


func _create_pause_overlay() -> void:
	if pause_canvas != null and is_instance_valid(pause_canvas):
		return

	var pause_scene: PackedScene = GameLoader.get_asset("pause_overlay")
	if pause_scene == null:
		push_warning("No se pudo cargar pause_overlay")
		return

	pause_canvas = pause_scene.instantiate()
	pause_canvas.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(pause_canvas)

	pause_menu_panel = pause_canvas.get_node("Center/MainPanel") as Control
	pause_resume_button = pause_canvas.get_node("Center/MainPanel/Margin/Layout/ResumeButton") as Button
	pause_options_button = pause_canvas.get_node("Center/MainPanel/Margin/Layout/OptionsButton") as Button
	pause_back_to_menu_button = pause_canvas.get_node("Center/MainPanel/Margin/Layout/BackToMenuButton") as Button

	pause_resume_button.pressed.connect(_resume_level)
	pause_options_button.pressed.connect(_show_pause_options)
	pause_back_to_menu_button.pressed.connect(_on_pause_back_to_menu_pressed)


func _pause_level() -> void:
	is_level_paused = true
	music.stream_paused = true
	_show_pause_main_menu()
	get_tree().paused = true


func _resume_level() -> void:
	get_tree().paused = false
	is_level_paused = false
	music.stream_paused = false
	if pause_canvas != null and is_instance_valid(pause_canvas):
		pause_canvas.visible = false


func _show_pause_main_menu() -> void:
	if pause_canvas == null or not is_instance_valid(pause_canvas):
		_create_pause_overlay()

	pause_canvas.visible = true
	if pause_menu_panel != null and is_instance_valid(pause_menu_panel):
		pause_menu_panel.visible = true

	if pause_options_screen != null and is_instance_valid(pause_options_screen):
		pause_options_screen.visible = false

	if pause_resume_button != null and is_instance_valid(pause_resume_button):
		pause_resume_button.grab_focus()


func _show_pause_options() -> void:
	if pause_canvas == null or not is_instance_valid(pause_canvas):
		_create_pause_overlay()

	if pause_options_screen == null or not is_instance_valid(pause_options_screen):
		var options_scene: PackedScene = GameLoader.get_asset("opciones")
		if options_scene == null:
			push_warning("No se pudo abrir Opciones desde pausa")
			return

		pause_options_screen = options_scene.instantiate()
		pause_options_screen.call("set_return_to_main_menu_on_back", false)
		pause_options_screen.connect("back_requested", _show_pause_main_menu)
		pause_canvas.add_child(pause_options_screen)

	pause_menu_panel.visible = false
	pause_options_screen.visible = true


func _on_pause_back_to_menu_pressed() -> void:
	get_tree().paused = false
	is_level_paused = false
	music.stream_paused = false
	GameLoader.load_scene("main_menu")


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

	_update_hud_screen_filters()


func _trigger_background_flash() -> void:
	background_flash_timer = background_flash_time


func _update_hud_screen_filters() -> void:
	if rythm_bar == null or not is_instance_valid(rythm_bar):
		return

	var flash_t := background_flash_timer / background_flash_time if background_flash_time > 0.0 else 0.0
	rythm_bar.set_screen_filters(background_flash_alpha * flash_t, low_health_filter_alpha)


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


func _register_accuracy_result(correct: bool) -> void:
	if correct:
		accuracy_correct_count += 1
	else:
		accuracy_error_count += 1

	if rythm_bar != null and is_instance_valid(rythm_bar):
		rythm_bar.set_accuracy(_get_accuracy_percent())


func _get_accuracy_percent() -> float:
	var total := accuracy_correct_count + accuracy_error_count
	if total <= 0:
		return 100.0
	return float(accuracy_correct_count) / float(total) * 100.0


func _on_rhythm_note_missed() -> void:
	_register_accuracy_result(false)


func _on_projectile_evaded(projectile: Projectile, projectile_type: String) -> void:
	if game_over or projectile == null:
		return

	var normalized_type := Projectile.normalize_type(projectile_type)
	if normalized_type == "bullet":
		_register_accuracy_result(true)


func _on_projectile_hit_player(projectile: Projectile, projectile_type: String) -> void:
	if game_over or projectile == null:
		return

	var normalized_type := Projectile.normalize_type(projectile_type)
	if normalized_type == "bullet":
		_register_accuracy_result(false)


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
	if rythm_bar != null and is_instance_valid(rythm_bar):
		rythm_bar.set_health(current_health, max_health)

	if max_health <= 0 or current_health > max_health * 0.5:
		low_health_filter_alpha = 0.0
		return

	var health_ratio := float(current_health) / float(max_health)
	var danger_t: float = clamp((0.5 - health_ratio) / 0.4, 0.0, 1.0)
	low_health_filter_alpha = danger_t * max_low_health_filter_alpha


func _on_player_shield_blocked(_projectile) -> void:
	_register_accuracy_result(true)
	_add_score(shield_block_score)


func _on_player_death_started() -> void:
	if level_completed:
		return

	if is_level_paused:
		_resume_level()

	game_over = true
	music.stop()
	_deactivate_projectiles()

	if rythm_bar != null and is_instance_valid(rythm_bar):
		rythm_bar.clear_notes()


func _on_player_died() -> void:
	if level_completed:
		return

	if not game_over:
		_on_player_death_started()

	if is_in_editor:
		return

	_show_death_screen()


func _on_music_finished() -> void:
	if game_over or level_completed:
		return

	level_completed = true
	game_over = true
	low_health_filter_alpha = 0.0
	background_flash_timer = 0.0
	_deactivate_projectiles()

	if rythm_bar != null and is_instance_valid(rythm_bar):
		rythm_bar.clear_notes()
		rythm_bar.set_screen_filters(0.0, 0.0)

	if is_in_editor:
		return

	_show_level_complete_screen()


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

	death_screen = _create_result_screen("death_overlay")
	if death_screen == null:
		return

	death_score_label = death_screen.get_node("Center/Panel/Margin/Layout/ScoreLabel") as Label
	death_accuracy_label = death_screen.get_node("Center/Panel/Margin/Layout/AccuracyLabel") as Label


func _show_level_complete_screen() -> void:
	if level_complete_screen != null and is_instance_valid(level_complete_screen):
		return

	level_complete_screen = _create_result_screen("level_complete_overlay")
	if level_complete_screen == null:
		return

	level_complete_score_label = level_complete_screen.get_node("Center/Panel/Margin/Layout/ScoreLabel") as Label
	level_complete_accuracy_label = level_complete_screen.get_node("Center/Panel/Margin/Layout/AccuracyLabel") as Label


func _create_result_screen(asset_key: String) -> CanvasLayer:
	var result_scene: PackedScene = GameLoader.get_asset(asset_key)
	if result_scene == null:
		push_warning("No se pudo cargar %s" % asset_key)
		return null

	var result_screen := result_scene.instantiate() as CanvasLayer
	add_child(result_screen)

	var score_label := result_screen.get_node("Center/Panel/Margin/Layout/ScoreLabel") as Label
	var accuracy_label := result_screen.get_node("Center/Panel/Margin/Layout/AccuracyLabel") as Label
	var play_again := result_screen.get_node("Center/Panel/Margin/Layout/PlayAgainButton") as Button
	var back_to_menu := result_screen.get_node("Center/Panel/Margin/Layout/BackToMenuButton") as Button

	score_label.text = "Final Score: %06d" % score
	accuracy_label.text = "Accuracy: %.1f%%" % _get_accuracy_percent()
	play_again.pressed.connect(_on_play_again_pressed)
	back_to_menu.pressed.connect(_on_back_to_menu_pressed)

	result_screen.visible = true
	play_again.grab_focus()
	return result_screen


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
