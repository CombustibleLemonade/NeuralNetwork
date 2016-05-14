var neurons = {}

var neuron_types = [InputNeuron, ProcessNeuron, SineNeuron, OutputNeuron]
var input_neuron_types = [InputNeuron]
var process_neuron_types = [ProcessNeuron, SineNeuron]
var output_neuron_types = [OutputNeuron]
var axon_types = [Axon]

var fireing_neurons = []

# Base neuron class
class Neuron:
	var network
	
	var axons = []
	var dendrites = []
	
	var value = 0.0
	
	var index = 0
	
	func add_time(d):
		value *= pow(0.5, d)
	
	# "virtual" functions
	func add_value(v):
		pass
	
	func execute():
		pass
	
	func parse_json(j):
		var n = network.get_ref()
		
		n.neurons[network.get_ref().neuron2hash[get_script()]].push_back(self)

# Input neuron class
class InputNeuron:
	extends Neuron
	
	func add_value(v):
		value = v
	
	func to_json():
		return [network.get_ref().neuron2hash[get_script()], index]
	
	func parse_json(j):
		index = j[1]
		.parse_json(j)
	
	func execute():
		for a in axons:
			a.strength = value
			a.execute()
	
	func add_time(d):
		pass

# Process neuron class
class ProcessNeuron:
	extends Neuron
	
	var treshold = 1.0
	var down = -1.0
	
	func execute():
		for a in axons:
			a.execute()
		value = down
	
	func add_value(v):
		if value > down:
			value += v
		if value > treshold:
			network.get_ref().fireing_neurons.push_back(self)
	
	func to_json():
		return [network.get_ref().neuron2hash[get_script()], 
			index, treshold, down]
	
	func parse_json(j):
		index = j[1]
		.parse_json(j)

# Neuron that returns the sine of its input
class SineNeuron:
	extends ProcessNeuron
	
	var can_add = true
	
	func add_value(v):
		if can_add:
			value = v
			network.get_ref().fireing_neurons.push_back(self)
	
	func execute():
		var sin_val = sin(value)
		
		for a in axons:
			a.strength = sin_val
			a.execute()
		
		can_add = false

class CosineNeuron:
	extends SineNeuron
	
	func execute():
		var cos_val = cos(value)
		
		for a in axons:
			a.strength = cos_val
			a.execute()
		
		can_add = false

# Output neuron class
class OutputNeuron:
	extends Neuron
	
	func add_value(v):
		value += v
	
	func to_json():
		return [network.get_ref().neuron2hash[get_script()], index]
	
	func parse_json(j):
		index = j[1]
		.parse_json(j)
	
	func execute():
		pass

# Axon class which conects neurons
class Axon:
	var network
	
	var from
	var to
	
	var strength = 0.3
	var multiplier = 0.5
	
	func execute():
		to.get_ref().add_value(strength * multiplier)
	
	func to_json():
		return [strength, multiplier, 
			network.get_ref().neuron2hash[from.get_ref().get_script()], from.get_ref().index, 
			network.get_ref().neuron2hash[to.get_ref().get_script()], to.get_ref().index]
	
	func parse_json(j):
		strength = j[0]
		multiplier = j[1]
		from = weakref(network.get_ref().get_neuron(j[2], j[3]))
		to = weakref(network.get_ref().get_neuron(j[4], j[5]))
	
	func mutate():
		strength += pow(randf(), 3) * (randf() - 0.5)
		multiplier += pow(randf(), 3) * (randf() - 0.5)

func _init():
	set_neuron2hash()
	set_hash2neuron()
	
	for i in neuron_types:
		neurons[neuron2hash[i]] = []

# Create a network with in input neurons, p process neurons, o output neurons, and a axons
func initialize_new(inp, pro, out, ax):
	for i in range(inp):
		create_new_neuron(input_neuron_types[randi() % input_neuron_types.size()])
	for i in range(pro):
		create_new_neuron(process_neuron_types[randi() % process_neuron_types.size()])
	for i in range(out):
		create_new_neuron(output_neuron_types[randi() % output_neuron_types.size()])
	
	for i in range(ax):
		add_random_axon()

