extends Node
signal changed(current: int, maximum: int)
signal damaged(amount: int, direction: Vector2)
signal died
@export var maximum: int = 100
var current: int = 100
var immunity: float = 0.0
var damage_reduction: float = 0.0:
	set(value):
		damage_reduction = clampf(value,0.0,0.799999999) if is_finite(value) else 0.0

func _physics_process(delta: float) -> void:
	immunity = maxf(0.0, immunity-delta)

func damage(amount: int, direction: Vector2, invulnerability: float = 0.5) -> bool:
	if amount <= 0 or current <= 0 or immunity > 0.0:
		return false
	var received: int = maxi(1,roundi(amount*(1.0-damage_reduction)))
	current = maxi(0, current-received)
	immunity = invulnerability
	changed.emit(current, maximum)
	damaged.emit(received, direction)
	if current == 0:
		died.emit()
	return true

func heal(amount: int) -> bool:
	if current <= 0 or current >= maximum or amount <= 0:
		return false
	current = mini(maximum, current+amount)
	changed.emit(current, maximum)
	return true

func restore(value: int) -> void:
	current = clampi(value, 1, maximum)
	immunity = 0.0
	changed.emit(current, maximum)
