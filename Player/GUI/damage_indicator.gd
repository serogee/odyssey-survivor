extends Node2D
var speed = 30.0
var friction = 15.0
var SHIFT_DIRECTION: Vector2 = Vector2.ZERO

@onready var label = $Label

func _ready():
	SHIFT_DIRECTION = Vector2(randf_range(-1, 1), randf_range(-1, 1))

func _process(delta):
	global_position += speed * SHIFT_DIRECTION * delta
	speed = max(speed - friction * delta, 0)
