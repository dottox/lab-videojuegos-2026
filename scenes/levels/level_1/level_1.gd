extends BaseLevel

# Level 1 Specific Data
func setup_level():
	bpm = 130
	player.set_mode("normal") # Custom state for this level
	playfield.set_state("normal")

	synth = [
		9.9,11.7,13.7,15.5,17.5,19.3,21.2,23,25,25.6,26.1,
		26.6,27.6,28.7,29.6,29.9,30.4,31.3,32.5,33,33.6,34.2,
		35.1,35.7,36.3,36.7,37.4,37.9
	]

	clap = [10.5,11.3,12.3,13.2,14.2,15.1,16.1,16.9,17.9,
		18.9,19.8,20.8,21.7,22.6,23.6,25,25.9,26.9,27.1,27.3,
		27.8,28.1,28.8,29.6,30.6,30.9,31.1,31.6,33.5,34.7,34.9]
	spawn_clap_area1 = Rect2(100,100,210,500)
	spawn_clap_area2 = Rect2(840,100,210,500)
	bullet_clap_speed = 200
	bullets_per_clap = 16
	bullet_size = 5

	xilo = [
		24.4,24.6,24.8,
		31.9,32.1,32.3
	]


# Level 1 specific logic
func process_level_logic(_delta: float):
	next_clap_index = process_bullet(clap, next_clap_index, spawn_clap)
	next_synth_index = process_bullet(synth, next_synth_index, spawn_synth)
