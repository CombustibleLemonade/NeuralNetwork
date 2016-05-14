extends Control

var values = []

var min_val = 0
var max_val = 0

var minimum
var maximum

var force_minimax = false

var color = Color(0, 0.9, 0.1, 1)

func push_value(v):
	values.push_front(v)
	if values.size() > 400:
		values.pop_back()
	 
	min_val = values[0]
	max_val = values[0]
	
	if minimum != null:
		min_val = minimum
	if maximum != null:
		max_val = maximum
	
	if !force_minimax:
		for i in values:
			min_val = min(min_val, i)
			max_val = max(max_val, i)
	
	update()

func _draw():
	var w = get_rect().size.x
	var h = get_rect().size.y
	
	for i in range(values.size() - 1):
		draw_line(Vector2(w-4*i, to_y(values[i]) ), Vector2(w-4*i - 4, to_y(values[i+1])), color, 1)

func to_y(v):
	var h = get_rect().size.y
	var new_v = v - min_val
	
	new_v /= (max_val - min_val + 0.01)
	
	new_v *= h
	
	new_v = h - new_v
	
	return new_v
