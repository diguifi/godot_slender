extends Spatial

onready var terror_audio = $TerrorBeatsAudio

func _ready() -> void:
	Signals.connect("got_note", self, "_got_note")


func _input(event: InputEvent) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		if event.is_action_pressed("action"):
			toggle_mouse_mode()
	else:
		if event.is_action_pressed("ui_cancel") || event.is_action_pressed("mouse_input"):
			toggle_mouse_mode()
				
func toggle_mouse_mode():
	match Input.get_mouse_mode():
			Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				
func _got_note():
	if !terror_audio.playing:
		terror_audio.play()
