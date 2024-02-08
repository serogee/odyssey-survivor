class_name Player extends CharacterBody2D

var movement_speed = 75
var hp = 100
var maxhp = 100
var last_movement = Vector2.UP
var time = 0
var effect_type = ""
var experience = 0
var experience_level = 1
var collected_experience = 0
var score = 0
#Attacks
var iceSpear = preload("res://Player/Attack/ice_spear.tscn")
var tornado = preload("res://Player/Attack/tornado.tscn")
var javelin = preload("res://Player/Attack/javelin.tscn")
var poisonSpear = preload("res://Player/Attack/poison_spear.tscn")
var spray = preload("res://Player/Attack/bed.tscn")
var soap = preload("res://Player/Attack/soap.tscn")

#AttackNodes
@onready var iceSpearTimer = get_node("%IceSpearTimer")
@onready var iceSpearAttackTimer = get_node("%IceSpearAttackTimer")
@onready var PoisonSpearTimer = get_node("%PoisonSpearTimer")
@onready var PoisonSpearAttackTimer = get_node("%PoisonSpearAttackTimer")
@onready var tornadoTimer = get_node("%TornadoTimer")
@onready var tornadoAttackTimer = get_node("%TornadoAttackTimer")
@onready var javelinBase = get_node("%JavelinBase")
@onready var SprayTimer = get_node("%SprayTimer")
@onready var SprayAttackTimer = get_node("%SprayAttackTimer")
@onready var SoapTimer = get_node("%SoapTimer")
@onready var SoapAttackTimer = get_node("%SoapAttackTimer")
#UPGRADES
var collected_upgrades = []
var upgrade_options = []
var armor = 0
var speed = 0
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0

#IceSpear
var icespear_ammo = 0
var icespear_baseammo = 0
var icespear_attackspeed = 1.5
var icespear_level = 0


#Poisonspear
var poison_ammo = 0
var poison_baseammo = 0
var poison_attackspeed = 1.5
var poison_level = 0

#Tornado
var tornado_ammo = 0
var tornado_baseammo = 0
var tornado_attackspeed = 3
var tornado_level = 0

#Javelin
var javelin_ammo = 0
var javelin_level = 0

#spray
var spray_ammo = 0
var spray_baseammo = 1
var spray_attackspeed = 1.8
var spray_level = 0

#soap
var soap_ammo = 0
var soap_baseammo = 1
var soap_attackspeed = 5
var soap_level = 0

#Enemy Related
var enemy_close = []

@export var map: TileMap
@export var input_enabled = true
@onready var sprite = $AnimatedSprite2D
@onready var walkTimer = get_node("%walkTimer")

#GUI
@onready var expBar = get_node("%ExperienceBar")
@onready var lblLevel = get_node("%lbl_level")
@onready var lblScore = get_node("%lbl_score")
@onready var levelPanel = get_node("%LevelUp")
@onready var upgradeOptions = get_node("%UpgradeOptions")
@onready var itemOptions = preload("res://Utility/item_option.tscn")
@onready var sndLevelUp = get_node("%snd_levelup")
@onready var healthBar = get_node("%HealthBar")
@onready var hp_level = get_node("%hp_level")
@onready var lblTimer = get_node("%lblTimer")
@onready var collectedWeapons = get_node("%CollectedWeapons")
@onready var collectedUpgrades = get_node("%CollectedUpgrades")
@onready var itemContainer = preload("res://Player/GUI/item_container.tscn")
@onready var deathPanel = get_node("%DeathPanel")
@onready var lblResult = get_node("%lbl_Result")
@onready var sndVictory = get_node("%snd_victory")
@onready var sndLose = get_node("%snd_lose")

#Signal
signal playerdeath

func _ready():
	upgrade_character("icespear1")
	attack()
	set_expbar(experience, calculate_experiencecap())
	var tile_map = get_parent().get_node("TileMap")
	var mapRect = tile_map.get_used_rect()
	var tileSize = tile_map.cell_quadrant_size
	var worldSizeInPixels = mapRect.size * tileSize
	$Camera2D.limit_right = worldSizeInPixels.x
	$Camera2D.limit_bottom = worldSizeInPixels.y
	_on_hurt_box_hurt(0,0,0,0)
