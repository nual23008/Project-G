extends RefCounted
## Short-lived sprite effects stay below the pausable world and never mutate saves.

static func spawn(parent: Node, frames: SpriteFrames, at: Vector2, pivot: Vector2, state: StringName = &"play") -> AnimatedSprite2D:
	var effect := AnimatedSprite2D.new()
	effect.name = "SpriteEffect"
	effect.sprite_frames = frames
	effect.centered = false
	effect.offset = -pivot
	parent.add_child(effect)
	effect.global_position = at
	effect.reset_physics_interpolation()
	effect.animation_finished.connect(effect.queue_free)
	effect.play(state)
	return effect
