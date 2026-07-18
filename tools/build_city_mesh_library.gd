extends SceneTree
# Rebuilds res://levels/city_mesh_library.tres from the raw city/road GLB
# assets. Run with:
#   godot --headless --script res://tools/build_city_mesh_library.gd
# Add more tiles by adding entries to the TILES list below and re-running.

const OUTPUT_PATH = "res://levels/city_mesh_library.tres"

const TILES = [
	["road-straight", "res://Assets/roads/Models/GLB format/road-straight.glb"],
	["road-intersection", "res://Assets/roads/Models/GLB format/road-intersection.glb"],
	["road-end", "res://Assets/roads/Models/GLB format/road-end.glb"],
	["road-bend", "res://Assets/roads/Models/GLB format/road-bend.glb"],
	["tile-low", "res://Assets/roads/Models/GLB format/tile-low.glb"],
	["building-a", "res://Assets/city/Models/GLB format/building-a.glb"],
	["building-b", "res://Assets/city/Models/GLB format/building-b.glb"],
	["building-c", "res://Assets/city/Models/GLB format/building-c.glb"],
	["building-d", "res://Assets/city/Models/GLB format/building-d.glb"],
	["building-e", "res://Assets/city/Models/GLB format/building-e.glb"],
	["building-f", "res://Assets/city/Models/GLB format/building-f.glb"],
	["building-skyscraper-a", "res://Assets/city/Models/GLB format/building-skyscraper-a.glb"],
	["building-skyscraper-b", "res://Assets/city/Models/GLB format/building-skyscraper-b.glb"],
	["low-detail-building-a", "res://Assets/city/Models/GLB format/low-detail-building-a.glb"],
	["low-detail-building-wide-a", "res://Assets/city/Models/GLB format/low-detail-building-wide-a.glb"],
]

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found = _find_mesh_instance(child)
		if found:
			return found
	return null

func _initialize():
	var library = MeshLibrary.new()
	var id = 0
	for tile in TILES:
		var tile_name: String = tile[0]
		var path: String = tile[1]
		var scene: PackedScene = load(path)
		if scene == null:
			print("SKIP (failed to load): ", path)
			continue
		var inst = scene.instantiate()
		var mesh_inst = _find_mesh_instance(inst)
		if mesh_inst == null:
			print("SKIP (no MeshInstance3D found): ", path)
			inst.free()
			continue

		var mesh: Mesh = mesh_inst.mesh
		library.create_item(id)
		library.set_item_name(id, tile_name)
		library.set_item_mesh(id, mesh)
		library.set_item_mesh_transform(id, mesh_inst.transform)

		var shape = mesh.create_trimesh_shape()
		if shape:
			library.set_item_shapes(id, [shape, mesh_inst.transform])
		else:
			print("  (no collision shape generated for ", tile_name, ")")

		print("Added [", id, "] ", tile_name)
		id += 1
		inst.free()

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://levels"))
	var err = ResourceSaver.save(library, OUTPUT_PATH)
	print("Saved ", library.get_item_list().size(), " items to ", OUTPUT_PATH, " (err=", err, ")")
	quit()
