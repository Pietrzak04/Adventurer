extends KinematicBody2D

onready var anim_player = $AnimationPlayer
onready var timer = $Timer

export var fade_time = 3.0
var is_visible = true

func _on_Timer_timeout() -> void:
	if is_visible:
		is_visible = false
		anim_player.play("fade_out")
		timer.start(fade_time)
	else:
		is_visible = true
		anim_player.play("fade_in")
		timer.start(fade_time)
