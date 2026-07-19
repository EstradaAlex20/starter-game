extends SceneTree
# Extends the CityGridMap's road grid by one ring in each direction (matching
# the existing tile/orientation pattern) and fills every empty 3x3 block -
# both pre-existing and newly added - with random buildings. Run with:
#   godot --headless --script res://tools/extend_city_grid.gd
#
# Re-run any time you want to grow the grid further (it re-detects the
# current extent from the crossroads already placed) or re-roll buildings
# in blocks that are still empty.

const LEVEL_PATH = "res://levels/level_city.tscn"
const GRID_SPACING = 4

const ROAD_STRAIGHT = 0
const ROAD_CROSSROAD = 63
const PRESERVE_CENTER = Vector3i(0, 0, 0)  # the user's special road-crossroad-path piece

const ORIENT_STRAIGHT_VERTICAL = 16   # for x=const lines - confirmed interchangeable with 22
const ORIENT_STRAIGHT_HORIZONTAL = 10 # for z=const lines - confirmed interchangeable with 0
const ORIENT_CROSSROAD = 16           # confirmed interchangeable with 10 (symmetric piece)

const BUILDING_ORIENTATIONS = [0, 10, 16, 22]

var grid_map: GridMap
var rng = RandomNumberGenerator.new()

func _initialize():
	rng.randomize()
	var scene: PackedScene = load(LEVEL_PATH)
	var root = scene.instantiate()
	grid_map = root.find_child("CityGridMap", true, false)
	var library = grid_map.mesh_library

	var building_ids: Array = []
	for id in library.get_item_list():
		var item_name: String = library.get_item_name(id)
		if item_name.begins_with("building-") or item_name.begins_with("low-detail-building-"):
			building_ids.append(id)
	print("Building types available: ", building_ids.size())

	# Detect the current grid extent from existing crossroads.
	var x_lines_set = {}
	var z_lines_set = {}
	for cell in grid_map.get_used_cells():
		if grid_map.get_cell_item(cell) == ROAD_CROSSROAD:
			x_lines_set[cell.x] = true
			z_lines_set[cell.z] = true
	var x_lines: Array = x_lines_set.keys()
	x_lines.sort()
	var z_lines: Array = z_lines_set.keys()
	z_lines.sort()
	print("Current x lines: ", x_lines)
	print("Current z lines: ", z_lines)

	# Extend by one ring in each direction. Capture old min/max BEFORE
	# appending either new value - appending the first and then reading
	# x_lines[-1] for the second would read back the just-appended value
	# instead of the original max, silently skipping that side.
	var x_min_old = x_lines[0]
	var x_max_old = x_lines[-1]
	x_lines.append(x_min_old - GRID_SPACING)
	x_lines.append(x_max_old + GRID_SPACING)
	x_lines.sort()
	var z_min_old = z_lines[0]
	var z_max_old = z_lines[-1]
	z_lines.append(z_min_old - GRID_SPACING)
	z_lines.append(z_max_old + GRID_SPACING)
	z_lines.sort()
	print("New x lines: ", x_lines)
	print("New z lines: ", z_lines)

	var x_line_set = {}
	for x in x_lines:
		x_line_set[x] = true
	var z_line_set = {}
	for z in z_lines:
		z_line_set[z] = true

	var roads_added = 0
	for x in range(x_lines[0], x_lines[-1] + 1):
		for z in range(z_lines[0], z_lines[-1] + 1):
			var pos = Vector3i(x, 0, z)
			var is_x_line = x_line_set.has(x)
			var is_z_line = z_line_set.has(z)
			if is_x_line and is_z_line:
				if pos == PRESERVE_CENTER:
					continue
				if grid_map.get_cell_item(pos) != ROAD_CROSSROAD:
					grid_map.set_cell_item(pos, ROAD_CROSSROAD, ORIENT_CROSSROAD)
					roads_added += 1
			elif is_x_line:
				if grid_map.get_cell_item(pos) == -1:
					grid_map.set_cell_item(pos, ROAD_STRAIGHT, ORIENT_STRAIGHT_VERTICAL)
					roads_added += 1
			elif is_z_line:
				if grid_map.get_cell_item(pos) == -1:
					grid_map.set_cell_item(pos, ROAD_STRAIGHT, ORIENT_STRAIGHT_HORIZONTAL)
					roads_added += 1

	# Fill every empty block (pre-existing gaps and newly created ones) with
	# random buildings. Blocks that already have anything in them are left
	# untouched.
	var blocks_filled = 0
	var buildings_added = 0
	for xi in range(x_lines.size() - 1):
		for zi in range(z_lines.size() - 1):
			var bx0 = x_lines[xi]
			var bx1 = x_lines[xi + 1]
			var bz0 = z_lines[zi]
			var bz1 = z_lines[zi + 1]
			var occupied = false
			for x in range(bx0 + 1, bx1):
				for z in range(bz0 + 1, bz1):
					if grid_map.get_cell_item(Vector3i(x, 0, z)) != -1:
						occupied = true
			if occupied:
				continue
			blocks_filled += 1
			for x in range(bx0 + 1, bx1):
				for z in range(bz0 + 1, bz1):
					var building = building_ids[rng.randi() % building_ids.size()]
					var orientation = BUILDING_ORIENTATIONS[rng.randi() % BUILDING_ORIENTATIONS.size()]
					grid_map.set_cell_item(Vector3i(x, 0, z), building, orientation)
					buildings_added += 1

	print("Roads added: ", roads_added)
	print("Blocks filled with buildings: ", blocks_filled, " (", buildings_added, " building tiles)")

	var packed = PackedScene.new()
	packed.pack(root)
	var err = ResourceSaver.save(packed, LEVEL_PATH)
	print("Saved ", LEVEL_PATH, " (err=", err, ")")
	quit()
