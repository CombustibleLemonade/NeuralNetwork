extends Node2D

var has_balancer = true

var balancers = []
var use_balancers = false

var starting_force = 0

func _on_start_pressed():
	randomize()
	
	var start_gen = 1
	if get_node("gen_edit").get_text().is_valid_integer():
		start_gen = get_node("gen_edit").get_text().to_int()
	
	var b
	if start_gen != 1:
		use_balancers = true
		b = preload("Balancer.scn").instance()
		b.network.load_network("user://balance/" + str(start_gen) + ".cr")
		balancers.push_back(b)
	
	for i in range(8):
		for j in range(14):
			add_balancer(Vector2(100 + j * 250, 150 + i * 150))
	
	if start_gen != 1:
		balancers.erase(b)
	
	use_balancers = true
	
	n = start_gen
	
	set_process(true)

func _process(delta):
	get_node("score").set_text(str(get_top_score()))
	get_node("time_length").set_text(str(get_top_score() + starting_force))
	
	for b in balancers:
		b.extra_force = starting_force
	
	
	var avg_score = get_average_score()
	if avg_score > 30:
		starting_force += delta
	if avg_score < 15 && starting_force > 0:
		starting_force -= delta

var n = 1
func remove_old_balancer(b):
	if b == top_scorer:
		b.network.save("user://balance/" + str(n) + ".cr")
		n += 1
	balancers.erase(b)
	add_balancer(b.get_pos())

func add_balancer(pos):
	var b = preload("Balancer.scn").instance()
	b.extra_force = starting_force
	if use_balancers:
		balancers.sort_custom(self, "compare")
		b.network = balancers[0].network.copy()
		b.network.mutate()
	else:
		b.network.initialize_new(4, 10, 2, 30)
		top_scorer = b
	
	b.set_pos(pos)
	add_child(b)
	
	b.connect("exit_tree", self, "remove_old_balancer", [b])
	balancers.push_back(b)

func compare(a, b):
	return a.get_score() > b.get_score()


func _on_extra_force_value_changed( value ):
	for b in balancers:
		b.extra_force = value

var top_scorer

func get_top_score():
	var top_score = 0
	for b in balancers:
		if b.get_score() > top_score:
			top_scorer = b
		top_score = max(b.get_score(), top_score)
	
	return top_score

func get_average_score():
	var average_score = 0
	for b in balancers:
		average_score += b.get_score()
	average_score /= balancers.size()
	return average_score

