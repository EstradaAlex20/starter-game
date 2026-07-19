extends SceneTree
# Rebuilds res://levels/city_mesh_library.tres from every city/road GLB asset.
# Run with:
#   godot --headless --script res://tools/build_city_mesh_library.gd
#
# ORIGINAL_TILES keeps its exact order/ids (0-14) because levels/level_city.tscn's
# GridMap references those items by numeric id - reordering them would silently
# swap in different tiles on that already-built level. Everything else is
# auto-discovered from the source folders and appended after, in whatever
# order the filesystem returns (their ids aren't depended on anywhere yet).

const OUTPUT_PATH = "res://levels/city_mesh_library.tres"

const SOURCE_DIRS = [
	"res://Assets/roads/Models/GLB format",
	"res://Assets/city/Models/GLB format",
]

const ORIGINAL_TILES = [
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

func _discover_remaining_tiles() -> Array:
	var already_used = {}
	for tile in ORIGINAL_TILES:
		already_used[tile[1]] = true

	var tiles = []
	for dir_path in SOURCE_DIRS:
		var dir = DirAccess.open(dir_path)
		if dir == null:
			print("Could not open ", dir_path)
			continue
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".glb"):
				var full_path = dir_path + "/" + file_name
				if not already_used.has(full_path):
					tiles.append([file_name.get_basename(), full_path])
			file_name = dir.get_next()
		dir.list_dir_end()
	tiles.sort_custom(func(a, b): return a[0] < b[0])
	return tiles

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
	var skipped = 0
	for tile in ORIGINAL_TILES + _discover_remaining_tiles():
		var tile_name: String = tile[0]
		var path: String = tile[1]
		var scene: PackedScene = load(path)
		if scene == null:
			print("SKIP (failed to load): ", path)
			skipped += 1
			continue
		var inst = scene.instantiate()
		var mesh_inst = _find_mesh_instance(inst)
		if mesh_inst == null:
			print("SKIP (no MeshInstance3D found): ", path)
			inst.free()
			skipped += 1
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
	print("Saved ", library.get_item_list().size(), " items (", skipped, " skipped) to ", OUTPUT_PATH, " (err=", err, ")")
	quit()