func _physics_process(delta):
	movement()

func movement():
	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var mov = Vector2(x_mov,y_mov)
	if mov.x > 0:
		sprite.flip_h = true
	elif mov.x < 0:
		sprite.flip_h = false

	if mov == Vector2.ZERO:
		last_movement = mov
		sprite.play("idle")
	else:
		sprite.play("walk")
		
	velocity = mov.normalized()*movement_speed
	move_and_slide()

func attack():
	if poison_level > 0:
		PoisonSpearTimer.wait_time = poison_attackspeed * (1-spell_cooldown)
		if PoisonSpearTimer.is_stopped():
			PoisonSpearTimer.start()
	if icespear_level > 0:
		iceSpearTimer.wait_time = icespear_attackspeed * (1-spell_cooldown)
		if iceSpearTimer.is_stopped():
			iceSpearTimer.start()
	if tornado_level > 0:
		tornadoTimer.wait_time = tornado_attackspeed * (1-spell_cooldown)
		if tornadoTimer.is_stopped():
			tornadoTimer.start()
	if javelin_level > 0:
		spawn_javelin()
	if spray_level > 0:
		SprayTimer.wait_time = spray_attackspeed * (1-spell_cooldown)
		if SprayTimer.is_stopped():
			SprayTimer.start()
	if soap_level > 0:
		SoapTimer.wait_time = soap_attackspeed * (1-spell_cooldown)
		if SoapTimer.is_stopped():
			SoapTimer.start()

func _on_hurt_box_hurt(damage, _angle, _knockback, _effect_type):
	damage = int(clamp(damage-(damage*(0.1*armor)), 0.0, 999.0))
	if damage < 0:
		damage = 0
	hp -= damage
	hp_level.text = str("HP:", hp,"/", maxhp)
	healthBar.max_value = maxhp
	healthBar.value = hp
	if hp <= 0:
		death()

func _on_poison_spear_timer_timeout():
	poison_ammo += poison_baseammo + additional_attacks
	PoisonSpearAttackTimer.start()


func _on_poison_spear_attack_timer_timeout():
	if poison_ammo > 0:
		var poison_attack = poisonSpear.instantiate()
		poison_attack.position = position
		poison_attack.target = get_random_target()
		poison_attack.level = poison_level
		add_child(poison_attack)
		poison_ammo -= 1
		if poison_ammo > 0:
			PoisonSpearAttackTimer.start()
		else:
			PoisonSpearAttackTimer.stop()
			
func _on_ice_spear_timer_timeout():
	icespear_ammo += icespear_baseammo + additional_attacks
	iceSpearAttackTimer.start()


func _on_ice_spear_attack_timer_timeout():
	if icespear_ammo > 0:
		var icespear_attack = iceSpear.instantiate()
		icespear_attack.position = position
		icespear_attack.target = get_random_target()
		icespear_attack.level = icespear_level
		add_child(icespear_attack)
		icespear_ammo -= 1
		if icespear_ammo > 0:
			iceSpearAttackTimer.start()
		else:
			iceSpearAttackTimer.stop()
			
func _on_tornado_timer_timeout():
	tornado_ammo += tornado_baseammo + additional_attacks
	tornadoAttackTimer.start()

func _on_tornado_attack_timer_timeout():
	if tornado_ammo > 0:
		var tornado_attack = tornado.instantiate()
		tornado_attack.position = position
		tornado_attack.last_movement = last_movement
		tornado_attack.level = tornado_level
		add_child(tornado_attack)
		tornado_ammo -= 1
		if tornado_ammo > 0:
			tornadoAttackTimer.start()
		else:
			tornadoAttackTimer.stop()

func spawn_javelin():
	var get_javelin_total = javelinBase.get_child_count()
	var calc_spawns = (javelin_ammo + additional_attacks) - get_javelin_total
	while calc_spawns > 0:
		var javelin_spawn = javelin.instantiate()
		javelin_spawn.global_position = global_position
		javelinBase.add_child(javelin_spawn)
		calc_spawns -= 1
	#Upgrade Javelin
	var get_javelins = javelinBase.get_children()
	for i in get_javelins:
		if i.has_method("update_javelin"):
			i.update_javelin()
