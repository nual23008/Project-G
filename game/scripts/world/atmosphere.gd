extends Node2D
## Manifest-backed warm light and fireflies; positions are snapped to art pixels.
const GLOW: SpriteFrames = preload("res://resources/art/glow.tres")
const FIREFLY: SpriteFrames = preload("res://resources/art/firefly.tres")
var elapsed: float = 0.0
var lights: Array[Vector2] = [Vector2(440, 375), Vector2(600, 375), Vector2(472, 547), Vector2(552, 547), Vector2(512, 305)]
var motes: Array[AnimatedSprite2D] = []

func _ready() -> void:
	for point: Vector2 in lights:
		var glow := AnimatedSprite2D.new()
		glow.name = "LanternGlow"
		glow.sprite_frames = GLOW
		glow.position = point
		add_child(glow)
		glow.play(&"idle")
	for i: int in range(35):
		var mote := AnimatedSprite2D.new()
		mote.name = "Firefly" + str(i)
		mote.sprite_frames = FIREFLY
		add_child(mote)
		mote.play(&"idle")
		mote.frame = i % FIREFLY.get_frame_count(&"idle")
		motes.append(mote)
	_update_motes()

func _process(delta: float) -> void:
	elapsed += delta
	_update_motes()

func _update_motes() -> void:
	for i: int in range(motes.size()):
		var x: float = 155.0 + fmod(i * 73.0, 730.0) + sin(elapsed * 0.31 + i) * 8.0
		var y: float = 185.0 + fmod(i * 47.0, 440.0) + cos(elapsed * 0.27 + i * 2.0) * 7.0
		motes[i].position = Vector2(x, y).round()
