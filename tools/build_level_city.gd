extends SceneTree
# Assembles a sample city level from the GridMap mesh library and saves it as
# res://levels/level_city.tscn. Run with:
#   godot --headless --script res://tools/build_level_city.gd
# This is a one-shot generator, not something that needs to run again unless
# you want to regenerate the layout from scratch - once saved, edit
# level_city.tscn normally in the editor (move the GridMap palette, paint more
# tiles, drag buildings around, etc).

const OUTPUT_PATH = "res://levels/level_city.tscn"
const MESH_LIBRARY_PATH = "res://levels/city_mesh_library.tres"

# Item ids match the order they were added in build_city_mesh_library.gd.
const ROAD_STRAIGHT = 0
const ROAD_INTERSECTION = 1
const ROAD_END = 2
const TILE_LOW = 4
const BUILDING_A = 5
const BUILDING_B = 6
const BUILDING_C = 7
const BUILDING_D = 8
const BUILDING_E = 9
const BUILDING_F = 10
const SKYSCRAPER_A = 11
const SKYSCRAPER_B = 12
const LOW_DETAIL_A = 13
const LOW_DETAIL_WIDE_A = 14

# GridMap orientation indices for simple Y-axis rotations, computed from
# GridMap.get_orthogonal_index_from_basis() rather than guessed.
const ROT_0 = 0
const ROT_90 = 16
const ROT_180 = 10
const ROT_270 = 22

const HALF_ARM = 4

func _build_ground() -> StaticBody3D:
	var floor_body = StaticBody3D.new()
	floor_body.name = "Ground"

	var shape = BoxShape3D.new()
	shape.size = Vector3(30, 1, 30)
	var collision = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	collision.position = Vector3(0, -0.5, 0)
	floor_body.add_child(collision)
	collision.owner = floor_body

	var mesh = BoxMesh.new()
	mesh.size = Vector3(1, 1, 1)
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "MeshInstance3D"
	mesh_inst.mesh = mesh
	mesh_inst.transform = Transform3D(Basis().scaled(Vector3(30, 1, 30)), Vector3(0, -0.5, 0))

	var material = StandardMaterial3D.new()
	material.albedo_texture = load("res://Assets/grass/JPEG/Stylized_HandpaintedGrass_01/Stylized_HandpaintedGrass_01_basecolor.jpg")
	material.roughness_texture = load("res://Assets/grass/JPEG/Stylized_HandpaintedGrass_01/Stylized_HandpaintedGrass_01_roughness.jpg")
	material.normal_enabled = true
	material.normal_texture = load("res://Assets/grass/JPEG/Stylized_HandpaintedGrass_01/Stylized_HandpaintedGrass_01_normal.jpg")
	material.ao_enabled = true
	material.ao_texture = load("res://Assets/grass/JPEG/Stylized_HandpaintedGrass_01/Stylized_HandpaintedGrass_01_ambientocclusion.jpg")
	material.uv1_scale = Vector3(12, 12, 12)
	material.uv1_triplanar = true
	mesh_inst.set_surface_override_material(0, material)

	floor_body.add_child(mesh_inst)
	mesh_inst.owner = floor_body
	return floor_body

