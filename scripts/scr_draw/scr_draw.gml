

function draw_vertex_3d (_x, _y, _z)
{
	gpu_set_depth(_z)
	draw_vertex(_x, _y)
}
