shader_type canvas_item;
// Measured per-sprite outline removes neighboring locker states from the
// overlapping atlas rectangles. A small allowance retains antialiased edges.
uniform vec2 clip_points[128];
uniform int clip_count = 0;
varying vec2 crop_pixel;
void vertex() {
	crop_pixel = VERTEX;
}
void fragment() {
	bool inside = false;
	float nearest_edge = 1000000.0;
	for (int i = 0; i < 128; i++) {
		if (i >= clip_count) { break; }
		vec2 a = clip_points[i];
		vec2 b = clip_points[(i + 1) % clip_count];
		vec2 edge = b - a;
		float t = clamp(dot(crop_pixel - a, edge) / max(dot(edge, edge), 0.001), 0.0, 1.0);
		nearest_edge = min(nearest_edge, length(crop_pixel - a - edge * t));
		if ((a.y > crop_pixel.y) != (b.y > crop_pixel.y)) {
			float crossing = a.x + (crop_pixel.y - a.y) * edge.x / edge.y;
			if (crop_pixel.x < crossing) { inside = !inside; }
		}
	}
	if (!inside && nearest_edge > 1.25) { discard; }
}
