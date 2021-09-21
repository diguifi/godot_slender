extends Spatial

export var fast_close := true

func _ready() -> void:
	if !OS.is_debug_build():
		fast_close = false
	
	if fast_close:
		print("** 'Esc' to close 'F1' to release mouse **")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and fast_close:
		get_tree().quit()
	if event.is_action_pressed("ui_cancel") and !fast_close:
		toggle_mouse_mode()
	
	if event.is_action_pressed("mouse_input") and fast_close:
		toggle_mouse_mode()
				
func toggle_mouse_mode():
	match Input.get_mouse_mode():
			Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
