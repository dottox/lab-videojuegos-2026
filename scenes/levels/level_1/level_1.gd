extends Node2D

@onready var entities: Node2D = $entities
@onready var music: AudioStreamPlayer2D = $AudioStreamPlayer2D

var player_scene := preload("res://scenes/player/player.tscn")
var player

var playfield_scene := preload("res://scenes/playfield/playfield.tscn")
var playfield

var bullet_scene := preload("res://scenes/projectiles/bullet/bullet.tscn")

var music_timer
var bpm := 120

var rythm_bar_scene := preload("res://scenes/ui/progress_bar/progress_bar.tscn")
var rythm_bar 


#Patron de clap + variables de los claps
var next_clap_index := 0
var clap = [10.5,11.3,12.3,13.2,14.2,15.1,16.1,16.9,17.9,
	18.9,19.8,20.8,21.7,22.6,23.6,25,25.9,26.9,27.1,27.3,
	27.8,28.1,28.8,29.6,30.6,30.9,31.1,31.6,33.5,34.7,34.9]
var spawn_clap_area1 = Rect2(100,100,210,500)
var spawn_clap_area2 = Rect2(840,100,210,500)
var bullet_clap_speed = 200
var bullets_per_clap = 16
var bullet_size = 5
	
#Patrón de Synth
var next_synth_index := 0
var synth = [
	9.9,11.7,13.7,15.5,17.5,19.3,21.2,23,25,25.6,26.1,
	26.6,27.6,28.7,29.6,29.9,30.4,31.3,32.5,33,33.6,34.2,
	35.1,35.7,36.3,36.7,37.4,37.9
]

#Patrón de Xilo
var next_xilo_index := 0
var xilo = [
	24.4,24.6,24.8,
	31.9,32.1,32.3
]

func _draw():
	#For debug purpose
	draw_rect(spawn_clap_area1, Color.BLUE_VIOLET)
	draw_rect(spawn_clap_area2, Color.BLUE_VIOLET)
	
func _ready():
	spawn_playfield()
	spawn_player()
	init_music()
	init_progress_bar()
	
func _physics_process(delta: float):
	music_timer = music.get_playback_position()
	#print("Time: " + str(music_timer))

	if music.playing:
		rythm_bar.update_song_time(music_timer)
	
	if Input.is_action_just_pressed("hit_debug"):
		print("¡Xilo!: " + str(music_timer))
		
	next_clap_index = process_bullet(clap,next_clap_index,spawn_clap,music_timer)

	next_synth_index = process_bullet(synth,next_synth_index,spawn_synth,music_timer)

	next_xilo_index = process_bullet(xilo,next_xilo_index,spawn_xilo,music_timer)

func process_bullet(times:Array, index:int, callback:Callable, song_time:float) -> int:
	while index < times.size() and song_time >= times[index]:
		callback.call()
		index += 1
	return index

func spawn_clap():
	#print("Clap")
	var area = spawn_clap_area1 if randi() % 2 == 0 else spawn_clap_area2
	var spawn_pos = random_point_in_rect(area)
	
	spawn_radial_bullets(spawn_pos, bullets_per_clap)

func spawn_radial_bullets(center: Vector2, amount: int):

	for i in amount:
		var bullet = bullet_scene.instantiate()
		entities.add_child(bullet)

		bullet.global_position = center

		var angle = TAU * i / amount
		var direction = Vector2.RIGHT.rotated(angle)

		bullet.set_bullet_velocity(direction * bullet_clap_speed)
		bullet.set_bullet_size(bullet_size)

func spawn_synth():
	#print("SYNTH")
	pass

func spawn_xilo():
	#print("XILO")
	pass

func spawn_player():
	player = player_scene.instantiate()
	entities.add_child(player)
	player.set_mode("normal")
	player.global_position = playfield.global_position
	player.playfield = playfield
	
func spawn_playfield():
	playfield = playfield_scene.instantiate()
	entities.add_child(playfield)
	playfield.set_state("normal")
	playfield.global_position = (get_viewport().get_visible_rect().size / 2.0) + Vector2(0, 100)
	
func random_point_in_rect(rect: Rect2) -> Vector2:
	var x = randf_range(rect.position.x, rect.end.x)
	var y = randf_range(rect.position.y, rect.end.y)
	return Vector2(x, y)
	
func init_music():
	#Inicio canción
	#music.play(0)
	#Primer drop
	music.play(0)
	#Para debuguear, que vaya 'lento'
	#music.pitch_scale = 0.5 
	
func init_progress_bar():
	rythm_bar = rythm_bar_scene.instantiate()
	entities.add_child(rythm_bar)
	rythm_bar.set_bpm(bpm)
