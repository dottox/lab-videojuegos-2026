extends PlayfieldState

#Variables relacionadas al tamaño
var default_size = Vector2(500,250)

# Called when the node enters the scene tree for the first time.
func enter(playfield):
	playfield.set_size(default_size)
	
