


function MapModelBuilder () constructor begin
	static FORMAT = function () {
		vertex_format_begin()
		vertex_format_add_position_3d()
		vertex_format_add_color()
		return vertex_format_end()
	}()
	
	vb = vertex_create_buffer()
	
	cur_colour = c_white
	cur_shade = 1.0
	cur_mix = c_white
	
	static begin_building = function ()
	{
		vertex_begin(vb, FORMAT)
		cur_colour = c_white
		cur_shade = 1.0
		__update_mix()
	}
	
	static end_building = function ()
	{
		vertex_end(vb)
	}
	
	static add_top_face = function (_type, _x, _y, _z)
	{
		var x0 = _x
		var y0 = _y
		var x1 = _x + 1
		var y1 = _y + 1
		_z += 1
		
		set_cur_colour(_type.colour)
		set_cur_shade(1.0)
		
		__addv(vb, x0, y1, _z)
		__addv(vb, x1, y1, _z)
		__addv(vb, x0, y0, _z)

		__addv(vb, x1, y1, _z)
		__addv(vb, x1, y0, _z)
		__addv(vb, x0, y0, _z)
	}
	
	static add_bottom_face = function (_type, _x, _y, _z)
	{
		var x0 = _x
		var y0 = _y
		var x1 = _x + 1
		var y1 = _y + 1
		
		set_cur_colour(_type.colour)
		set_cur_shade(0.5)
		
		__addv(vb, x0, y0, _z)
		__addv(vb, x1, y0, _z)
		__addv(vb, x0, y1, _z)
		
		__addv(vb, x1, y0, _z)
		__addv(vb, x1, y1, _z)
		__addv(vb, x0, y1, _z)
	}
	
	static add_south_face = function (_type, _x, _y, _z)
	{
		var x0 = _x
		var z0 = _z
		var x1 = _x + 1
		var z1 = _z + 1
		
		set_cur_colour(_type.colour)
		set_cur_shade(0.6)
		
		__addv(vb, x0, _y, z1)
		__addv(vb, x1, _y, z1)
		__addv(vb, x0, _y, z0)
		
		__addv(vb, x1, _y, z1)
		__addv(vb, x1, _y, z0)
		__addv(vb, x0, _y, z0)
	}
	
	static add_north_face = function (_type, _x, _y, _z)
	{
		var x0 = _x
		var z0 = _z
		var x1 = _x + 1
		var z1 = _z + 1
		_y += 1
		
		set_cur_colour(_type.colour)
		set_cur_shade(0.6)
		
		__addv(vb, x1, _y, z1)
		__addv(vb, x0, _y, z1)
		__addv(vb, x1, _y, z0)
		
		__addv(vb, x0, _y, z1)
		__addv(vb, x0, _y, z0)
		__addv(vb, x1, _y, z0)
	}
	
	static add_east_face = function (_type, _x, _y, _z)
	{
		var y0 = _y
		var y1 = _y + 1
		var z0 = _z
		var z1 = _z + 1
		_x += 1
		
		set_cur_colour(_type.colour)
		set_cur_shade(0.8)
		
		__addv(vb, _x, y0, z1)
		__addv(vb, _x, y1, z1)
		__addv(vb, _x, y0, z0)
		
		__addv(vb, _x, y1, z1)
		__addv(vb, _x, y1, z0)
		__addv(vb, _x, y0, z0)
	}
	
	static add_west_face = function (_type, _x, _y, _z)
	{
		var y0 = _y
		var y1 = _y + 1
		var z0 = _z
		var z1 = _z + 1
		
		set_cur_colour(_type.colour)
		set_cur_shade(0.8)
		
		__addv(vb, _x, y1, z1)
		__addv(vb, _x, y0, z1)
		__addv(vb, _x, y0, z0)
		
		__addv(vb, _x, y1, z1)
		__addv(vb, _x, y0, z0)
		__addv(vb, _x, y1, z0)
		
	}
	
	static __update_mix = function ()
	{
		cur_mix = merge_color(c_black, cur_colour, cur_shade)
	}
	
	static set_cur_colour = function (_c)
	{
		if _c <> cur_colour
		{
			cur_colour = _c
			__update_mix()
		}
	}
	
	static set_cur_shade = function (_s)
	{
		if _s <> cur_shade
		{
			cur_shade = _s
			__update_mix()
		}
	}
	
	
	static __addv = function (_vb, _x, _y, _z)
	{
		vertex_position_3d(_vb, _x, _y, _z)
		vertex_color(_vb, cur_mix, 1.0)
	}
end

