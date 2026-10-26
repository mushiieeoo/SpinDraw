class_name MovementAI
extends Node
## Movement brain, attached as a child of a Top.
##   ATTACK  - steers toward the enemy
##   SPEED   - stays fast, changes direction randomly, ricochets off the walls
##   DEFENSE - drifts to the arena center and resists being pushed away

var archetype := 0
var target: Top            # the enemy (set by main)
var center := Vector2.ZERO # arena center in GLOBAL coordinates (set by main)

var _top: Top
var _turn_timer := 0.0


func _ready() -> void:
	_top = get_parent() as Top
	_turn_timer = randf_range(0.4, 1.0)


func _physics_process(delta: float) -> void:
	if _top == null or _top.stats == null:
		return
	match archetype:
		GameConst.Archetype.ATTACK:
			_attack()
		GameConst.Archetype.SPEED:
			_speed(delta)
		GameConst.Archetype.DEFENSE:
			_defense()


func _attack() -> void:
	if not is_instance_valid(target):
		return
	var to_enemy := target.global_position - _top.global_position
	var desired := to_enemy.normalized() * _top.max_speed * 0.85
	# steering = (wanted velocity - current velocity), capped
	var accel := (desired - _top.linear_velocity) * 4.0
	var max_a := _top.max_speed * 3.0
	if accel.length() > max_a:
		accel = accel.normalized() * max_a
	_top.apply_central_force(accel * _top.mass)


func _speed(delta: float) -> void:
	var v := _top.linear_velocity
	var dir := v.normalized() if v.length() > 1.0 else Vector2.from_angle(randf() * TAU)
	_turn_timer -= delta
	if _turn_timer <= 0.0:
		dir = dir.rotated(randf_range(-1.3, 1.3))      # sudden erratic swerve
		_turn_timer = randf_range(0.5, 1.4)
	# keep the speed high; wall bounces change the direction we read next frame
	_top.linear_velocity = dir * lerpf(v.length(), _top.max_speed * 0.9, 0.1)


func _defense() -> void:
	# spring toward the center + damping, so it settles instead of orbiting
	var to_center := center - _top.global_position
	var accel := to_center * 3.0 - _top.linear_velocity * 3.5
	_top.apply_central_force(accel * _top.mass)
