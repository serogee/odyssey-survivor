extends CharacterBody2D


@export var movement_speed = 20.0
@export var hp = 10
@export var knockback_recovery = 3.5
@export var experience = 1
@export var enemy_damage = 1
var knockback = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")
@onready var damage_indicator = preload("res://Player/GUI/damage_indicator.tscn")
@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer
@onready var snd_hit = $snd_hit
@onready var hitBox = $HitBox

var status_effects = {
	"poison": {
		"is_active": false,
		"damage": 1,
		"duration": 5.0,
		"timer": 0.0,
	},
	"freeze": {
		"is_active": false,
		"movement_speed": 50,
		"duration": 1.0,
		"timer": 0.0,
	},
	"slow": {
		"is_active": false,
		"movement_speed": 50,
		"duration": 5.0,
		"timer": 0.0,
	},
}
var death_anim = preload("res://Enemy/explosion.tscn")
var exp_gem = preload("res://Objects/experience_gem.tscn")

signal remove_from_array(object)

func _ready():
	anim.play("walk")
	hitBox.damage = enemy_damage
	hitBox.effect_type = ""

func _physics_process(_delta):
	knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
	var direction = global_position.direction_to(player.global_position)
	if status_effects["freeze"].is_active:
		velocity = Vector2.ZERO
	else:
		velocity = direction*movement_speed
		velocity += knockback
		move_and_slide()
	
	if direction.x > 0.1:
		sprite.flip_h = true
	elif direction.x < -0.1:
		sprite.flip_h = false
	
	for effect in status_effects.keys():
		if status_effects[effect].is_active:
			status_effects[effect].timer += _delta
		if status_effects[effect].timer >= status_effects[effect].duration:
			status_effects[effect].is_active = false
		if status_effects["poison"].is_active:
			_on_hurt_box_hurt(1, Vector2.ZERO, 0, null)
			

func death():
	emit_signal("remove_from_array",self)
	var enemy_death = death_anim.instantiate()
	enemy_death.scale = sprite.scale
	enemy_death.global_position = global_position
	get_parent().call_deferred("add_child",enemy_death)
	var new_gem = exp_gem.instantiate()
	new_gem.global_position = global_position
	new_gem.experience = experience
	loot_base.call_deferred("add_child",new_gem)
	queue_free()

func _on_hurt_box_hurt(damage, angle, knockback_amount, effect_type):
	hp -= damage
	knockback = angle * knockback_amount
	if effect_type == "freeze":
		status_effects["freeze"].is_active = true
		status_effects["freeze"].timer = 0.0
	if effect_type == "poison":
		status_effects["poison"].is_active = true
		status_effects["poison"].timer = 0.0
	spawn_dmgIndicator(damage)
	if hp <= 0:
		death()
	else:
		snd_hit.play()

func spawn_effect(EFFECT:PackedScene, effect_position: Vector2 = global_position) -> Node2D:
	if EFFECT:
		var effect_s = damage_indicator.instantiate()
		get_tree().current_scene.add_child(effect_s)
		effect_s.global_position = effect_position
		return effect_s
	return null

func spawn_dmgIndicator(damage : int):
	var indicator = spawn_effect(damage_indicator)
	if indicator:
		indicator.get_node("Label").text = str(damage)
