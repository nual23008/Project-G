extends SceneTree
## Real player physics/hurtboxes: vitals, derived stats and one roll per swing.
const PROGRESSION := preload("res://scripts/progression/progression.gd")
const HEALTH := preload("res://scripts/combat/health.gd")
const HURTBOX := preload("res://scripts/combat/hurtbox.gd")
var checks: int = 0
var failures: Array[String] = []
var arena: Node2D
var player: CharacterBody2D
var targets: Array[Node2D] = []
var failures_reported: Array[String] = []
var resource_events: int = 0
var contact_observations: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ",message)
	if not value:
		failures.append(message)

func frames(count: int = 2) -> void:
	for i: int in range(count):
		await physics_frame
	await process_frame

func release_input() -> void:
	for action: String in ["move_left","move_right","move_up","move_down","sprint"]:
		Input.action_release(action)

func recover() -> void:
	release_input()
	player.input_enabled = true
	await frames(40)

func spawn_target(at: Vector2) -> Node2D:
	var target := Node2D.new()
	target.position = at
	target.add_to_group("enemies")
	var health := HEALTH.new()
	health.name = "Health"
	health.maximum = 200
	health.current = 200
	target.add_child(health)
	target.add_child(HURTBOX.new())
	arena.add_child(target)
	health.damaged.connect(func(amount: int, _direction: Vector2) -> void:
		contact_observations.append({"damage":amount,"body_frame":player.sprite.frame,"vfx_frame":player.melee.visual.frame}))
	return target

func reset_targets() -> void:
	for target: Node2D in targets:
		target.get_node("Health").restore(200)
	contact_observations.clear()

func check_blocked(message: String) -> void:
	var energy_before: float = player.energy
	var rng_before: int = player.crit_rng.state
	var reported_before: int = failures_reported.size()
	check(not player.empowered_attack(),message)
	check(player.energy == energy_before and player.crit_rng.state == rng_before,message+": no mana charge or critical roll")
	check(failures_reported.size() == reported_before+1,message+": actionable failure signal")

func test_interruptions(base: Dictionary) -> void:
	await recover()
	player.apply_stats(base,true)
	player.weapon_damage = 18
	player.facing = "down"
	reset_targets()
	check(player.empowered_attack(),"Interruption fixture starts a real empowered swing")
	await frames(2)
	var player_cooldown: float = player.cooldown
	check(player.melee.remaining > 0 and not player.melee.hit_applied,"Player is hurt before the pending swing reaches contact")
	check(player.get_node("Hurtbox").receive(1,player.global_position),"A real hurtbox hit interrupts the player's empowered anticipation")
	check(player.state == player.State.HURT and player.melee.remaining == 0 and not player.melee.visual.visible,"Hurt state cancels the pending player hitbox and hides its VFX immediately")
	check(player.cooldown == player_cooldown and player.energy == 30,"An interrupted legal swing keeps its cooldown and already charged 20 mana")
	await frames(8)
	check(targets[0].get_node("Health").current == 200 and targets[1].get_node("Health").current == 200 and contact_observations.is_empty(),"Interrupted empowered swing cannot damage real receivers after its old contact time")
	check(player.energy == 30 and not player.melee.visual.visible,"Interrupted empowered VFX stays hidden and mana is not refunded")
	await recover()
	player.apply_stats(base,true)
	var enemy_actor: CharacterBody2D = load("res://scripts/combat/enemy.gd").new()
	enemy_actor.position = player.position+Vector2(0,-26)
	enemy_actor.target = player
	arena.add_child(enemy_actor)
	# Only its brain is disabled: Health/Hurtbox/Melee still run real physics.
	# This isolates an in-flight swing without requiring village navigation.
	enemy_actor.set_physics_process(false)
	enemy_actor.state = enemy_actor.State.RECOVER
	enemy_actor.cooldown = 1.15
	enemy_actor.telegraph.show()
	check(enemy_actor.melee.begin(Vector2.DOWN,14),"Enemy interruption fixture starts its real melee component")
	await frames(2)
	var enemy_cooldown: float = enemy_actor.cooldown
	var hp_before: int = player.hp
	var enemy_hurtbox: Area2D
	for child: Node in enemy_actor.get_children():
		if child is Area2D:
			enemy_hurtbox = child
	check(enemy_hurtbox != null and enemy_hurtbox.receive(1,enemy_actor.global_position),"A real hurtbox hit interrupts enemy anticipation before contact")
	check(enemy_actor.state == enemy_actor.State.HURT and enemy_actor.melee.remaining == 0 and not enemy_actor.melee.visual.visible and not enemy_actor.telegraph.visible,"Enemy hurt cancels its pending strike and immediately hides strike/telegraph sprites")
	check(enemy_actor.cooldown == enemy_cooldown,"Enemy interruption preserves the already established cooldown")
	await frames(8)
	check(player.hp == hp_before and not enemy_actor.melee.hit_applied,"Interrupted enemy swing cannot damage the player on a later physics tick")
	enemy_actor.queue_free()
	await frames(2)
	await recover()

