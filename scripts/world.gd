extends Node3D
## Self-contained first playable 2.5D prototype.
## The environment is 3D; the player uses a camera-facing pixel-style sprite.

const WORLD_HALF := 17.0
const PLAYER_SPEED := 4.2
const PLAYER_RADIUS := 0.36
const PIXEL_SCALE := 3
const TILE_SIZE := 32

var player: Node3D
var camera: Camera3D
var hud: CanvasLayer
var touch_origin := Vector2.ZERO
var touch_vector := Vector2.ZERO
var touch_id := -1
var facing := Vector2.DOWN
var elapsed := 0.0
var obstacles: Array[Rect2] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 20261101
	_build_world()
	_build_player()
	_build_camera()
	_build_hud()
	get_viewport().size_changed.connect(_layout_hud)

func _make_material(color: Color, unshaded := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if unshaded else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return material

func _cube(parent: Node3D, name: String, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(color)
	mesh_instance.position = position
	parent.add_child(mesh_instance)
	return mesh_instance

func _build_world() -> void:
	_cube(self, "Grass", Vector3(0, -0.15, 0), Vector3(36, 0.3, 36), Color("#78b953"))
	for x in range(-16, 17):
		for z in range(-16, 17):
			if abs(x) <= 2 or (z >= -2 and z <= 1):
				_cube(self, "Path", Vector3(x, 0.015, z), Vector3(1, 0.035, 1), Color("#d9c18a"))
			elif rng.randf() < 0.12:
				_cube(self, "GrassTuft", Vector3(x + 0.2, 0.07, z), Vector3(0.16, 0.12, 0.2), Color("#4e923e"))
	_build_house(Vector3(-7, 0, -5), Color("#e7cda0"), Color("#c45e56"))
	_build_house(Vector3(7, 0, -6), Color("#d9dfac"), Color("#657fc4"))
	for i in range(22):
		var x := rng.randi_range(-15, 15)
		var z := rng.randi_range(-15, 15)
		if abs(x) < 4 or abs(z) < 3 or (abs(x + 7) < 4 and abs(z + 5) < 4) or (abs(x - 7) < 4 and abs(z + 6) < 4):
			continue
		_build_tree(Vector3(x, 0, z))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.2
	add_child(sun)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#91c8e8")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.7
	environment.environment = env
	add_child(environment)

func _build_house(at: Vector3, wall: Color, roof: Color) -> void:
	var house := Node3D.new()
	house.position = at
	add_child(house)
	_cube(house, "Walls", Vector3(0, 1.4, 0), Vector3(4.2, 2.8, 3.8), wall)
	_cube(house, "Roof", Vector3(0, 3.05, 0), Vector3(5.1, 0.65, 4.5), roof)
	_cube(house, "Door", Vector3(0, 0.85, 1.94), Vector3(0.95, 1.7, 0.12), Color("#78513e"))
	for x in [-1.35, 1.35]:
		_cube(house, "Window", Vector3(x, 1.8, 1.95), Vector3(0.75, 0.75, 0.13), Color("#7bc5e5"))
	obstacles.append(Rect2(Vector2(at.x - 2.5, at.z - 2.2), Vector2(5.0, 4.4)))

func _build_tree(at: Vector3) -> void:
	var tree := Node3D.new()
	tree.position = at
	add_child(tree)
	_cube(tree, "Trunk", Vector3(0, 0.75, 0), Vector3(0.5, 1.5, 0.5), Color("#80543b"))
	_cube(tree, "CanopyLow", Vector3(0, 2.05, 0), Vector3(2.0, 1.5, 2.0), Color("#3f8e4b"))
	_cube(tree, "CanopyTop", Vector3(0, 3.0, 0), Vector3(1.45, 0.85, 1.45), Color("#58ab55"))
	obstacles.append(Rect2(Vector2(at.x - 0.55, at.z - 0.55), Vector2(1.1, 1.1)))

func _build_player() -> void:
	player = Node3D.new()
	player.name = "Player"
	player.position = Vector3(0, 0, 5)
	add_child(player)
	var sprite := Sprite3D.new()
	sprite.name = "CharacterSprite"
	sprite.texture = _character_texture()
	sprite.pixel_size = 0.038
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = false
	sprite.position.y = 0.72
	player.add_child(sprite)
	_cube(player, "Shadow", Vector3(0, 0.025, 0), Vector3(0.62, 0.03, 0.35), Color("#49783b"))

func _character_texture() -> Texture2D:
	var image := Image.create(24, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_rect_pixels(image, Rect2i(8, 2, 8, 8), Color("#513a35"))
	_rect_pixels(image, Rect2i(7, 5, 10, 8), Color("#f1c18d"))
	_rect_pixels(image, Rect2i(9, 8, 2, 2), Color("#302c36"))
	_rect_pixels(image, Rect2i(15, 8, 2, 2), Color("#302c36"))
	_rect_pixels(image, Rect2i(7, 14, 10, 10), Color("#3d71b8"))
	_rect_pixels(image, Rect2i(5, 15, 3, 8), Color("#f1c18d"))
	_rect_pixels(image, Rect2i(17, 15, 3, 8), Color("#f1c18d"))
	_rect_pixels(image, Rect2i(8, 24, 4, 7), Color("#303b65"))
	_rect_pixels(image, Rect2i(13, 24, 4, 7), Color("#303b65"))
	return ImageTexture.create_from_image(image)

func _rect_pixels(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.5
	camera.position = Vector3(0, 12, 13)
	add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.current = true

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	root.name = "HUD"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)
	var title := Label.new()
	title.name = "Title"
	title.text = "RPG ATTEMPT  |  PROTOTYPE 001"
	title.position = Vector2(18, 16)
	title.add_theme_font_size_override("font_size", 19)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title)
	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "Drag the left side to move  •  WASD / arrows on keyboard"
	hint.position = Vector2(18, 46)
	hint.add_theme_font_size_override("font_size", 13)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hint)
	var pad := Label.new()
	pad.name = "Pad"
	pad.text = "◎"
	pad.add_theme_font_size_override("font_size", 78)
	pad.modulate = Color(1, 1, 1, 0.6)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(pad)
	_layout_hud()

func _layout_hud() -> void:
	if hud == null:
		return
	var pad := hud.get_node_or_null("HUD/Pad") as Label
	if pad != null:
		pad.position = Vector2(35, get_viewport().get_visible_rect().size.y - 150)

func _input(event: InputEvent) -> void:
	var size := get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < size.x * 0.6 and touch_id == -1:
			touch_id = event.index
			touch_origin = event.position
			touch_vector = Vector2.ZERO
		elif not event.pressed and event.index == touch_id:
			touch_id = -1
			touch_vector = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == touch_id:
		touch_vector = (event.position - touch_origin).limit_length(75.0) / 75.0

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1
	direction = (direction + touch_vector).limit_length(1.0)
	if direction.length() > 0.08:
		facing = direction
		var movement := Vector3(direction.x, 0, direction.y) * PLAYER_SPEED * delta
		_move_with_collision(movement)
		elapsed += delta
		var sprite := player.get_node("CharacterSprite") as Sprite3D
		sprite.position.y = 0.72 + abs(sin(elapsed * 12.0)) * 0.045
	else:
		(player.get_node("CharacterSprite") as Sprite3D).position.y = 0.72
	var target := player.position + Vector3(0, 12, 13)
	camera.position = camera.position.lerp(target, min(1.0, delta * 6.0))

func _move_with_collision(movement: Vector3) -> void:
	var candidate := player.position + Vector3(movement.x, 0, 0)
	if _can_stand(candidate):
		player.position.x = candidate.x
	candidate = player.position + Vector3(0, 0, movement.z)
	if _can_stand(candidate):
		player.position.z = candidate.z

func _can_stand(point: Vector3) -> bool:
	if abs(point.x) > WORLD_HALF or abs(point.z) > WORLD_HALF:
		return false
	for obstacle in obstacles:
		var expanded := obstacle.grow(PLAYER_RADIUS)
		if expanded.has_point(Vector2(point.x, point.z)):
			return false
	return true
