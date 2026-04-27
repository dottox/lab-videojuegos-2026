extends Node2D
class_name BaseLevel

@onready var entities: Node2D = $entities
@onready var music: AudioStreamPlayer2D = $AudioStreamPlayer2D

# References to shared objects
var player
var playfield
var rythm_bar
var bullet_scene

# Logic variables (to be overridden by child levels)
var music_timer: float = 0.0
var bpm: int = 120
var next_synth_index: int = 0
var next_clap_index: int = 0
var next_xilo_index: int = 0
var synth: Array[int] = []
var xilo: Array[int] = []
var clap: Array[int] = []
var spawn_clap_area1: Rect2 = Rect2()
var spawn_clap_area2: Rect2 = Rect2()
var bullet_clap_speed: int = 200
var bullets_per_clap: int = 16
var bullet_size: int = 5

func _ready():
	await GameLoader.loading_finished
	# Use assets already loaded in background by GameLoader (Singleton)
	spawn_playfield()
	spawn_player()
	bullet_scene = GameLoader.get_asset("bullet")
	init_progress_bar()
	
	# Call custom setup for specific levels
	setup_level()
	init_music()

func setup_level():
	# Virtual method: Override in child classes (Level1, Level2, etc.)
	pass

func spawn_player():
	var scene = GameLoader.get_asset("player")
	player = scene.instantiate()
	entities.add_child(player)
	player.global_position = playfield.global_position
	player.playfield = playfield

func spawn_playfield():
	var scene = GameLoader.get_asset("playfield")
	playfield = scene.instantiate()
	entities.add_child(playfield)
	playfield.global_position = (get_viewport().get_visible_rect().size / 2.0) + Vector2(0, 100)

func spawn_clap():
	#print("Clap")
	var area = spawn_clap_area1 if randi() % 2 == 0 else spawn_clap_area2
	var spawn_pos = random_point_in_rect(area)
	
	spawn_radial_bullets(spawn_pos, bullets_per_clap)


func spawn_synth():
	#print("SYNTH")
	pass

func spawn_xilo():
	#print("XILO")
	pass
	
func init_progress_bar():
	var scene = GameLoader.get_asset("rythm_bar")
	rythm_bar = scene.instantiate()
	entities.add_child(rythm_bar)
	rythm_bar.set_bpm(bpm)

func init_music():
	music.play(0)

# Helper for all levels
func process_bullet(times:Array, index:int, callback:Callable) -> int:
	while index < times.size() and music_timer >= times[index]:
		callback.call()
		index += 1
	return index

func random_point_in_rect(rect: Rect2) -> Vector2:
	var x = randf_range(rect.position.x, rect.end.x)
	var y = randf_range(rect.position.y, rect.end.y)
	return Vector2(x, y)

func spawn_radial_bullets(center: Vector2, amount: int):
	for i in amount:
		var bullet = bullet_scene.instantiate()
		entities.add_child(bullet)

		bullet.global_position = center

		var angle = TAU * i / amount
		var direction = Vector2.RIGHT.rotated(angle)

		bullet.set_bullet_velocity(direction * bullet_clap_speed)
		bullet.set_bullet_size(bullet_size)
		
func _physics_process(delta: float):
	music_timer = music.get_playback_position()
	#print("Time: " + str(music_timer))

	if music.playing:
		rythm_bar.update_song_time(music_timer)
	
	if Input.is_action_just_pressed("hit_debug"):
		print("¡Xilo!: " + str(music_timer))
		
	next_clap_index = process_bullet(clap,next_clap_index,spawn_clap)

	next_synth_index = process_bullet(synth,next_synth_index,spawn_synth)

	next_xilo_index = process_bullet(xilo,next_xilo_index,spawn_xilo)