func run() -> void:
	load("res://scripts/core/input_setup.gd").configure()
	arena = Node2D.new()
	arena.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.add_child(arena)
	player = load("res://scenes/player/player.tscn").instantiate()
	arena.add_child(player)
	player.position = Vector2(200,200)
	player.action_failed.connect(func(reason: String) -> void: failures_reported.append(reason))
	player.resources_changed.connect(func(_e: float, _me: float, _s: float, _ms: float) -> void: resource_events += 1)
	await frames()
	var model := PROGRESSION.new()
	var base: Dictionary = model.derived_stats()
	player.apply_stats(base,true)
	check(player.hp == 100 and player.max_hp == 100 and player.energy == 50 and player.stamina == 100,"Starting health, mana and stamina preserve the contract")
	check(player.walk_speed == 72 and player.run_speed == 112 and player.strength == 10 and player.defense == 0 and player.luck == 0,"Starting movement and displayed combat stats preserve old balance")
	check(player.crit_chance == 0 and player.health.damage_reduction == 0 and player.weapon_damage == 18,"Base stats introduce neither random crits, mitigation nor duplicate weapon bonus")
	player.health.damage(35,Vector2.ZERO,0.0)
	player.restore_vitals(20,40)
	model.gain_experience(1000)
	for stat: String in PROGRESSION.STAT_KEYS:
		check(model.allocate(stat),"Earned points allocate to real stat: "+stat)
	var enhanced: Dictionary = model.derived_stats()
	player.apply_stats(enhanced)
	check(player.max_hp == 120 and player.hp == 85,"Health allocation preserves 35 missing HP instead of healing to full")
	check(player.max_energy == 60 and player.energy == 30 and player.max_stamina == 110 and player.stamina == 50,"Mana/stamina allocation preserves each missing amount")
	player.apply_stats(enhanced)
	check(player.hp == 85 and player.energy == 30 and player.stamina == 50,"Reapplying stats cannot refill missing vitals")
	check(player.walk_speed > 72 and player.run_speed > 112 and player.walk_speed == enhanced.walk_speed,"Speed allocation applies to the real controller")
	check(player.luck == 1 and player.strength == 11 and player.defense == 1 and player.crit_chance > 0 and player.health.damage_reduction > 0,"Luck, strength and defense derived properties are active")
	player.weapon_damage = 18+int(enhanced.damage_bonus)
	player.apply_stats(enhanced)
	check(player.weapon_damage == 20,"Main-supplied weapon damage is not increased twice by apply_stats")
	player.health.current = 0
	player.apply_stats(enhanced)
	check(player.hp == 0,"Stat allocation never resurrects a dead player")
	player.apply_stats(base,true)
	player.weapon_damage = 18
	await recover()
	player.apply_stats(base,true)
	Input.action_press("move_right")
	Input.action_press("sprint")
	var start: Vector2 = player.position
	await frames(60)
	check(absf(player.stamina-82.0) < .4 and player.position.x-start.x > 110,"Actual sprint movement costs 18 stamina per second at the original run speed")
	Input.action_release("move_right")
	await frames(20)
	check(player.stamina >= 81.6 and not player.sprinting,"Holding Shift while stationary spends no stamina")
	release_input()
	player.restore_vitals(10,50)
	await frames(30)
	check(is_equal_approx(player.energy,10) and is_equal_approx(player.stamina,50),"Mana and stamina respect their regeneration delays")
	await frames(30)
	check(absf(player.stamina-58.0) < .4 and is_equal_approx(player.energy,10),"Stamina regenerates at 20 per second after 0.6 seconds")
	await frames(60)
	check(absf(player.energy-11.5) < .1,"Mana regenerates at 3 per second after 1.5 seconds")
	var paused_energy: float = player.energy
	var paused_stamina: float = player.stamina
	var paused_position: Vector2 = player.position
	paused = true
	Input.action_press("move_right")
	Input.action_press("sprint")
	await frames(60)
	check(player.energy == paused_energy and player.stamina == paused_stamina and player.position == paused_position,"World pause freezes regeneration, sprint spending and movement")
	paused = false
	release_input()
	player.restore_vitals(50,20.1)
	Input.action_press("move_right")
	Input.action_press("sprint")
	await frames(80)
	check(player.stamina == 0 and player.sprint_exhausted and is_equal_approx(player.velocity.length(),72),"Exhaustion falls back to walking without an on/off sprint jitter")
	Input.action_release("move_right")
	await frames(60)
	check(player.stamina > 0 and player.stamina < 20 and player.sprint_exhausted,"Exhaustion remains locked while stamina recovers below 20")
	await frames(30)
	check(player.stamina >= 20 and not player.sprint_exhausted,"Sprint unlocks only after recovering 20 stamina")
	Input.action_press("move_right")
	await frames(2)
	check(player.sprinting and is_equal_approx(player.velocity.length(),112),"Sprint resumes at the original run speed after recovery")
	await recover()
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.position = player.position+Vector2(15,0)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(16,100)
	collision.shape = rectangle
	wall.add_child(collision)
	arena.add_child(wall)
	Input.action_press("move_right")
	Input.action_press("sprint")
	await frames(10)
	player.restore_vitals(50,100)
	await frames(20)
	check(player.stamina == 100 and not player.sprinting,"Pressing into a wall does not spend stamina without actual motion")
	wall.queue_free()
	await recover()
	player.apply_stats(base,true)
	player.facing = "down"
	targets.append(spawn_target(player.position+Vector2(-4,26)))
	targets.append(spawn_target(player.position+Vector2(4,26)))
	await frames(3)
	var zero_luck_state: int = player.crit_rng.state
	check(player.attack(),"Normal attack begins with the original public API")
	await frames(7)
	check(targets[0].get_node("Health").current == 182 and targets[1].get_node("Health").current == 182,"Normal melee still deals 18 damage to real hurtboxes")
	check(not player.last_swing_critical and player.crit_rng.state == zero_luck_state,"Zero luck never rolls the RNG during regression combat")
	await recover()
	reset_targets()
	player.restore_vitals(50,80)
	Input.action_press("move_right")
	Input.action_press("sprint")
	check(player.empowered_attack(),"Empowered attack starts using the same body animation")
	check(player.energy == 30 and player.melee.damage == 32 and player.melee.empowered_swing,"Empowered attack charges 20 mana and applies rounded 1.8x damage")
	check(player.melee.visual.sprite_frames == load("res://resources/art/empowered_slash.tres"),"Empowered swing uses its own live VFX resource")
	check_blocked("Cooldown blocks a second empowered swing")
	await frames(7)
	check(targets[0].get_node("Health").current == 168 and targets[1].get_node("Health").current == 168,"Empowered damage reaches both real physics receivers")
	check(not contact_observations.is_empty() and contact_observations[0].body_frame == 2 and contact_observations[0].vfx_frame == 2,"Empowered body and VFX contact stay on the damage tick")
	check(player.stamina == 80,"Attack lock consumes no stamina even while movement and Shift are held")
	await recover()
	player.crit_chance = .49
	player.restore_vitals(50,80)
	player.input_enabled = false
	check_blocked("UI lock blocks empowered attacks")
	var locked_position: Vector2 = player.position
	Input.action_press("move_right")
	Input.action_press("sprint")
	await frames(15)
	check(player.position == locked_position and player.stamina == 80,"Blocked UI input cannot move or consume stamina")
	release_input()
	player.input_enabled = true
	player.health.current = 0
	check_blocked("Death blocks empowered attacks")
	player.health.restore(100)
	player.state = player.State.HURT
	check_blocked("Hurt state blocks empowered attacks")
	player.state = player.State.IDLE
	player.weapon_damage = 0
	check_blocked("Missing weapon blocks empowered attacks")
	player.weapon_damage = 18
	player.restore_vitals(19,80)
	check_blocked("Insufficient mana blocks empowered attacks")
	await test_interruptions(base)
	player.apply_stats(enhanced,true)
	player.weapon_damage = 18+int(enhanced.damage_bonus)
	reset_targets()
	var probe := RandomNumberGenerator.new()
	var winning_seed: int = 0
	for candidate: int in range(1,100000):
		probe.seed = candidate
		if probe.randf() < player.crit_chance:
			winning_seed = candidate
			break
	check(winning_seed > 0,"Dedicated combat RNG can be seeded for a deterministic luck test")
	probe.seed = winning_seed
	probe.randf()
	var expected_rng_state: int = probe.state
	player.crit_rng.seed = winning_seed
	player.facing = "down"
	check(player.attack(),"Strength/luck swing starts with allocated real model stats")
	check(player.last_swing_critical and player.melee.damage == 30 and player.crit_rng.state == expected_rng_state,"A critical uses strength bonus and exactly one 1.5x RNG roll per swing")
	await frames(7)
	check(targets[0].get_node("Health").current == 170 and targets[1].get_node("Health").current == 170,"One critical roll applies consistently across multiple hurtboxes")
	var before_defense_hit: int = player.hp
	player.health.damage(50,Vector2.ZERO,0.0)
	check(before_defense_hit-player.hp == 49,"Allocated defense changes actual incoming damage on the real player")
	var health := HEALTH.new()
	health.damage_reduction = .5
	check(health.damage(20,Vector2.ZERO,0.0) and health.current == 90,"Defense reduces real incoming health damage")
	health.damage_reduction = 1.0
	check(health.damage_reduction < .8 and health.damage(1,Vector2.ZERO,0.0) and health.current == 89,"Defense is capped below 80 percent and every accepted hit deals at least one")
	health.damage_reduction = NAN
	check(health.damage_reduction == 0 and not health.damage(0,Vector2.ZERO,0.0),"Invalid reduction cannot create immunity and zero damage remains rejected")
	health.free()
	await recover()
	player.apply_stats(enhanced,true)
	Input.action_press("move_right")
	await frames(2)
	check(is_equal_approx(player.sprite.speed_scale,player.walk_speed/72.0),"Walk animation cadence follows allocated movement speed")
	Input.action_press("sprint")
	await frames(2)
	check(is_equal_approx(player.sprite.speed_scale,1.45*player.walk_speed/72.0),"Sprint animation keeps the stride synchronized with the speed stat")
	release_input()
	await frames(2)
	check(player.sprite.speed_scale == 1.0,"Standing idle keeps its own cadence after speed upgrades")
	check(player.attack(),"A speed-upgraded player can start a normal swing")
	await frames(2)
	check(player.sprite.speed_scale == 1.0,"Speed upgrades do not accelerate attack/contact timing")
	player.restore_vitals(10,40)
	player.health.current = 0
	await frames(60)
	check(player.energy == 10 and player.stamina == 40,"Dead actors cannot regenerate mana or stamina")
	check(resource_events > 10,"Live vital mutations emit resource updates for the UI")
	release_input()
	arena.queue_free()
	await frames(2)
	print("PROGRESSION COMBAT RESULT: ",checks-failures.size(),"/",checks," checks passed")
	quit(0 if failures.is_empty() else 1)
