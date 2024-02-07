extends Node2D


@export var spawns: Array[Spawn_info] = []

@onready var player = get_tree().get_first_node_in_group("player")

@export var time = 0

signal changetime(time)

var max_enemies = 100

func _ready():
	connect("changetime",Callable(player,"change_time"))
	get_spawn_area()

func _on_timer_timeout():
	time += 1
	var enemy_spawns = spawns
	

	if enemy_spawns.size() < max_enemies:
		for i in enemy_spawns:
			if time >= i.time_start and time <= i.time_end:
				if i.spawn_delay_counter < i.enemy_spawn_delay:
					i.spawn_delay_counter += 1
				else:
					i.spawn_delay_counter = 0
					var new_enemy = i.enemy
					var counter = 0
					while  counter < i.enemy_num:
						var enemy_spawn = new_enemy.instantiate()
						enemy_spawn.global_position = get_random_position()
						add_child(enemy_spawn)
						counter += 1
	emit_signal("changetime",time)

var spawn_area = null

func get_spawn_area():
	if spawn_area == null:
		var spawn_area_reference = $"../SpawnArea"
		spawn_area = Rect2(get_parent().to_global(spawn_area_reference.position), get_parent().to_global(spawn_area_reference.size))
	return spawn_area

func get_random_position():
	var vpr = get_viewport_rect().size * randf_range(1.1,1.4)
	var top_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y - vpr.y/2)
	var top_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y - vpr.y/2)
	var bottom_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y + vpr.y/2)
	var bottom_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y + vpr.y/2)
	var pos_side = ["up","down","right","left"].pick_random()
	var spawn_pos1 = Vector2.ZERO
	var spawn_pos2 = Vector2.ZERO
	
	match pos_side:
		"up":
			spawn_pos1 = top_left
			spawn_pos2 = top_right
		"down":
			spawn_pos1 = bottom_left
			spawn_pos2 = bottom_right
		"right":
			spawn_pos1 = top_right
			spawn_pos2 = bottom_right
		"left":
			spawn_pos1 = top_left
			spawn_pos2 = bottom_left
	# print("Player: ", player.global_position)
	spawn_area = get_spawn_area()
	if spawn_area == null: 
		pass
		# print("Spawn area is null")
	else:
		# print(spawn_area.position, " ", spawn_area.end)
		if spawn_pos1.x < spawn_area.position.x: # If too far to the left
			# print("Too far left")
			spawn_pos1.x = spawn_area.position.x
		if spawn_pos1.x > spawn_area.end.x: # Too far to the right
			# print("Too far right")
			spawn_pos1.x = spawn_area.end.x
		if spawn_pos1.y < spawn_area.position.y: # Too far above
			# print("Too far up")
			spawn_pos1.y = spawn_area.position.y
		if spawn_pos1.y > spawn_area.end.y: # Too far below
			# print("Too far down")
			spawn_pos1.y = spawn_area.end.y

		if spawn_pos2.x < spawn_area.position.x: # If too far to the left
			# print("Too far left")
			spawn_pos2.x = spawn_area.position.x
		if spawn_pos2.x > spawn_area.end.x: # Too far to the right
			# print("Too far right")
			spawn_pos2.x = spawn_area.end.x
		if spawn_pos2.y < spawn_area.position.y: # Too far above
			# print("Too far up")
			spawn_pos2.y = spawn_area.position.y
		if spawn_pos2.y > spawn_area.end.y: # Too far below
			# print("Too far down")
			spawn_pos2.y = spawn_area.end.y

	# print(spawn_pos1, spawn_pos2)
	var x_spawn = randf_range(spawn_pos1.x, spawn_pos2.x)
	var y_spawn = randf_range(spawn_pos1.y,spawn_pos2.y)
	var spawn = Vector2(x_spawn,y_spawn)
	# print("Spawn: ", spawn)
	return spawn
