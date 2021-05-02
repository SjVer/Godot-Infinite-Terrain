extends KinematicBody

var dir = Vector3()

var camera
var rotation_helper

export(float) var MOVE_SPEED = 1.0
export(float) var MOUSE_SENSITIVITY = 0.05

func _ready():
	camera = $Camera #$Rotation_Helper/Camera
	#rotation_helper = $Rotation_Helper

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	process_input()
	process_movement(delta)

func process_input():

	# ----------------------------------
	# Walking
	dir = Vector3()
	var cam_xform = camera.get_global_transform()

	var input_movement_vector = Vector3()

	if Input.is_action_pressed("forward"):
		input_movement_vector.z += MOVE_SPEED * 10
	if Input.is_action_pressed("backward"):
		input_movement_vector.z -= MOVE_SPEED * 10
	if Input.is_action_pressed("left"):
		input_movement_vector.x -= MOVE_SPEED * 10
	if Input.is_action_pressed("right"):
		input_movement_vector.x += MOVE_SPEED * 10
	if Input.is_action_pressed("up"):
		input_movement_vector.y += MOVE_SPEED * 10
	if Input.is_action_pressed("down"):
		input_movement_vector.y -= MOVE_SPEED * 10

	#input_movement_vector = input_movement_vector.normalized()
	
	# Basis vectors are already normalized.
	dir += -cam_xform.basis.z * input_movement_vector.z
	dir += cam_xform.basis.x * input_movement_vector.x
	dir += cam_xform.basis.y * input_movement_vector.y
	# ----------------------------------


	# ----------------------------------
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ----------------------------------

func process_movement(delta):
	move_and_slide(dir)

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		#rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		camera.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

		#var camera_rot = rotation_helper.rotation_degrees
		#camera_rot.x = clamp(camera_rot.x, -70, 70)
		#rotation_helper.rotation_degrees = camera_rot