# Creates a new neuron of type type
func create_new_neuron(type):
	var neuron = type.new()
	neuron.network = weakref(self)
	neuron.index = neurons[neuron2hash[type]].size()
	neurons[neuron2hash[type]].push_back(neuron)
	
	return neuron

# Convert to json
func to_json():
	var axons = []
	for n in get_all_neurons():
		for a in n.axons:
			var axon = a.to_json()
			axons.push_back(axon)
	
	var neuron_arr = []
	for n in get_all_neurons():
		var neuron = n.to_json()
		neuron_arr.push_back(neuron)
	
	return [neuron_arr, axons]

# Parse json
func parse_json(j):
	var neuron_arr = j[0]
	
	for n in neuron_arr:
		neuron_parse_json(n)
	
	var axons = j[1]
	for a in axons:
		axon_parse_json(a)

# Parse json of a single neuron
func neuron_parse_json(n):
	var neuron = hash2neuron[n[0]].new()
	neuron.network = weakref(self)
	neuron.parse_json(n)

# Parse json of a single axon
func axon_parse_json(a):
	var axon = Axon.new()
	axon.network = weakref(self)
	axon.parse_json(a)
	
	axon.from.get_ref().axons.push_back(axon)
	axon.to.get_ref().dendrites.push_back(axon)

# Gets a neuron
func get_neuron(type, index):
	return neurons[type][index]

# Load a neural network
func load_network(path):
	var save = File.new()
	
	if not save.file_exists(path):
		return #Error
	
	save.open(path, File.READ)
	var all = save.get_var()
	
	parse_json(all)

# Save the network
func save(path):
	var j = to_json()
	
	var dir = Directory.new()
	dir.open("user://")
	if !dir.dir_exists(path.get_base_dir()):
		dir.make_dir(path.get_base_dir())
	
	var save = File.new()
	save.open(path, File.WRITE)
	save.store_var(j)

# Copies the neural network
func copy():
	var new_net = get_script().new()
	
	var j = to_json()
	new_net.parse_json(j)
	
	return new_net

# Process the neurons into json-compatible stuff
func save_neurons(arr):
	var neurons = []
	
	for i in arr:
		var n = []
		
		for j in i.axons:
			n.push_back([j.to.type, j.to.index])
	
	return neurons

# Set the inputs of the neural network
func set_inputs(inp):
	for i in range(min(inp.size(), neurons[neuron2hash[InputNeuron]].size() )):
		# TODO: input neuron order
		neurons[neuron2hash[InputNeuron]][i].add_value(inp[i])
	
	compute()

# Computes a propagation of the network
func compute():
	# TODO: multiple input neuron types
	for i in neurons[neuron2hash[InputNeuron]]:
		i.execute()
	
	while fireing_neurons.size() > 0:
		for i in fireing_neurons:
			fireing_neurons.erase(i)
			if i extends Neuron:
				i.execute()

# Get the outputs of the neural network
func get_outputs():
	var out = []
	
	# TODO: multiple output neuron types
	for i in neurons[neuron2hash[OutputNeuron]]:
		out.push_back(i.value)
	
	return out

func add_time(d):
	for i in get_all_neurons():
		i.add_time(d)

# TODO: add random mutations
func mutate():
	if randi() % 2 == 0:
		add_random_axon()
	if randi() % 2 == 0 && get_all_axons().size() > 1:
		remove_random_axon()
	if randi() % 2 == 0:
		mutate_random_axon()
	if randi() % 2 == 0:
		add_random_neuron()
	if randi() % 2 == 0 && get_all_neurons_of_types(process_neuron_types).size() > 1:
		remove_random_neuron()
	
	# Broken
	#if randi() % 2 == 0:
	#	substitute_random_neuron()
	
	if randi() % 2 == 0:
		mutate()
	
	for i in neurons.keys():
		for j in range(neurons[i].size()):
			neurons[i][j].index = j

