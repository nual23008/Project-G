extends RefCounted
## Integer XP and a conserved stat-point budget. Definitions never own live vitals.
signal changed
signal level_gained(old_level: int, new_level: int, points: int)

const MAX_LEVEL: int = 9999
const POINTS_PER_LEVEL: int = 5
const MAX_POINTS: int = (MAX_LEVEL - 1) * POINTS_PER_LEVEL
const MAX_INTEGER: int = 9223372036854775807
const STAT_KEYS: Array[String] = ["health", "energy", "stamina", "speed", "luck", "strength", "defense"]

var level: int = 1
var experience: int = 0
var unspent_points: int = 0
var allocated: Dictionary = {}

func _init() -> void:
	reset()

func reset() -> void:
	level = 1
	experience = 0
	unspent_points = 0
	allocated = {}
	for stat: String in STAT_KEYS:
		allocated[stat] = 0
	changed.emit()

func xp_required(level_override: int = 0) -> int:
	var current_level: int = level if level_override == 0 else level_override
	if current_level < 1 or current_level >= MAX_LEVEL:
		return 0
	var offset: int = current_level - 1
	return 100 + 25 * offset + 5 * offset * offset

func gain_experience(amount: Variant) -> Dictionary:
	var result: Dictionary = {"accepted": false, "gained": 0, "old_level": level, "new_level": level, "levels_gained": 0, "points_gained": 0, "max_level": level == MAX_LEVEL}
	if not _integer(amount, 0, MAX_INTEGER):
		return result
	result.accepted = true
	var grant: int = int(amount)
	if grant == 0 or level == MAX_LEVEL:
		return result
	var left: int = grant
	var old_level: int = level
	# Subtract one bounded requirement at a time instead of adding an arbitrary
	# grant to experience: even INT64_MAX cannot overflow the XP accumulator.
	while left > 0 and level < MAX_LEVEL:
		var needed: int = xp_required() - experience
		if left < needed:
			experience += left
			left = 0
		else:
			left -= needed
			experience = 0
			level += 1
	if level == MAX_LEVEL:
		experience = 0
	var points: int = (level - old_level) * POINTS_PER_LEVEL
	unspent_points += points
	result.gained = grant - left
	result.new_level = level
	result.levels_gained = level - old_level
	result.points_gained = points
	result.max_level = level == MAX_LEVEL
	if level != old_level:
		level_gained.emit(old_level, level, points)
	changed.emit()
	return result

func allocate(stat: String, amount: Variant = 1) -> bool:
	if not STAT_KEYS.has(stat) or not _integer(amount, 1, MAX_POINTS) or int(amount) > unspent_points:
		return false
	allocated[stat] = int(allocated[stat]) + int(amount)
	unspent_points -= int(amount)
	changed.emit()
	return true

func derived_stats() -> Dictionary:
	return _derived(allocated)

func _derived(points: Dictionary) -> Dictionary:
	var speed_points: int = int(points.speed)
	var luck_points: int = int(points.luck)
	var strength_points: int = int(points.strength)
	var defense_points: int = int(points.defense)
	var walk: float = 72.0 + 108.0 * speed_points / (speed_points + 50.0)
	var luck_rate: float = 0.5 * luck_points / (luck_points + 100.0)
	return {
		"max_health": 100 + 20 * int(points.health),
		"max_energy": 50 + 10 * int(points.energy),
		"max_stamina": 100 + 10 * int(points.stamina),
		"walk_speed": walk,
		"run_speed": walk * 112.0 / 72.0,
		"luck": luck_points,
		"strength": 10 + strength_points,
		"defense": defense_points,
		"damage_bonus": 2 * strength_points,
		"damage_reduction": 0.8 * defense_points / (defense_points + 40.0),
		"crit_chance": luck_rate,
		"xp_bonus": luck_rate
	}

func snapshot() -> Dictionary:
	return {"level": level, "experience": experience, "unspent_points": unspent_points, "allocated": allocated.duplicate(true)}

func restore(data: Variant) -> bool:
	if not valid_data(data):
		return false
	level = int(data.level)
	experience = int(data.experience)
	unspent_points = int(data.unspent_points)
	allocated = {}
	for stat: String in STAT_KEYS:
		allocated[stat] = int(data.allocated[stat])
	# Loading is not a new level reward and must never emit level_gained.
	changed.emit()
	return true

func valid_data(data: Variant) -> bool:
	if not data is Dictionary or not _integer(data.get("level"), 1, MAX_LEVEL) or not _integer(data.get("unspent_points"), 0, MAX_POINTS) or not data.get("allocated") is Dictionary or data.allocated.size() != STAT_KEYS.size():
		return false
	var saved_level: int = int(data.level)
	var requirement: int = xp_required(saved_level)
	if not _integer(data.get("experience"), 0, 0 if saved_level == MAX_LEVEL else requirement - 1):
		return false
	var total: int = int(data.unspent_points)
	for stat: String in STAT_KEYS:
		if not _integer(data.allocated.get(stat), 0, MAX_POINTS):
			return false
		total += int(data.allocated[stat])
	return total == POINTS_PER_LEVEL * (saved_level - 1)

func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	if value is int:
		return value >= minimum and value <= maximum
	if not value is float or not is_finite(value) or value != floorf(value):
		return false
	# 2^63 is exactly representable as a float but is outside signed int64.
	return value >= minimum and value < 9223372036854775808.0 and value <= maximum
