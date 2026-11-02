extends Node2D
## A compact authored map. Tile and prop positions are data, not random gameplay.
const NPC_SCRIPT := preload("res://scripts/dialogue/npc.gd")
const TILE: int = 16
const OBJECT_SCRIPT := preload("res://scripts/world/world_object.gd")
const ENEMY_SCRIPT := preload("res://scripts/combat/enemy.gd")
@export_file("*.json") var definition_path: String = "res://resources/world/dawn_village.json"
var content_state: Dictionary = {"collected":[],"defeated":[],"enemies":[],"drops":[]}
var navigation := AStarGrid2D.new()
signal enemy_defeated(id: String)
var definition: Dictionary = {}
var obstacle_count: int = 0
@onready var player: CharacterBody2D = $Actors/Player
@onready var rowan: StaticBody2D = $Actors/ElderRowan
@onready var ground: TileMapLayer = $Ground
@onready var actors: Node2D = $Actors
@onready var camera: Camera2D = $Camera

func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(definition_path))
	if not parsed is Dictionary:
		push_error("Village data invalid.")
		return
	definition = parsed
	_create_tiles()
	for entry: Dictionary in definition.props:
		_create_prop(str(entry.kind), Vector2(entry.at[0], entry.at[1]), entry)
	_create_forest()
	for point: Array in definition.flowers:
		_create_prop("flowers", Vector2(point[0], point[1]))
	for y: int in range(10, 42, 2):
		for x: int in range(10, 57, 2):
			var cell := Vector2i(x, y)
			if ground.get_cell_source_id(cell) == 0 and ground.get_cell_atlas_coords(cell).y == 0 and posmod(x*37+y*13, 11) < 3:
				_create_prop("fern", Vector2(x*TILE + posmod(y*7, 9), y*TILE))
	_create_boundaries()
	player.position = Vector2(definition.spawn[0], definition.spawn[1])
	rowan.position = Vector2(definition.rowan[0], definition.rowan[1])
	if definition.id != "dawn_village":
		rowan.remove_from_group("interactables")
		rowan.hide()
		rowan.collision_layer = 0
		modulate = Color(0.78,0.9,0.95)
	for entry: Dictionary in definition.get("objects",[]):
		if not content_state.collected.has(entry.id):
			spawn_object(entry)
	for entry: Dictionary in content_state.drops:
		spawn_object(entry)
	_build_navigation()
	for entry: Dictionary in definition.get("enemies",[]):
		if content_state.defeated.has(entry.id):
			continue
		var enemy := ENEMY_SCRIPT.new()
		enemy.enemy_id = str(entry.id)
		enemy.position = Vector2(entry.at[0],entry.at[1])
		actors.add_child(enemy)
		enemy.target = player
		for saved: Dictionary in content_state.enemies:
			if saved.id == entry.id:
				enemy.position = Vector2(saved.at[0],saved.at[1])
				enemy.health.restore(int(saved.hp))
		enemy.defeated.connect(_on_enemy_defeated)
	camera.limit_right = int(definition.width) * TILE
	camera.limit_bottom = int(definition.height) * TILE
	camera.position = player.position.round()
	camera.reset_smoothing()

func _physics_process(_delta: float) -> void:
	# Integer camera positions and no subpixel smoothing prevent pixel shimmer.
	camera.position = player.position.round()

