extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var run_speed: float = 10.0
@export var jump_speed: float = 4.1
@export var turn_speed: float = 4.0
@export var mouse_sensitivity: float = 0.001

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var animation_player: AnimationPlayer
var main_node: Node

@onready var pivot = $CameraPivot
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var jump_sound = preload("res://Sounds/robot_jump.wav")
var land_sound = preload("res://Sounds/robot_land.wav")
var step_sounds = [
	preload("res://Sounds/robot_step_01.wav"),
	preload("res://Sounds/robot_step_02.wav"),
	preload("res://Sounds/robot_step_03.wav"),
	preload("res://Sounds/robot_step_04.wav"),
	preload("res://Sounds/robot_step_05.wav")
]

var sfx_player: AudioStreamPlayer
var footstep_player: AudioStreamPlayer

var footstep_interval: float = 0.4 
var footstep_timer: float = 0.0

var was_on_floor: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	footstep_player = AudioStreamPlayer.new()
	add_child(footstep_player)

	animation_player = $godot_plush_model/AnimationPlayer

	main_node = get_tree().get_root().get_node("Main")

	play_animation("idle")
	
	was_on_floor = is_on_floor()
	
	randomize()

func _input(event: InputEvent) -> void:
	if main_node.game_ended:
		return
	
	if event is InputEventMouseMotion:
		rotation.y += event.relative.x * mouse_sensitivity
		var new_x_rot = pivot.rotation.x - event.relative.y * mouse_sensitivity
		new_x_rot = clamp(new_x_rot, deg_to_rad(-45), deg_to_rad(45))
		pivot.rotation.x = new_x_rot

func _physics_process(delta: float) -> void:
	var vel = velocity

	vel.y -= gravity * delta

	if main_node.game_ended:
		pivot.rotate_y(0.02)
		rotation.y = 0
		vel.x = 0
		vel.z = 0
		if main_node.did_we_win:
			if is_on_floor():
				vel.y = jump_speed
		velocity = vel
		move_and_slide()
		_update_animation(delta)
		return
	else:

		if Input.is_action_pressed("move_left"):
			rotation.y += turn_speed * delta
		elif Input.is_action_pressed("move_right"):
			rotation.y -= turn_speed * delta

		var input_dir = Vector2.ZERO
		if Input.is_action_pressed("move_forward"):
			input_dir.y += 1
		if Input.is_action_pressed("move_backward"):
			input_dir.y -= 1
		input_dir = input_dir.normalized()

		var direction_3d = Vector3(input_dir.x, 0.0, input_dir.y)
		direction_3d = (transform.basis * direction_3d).normalized()

		var current_speed = walk_speed
		if Input.is_action_pressed("shift"):
			current_speed = run_speed

		vel.x = direction_3d.x * current_speed
		vel.z = direction_3d.z * current_speed

		if Input.is_action_just_pressed("jump") and is_on_floor():
			vel.y = jump_speed
			sfx_player.stream = jump_sound
			sfx_player.play()

		velocity = vel
		move_and_slide()

		if is_on_floor() and not was_on_floor:
			sfx_player.stream = land_sound
			sfx_player.play()

		footstep_timer -= delta
		var horizontal_speed = Vector2(velocity.x, velocity.z).length()
		if footstep_timer <= 0.0 and is_on_floor() and horizontal_speed > 0.1:
			footstep_timer = footstep_interval
			footstep_player.stream = step_sounds[randi() % step_sounds.size()]
			footstep_player.play()

		was_on_floor = is_on_floor()

		_update_animation(delta)


func _update_animation(delta: float) -> void:
	if not is_on_floor():
		play_animation("fall")
		return

	var horizontal_speed = Vector2(velocity.x, velocity.z).length()

	if horizontal_speed < 0.1:
		play_animation("idle")
	else:
		if horizontal_speed >= run_speed - 0.1:
			play_animation("run")
		else:
			play_animation("walk")

	if Input.is_action_pressed("move_left"):
		play_animation("tilt_l")
	elif Input.is_action_pressed("move_right"):
		play_animation("tilt_r")

func play_animation(anim_name: String) -> void:
	if animation_player.current_animation == anim_name:
		return
	animation_player.play(anim_name)
