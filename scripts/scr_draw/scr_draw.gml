

function draw_vertex_3d (_x, _y, _z)
{
	gpu_set_depth(_z)
	draw_vertex(_x, _y)
}

function corners_linelist (x0, y0, z0, x1, y1, z1)
{
	draw_vertex_3d(x0, y0, z0)
	draw_vertex_3d(x1, y0, z0)
		
	draw_vertex_3d(x0, y0, z0)
	draw_vertex_3d(x0, y1, z0)

	draw_vertex_3d(x0, y0, z0)
	draw_vertex_3d(x0, y0, z1)

	draw_vertex_3d(x1, y1, z1)
	draw_vertex_3d(x0, y1, z1)

	draw_vertex_3d(x1, y1, z1)
	draw_vertex_3d(x1, y0, z1)

	draw_vertex_3d(x1, y1, z1)
	draw_vertex_3d(x1, y1, z0)
	
	draw_vertex_3d(x1, y0, z0)
	draw_vertex_3d(x1, y1, z0)
	
	draw_vertex_3d(x0, y1, z0)
	draw_vertex_3d(x1, y1, z0)
	
	draw_vertex_3d(x0, y0, z1)
	draw_vertex_3d(x0, y1, z1)
	
	draw_vertex_3d(x0, y0, z1)
	draw_vertex_3d(x1, y0, z1)
	
	draw_vertex_3d(x1, y0, z0)
	draw_vertex_3d(x1, y0, z1)
	
	draw_vertex_3d(x0, y1, z0)
	draw_vertex_3d(x0, y1, z1)
}
