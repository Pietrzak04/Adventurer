extends CanvasLayer

onready var spawn_point = $Node2D
onready var move = $Tween
onready var particles = $Node2D/Particles2D
onready var sprite = $Node2D/Sprite

export var speed = 1

func _ready():
	var move_to = get_node("../../Player/CanvasLayer/GUI/ScoreBar/TextureRect/GemPoint").global_position
	move.interpolate_property(spawn_point, "position:x", spawn_point.position.x, move_to.x, speed, Tween.TRANS_LINEAR, Tween.EASE_IN)
	move.interpolate_property(spawn_point, "position:y", spawn_point.position.y, move_to.y, speed, Tween.TRANS_EXPO, Tween.EASE_OUT)
	move.interpolate_property(spawn_point, "rotation_degrees", 0.0, 90.0, speed, Tween.TRANS_SINE, Tween.EASE_OUT)
	move.interpolate_property(sprite, "rotation_degrees", 0.0, -90.0, speed, Tween.TRANS_SINE, Tween.EASE_OUT)
	move.start()

func _on_Tween_tween_all_completed():
	queue_free()