func _on_spray_timer_timeout():
	spray_ammo += spray_baseammo + additional_attacks
	SprayAttackTimer.start()

func _on_spray_attack_timer_timeout():
	if spray_ammo > 0:
		var spray_attack = spray.instantiate() 
		spray_attack.position
		spray_attack.target = get_random_target()
		spray_attack.level = spray_level
		add_child(spray_attack)
		spray_ammo -= 1
		if spray_ammo > 0:
			SprayAttackTimer.start()
		else:
			SprayAttackTimer.stop()

func _on_soap_timer_timeout():
	soap_ammo += soap_baseammo + additional_attacks
	SoapAttackTimer.start()


func _on_soap_attack_timer_timeout():
	pass
	if soap_ammo > 0:
		var soap_attack = soap.instantiate() 
		soap_attack.position = position
		soap_attack.target = get_random_target()
		soap_attack.level - soap_level
		add_child(soap_attack)
		soap_ammo -= 1
		if soap_ammo > 0:
			SoapAttackTimer.start()
		else:
			SoapAttackTimer.stop()

func sort_closest(a, b):
	return (global_position.distance_to(a.global_position)) < (global_position.distance_to(b.global_position))
	
func get_random_target():
	if enemy_close.size() > 0:
		enemy_close.sort_custom(sort_closest)
		return enemy_close.front().global_position
	else:
		return Vector2.UP


func _on_enemy_detection_area_body_entered(body):
	if not enemy_close.has(body):
		enemy_close.append(body)

func _on_enemy_detection_area_body_exited(body):
	if enemy_close.has(body):
		enemy_close.erase(body)


func _on_grab_area_area_entered(area):
	if area.is_in_group("loot"):
		area.target = self

func _on_collect_area_area_entered(area):
	if area.is_in_group("loot") and area.is_in_group("exp"):
		var gem_exp = area.collect()
		calculate_experience(gem_exp)
		lblScore.text = str("Score: ", score)
	elif area.is_in_group("loot") and area.is_in_group("food"):
		var food = area.collect()
		var hpfood = 20
		hp += hpfood
		if hp >= maxhp:
			hp += maxhp - hp 
			hp_level.text = str("HP:", hp,"/", maxhp)
			healthBar.max_value = maxhp
			healthBar.value = hp
		else:
			hp_level.text = str("HP:", hp,"/", maxhp)
			healthBar.max_value = maxhp
			healthBar.value = hp
func calculate_experience(gem_exp):
	var exp_required = calculate_experiencecap()
	collected_experience += gem_exp
	score += collected_experience
	if experience + collected_experience >= exp_required: #level up
		collected_experience -= exp_required-experience
		experience_level += 1
		experience = 0
		exp_required = calculate_experiencecap()
		levelup()
	else:
		experience += collected_experience
		collected_experience = 0
	
	set_expbar(experience, exp_required)

func calculate_experiencecap():
	var exp_cap = experience_level
	if experience_level < 20:
		exp_cap = experience_level*5
	elif experience_level < 40:
		exp_cap + 95 * (experience_level-19)*8
	else:
		exp_cap = 255 + (experience_level-39)*12
		
	return exp_cap
		
func set_expbar(set_value = 1, set_max_value = 100):
	expBar.value = set_value
	expBar.max_value = set_max_value

