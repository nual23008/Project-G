extends Node
signal changed(current: int, maximum: int)
signal damaged(amount: int, direction: Vector2)
signal died
@export var maximum: int = 100
var current: int = 100
var immunity: float = 0.0

func _physics_process(delta: float) -> void:
	immunity = maxf(0.0, immunity-delta)

func damage(amount: int, direction: Vector2, invulnerability: float = 0.5) -> bool:
	if amount <= 0 or current <= 0 or immunity > 0.0:
		return false
	current = maxi(0, current-amount)
	immunity = invulnerability
	changed.emit(current, maximum)
	damaged.emit(amount, direction)
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
