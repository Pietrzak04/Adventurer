tool
extends Node2D

const IDLE_DURATION = 0.0
const UNIT_SIZE = 16

export var direction = Vector2.ZERO
export var distance = 8.0 

export var speed = 3.0

onready var platform = $Platform
onready var tween = $Tween

func _ready():
	_init_tween()

func _init_tween():
	var move_to = distance * direction * UNIT_SIZE
	var duration = move_to.length() / float(speed * UNIT_SIZE)
	tween.interpolate_property(platform, "position", Vector2.ZERO, move_to, duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT, IDLE_DURATION)
	tween.interpolate_property(platform, "position", move_to, Vector2.ZERO, duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT, duration + IDLE_DURATION)
	tween.start()