func levelup():
	sndLevelUp.play()
	lblLevel.text = str("Level: ", experience_level)
	var tween = levelPanel.create_tween()
	tween.tween_property(levelPanel,"position",Vector2(168,95),0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	levelPanel.visible = true
	var options = 0
	var optionsmax = 3
	while options < optionsmax:
		var option_choice = itemOptions.instantiate()
		option_choice.item = get_random_item()
		upgradeOptions.add_child(option_choice)
		options += 1
	get_tree().paused = true

func upgrade_character(upgrade):
	match upgrade:
		"icespear1":
			icespear_level = 1
			icespear_baseammo += 1
		"icespear2":
			icespear_level = 2
			icespear_baseammo += 1
		"icespear3":
			icespear_level = 3
		"icespear4":
			icespear_level = 4
			icespear_baseammo += 2
		"poisonspear1":
			poison_level = 1
			poison_baseammo += 1
		"poisonspear2":
			poison_level = 2
			poison_baseammo += 1
		"poisonspear3":
			poison_level = 3
		"poisonspear4":
			poison_level = 4
			poison_baseammo += 2
		"tornado1":
			tornado_level = 1
			tornado_baseammo += 1
		"tornado2":
			tornado_level = 2
			tornado_baseammo += 1
		"tornado3":
			tornado_level = 3
			tornado_attackspeed -= 0.5
		"tornado4":
			tornado_level = 4
		"javelin1":
			javelin_level = 1
			javelin_ammo = 1
		"javelin2":
			javelin_level = 2
		"javelin3":
			javelin_level = 3
		"javelin4":
			javelin_level = 4
		"armor1","armor2","armor3","armor4":
			armor += 1
		"speed1","speed2","spee
		d3","speed4":
			movement_speed += 20.0
		"tome1","tome2","tome3","tome4":
			spell_size += 0.10
		"scroll1","scroll2","scroll3","scroll4":
			spell_cooldown += 0.05
		"ring1":
			additional_attacks += 1
		"spray1":
			spray_level = 1
		"spray2":
			spray_level = 2
			spray_baseammo += 1
		"spray3":
			spray_level = 3
		"spray4":
			spray_level = 4
		"soap1":
			soap_level = 1
		"soap2":
			soap_level = 2
			soap_baseammo += 1
		"soap3":
			soap_level = 3
		"soap4":
			soap_level = 4
		"food":
			hp += 20
			hp = clamp(hp,0,maxhp)
	adjust_gui_collection(upgrade)
	attack()
	var option_children = upgradeOptions.get_children()
	for i in option_children:
		i.queue_free()
	upgrade_options.clear()
	collected_upgrades.append(upgrade)
	levelPanel.visible = false
	levelPanel.position = Vector2(500,200)
	get_tree().paused = false
	calculate_experience(0)
	
func get_random_item():
	var dblist = []
	for i in UpgradeDb.UPGRADES:
		if i in collected_upgrades: #Find already collected upgrades
			pass
		elif i in upgrade_options: #If the upgrade is already an option
			pass
		elif UpgradeDb.UPGRADES[i]["type"] == "item": #Don't pick food
			pass
		elif UpgradeDb.UPGRADES[i]["prerequisite"].size() > 0: #Check for PreRequisites
			var to_add = true
			for n in UpgradeDb.UPGRADES[i]["prerequisite"]:
				if not n in collected_upgrades:
					to_add = false
			if to_add:
				dblist.append(i)
		else:
			dblist.append(i)
	if dblist.size() > 0:
		var randomitem = dblist.pick_random()
		upgrade_options.append(randomitem)
		return randomitem
	else:
		return null

func change_time(argtime = 0):
	time = argtime
	var get_m = int(time/60.0)
	var get_s = time % 60
	if get_m < 10:
		get_m = str(0,get_m)
	if get_s < 10:
		get_s = str(0,get_s)
	lblTimer.text = str(get_m,":",get_s)

func adjust_gui_collection(upgrade):
	var get_upgraded_displayname = UpgradeDb.UPGRADES[upgrade]["displayname"]
	var get_type = UpgradeDb.UPGRADES[upgrade]["type"]
	if get_type != "item":
		var get_collected_displaynames = []
		for i in collected_upgrades:
			get_collected_displaynames.append(UpgradeDb.UPGRADES[i]["displayname"])
		if not get_upgraded_displayname in get_collected_displaynames:
			var new_item = itemContainer.instantiate()
			new_item.upgrade = upgrade
			match get_type:
				"weapon":
					collectedWeapons.add_child(new_item)
				"upgrade":
					collectedUpgrades.add_child(new_item)

func death():
	deathPanel.visible = true
	emit_signal("playerdeath")
	get_tree().paused = true
	var tween = deathPanel.create_tween()
	tween.tween_property(deathPanel,"position",Vector2(220,50),3.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()
	if time >= 300:
		lblResult.text = "You Win"
		sndVictory.play()
	else:
		lblResult.text = "You Lose"
		sndLose.play()

func _on_btn_menu_click_end():
	get_tree().paused = false
	var _level = get_tree().change_scene_to_file("res://TitleScreen/menu.tscn")