func _create_tiles() -> void:
	var atlas := TileSetAtlasSource.new()
	# Terrain clips and their source atlas share the manifest contract.
	var grass_frames: SpriteFrames = preload("res://resources/art/grass.tres")
	var terrain_frames: Array[SpriteFrames] = [grass_frames, preload("res://resources/art/stone_path.tres"), preload("res://resources/art/water.tres"), preload("res://resources/art/shore.tres")]
	var grass_tile := grass_frames.get_frame_texture(&"idle", 0) as AtlasTexture
	atlas.texture = grass_tile.atlas
	atlas.texture_region_size = Vector2i(TILE, TILE)
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 2)
	# Atlas must belong to TileSet before TileData can see physics layers.
	tileset.add_source(atlas, 0)
	for y: int in range(4):
		for x: int in range(8):
			var tile := Vector2i(x, y)
			atlas.create_tile(tile)
			var clip: SpriteFrames = terrain_frames[y]
			if clip.get_frame_count(&"idle") > 1:
				atlas.set_tile_animation_columns(tile, 4)
				atlas.set_tile_animation_separation(tile, Vector2i(7, 0))
				atlas.set_tile_animation_frames_count(tile, clip.get_frame_count(&"idle"))
				atlas.set_tile_animation_speed(tile, clip.get_animation_speed(&"idle"))
			if y == 2:
				var data: TileData = atlas.get_tile_data(tile, 0)
				data.set_collision_polygons_count(0, 1)
				data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
	ground.tile_set = tileset
	var path_atlas := TileSetAtlasSource.new()
	var path_frames: SpriteFrames = preload("res://resources/art/stone_path.tres")
	var path_tile := path_frames.get_frame_texture(&"edges", 0) as AtlasTexture
	path_atlas.texture = path_tile.atlas
	path_atlas.texture_region_size = Vector2i(TILE, TILE)
	tileset.add_source(path_atlas, 1)
	for y: int in range(4):
		for x: int in range(16):
			path_atlas.create_tile(Vector2i(x, y))
	for y: int in range(int(definition.height)):
		for x: int in range(int(definition.width)):
			var variant_index: int = posmod(x * 13 + y * 7 + x * y, 8)
			ground.set_cell(Vector2i(x, y), 0, Vector2i(variant_index, 0))
	var path_cells: Dictionary = {}
	for path: Array in definition.paths:
		for y: int in range(path[1], path[1] + path[3]):
			for x: int in range(path[0], path[0] + path[2]):
				path_cells[Vector2i(x, y)] = true
	for cell: Vector2i in path_cells:
		var mask: int = 0
		var neighbors: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
		for i: int in range(neighbors.size()):
			if path_cells.has(cell+neighbors[i]):
				mask |= 1 << i
		ground.set_cell(cell, 1, Vector2i(mask, posmod(cell.x*7+cell.y*3, 4)))
	var pond: Array = definition.pond
	for y: int in range(pond[1]-1, pond[1]+pond[3]+1):
		for x: int in range(pond[0]-1, pond[0]+pond[2]+1):
			var edge: bool = x < pond[0] or x >= pond[0]+pond[2] or y < pond[1] or y >= pond[1]+pond[3]
			var corner: bool = (x == pond[0] or x == pond[0]+pond[2]-1) and (y == pond[1] or y == pond[1]+pond[3]-1)
			ground.set_cell(Vector2i(x, y), 0, Vector2i(posmod(x+y, 8), 3 if edge or corner else 2))

func _create_prop(kind: String, point: Vector2, data: Dictionary = {}) -> void:
	var frames: SpriteFrames = load("res://resources/art/" + kind + ".tres") as SpriteFrames
	if frames == null:
		push_error("Missing prop animation: " + kind)
		return
	var sizes: Dictionary = {"pine": Vector2(13, 11), "oak": Vector2(16, 12), "house": Vector2(82, 37), "crystal": Vector2(30, 14), "rock": Vector2(24, 13), "lamp": Vector2(6, 6), "sign": Vector2(12, 8), "fence": Vector2(48, 6)}
	var base: Node2D
	if sizes.has(kind):
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 2
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = sizes[kind]
		collision.shape = shape
		collision.position.y = -16 if kind == "house" else -3
		body.add_child(collision)
		base = body
		obstacle_count += 1
	else:
		base = Node2D.new()
	base.name = kind.capitalize()
	base.position = point
	if kind == "fence" and point.y == 160:
		base.add_to_group("north_gate")
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = frames
	var frame_texture: Texture2D = frames.get_frame_texture(&"idle", 0)
	sprite.centered = false
	sprite.position = Vector2(-frame_texture.get_width() / 2.0, -frame_texture.get_height() + 4)
	base.add_child(sprite)
	sprite.play(&"idle")
	sprite.frame = posmod(int(point.x * 7 + point.y * 13), frames.get_frame_count(&"idle"))
	if data.has("dialogue"):
		base.set_script(NPC_SCRIPT)
		base.set("npc_id", str(data.dialogue))
		base.set("dialogue_id", str(data.dialogue))
		base.set("display_name", str(data.get("name", "Ghi chép")))
	actors.add_child(base)

func _create_forest() -> void:
	# Fixed layout: three rings of trees frame the map, plus three authored groves.
	for row: int in range(3):
		for x: int in range(32, 1024, 40):
			_create_prop("pine" if (x / 8 + row) % 3 != 0 else "oak", Vector2(x + row * 9 % 17, 45 + row * 35))
			if definition.id != "whispering_forest" or absf(x-512)>66:
				_create_prop("pine", Vector2(x + row * 7 % 13, 735 - row * 25))
	for y: int in range(160, 720, 42):
		for x: int in [36, 78, 942, 986]:
			_create_prop("pine" if y % 3 else "oak", Vector2(x + y % 17, y))
	for grove: Array in definition.groves:
		for y: int in range(grove[1], grove[1]+grove[3], 3):
			for x: int in range(grove[0], grove[0]+grove[2], 3):
				_create_prop("pine" if (x+y) % 3 else "oak", Vector2(x*TILE + y%9, y*TILE))

func _create_boundaries() -> void:
	var body := StaticBody2D.new()
	body.name = "WorldBoundary"
	body.collision_layer = 1
	body.collision_mask = 2
	var rects: Array[Rect2] = [Rect2(0, -16, 1024, 32), Rect2(0, 752, 1024, 32), Rect2(-16, 0, 32, 768), Rect2(1008, 0, 32, 768)]
	for rect: Rect2 in rects:
		var collider := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collider.shape = shape
		collider.position = rect.get_center()
		body.add_child(collider)
	add_child(body)

func open_gate(open: bool) -> void:
	for node: Node in get_tree().get_nodes_in_group("north_gate"):
		if is_ancestor_of(node):
			node.visible = not open
			node.collision_layer = 0 if open else 1

func spawn_object(entry: Dictionary) -> Node2D:
	var object := OBJECT_SCRIPT.new()
	object.setup(entry)
	actors.add_child(object)
	return object

func consume_object(object: Node2D) -> void:
	var id: String = object.object_id
	if object.data.kind == "drop":
		for i: int in range(content_state.drops.size()-1,-1,-1):
			if content_state.drops[i].id == id:
				content_state.drops.remove_at(i)
	elif not content_state.collected.has(id):
		content_state.collected.append(id)
	object.remove_from_group("interactables")
	object.play_collected()
	object.queue_free()

func drop_item(item: String, count: int, point: Vector2, id: String) -> void:
	var entry: Dictionary = {"id":id,"kind":"drop","name":"Nhặt vật phẩm","item":item,"count":count,"at":[point.x,point.y]}
	content_state.drops.append(entry)
	spawn_object(entry)

func _on_enemy_defeated(id: String, point: Vector2, loot: Array) -> void:
	if content_state.defeated.has(id):
		return
	content_state.defeated.append(id)
	for i: int in range(loot.size()):
		drop_item(str(loot[i].item),int(loot[i].count),point+Vector2(i*20-10,0),id+"_loot_"+str(i))
	enemy_defeated.emit(id)

func snapshot() -> Dictionary:
	var state: Dictionary = content_state.duplicate(true)
	state.enemies = []
	for child: Node in actors.get_children():
		if child.is_in_group("enemies") and not child.is_queued_for_deletion() and child.health.current > 0:
			state.enemies.append({"id":child.enemy_id,"at":[child.position.x,child.position.y],"hp":child.health.current})
	return state

func _build_navigation() -> void:
	navigation.region = Rect2i(0,0,64,48)
	navigation.cell_size = Vector2(16,16)
	navigation.offset = Vector2(8,8)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for y: int in range(48):
		for x: int in range(64):
			var tile := Vector2i(x,y)
			if x == 0 or y == 0 or x == 63 or y == 47 or (ground.get_cell_source_id(tile)==0 and ground.get_cell_atlas_coords(tile).y==2):
				navigation.set_point_solid(tile)
	for body: Node in actors.get_children():
		if not body is StaticBody2D or body.collision_layer == 0:
			continue
		for child: Node in body.get_children():
			if child is CollisionShape2D:
				var rect: Rect2 = child.shape.get_rect().grow(5)
				for y: int in range(maxi(0,int((body.position.y+child.position.y+rect.position.y)/16)),mini(48,ceili((body.position.y+child.position.y+rect.end.y)/16))):
					for x: int in range(maxi(0,int((body.position.x+child.position.x+rect.position.x)/16)),mini(64,ceili((body.position.x+child.position.x+rect.end.x)/16))):
						navigation.set_point_solid(Vector2i(x,y))

func next_step(from: Vector2, to: Vector2) -> Vector2:
	var start := Vector2i(clampi(int(from.x/16),1,62),clampi(int(from.y/16),1,46))
	var goal := Vector2i(clampi(int(to.x/16),1,62),clampi(int(to.y/16),1,46))
	if navigation.is_point_solid(start) or navigation.is_point_solid(goal):
		return to
	var path: PackedVector2Array = navigation.get_point_path(start,goal)
	return path[1] if path.size()>1 else to
