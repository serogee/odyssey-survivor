 #dual alcohol spray
extends Area2D

var level = 1
var hp = 1
var speed = 100
var damage = 5
var knockback_amount = 100
var attack_size = 1.0
var effect_type = ""

var target = Vector2.ZERO
var angle = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
signal remove_from_array(object)

func _ready():
	angle = global_position.direction_to(target)
	rotation = angle.angle() + deg_to_rad(0)
	match level:
		1:
			hp = 5
			speed = 200
			damage = 2
			knockback_amount = 90
			attack_size = 1.0 * (1 + player.spell_size)
		2:
			hp = 5
			speed = 200
			damage = 2
			knockback_amount = 90
			attack_size = 1.0 * (1 + player.spell_size)
		3:
			hp = 7
			speed = 200
			damage = 3
			knockback_amount = 90
			attack_size = 1.0 * (1 + player.spell_size)
		4:
			hp = 8
			speed = 200
			damage = 4
			knockback_amount = 90
			attack_size = 1.0 * (1 + player.spell_size)

	
	var tween = create_tween()
	tween.tween_property(self,"scale",Vector2(1.9,1.9)*attack_size,1).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()

func _physics_process(delta):
	position += angle*speed*delta

func enemy_hit(charge = 1):
	hp -= charge
	if hp <= 0:
		die()

func _on_timer_timeout():
	die()

func die():
	emit_signal("remove_from_array",self)
	queue_free()
