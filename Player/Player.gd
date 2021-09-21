extends KinematicBody

# Camera
export(float) var mouse_sensitivity = 8.0
export(NodePath) var head_path = "Head"
export(NodePath) var cam_path = "Head/Camera"
export(float) var FOV = 80.0
var mouse_axis := Vector2()
onready var head: Spatial = get_node(head_path)
onready var cam: Camera = get_node(cam_path)
# Move
var velocity := Vector3()
var direction := Vector3()
var move_axis := Vector2()
var snap := Vector3()
var sprint_enabled := true
var sprinting := false
var tired := false
var current_sprinting_time = 0
export(bool) var gets_tired = true
export(float) var max_sprinting_time = 5.0
onready var steps_audio = $SteapsAudio
onready var sprint_audio = $SteapsSprintAudio
# Walk
const FLOOR_MAX_ANGLE: float = deg2rad(46.0)
export(float) var gravity = 30.0
export(int) var walk_speed = 5
export(int) var sprint_speed = 7
export(int) var acceleration = 2
export(int) var deacceleration = 5
export(float, 0.0, 1.0, 0.05) var air_control = 0.3
export(int) var jump_height = 10
var _speed: int
var _is_sprinting_input := false
var _is_jumping_input := false
# Game
var total_notes = 0

func _ready() -> void:
	Signals.connect("got_note", self, "_got_note")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam.fov = FOV


func _process(_delta: float) -> void:
	move_axis.x = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	move_axis.y = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	
	if Input.is_action_just_pressed("move_jump"):
		_is_jumping_input = true
	
	if Input.is_action_pressed("move_sprint"):
		_is_sprinting_input = true
	else:
		_is_sprinting_input = false


func _physics_process(delta: float) -> void:
	walk(delta)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_axis = event.relative
		camera_rotation()

func walk(delta: float) -> void:
	direction_input()
	
	if is_on_floor():
		snap = -get_floor_normal() - get_floor_velocity() * delta
		
		# Workaround for sliding down after jump on slope
		if velocity.y < 0:
			velocity.y = 0
		
		jump()
	else:
		# Workaround for 'vertical bump' when going off platform
		if snap != Vector3.ZERO && velocity.y != 0:
			velocity.y = 0
		
		snap = Vector3.ZERO
		
		velocity.y -= gravity * delta
	
	sprint(delta)
	accelerate(delta)
	
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true, 4, FLOOR_MAX_ANGLE)
	_is_jumping_input = false


func camera_rotation() -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	if mouse_axis.length() > 0:
		var horizontal: float = -mouse_axis.x * (mouse_sensitivity / 100)
		var vertical: float = -mouse_axis.y * (mouse_sensitivity / 100)
		
		mouse_axis = Vector2()
		
		rotate_y(deg2rad(horizontal))
		head.rotate_x(deg2rad(vertical))
		
		# Clamp mouse rotation
		var temp_rot: Vector3 = head.rotation_degrees
		temp_rot.x = clamp(temp_rot.x, -90, 90)
		head.rotation_degrees = temp_rot


func direction_input() -> void:
	direction = Vector3()
	var aim: Basis = get_global_transform().basis
	if move_axis.x >= 0.5:
		direction -= aim.z
	if move_axis.x <= -0.5:
		direction += aim.z
	if move_axis.y <= -0.5:
		direction -= aim.x
	if move_axis.y >= 0.5:
		direction += aim.x
	direction.y = 0
	direction = direction.normalized()


func accelerate(delta: float) -> void:
	# Where would the player go
	play_movement_sfx()
		
	var _temp_vel: Vector3 = velocity
	var _temp_accel: float
	var _target: Vector3 = direction * _speed
	
	_temp_vel.y = 0
	if direction.dot(_temp_vel) > 0:
		_temp_accel = acceleration
		
	else:
		_temp_accel = deacceleration
	
	if not is_on_floor():
		_temp_accel *= air_control
	
	# Interpolation
	_temp_vel = _temp_vel.linear_interpolate(_target, _temp_accel * delta)
	
	velocity.x = _temp_vel.x
	velocity.z = _temp_vel.z
	
	# Make too low values zero
	if direction.dot(velocity) == 0:
		var _vel_clamp := 0.01
		if abs(velocity.x) < _vel_clamp:
			velocity.x = 0
		if abs(velocity.z) < _vel_clamp:
			velocity.z = 0

func play_movement_sfx():
	var is_moving = direction.x != 0 || direction.y != 0
	var is_sprinting = is_moving and can_sprint()
	if is_moving and !is_sprinting:
		if !steps_audio.playing:
			steps_audio.play()
	else:
		steps_audio.stop()
		
	if is_sprinting:
		if !sprint_audio.playing:
			sprint_audio.play()
	else:
		sprint_audio.stop()

func jump() -> void:
	if _is_jumping_input:
		velocity.y = jump_height
		snap = Vector3.ZERO


func sprint(delta: float) -> void:
	if can_sprint():
		_speed = sprint_speed
		cam.set_fov(lerp(cam.fov, FOV * 1.05, delta * 8))
		sprinting = true
		
	else:
		_speed = walk_speed
		cam.set_fov(lerp(cam.fov, FOV, delta * 8))
		sprinting = false
		
	check_tired(delta)

func check_tired(delta: float) -> void:
	if gets_tired:
		if max_sprinting_time > 0:
			if can_sprint():
				current_sprinting_time += delta
				if current_sprinting_time >= max_sprinting_time:
					tired = true
			else:
				current_sprinting_time -= delta
				if current_sprinting_time <= 0:
					tired = false
					current_sprinting_time = 0

func can_sprint() -> bool:
	return (sprint_enabled and
		is_on_floor() and
		_is_sprinting_input and
		move_axis.x >= 0.5 and
		!tired)

func _got_note():
	total_notes += 1
	if total_notes == 8:
		get_tree().change_scene("res://Levels/Menus/Victory.tscn")
