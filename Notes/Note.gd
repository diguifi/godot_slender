extends Sprite3D

export var note_id = 0
onready var camera = get_viewport().get_camera()
var can_pick := false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action") and can_pick:
		Signals.emit_signal("got_note")
		get_parent().queue_free()

func _process(delta):
	var camera_pos = camera.global_transform.origin
	var note_pos = global_transform.origin
	if note_pos.distance_to(camera_pos) <= 2.5:
		can_pick = true
	else:
		can_pick = false
