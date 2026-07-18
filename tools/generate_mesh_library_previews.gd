extends SceneTree
# Renders a thumbnail preview for every item in the city MeshLibrary and
# saves them back into the resource, so the GridMap palette dock shows real
# icons instead of blank tiles with just names.
#
# Must run WITHOUT --headless (needs real GPU rendering):
#   godot --script res://tools/generate_mesh_library_previews.gd
#
# Re-run this any time build_city_mesh_library.gd is re-run and adds new
# tiles, since a fresh MeshLibrary has no stored previews at all.

const LIBRARY_PATH = "res://levels/city_mesh_library.tres"
const PREVIEW_SIZE = 128
const DEBUG_OUTPUT_DIR = "res://tools/preview_debug"

var library: MeshLibrary
var viewport: SubViewport
var cam: Camera3D
var mesh_instance: MeshInstance3D
var ids: Array
var index := 0
var frame := 0

func _initialize():
	library = load(LIBRARY_PATH)
	ids = library.get_item_list()
	print("Generating previews for ", ids.size(), " items")

	viewport = SubViewport.new()
	viewport.size = Vector2i(PREVIEW_SIZE, PREVIEW_SIZE)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)

	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.5
	env_node.environment = env
	viewport.add_child(env_node)

	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -45, 0)
	light.light_energy = 0.6
	viewport.add_child(light)

	cam = Camera3D.new()
	viewport.add_child(cam)

	mesh_instance = MeshInstance3D.new()
	viewport.add_child(mesh_instance)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DEBUG_OUTPUT_DIR))

func _frame_mesh(mesh: Mesh):
	var aabb = mesh.get_aabb()
	var center = aabb.position + aabb.size / 2.0
	var radius = max(aabb.size.length() / 2.0, 0.05)
	var direction = Vector3(1, 0.85, 1).normalized()
	var distance = radius / sin(deg_to_rad(cam.fov / 2.0)) * 1.15
	cam.position = center + direction * distance
	cam.look_at(center, Vector3.UP)

func _process(delta):
	frame += 1
	# Give each item's viewport a couple of frames to actually render before
	# capturing, and a couple more after swapping meshes.
	if index >= ids.size():
		var save_err = ResourceSaver.save(library, LIBRARY_PATH)
		print("Saved previews to ", LIBRARY_PATH, " (err=", save_err, ")")
		quit()
		return false

	if frame % 3 == 1:
		var id = ids[index]
		mesh_instance.mesh = library.get_item_mesh(id)
		_frame_mesh(mesh_instance.mesh)
	elif frame % 3 == 0:
		var id = ids[index]
		var img = viewport.get_texture().get_image()
		var tex = ImageTexture.create_from_image(img)
		library.set_item_preview(id, tex)
		img.save_png(DEBUG_OUTPUT_DIR + "/" + library.get_item_name(id) + ".png")
		print("Captured preview for [", id, "] ", library.get_item_name(id))
		index += 1

	return false
