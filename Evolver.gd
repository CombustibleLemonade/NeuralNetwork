extends Node

var path = "user://"

var generation_size = 50
var generation = 1
var survivor_count = 5

var creature_index = 0
var creatures = []

func _ready():
	randomize()
	set_process(true)

func _process(delta):
	inc_gen()

# Increment the generation by 1
func inc_gen():
	get_node("generation_count").set_text("generation: " + str(generation))
	
	if generation == 1:
		initialize()
	else:
		load_gen(generation)
	
	var creature_scores = []
	for c in creatures:
		creature_scores.push_back([test_creature(c), c])
	creature_scores.sort_custom(self, "compare")
	
	generation += 1
	
	creatures = []
	for i in range(survivor_count):
		creatures.push_back(creature_scores[i][1])
	for i in range(generation_size - survivor_count):
		var c = creature_scores[randi() % survivor_count][1]
		c = c.copy()
		c.mutate()
		
		creatures.push_back(c)
	
	var print_str = ""
	for s in creature_scores:
		print_str += str(s[0]) + " -- "
	print(creature_scores[0][0])
	
	get_node("graph").push_value(creature_scores[0][0])
	set_sine_graph(creature_scores[0][1])
	
	save_gen()

# For sorting
func compare(a, b):
	return a[0] > b[0]

# Draw the sine
func set_sine_graph(c):
	get_node("sine_approx").minimum = -1
	get_node("sine_approx").maximum = 2
	get_node("sine_approx").force_minimax = true
	
	get_node("sine").minimum = -1
	get_node("sine").maximum = 2
	get_node("sine").force_minimax = true
	
	get_node("sine_approx").values = []
	for i in range(63):
		var c_n = c.copy()
		c_n.set_inputs([i * 0.1])
		c_n.compute()
		get_node("sine_approx").push_value(c_n.get_outputs()[0])
	
	get_node("sine").color = Color(1, 0, 0, 1)
	get_node("sine").values = []
	for i in range(63):
		get_node("sine").push_value(formula(i * 0.1))

# Create initial set of creatures
func initialize():
	for i in range(generation_size):
		var c = preload("res://neuralNet.gd").new()
		c.initialize_new(1, 30, 1, 30)
		creatures.push_back(c)

# Load an already existing generation from the file system
func load_gen(gen):
	creatures = []
	
	var d = Directory.new()
	d.open(path + str(generation))
	
	for i in range(generation_size):
		var c = preload("res://neuralNet.gd").new()
		
		c.load_network(path + str(generation) + "/" + str(i) + ".txt")
		creatures.push_back(c)

func save_gen():
	for i in range(creatures.size()):
		creatures[i].save_network(path + str(generation) + "/" + str(i) + ".txt")

# To be overridden
func test_creature(c):
	pass

func formula(val):
	return val