# Add a random axon between two neurons
func add_random_axon():
	var from_neurons = get_all_from_neurons()
	var to_neurons = get_all_to_neurons()
	
	var from = from_neurons[randi() % from_neurons.size()]
	var to = to_neurons[randi() % to_neurons.size()]
	
	add_axon(from, to)

# Adds an axon from from, to to
func add_axon(from, to):
	var a = Axon.new()
	a.network = weakref(self)
	
	a.to = weakref(to)
	a.from = weakref(from)
	
	a.strength = randf()
	a.multiplier = randf()
	
	from.axons.push_back(a)
	to.dendrites.push_back(a)

# Removes a random axon
func remove_random_axon():
	var axons = get_all_axons()
	var a = axons[randi() % axons.size()]
	
	a.from.get_ref().axons.erase(a)
	a.to.get_ref().dendrites.erase(a)

# Change the strength of a random axon by a random amount
func mutate_random_axon():
	var axons = get_all_axons()
	
	var axon = axons[randi() % axons.size()]
	
	axon.mutate()

# Returns all neurons
func get_all_neurons():
	return get_all_neurons_of_types(neuron_types)

# Returns all input neurons
func get_all_input_neurons():
	return get_all_neurons_of_types(input_neuron_types)

# Returns all process neurons
func get_all_process_neurons():
	return get_all_neurons_of_types(process_neuron_types)

# Returns all output neurons
func get_all_output_neurons():
	return get_all_neurons_of_types(output_neuron_types)

# Returns all neurons axons can be from
func get_all_from_neurons():
	return get_all_neurons_of_types(input_neuron_types + process_neuron_types)

# Returns all neurons axons can go to
func get_all_to_neurons():
	return get_all_neurons_of_types(process_neuron_types + output_neuron_types)

# Gets all neurons of type types
func get_all_neurons_of_types(types):
	var all_neurons = []
	for t in types:
		all_neurons += neurons[neuron2hash[t]]
	return all_neurons

# Returns all axons
func get_all_axons():
	var axons = []
	for n in get_all_neurons():
		for a in n.axons:
			axons.push_back(a)
	
	return axons

# Add a random neuron
func add_random_neuron():
	var n = create_new_neuron(process_neuron_types[randi() % process_neuron_types.size()])
	
	var from_neurons = get_all_from_neurons()
	var to_neurons = get_all_to_neurons()
	
	for i in range(randi() % 3 + 1):
		var from = from_neurons[randi() % from_neurons.size()]
		var to = n
		
		add_axon(from, to)
	
	for i in range(randi() % 3 + 1):
		var from = n
		var to = to_neurons[randi() % to_neurons.size()]
		add_axon(from, to)

# Substitute a neuron into an existing axon
func substitute_random_neuron():
	var n = create_new_neuron(process_neuron_types[randi() % process_neuron_types.size()])
	
	var all_axons = get_all_axons()
	var ax = all_axons[randi() % all_axons.size()]
	
	var from = ax.from.get_ref()
	var to = ax.to.get_ref()
	
	ax.to = weakref(n)
	n.dendrites.push_back(ax)
	
	var out_axon = Axon.new()
	out_axon.from = weakref(n)
	out_axon.to = weakref(to)
	
	n.axons.push_back(out_axon)
	to.dendrites.push_back(out_axon)

# Remove a random neuron
func remove_random_neuron():
	var all = get_all_neurons_of_types(process_neuron_types)
	var n = all[randi() % all.size()]
	
	if n.dendrites.size() + n.axons.size() >= get_all_axons().size() - 5:
		return
	
	for a in n.dendrites:
		a.from.get_ref().axons.erase(a)
	for a in n.axons:
		a.to.get_ref().dendrites.erase(a)
	
	for t in neurons.keys():
		neurons[t].erase(n)

# Sets the neuron to hash dictionary
func set_neuron2hash():
	for i in range(neuron_types.size()):
		neuron2hash[neuron_types[i]] = i

# Sets the hash to neuron dictionary
func set_hash2neuron():
	for t in neuron_types:
		hash2neuron[neuron2hash[t]] = t

var neuron2hash = {}
var hash2neuron = {}
