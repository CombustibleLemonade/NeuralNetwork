extends "Evolver.gd"

var i = 1

func test_creature(c):
	i += 1
	
	randomize()
	
	var out = - 0.0001 * pow(c.get_all_axons().size(), 4)
	for i in range(20):
		var val = (randf() + i)
		c = c.copy()
		
		c.set_inputs([val])
		c.compute()
		out -= 100 * pow(c.get_outputs()[0] - formula(val), 2)
	
	
	return out

func formula(val):
	return sin(val)