func _build_grid_map() -> GridMap:
	var grid_map = GridMap.new()
	grid_map.name = "CityGridMap"
	grid_map.mesh_library = load(MESH_LIBRARY_PATH)
	grid_map.cell_size = Vector3(1, 1, 1)
	# GridMap's default cell_center_y offsets cell content up by half a cell,
	# which put the road surface ~0.5 above the grass ground - shift the whole
	# map down so both surfaces are flush (confirmed empirically, not assumed).
	grid_map.position = Vector3(0, -0.5, 0)

	# Center intersection.
	grid_map.set_cell_item(Vector3i(0, 0, 0), ROAD_INTERSECTION, ROT_0)

	# Four straight arms radiating out from the intersection, capped with
	# road-end pieces. Straight segments along X need a 90-degree turn from
	# their default (assumed along-Z) orientation.
	for i in range(1, HALF_ARM):
		grid_map.set_cell_item(Vector3i(i, 0, 0), ROAD_STRAIGHT, ROT_90)
		grid_map.set_cell_item(Vector3i(-i, 0, 0), ROAD_STRAIGHT, ROT_90)
		grid_map.set_cell_item(Vector3i(0, 0, i), ROAD_STRAIGHT, ROT_0)
		grid_map.set_cell_item(Vector3i(0, 0, -i), ROAD_STRAIGHT, ROT_0)

	# End caps. Rotations here are a best guess at which side is "open" since
	# there's no way to visually preview this - nudge 90/180 degrees in the
	# editor if one looks like it's facing the wrong way.
	grid_map.set_cell_item(Vector3i(0, 0, HALF_ARM), ROAD_END, ROT_0)
	grid_map.set_cell_item(Vector3i(0, 0, -HALF_ARM), ROAD_END, ROT_180)
	grid_map.set_cell_item(Vector3i(HALF_ARM, 0, 0), ROAD_END, ROT_90)
	grid_map.set_cell_item(Vector3i(-HALF_ARM, 0, 0), ROAD_END, ROT_270)

	# Sidewalk tiles flanking each arm.
	for i in range(1, HALF_ARM):
		grid_map.set_cell_item(Vector3i(i, 0, 1), TILE_LOW, ROT_0)
		grid_map.set_cell_item(Vector3i(i, 0, -1), TILE_LOW, ROT_0)
		grid_map.set_cell_item(Vector3i(-i, 0, 1), TILE_LOW, ROT_0)
		grid_map.set_cell_item(Vector3i(-i, 0, -1), TILE_LOW, ROT_0)
		grid_map.set_cell_item(Vector3i(1, 0, i), TILE_LOW, ROT_0)
		grid_map.set_cell_item(Vector3i(-1, 0, i), TILE_LOW, ROT_0)
		grid_map.set_cell_item(Vector3i(1, 0, -i), TILE_LOW, ROT_0)
		grid_map.set_cell_item(Vector3i(-1, 0, -i), TILE_LOW, ROT_0)

	# A scattering of buildings, one quadrant at a time.
	var buildings = [
		[Vector3i(2, 0, 2), BUILDING_A, ROT_0],
		[Vector3i(3, 0, 3), SKYSCRAPER_A, ROT_0],
		[Vector3i(3, 0, 2), LOW_DETAIL_A, ROT_90],

		[Vector3i(2, 0, -2), BUILDING_B, ROT_0],
		[Vector3i(3, 0, -3), BUILDING_C, ROT_0],
		[Vector3i(2, 0, -3), LOW_DETAIL_WIDE_A, ROT_0],

		[Vector3i(-2, 0, 2), BUILDING_D, ROT_0],
		[Vector3i(-3, 0, 3), BUILDING_E, ROT_0],

		[Vector3i(-2, 0, -2), BUILDING_F, ROT_0],
		[Vector3i(-3, 0, -3), SKYSCRAPER_B, ROT_0],
	]
	for b in buildings:
		grid_map.set_cell_item(b[0], b[1], b[2])

	return grid_map

func _build_lighting() -> Array:
	var world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var env = Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_sky_contribution = 0.0
	env.ambient_light_energy = 0.6
	world_env.environment = env

	var sun = DirectionalLight3D.new()
	sun.name = "DirectionalLight3D"
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.0

	return [world_env, sun]

func _initialize():
	var root = Node3D.new()
	root.name = "LevelCity"

	var ground = _build_ground()
	root.add_child(ground)
	ground.owner = root
	for c in ground.get_children():
		c.owner = root

	var grid_map = _build_grid_map()
	root.add_child(grid_map)
	grid_map.owner = root

	for node in _build_lighting():
		root.add_child(node)
		node.owner = root

	var player_scene: PackedScene = load("res://zombie_character.tscn")
	var player = player_scene.instantiate()
	player.name = "Zombie"
	player.transform = Transform3D(Basis(), Vector3(0, 0.1, 2))
	root.add_child(player)
	player.owner = root

	var coin_scene: PackedScene = load("res://coin.tscn")
	var coin_positions = [
		Vector3(2, 0.5, 2),
		Vector3(-2, 0.5, -2),
		Vector3(0, 0.5, -2),
		Vector3(2, 0.5, -1),
	]
	var idx = 0
	for pos in coin_positions:
		var coin = coin_scene.instantiate()
		coin.name = "Coin%d" % idx
		coin.position = pos
		root.add_child(coin)
		coin.owner = root
		idx += 1

	var packed = PackedScene.new()
	var pack_err = packed.pack(root)
	print("pack() err=", pack_err)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://levels"))
	var save_err = ResourceSaver.save(packed, OUTPUT_PATH)
	print("Saved level to ", OUTPUT_PATH, " (err=", save_err, ")")
	quit()
