extends Node3D
## Deterministic, streamed terrain around the handcrafted starting town.
## Chunk content depends only on world seed and global tile coordinates.
const CHUNK_SIZE := 16
const TILE_SIZE := 4
const ACTIVE_RADIUS := 2
const WORLD_SEED := 827194
var chunks: Dictionary = {}
var current_chunk := Vector2i(999999, 999999)
var terrain_noise := FastNoiseLite.new()
var height_noise := FastNoiseLite.new()
var is_past := false

func _ready() -> void:
	terrain_noise.seed = WORLD_SEED
	terrain_noise.frequency = 0.025
	terrain_noise.fractal_octaves = 3
	height_noise.seed = WORLD_SEED + 19
	height_noise.frequency = 0.05

func set_era(past: bool) -> void:
	if is_past == past:
		return
	is_past = past
	for key in chunks.keys():
		var node := chunks[key] as Node3D
		if is_instance_valid(node):
			node.queue_free()
	chunks.clear()
	current_chunk = Vector2i(999999, 999999)

func update_streaming(world_position: Vector3) -> void:
	var center := Vector2i(floori(world_position.x / CHUNK_SIZE), floori(world_position.z / CHUNK_SIZE))
	if center == current_chunk:
		return
	current_chunk = center
	var wanted: Dictionary = {}
	for dz in range(-ACTIVE_RADIUS, ACTIVE_RADIUS + 1):
		for dx in range(-ACTIVE_RADIUS, ACTIVE_RADIUS + 1):
			var coord := center + Vector2i(dx, dz)
			if coord == Vector2i.ZERO:
				continue
			wanted[coord] = true
			if not chunks.has(coord):
				chunks[coord] = _generate_chunk(coord)
	for coord in chunks.keys():
		if not wanted.has(coord):
			var old := chunks[coord] as Node3D
			if is_instance_valid(old):
				old.queue_free()
			chunks.erase(coord)

func _generate_chunk(coord: Vector2i) -> Node3D:
	var chunk := Node3D.new()
	chunk.name = "Chunk_%d_%d" % [coord.x, coord.y]
	add_child(chunk)
	for local_z in range(CHUNK_SIZE / TILE_SIZE):
		for local_x in range(CHUNK_SIZE / TILE_SIZE):
			var x := float(coord.x * CHUNK_SIZE + local_x * TILE_SIZE + TILE_SIZE / 2)
			var z := float(coord.y * CHUNK_SIZE + local_z * TILE_SIZE + TILE_SIZE / 2)
			# Do not cover the authored starting town.
			if absf(x) < 18.0 and absf(z) < 18.0:
				continue
			var n := terrain_noise.get_noise_2d(x, z)
			var wet := height_noise.get_noise_2d(x, z)
			var water := n < -0.38
			var color := Color("#4d91b8") if water else Color("#d7c18c") if n < -0.23 else Color("#529e55") if n < 0.35 else Color("#39784b")
			if is_past and not water:
				color = color.lerp(Color("#a69b70"), 0.18)
			_cube(chunk, Vector3(x, -0.17, z), Vector3(TILE_SIZE, 0.3, TILE_SIZE), color)
			if water:
				continue
			# Global-coordinate hashing prevents decoration from changing when chunks reload.
			var h := _hash2(int(x), int(z))
			if n > 0.12 and h % 7 == 0:
				_cube(chunk, Vector3(x, 0.62, z), Vector3(0.42, 1.25, 0.42), Color("#76523b"))
				_cube(chunk, Vector3(x, 1.65, z), Vector3(2.4, 1.7, 2.3), Color("#43834b" if is_past else "#54a85d"))
			elif wet > 0.3 and h % 9 == 0:
				_cube(chunk, Vector3(x, 0.35, z), Vector3(1.2, 0.65, 1.0), Color("#8d8b89"))
	return chunk

func _hash2(x: int, z: int) -> int:
	var value := (x * 73856093) ^ (z * 19349663) ^ WORLD_SEED
	return absi(value % 2147483647)

func _cube(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	instance.material_override = mat
	parent.add_child(instance)
