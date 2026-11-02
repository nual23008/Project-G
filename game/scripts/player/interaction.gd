extends Node
## Composition component: proximity + line of sight, no quest dependencies.
signal target_changed(target: Node2D)

@export var reach: float = 42.0
var target: Node2D

func _physics_process(_delta: float) -> void:
	var nearest: Node2D = find_nearest()
	if nearest != target:
		target = nearest
		target_changed.emit(target)

func find_nearest() -> Node2D:
	var actor := get_parent() as CharacterBody2D
	var nearest: Node2D = null
	var best: float = reach * reach
	for candidate: Node in get_tree().get_nodes_in_group("interactables"):
		if not is_instance_valid(candidate) or not candidate is Node2D:
			continue
		var distance: float = actor.global_position.distance_squared_to(candidate.global_position)
		if distance > best:
			continue
		var ray := PhysicsRayQueryParameters2D.create(actor.global_position, candidate.global_position, 5, [actor.get_rid()])
		var hit: Dictionary = actor.get_world_2d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty() and hit.collider != candidate:
			continue
		nearest = candidate
		best = distance
	return nearest

func get_dialogue_id() -> String:
	# Refresh at the interaction edge; a stale prompt never opens a distant NPC.
	target = find_nearest()
	return str(target.get("dialogue_id")) if is_instance_valid(target) else ""

func get_target() -> Node2D:
	target = find_nearest()
	return target
