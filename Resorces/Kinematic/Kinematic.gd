extends KinematicBody2D

class_name Kinematic

const FLOOR_NORMAL = Vector2.UP

export var gravity: = 3000.0
export var speed: = Vector2(300.0, 0.0)
var _velocity: = Vector2.ZERO
export (float, 0, 1.0) var friction = 0.2
export (float, 0, 1.0) var acceleration = 0.2
