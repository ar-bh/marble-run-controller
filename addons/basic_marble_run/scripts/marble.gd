class_name Marble
extends RigidBody3D # not CharacterBody3D

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var camera_height := 1.4
@export var follow_smoothing := 10.0
@export var pitch_min := -0.7
@export var pitch_max := 1.1

@export_group("Movement")
@export var torque_strength := 12.0 # wasd rotates the ball not add velocity
@export var max_speed := 14.0 # even though ball is being rotated instead of using velocity, speed should still be capped

var _camera_input_direction := Vector2.ZERO

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var _camera: Camera3D = %Camera3D

func _ready() -> void:
	# make the camera pivot not inherit the rotation of the Marble so view does not tumble
	_camera_pivot.top_level = true
	_spring_arm.add_excluded_object(get_rid())
	_camera_pivot.global_position = global_position + Vector3.UP * camera_height
	
func _input(event: InputEvent) -> void:
	# handle mouse mode
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
func _unhandled_input(event: InputEvent) -> void:
	# handle mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_camera_input_direction = event.screen_relative * mouse_sensitivity
		
func _physics_process(delta: float) -> void:
	var target := global_position + Vector3.UP * camera_height
	var t := 1.0 - exp(-follow_smoothing * delta)
	_camera_pivot.global_position = _camera_pivot.global_position.lerp(target, t)
	
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, pitch_min, pitch_max)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	_camera_input_direction = Vector2.ZERO

	var raw_input := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward",
	)
	
	# camera looks down -z so basis.z is world-back
	# get_vector's forward is -Y so z * y = look direction
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	
	var move_direction := (forward * raw_input.y) + (right * raw_input.x)
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	
	if move_direction.length() > 0.1:
		apply_torque(Vector3.UP.cross(move_direction) * torque_strength)
	
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed
