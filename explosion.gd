extends Particles2D

func _ready():
	emitting = true

func _on_lifespanTimer_timeout():
	queue_free()
