extends Node3D

@onready var core = get_tree().get_first_node_in_group("core")

var rotating_speed = null
var gravity_center_id = null
var body_type = null
var gravity_center: Node = null
var angle = 0.0

var next_coords: Vector3
var updated = true

var up_vec = Vector3.UP

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if name == "1":
		return

	up_vec = up_vec.rotated(Vector3.RIGHT, angle)

	if !gravity_center:
		if core.spawner.cache.has(gravity_center_id):
			gravity_center = core.spawner.cache[gravity_center_id]
			core.spawner.remove_child(self)
			gravity_center.add_child(self)
		return
	
	if !updated:
		pass
	else:
		position = Vector3(
			next_coords.x,
			next_coords.y,
			next_coords.z
		)
		updated = false
		if body_type == 1:
			set_process(false)
