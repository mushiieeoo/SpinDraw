class_name ShapeUtils
extends RefCounted
## Geometry helpers: cells -> points -> convex hull -> area + centroid.

## Every drawn cell contributes its 4 corners, so the hull wraps the full squares.
static func cells_to_points(cells: Array[Vector2i], grid: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for c in cells:
		var o := Vector2(c) * grid
		pts.append(o)
		pts.append(o + Vector2(grid, 0))
		pts.append(o + Vector2(grid, grid))
		pts.append(o + Vector2(0, grid))
	return pts


## Convex hull without the duplicated closing point Godot adds.
static func convex_hull(points: PackedVector2Array) -> PackedVector2Array:
	var hull := Geometry2D.convex_hull(points)
	if hull.size() > 1 and hull[0].is_equal_approx(hull[hull.size() - 1]):
		hull.remove_at(hull.size() - 1)
	return hull


## Polygon area and area-centroid (shoelace formula).
static func area_and_centroid(poly: PackedVector2Array) -> Dictionary:
	var a2 := 0.0
	var cx := 0.0
	var cy := 0.0
	var n := poly.size()
	for i in n:
		var p := poly[i]
		var q := poly[(i + 1) % n]
		var cross := p.x * q.y - q.x * p.y
		a2 += cross
		cx += (p.x + q.x) * cross
		cy += (p.y + q.y) * cross
	if absf(a2) < 0.0001:
		return {"area": 0.0, "centroid": Vector2.ZERO}
	return {"area": absf(a2) * 0.5, "centroid": Vector2(cx, cy) / (3.0 * a2)}


## Bresenham line between two grid cells (no gaps when the mouse moves fast).
static func line_cells(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var x := a.x
	var y := a.y
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var err := dx + dy
	while true:
		out.append(Vector2i(x, y))
		if x == b.x and y == b.y:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
	return out
