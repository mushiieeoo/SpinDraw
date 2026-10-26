class_name TopStats
extends RefCounted
## Stats come from the hull area. Big = tanky and slow, small = glass cannon.

# Each range goes from TINY (x) to HUGE (y).
const HP_RANGE := Vector2(60.0, 300.0)
const MASS_RANGE := Vector2(0.6, 4.0)
const SPEED_RANGE := Vector2(700.0, 280.0)   # tiny is FAST
const RPM_RANGE := Vector2(2200.0, 700.0)    # tiny spins FAST

var area := 0.0
var size_t := 0.0   # 0 = tiny, 1 = huge
var hp := 0.0
var mass := 0.0
var speed := 0.0
var rpm := 0.0


static func from_area(a: float) -> TopStats:
	var s := TopStats.new()
	s.area = a
	s.size_t = clampf(sqrt(a / GameConst.AREA_REF), 0.0, 1.0)
	s.hp = lerpf(HP_RANGE.x, HP_RANGE.y, s.size_t)
	s.mass = lerpf(MASS_RANGE.x, MASS_RANGE.y, s.size_t)
	s.speed = lerpf(SPEED_RANGE.x, SPEED_RANGE.y, s.size_t)
	s.rpm = lerpf(RPM_RANGE.x, RPM_RANGE.y, s.size_t)
	return s


## Spin speed in rad/s for the physics body.
func spin_speed() -> float:
	return rpm * TAU / 60.0 / GameConst.SPIN_DIV
