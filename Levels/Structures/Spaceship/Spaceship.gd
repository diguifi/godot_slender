extends Spatial

onready var sound = $SpaceshipAudio

func _ready():
	Signals.connect("enable_spaceship", self, "_make_visible")

func win_game():
	if visible:
		get_tree().change_scene("res://Levels/Menus/Victory.tscn")
	
func _make_visible():
	sound.play()
	visible = true


func _on_Area_area_entered(area):
	if area.name == 'PlayerArea':
		win_game()
