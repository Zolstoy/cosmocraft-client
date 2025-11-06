extends Node3D

@onready var body_scene: PackedScene = load("res://scenes/body.tscn")
@onready var star_light_scene: PackedScene = load("res://scenes/star_light.tscn")

@onready var core = get_tree().get_first_node_in_group("core")
@onready var info = get_tree().get_first_node_in_group("info")


var cache: Dictionary = {}
var init_elements = [];
var update_elements = [];

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	info.set_visible(!init_elements.is_empty())

	for body_info in init_elements:
		var id = int(body_info["id"])
		assert(id > 0)
		var coords = Vector3(body_info["x"], body_info["y"], body_info["z"])
		var body_tree = get_colored_body_node(str(int(body_info.body_type)), coords, body_info.size)
		body_tree.next_coords = coords
		body_tree.updated = true
		body_tree.set_name(str(id))
		body_tree.rotating_speed = body_info.rotating_speed
		body_tree.body_type = body_info["body_type"]
		body_tree.gravity_center_id = int(body_info.gravity_center)
		cache[id] = body_tree
		add_child(body_tree)
	init_elements.clear()

	for element in update_elements:
		var id = int(element["id"])
		assert(id > 0)
		if !cache.has(id):
			continue
		var body_node = cache[id]
		var new_coords_sph = Vector3(element["x"], element["y"], element["z"])
		body_node.next_coords = new_coords_sph
		body_node.updated = true
	update_elements.clear()

func stop():
	for node in get_children():
		remove_child(node)
		cache.clear()
		init_elements.clear()
		update_elements.clear()
	set_process(false)

func get_colored_body_node(type: String, coords: Vector3, size: float) -> Node:
	var body_tree: Node3D = body_scene.instantiate()
	var model: CSGSphere3D = body_tree.get_child(0)
	model.radius = size
	var mat = model.material as StandardMaterial3D
	var color: Color

	if type == "1":
		var star_light_tree: Node3D = star_light_scene.instantiate()
		star_light_tree.position = Vector3(coords.x, coords.y, coords.z)
		add_child(star_light_tree)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		color = Color(0.99, 0.99, 0.99)
	elif type == "2":
		color = Color(0.2, 0.9, 0.2)
	elif type == "3":
		color = Color(0.4, 0.4, 0.4)
	elif type == "4":
		color = Color(0.9, 0.2, 0.2)
	else:
		color = Color(0, 0, 1)

	mat.albedo_color = color
	return body_tree
