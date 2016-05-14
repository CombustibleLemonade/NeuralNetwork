#extends "neuralNet.gd"
extends Node2D

var network = preload("neuralNet.gd").new()
var time = 0
var extra_force = 0

func _ready():
	set_fixed_process(true)

func _fixed_process(delta):
	network.add_time(1)
	
	time += delta
	if time < 0.2:
		get_node("RigidBody2D").set_angular_velocity(randf() * 30 - 15)
	
	network.set_inputs([
		get_node("RigidBody2D").get_pos().x, 
		get_node("KinematicBody2D").get_pos().x, 
		get_node("RigidBody2D").get_angular_velocity(),
		get_node("RigidBody2D").get_linear_velocity().x])
	
	network.compute()
	var o = network.get_outputs()
	
	get_node("KinematicBody2D").move(Vector2(o[0] - o[1], 0))
	
	if get_node("RigidBody2D").get_pos().y > 0:
		die()
	if abs(get_node("KinematicBody2D").get_pos().x) > 500:
		die()
	
	get_node("RigidBody2D").apply_impulse(Vector2(), Vector2((randf()-0.5) * (time + extra_force), 0) )
	
	var rounded_time = floor(time * 100)/100
	get_node("time").set_text("elapsed time: " + str(rounded_time))

func die():
	queue_free()

func get_score():
	return time # - network.get_all_axons().size() - network.get_all_neurons().size()

func copy():
	var b = preload("Balancer.scn").instance()
	b.parse_json(to_json())
	return b

func set_winner(win):
	if win:
		get_node("RigidBody2D/Poly").set_color(Color(1, 1, 0))
	else:
		get_node("RigidBody2D/Poly").set_color(Color(1, 1, 1))
