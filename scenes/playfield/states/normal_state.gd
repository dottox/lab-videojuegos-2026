extends PlayfieldState

# Called when the node enters the scene tree for the first time.
func enter(playfield):
	playfield.queue_redraw()
	
