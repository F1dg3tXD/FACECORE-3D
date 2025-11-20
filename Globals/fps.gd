extends Label

var update_interval := 0.1  # 10 times per second
var timer := 0.0

func _process(delta):
	timer -= delta
	if timer <= 0.0:
		text = "FPS: %d" % Engine.get_frames_per_second()
		timer = update_interval
