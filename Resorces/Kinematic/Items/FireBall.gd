extends Kinematic

onready var sprite = $Sprite
onready var particles = $Particles2D
onready var animation = $AnimationPlayer
onready var detector = $ShootDetector

var direction = 1

func _ready():
	particles.emitting = true
	animation.play("rotation")
	direction = get_node("../Player/AnimatedSprite").scale.x
	detector.scale.x = direction
	particles.scale.x = direction
	sprite.scale.x = direction * 0.5

func _physics_process(_delta: float):
	_velocity.x = speed.x * direction
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL)

func _on_ShootDetector_body_entered(body: Node):
	particles.emitting = false
	animation.play("fade_out")
