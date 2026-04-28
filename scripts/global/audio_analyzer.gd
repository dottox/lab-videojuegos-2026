extends Node

var spectrum: AudioEffectSpectrumAnalyzerInstance
var music_player: AudioStreamPlayer2D
var bus_index

#Define qué frecuencias va a 'analizar'
const MIN_FREQ = 20.0
const MAX_FREQ = 20000.0
const BANDS = 64

var bass := 0.0
var mid := 0.0
var high := 0.0
var loudness := 0.0
var spectrum_frequency := []

func _process(_delta):
	if spectrum == null:
		
		return

	bass = get_band_energy(20, 150)
	mid = get_band_energy(150, 2000)
	high = get_band_energy(2000, 8000)

	loudness = (bass + mid + high) / 3.0
	
	spectrum_frequency = get_frequency_spectrum()
	

func get_band_energy(from_hz: float, to_hz: float) -> float:
	var magnitude = spectrum.get_magnitude_for_frequency_range(
		from_hz,
		to_hz,
		AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
	)

	return magnitude.length()
	
#Esto devuelve un array con length = 64 de todos los sonidos
func get_frequency_spectrum() -> Array:
	var result := []
	
	if spectrum == null:
		return result
	
	for i in BANDS:
		var f1 = MIN_FREQ * pow(MAX_FREQ / MIN_FREQ, float(i)/BANDS)
		var f2 = MIN_FREQ * pow(MAX_FREQ / MIN_FREQ, float(i+1)/BANDS)
		
		var mag = spectrum.get_magnitude_for_frequency_range(f1, f2)
		result.append((mag.x + mag.y) * 0.5)
	return result

func register_music(player: AudioStreamPlayer2D):
	music_player = player
	bus_index = AudioServer.get_bus_index(player.bus)
	spectrum = AudioServer.get_bus_effect_instance(bus_index, 0)
	
	#Debug
	#print("Bus:", player.bus)
	#print("Bus index:", bus_index)
	#print("Effects:", AudioServer.get_bus_effect_count(bus_index))
