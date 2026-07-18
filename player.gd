extends CharacterBody3D

# Movement constants
const SPEED = 5.0
const ACCELERATION = 15.0
const DECELERATION = 20.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	# Add the gravity if the player is in the air
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump (Optional: Spacebar mapped to "ui_accept" by default)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction using your Input Map actions
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Calculate direction relative to the player's orientation
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		# Smoothly accelerate toward target speed
		velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCELERATION * delta)
	else:
		# Smoothly friction to a stop
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)

	# Move the character using the calculated velocity vector
	move_and_slide()
