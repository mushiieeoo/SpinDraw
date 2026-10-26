class_name TopDesign
extends RefCounted
## A finished drawing: cells + hull + centroid + stats + archetype + color.
## Created from the drawing box ("lock in") or randomly for a CPU opponent.

var cells: Array[Vector2i] = []
var hull := PackedVector2Array()
var centroid := Vector2.ZERO
var stats: TopStats
var archetype := 0
var color := Pal.RED
var is_cpu := false


## Returns null if the drawing is empty or too small.
static func from_cells(p_cells: Array[Vector2i], p_arch: int, p_color: Color) -> TopDesign:
	if p_cells.is_empty():
		return null
	var h := ShapeUtils.convex_hull(ShapeUtils.cells_to_points(p_cells, GameConst.GRID))
	if h.size() < 3:
		return null
	var ac := ShapeUtils.area_and_centroid(h)
	var area: float = ac["area"]
	if area < GameConst.MIN_AREA:
		return null
	var d := TopDesign.new()
	d.cells = p_cells.duplicate()
	d.hull = h
	d.centroid = ac["centroid"]
	d.stats = TopStats.from_area(area)
	d.archetype = p_arch
	d.color = p_color
	return d


## A random blobby/star-ish shape so you can fight a CPU without drawing two tops.
static func random_cpu(p_arch: int, p_color: Color) -> TopDesign:
	var n := GameConst.GRID_N
	var center := Vector2(n / 2.0, n / 2.0)
	var r := randf_range(4.0, 13.0)
	var lobes := randi_range(2, 6)
	var wobble := randf_range(0.0, 0.45)
	var phase := randf() * TAU
	var out: Array[Vector2i] = []
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5, y + 0.5) - center
			var rr := r * (1.0 + wobble * sin(lobes * d.angle() + phase))
			if d.length() <= rr:
				out.append(Vector2i(x, y))
	var design := from_cells(out, p_arch, p_color)
	if design != null:
		design.is_cpu = true
	return design
