extends Spatial

enum state {
	NONE,
	HAUNTING,
	STANDING,
	JUMPSCARING
}

onready var player = get_node("/root/L_Main/Player")
onready var camera = get_viewport().get_camera()
export var time_for_new_action = 16

var current_state = state.HAUNTING
var last_state = state.NONE
var current_distance = 15
var jumpscare_chance = 10
var stand_still_chance = 20

var player_can_see := false
var last_player_can_see := false
var can_disapear_after_being_seen := false
var count_player_looking := false
var time_player_sees = 0
var max_time_player_sees = 6

var should_jumpscare := false
var should_stand_still := false

var timer = 0
var jumpscare_time = 1.5
var random_generator = RandomNumberGenerator.new()

func _ready():
	Signals.connect("got_note", self, "_got_note")

func _process(delta):
	timer += delta
	if count_player_looking:
		time_player_sees += delta
	set_state()
	recalculate_bilu_variables(player.total_notes)
	fixed_look_to_player()
	
func _physics_process(_delta):
	haunt_player()
	last_player_can_see = player_can_see
	
func fixed_look_to_player():
	var camera_pos = camera.global_transform.origin
	camera_pos.y = 0
	look_at(camera_pos, Vector3(0, 1, 0))
	
func haunt_player():
	if timer >= time_for_new_action:
		calculate_new_action()
	move_bilu(should_jumpscare, should_stand_still)

func move_bilu(go_to_front, stand_still):
	var camera_aim = camera.get_global_transform().basis
	var camera_pos = camera.get_global_transform().origin
	
	if go_to_front:
		stay_in_front_of_player(camera_aim, camera_pos)
	elif !stand_still:
		stay_behind_player(camera_aim, camera_pos)
	else:
		stand_still()
	
func stay_behind_player(camera_aim, camera_pos):
	global_transform.origin = camera_pos
	global_transform.origin.y += -1.65
	global_transform.origin.z += camera_aim.z.z * current_distance
	global_transform.origin.x += camera_aim.z.x * current_distance
	
func stay_in_front_of_player(camera_aim, camera_pos):
	if timer <= jumpscare_time:
		global_transform.origin = camera_pos
		global_transform.origin.y += -1.65
		global_transform.origin.z += camera_aim.z.z * -current_distance
		global_transform.origin.x += camera_aim.z.x * -current_distance
	else:
		should_jumpscare = false
	
func stand_still():
	if !last_player_can_see and player_can_see and !can_disapear_after_being_seen:
		count_player_looking = true
		can_disapear_after_being_seen = true
	if last_player_can_see and !player_can_see and can_disapear_after_being_seen:
		count_player_looking = false
		can_disapear_after_being_seen = false
		should_stand_still = false
	
	if time_player_sees > max_time_player_sees:
		get_tree().change_scene("res://Levels/Menus/GameOver.tscn")
	
func calculate_new_action():
	timer = 0
	should_stand_still = false
	should_jumpscare = false
	random_generator.randomize()
	var random_value_stand = random_generator.randi_range(1,100)
	random_generator.randomize()
	var random_value_scare = random_generator.randi_range(1,100)
	if stand_still_chance >= random_value_stand:
		should_stand_still = true
	elif jumpscare_chance  >= random_value_scare:
		should_jumpscare = true
		
func set_state():
	var message = ''
	if should_jumpscare:
		current_state = state.JUMPSCARING
		message = 'jumpscare mode'
	elif should_stand_still:
		current_state = state.STANDING
		message = 'standing mode'
	else:
		current_state = state.HAUNTING
		message = 'haunting...'
		
	if (current_state != last_state):
		last_state = current_state
		print(message)
		apply_state_properties()
	
func apply_state_properties():
	match current_state:
		state.JUMPSCARING:
			pass
		state.STANDING:
			time_player_sees = 0
			count_player_looking = false
		state.HAUNTING:
			pass
			
func recalculate_bilu_variables(player_notes):
	if player_notes > 0:
		time_for_new_action = 16 - player_notes
		current_distance = 15 / player_notes
		jumpscare_chance = 10 + (player_notes * 4)
		stand_still_chance = 20 + (player_notes * 5)

func _on_VisibilityNotifier_camera_entered(camera):
	player_can_see = true

func _on_VisibilityNotifier_camera_exited(camera):
	player_can_see = false
