extends KinematicBody2D

var graphical_repr_class = preload("res://graphicalRepr.tscn")
var explosion_class = preload("res://explosion.tscn")

signal player_shooted

var can_shoot = true
var aim_start = null
var is_aiming = false
var can_deal_damage = false
var dir = Vector2()
var max_dir_speed = 600.0
var original_speed_decrease = 25.0
var speed_decrease = 25.0
var dir_speed = max_dir_speed

var max_fuel = 500.0
var fuel = max_fuel
var fuel_decrease = 50.0
var fuel_increase = 50.0

var energy = 0.0
var energy_increase = 80.0

var gravity_speed = 100.0
var gravity_motion = Vector2.DOWN * gravity_speed

enum STATE {IDLE, AIMING, ATTACK}
var current_state = STATE.IDLE

func set_state(state):
	match state:
		STATE.IDLE:
			current_state = STATE.IDLE
			can_shoot = true
			is_aiming = false
			can_deal_damage = false
		STATE.AIMING:
			current_state = STATE.AIMING
			can_shoot = false
			is_aiming = true
			aim_start = get_global_mouse_position()
			$fuelTimer.stop()
			$attackTimer.start()
		STATE.ATTACK:
			current_state = STATE.ATTACK
			is_aiming = false
			can_deal_damage = true
			can_shoot = true
			var input_dir = (aim_start - get_global_mouse_position()).normalized()
			var resulting_motion = (dir * dir_speed) + (input_dir * energy)
			dir = resulting_motion.normalized()
			dir_speed = resulting_motion.length()
			$speedDecreaseTimer.start()
			$fuelTimer.start()
			$attackTimer.stop()
			print("energy ", energy)
			energy = 0

func _ready():
	connect("player_shooted", get_parent(), "_on_player_shooted")

func get_graphical_repr():
	var graphical_repr = graphical_repr_class.instance()
	graphical_repr.texture = $sprite.texture
	graphical_repr.original = self
	graphical_repr.transform = transform
	return graphical_repr

func get_repr_rotation():
	return $sprite.rotation

func destroy():
	var explosion = explosion_class.instance()
	explosion.position = position
	get_parent().add_child(explosion)
	get_parent().deploy_new_player()
	queue_free()

func _input(event):
	# is idle ?
	if event.is_action_pressed("shoot") and can_shoot:
		set_state(STATE.AIMING)

	if event.is_action_released("shoot"):
		# attack state
		set_state(STATE.ATTACK)

func _process(_delta):
	update()
	if is_aiming:
		$sprite.rotation = (aim_start - get_global_mouse_position()).angle() + PI/2 - rotation

func _draw():
	if is_aiming:
		var start = aim_start - position
		var end = get_global_mouse_position() - position
		draw_line(start, end, Color(1, 1, 1), 2)
	

func _physics_process(delta):
	var dir_motion = dir * dir_speed
	var total_motion = dir_motion + gravity_motion
	var collision = move_and_collide(total_motion * delta)
	if collision:
		var prev_dir_speed = dir_speed
		dir = dir.bounce(collision.normal).normalized()
		dir_speed /= 2.5
		if collision.collider.has_method("handle_collision"):
			collision.collider.handle_collision(-dir, dir_speed)

		if collision.collider.has_method("deal_damage") and can_deal_damage:
			# refreshing state ?
			collision.collider.deal_damage(prev_dir_speed)
			set_state(STATE.IDLE)

func _on_speedDecreaseTimer_timeout():
	$speedDecreaseTimer.stop()
	dir_speed -= speed_decrease
	if dir_speed > 0:
		$speedDecreaseTimer.start()
	else:
		speed_decrease = original_speed_decrease
		dir = Vector2()
		can_deal_damage = false

func _on_attackTimer_timeout():
	fuel -= fuel_decrease
	energy += energy_increase
	get_node("../fuelBar").value = get_node("../fuelBar").max_value * (fuel/max_fuel)
	if fuel > 0:
		$attackTimer.start()
	else:
		$attackTimer.stop()

func _on_fuelTimer_timeout():
	fuel += fuel_increase
	get_node("../fuelBar").value = get_node("../fuelBar").max_value * (fuel/max_fuel)
	if fuel < max_fuel:
		$fuelTimer.start()
	else:
		$fuelTimer.stop()
