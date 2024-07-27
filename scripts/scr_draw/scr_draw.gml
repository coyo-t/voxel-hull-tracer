
function create_bkd_octohedron ()
{
	var vb = vertex_create_buffer()
	vertex_format_begin()
	vertex_format_add_position_3d()
	var fmt = vertex_format_end()
	
	vertex_begin(vb, fmt)
	vertex_position_3d(vb, 0, 0, 1)
	vertex_position_3d(vb, 1, 0, 0)
	vertex_position_3d(vb, 0, 1, 0)
	
	vertex_position_3d(vb, 0, 0, 1)
	vertex_position_3d(vb, 0, 1, 0)
	vertex_position_3d(vb, -1, 0, 0)
	
	vertex_position_3d(vb, 0, 0, 1)
	vertex_position_3d(vb, 0, -1, 0)
	vertex_position_3d(vb, 1, 0, 0)

	vertex_position_3d(vb, 0, 0, 1)
	vertex_position_3d(vb, -1, 0, 0)
	vertex_position_3d(vb, 0, -1, 0)

	vertex_position_3d(vb, 0, 0, -1)
	vertex_position_3d(vb, 1, 0, 0)
	vertex_position_3d(vb, 0, 1, 0)
	
	vertex_position_3d(vb, 0, 0, -1)
	vertex_position_3d(vb, 0, 1, 0)
	vertex_position_3d(vb, -1, 0, 0)
	
	vertex_position_3d(vb, 0, 0, -1)
	vertex_position_3d(vb, 0, -1, 0)
	vertex_position_3d(vb, 1, 0, 0)

	vertex_position_3d(vb, 0, 0, -1)
	vertex_position_3d(vb, -1, 0, 0)
	vertex_position_3d(vb, 0, -1, 0)
	
	vertex_end(vb)
	
	vertex_freeze(vb)
	
	static __BKD_V = function (_vb, _fmt) constructor begin
		vb = _vb
		format = _fmt
		
		static submit = function (_tex)
		{
			vertex_submit(vb, pr_trianglelist, _tex)
		}
		
		static free = function ()
		{
			vertex_delete_buffer(vb)
			vertex_format_delete(format)
		}
	end
	
	return new __BKD_V(vb, fmt)
}

function draw_vertex_3d (_x, _y, _z)
{
	gpu_set_depth(_z)
	draw_vertex(_x, _y)
}

function draw_vertex_3d_colour (_x, _y, _z, _c, _a=1.0)
{
	gpu_set_depth(_z)
	draw_vertex_color(_x, _y, _c, _a)
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
