extends CharacterBody3D

# Movement constants
const SPEED = 5.0
const ACCELERATION = 15.0
const DECELERATION = 20.0
const JUMP_VELOCITY = 4.5

@export var mouse_sensitivity: float = 0.003
@export var min_pitch_degrees: float = -60.0
@export var max_pitch_degrees: float = 10.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_pitch: float

# The zombie model and its animations ship as separate FBX files that share the
# same skeleton, so at startup we pull the animations out of their own scenes
# and register them on our AnimationPlayer under simple names.
const ANIMATION_SOURCES = {
	"idle": ["res://Assets/zombie/Animations/idle.fbx", "Root|Idle", true],
	"run": ["res://Assets/zombie/Animations/run.fbx", "Root|Run", true],
	"jump": ["res://Assets/zombie/Animations/jump.fbx", "Root|Jump", false],
}

func _ready():
	_build_animation_library()
	anim_player.play("idle")
	camera_pitch = camera_pivot.rotation.x
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_animation_library():
	var library = AnimationLibrary.new()
	for anim_name in ANIMATION_SOURCES:
		var source = ANIMATION_SOURCES[anim_name]
		var source_scene: PackedScene = load(source[0])
		var temp_instance = source_scene.instantiate()
		var source_player: AnimationPlayer = temp_instance.find_child("AnimationPlayer", true, false)
		var anim: Animation = source_player.get_animation(source[1]).duplicate()
		anim.loop_mode = Animation.LOOP_LINEAR if source[2] else Animation.LOOP_NONE
		library.add_animation(anim_name, anim)
		temp_instance.free()
	anim_player.add_animation_library("", library)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		camera_pitch = clamp(
			camera_pitch - event.relative.y * mouse_sensitivity,
			deg_to_rad(min_pitch_degrees),
			deg_to_rad(max_pitch_degrees)
		)
		camera_pivot.rotation.x = camera_pitch

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# This model's forward is local +Z rather than Godot's usual -Z (a 180-degree
	# flip), which flips "right" to local -X as well - so both axes get negated.
	# Facing is fully driven by the mouse now, so movement can freely strafe/backpedal
	# relative to it without any risk of fighting a self-referential rotation target.
	var direction = (transform.basis * Vector3(-input_dir.x, 0, -input_dir.y)).normalized()

	if direction.length() > 0.01:
		velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)

	move_and_slide()

	_update_animation(direction)

func _update_animation(direction: Vector3):
	var target_anim: String
	if not is_on_floor():
		target_anim = "jump"
	elif direction.length() > 0.01:
		target_anim = "run"
	else:
		target_anim = "idle"

	if anim_player.current_animation != target_anim:
		anim_player.play(target_anim)
