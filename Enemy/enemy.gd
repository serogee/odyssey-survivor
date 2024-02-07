extends CharacterBody2D

@export var movement_speed = 20.0
@export var hp = 10
@export var knockback_recovery = 3.5
@export var experience = 1
@export var enemy_damage = 1
@export var is_level_boss = false
@export var is_roach = false
@export var is_miniboss = false
const FILE_BEGIN = "res://World/world"
var knockback = Vector2.ZERO
var rng = RandomNumberGenerator.new()
var crit = false
@onready var player = get_tree().get_first_node_in_group("player")
@onready var enemy_count = get_tree().get_first_node_in_group("enemy_spawner")
@onready var loot_base = get_tree().get_first_node_in_group("loot")
@onready var damage_indicator = preload("res://Player/GUI/damage_indicator.tscn")
@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer
@onready var snd_hit = $snd_hit
@onready var hitBox = $HitBox

var status_effects = {
	"poison": {
		"is_active": false,
		"damage": 10,
		"duration": 5.0,
		"timer": 0.0,
		"damage_interval": 1.0,
		"last_damage_time": 0.0
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
		"duration": 2.0,
		"timer": 0.0,
	},
}
var death_anim = preload("res://Enemy/explosion.tscn")
var exp_gem = preload("res://Objects/experience_gem.tscn")
var food = preload("res://Objects/food.tscn")
signal remove_from_array(object)

func _ready():
	anim.play("walk")
	hitBox.damage = enemy_damage
	hitBox.effect_type = ""

func _physics_process(_delta):
	knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
	var direction = global_position.direction_to(player.global_position)
	if is_miniboss != true:
		if status_effects["freeze"].is_active:
			velocity = Vector2.ZERO
		elif status_effects["slow"].is_active:
			var slowed_speed = movement_speed - status_effects["slow"].movement_speed
			velocity = direction*slowed_speed
			velocity += knockback
			move_and_slide()
		else:
			velocity = direction*movement_speed
			velocity += knockback
			move_and_slide()
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
			status_effects["poison"].last_damage_time += _delta
		if status_effects["poison"].last_damage_time >= status_effects["poison"].damage_interval:
			_on_hurt_box_hurt(status_effects["poison"].damage, Vector2.ZERO, 0, "")
			status_effects["poison"].last_damage_time = 0.0
func death():
	if is_level_boss == true:
		emit_signal("remove_from_array",self)
		var enemy_death = death_anim.instantiate()
		enemy_death.scale = sprite.scale
		enemy_death.global_position = global_position
		get_parent().call_deferred("add_child",enemy_death)
		var current_scene_file = get_tree().current_scene.scene_file_path
		var next_scene_number = current_scene_file.to_int() + 1
		var next_scene_path = FILE_BEGIN + str(next_scene_number) + ".tscn"
		get_tree().change_scene_to_file(next_scene_path)
		queue_free()
	else:
		emit_signal("remove_from_array",self)
		var enemy_death = death_anim.instantiate()
		enemy_death.scale = sprite.scale
		enemy_death.global_position = global_position
		get_parent().call_deferred("add_child",enemy_death)
		rng.randomize()
		if rng.randi_range(0, 100) > 1:
			var new_gem = exp_gem.instantiate()
			new_gem.global_position = global_position
			new_gem.experience = experience
			loot_base.call_deferred("add_child",new_gem)
		else:
			var new_food = food.instantiate()
			new_food.global_position = global_position
			loot_base.call_deferred("add_child",new_food)
		queue_free()

func _on_hurt_box_hurt(damage, angle, knockback_amount, effect_type):
	if rng.randi_range(0, 100) > 99:
		damage *= 2
		crit = true
	if is_roach == true:
		movement_speed = 120
	hp -= damage
	knockback = angle * knockback_amount
	if effect_type == "slow":
		status_effects["slow"].is_active = true
		status_effects["slow"].timer = 0.0
	if effect_type == "freeze":
		status_effects["freeze"].is_active = true
		status_effects["freeze"].timer = 0.0
	if effect_type == "poison":
		status_effects["poison"].is_active = true
		status_effects["poison"].timer = 0.0
	rng.randomize()
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
		if crit == true:
			indicator.get_node("Label").set("theme_override_font_sizes/font_size", 24)
			var red = Color(1.0,0.0,0.0,1.0)
			indicator.get_node("Label").set("theme_override_colors/font_color", red)
			indicator.get_node("Label").text = str(damage) + "!"
		else:
			indicator.get_node("Label").text = str(damage)
