extends Area3D

const ROTATE_SPEED = 2.0
const BOB_HEIGHT = 0.15
const BOB_SPEED = 2.0

var _base_y: float
var _time := 0.0

func _ready():
	_base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta):
	_time += delta
	rotate_y(ROTATE_SPEED * delta)
	position.y = _base_y + sin(_time * BOB_SPEED) * BOB_HEIGHT

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		ScoreManager.add_coin()
		queue_free()
