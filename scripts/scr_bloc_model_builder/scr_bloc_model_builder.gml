function MapRenderer (_map) constructor begin
	map = _map
	built = false
	builder = new MapModelBuilder()
	
	static rebuild = function ()
	{
		if built
		{
			return
		}
		builder.begin_building()
		for (var zz = -1; zz < map.zsize; zz++)
		{
			for (var yy = 0; yy < map.ysize; yy++)
			{
				for (var xx = 0; xx < map.xsize; xx++)
				{
					var thing = map.get(xx, yy, zz)
					if array_length(thing.render_shapes) <= 0
					{
						continue
					}

					if not map.get(xx, yy, zz+1).is_full_block()
					{
						builder.add_top_face(thing, xx, yy, zz)
					}
				
					if not map.get(xx, yy, zz-1).is_full_block()
					{
						builder.add_bottom_face(thing, xx, yy, zz)
					}
				
					if not map.get(xx, yy+1, zz).is_full_block()
					{
						builder.add_north_face(thing, xx, yy, zz)
					}
				
					if not map.get(xx, yy-1, zz).is_full_block()
					{
						builder.add_south_face(thing, xx, yy, zz)
					}
				
					if not map.get(xx+1, yy, zz).is_full_block()
					{
						builder.add_east_face(thing, xx, yy, zz)
					}
				
					if not map.get(xx-1, yy, zz).is_full_block()
					{
						builder.add_west_face(thing, xx, yy, zz)
					}
				}
			}
		}
		builder.end_building()
		built = true
	}
	
	static draw = function ()
	{
		rebuild()
		
		var vbs = builder.vbs
		var txs = builder.textures
		
		for (var i = builder.vbcount; --i >= 0;)
		{
			vertex_submit(vbs[i], pr_trianglelist, txs[i])
		}
		
		//vertex_submit(builder.vb, pr_trianglelist, sprite_get_texture(spr_stone, 0))
	}

	static draw_world_axis = function ()
	{
		draw_primitive_begin(pr_linelist)
		draw_set_color(c_red)
		gpu_set_depth(0); draw_vertex(0, 0)
		gpu_set_depth(0); draw_vertex(map.xsize, 0)
		draw_set_color(c_maroon)
		gpu_set_depth(0); draw_vertex(0, 0)
		gpu_set_depth(0); draw_vertex(-map.xsize, 0)
		draw_set_color(c_yellow)
		gpu_set_depth(0); draw_vertex(0, 0)
		gpu_set_depth(0); draw_vertex(0, map.ysize)
		draw_set_color(c_grey)
		gpu_set_depth(0); draw_vertex(0, 0)
		gpu_set_depth(0); draw_vertex(0, -map.ysize)
		draw_set_color(c_aqua)
		gpu_set_depth(0); draw_vertex(0, 0)
		gpu_set_depth(map.zsize); draw_vertex(0, 0)
		draw_set_color(c_teal)
		gpu_set_depth(0); draw_vertex(0, 0)
		gpu_set_depth(-map.zsize); draw_vertex(0, 0)
		draw_primitive_end()
		draw_set_color(c_white)
	}
end


function MapModelBuilder () constructor begin
	static FORMAT = function () {
		vertex_format_begin()
		vertex_format_add_position_3d()
		vertex_format_add_texcoord()
		vertex_format_add_color()
		return vertex_format_end()
	}()
	
	vb = vertex_create_buffer()
	
	tex_to_vb = {}
	vb_to_tex = {}
	textures = []
	vbs = []
	vbcount = 0
	
	cur_colour = c_white
	cur_shade = 1.0
	cur_mix = c_white
	
	cur_uvs = []
	cur_spr = -1
	
	static begin_building = function ()
	{
		//vertex_begin(vb, FORMAT)
		tex_to_vb = {}
		vb_to_tex = {}
		vbcount = 0
		cur_colour = c_white
		cur_shade = 1.0
		cur_spr = -1
		__update_mix()
	}
	
	static get_tex_uvs = function (_s)
	{
		var tex = sprite_get_texture(_s, 0)
		if tex_to_vb[$ tex] == undefined
		{
			if vbcount >= array_length(vbs)
			{
				var vv = vertex_create_buffer()
				array_push(vbs, vv)
				array_push(textures, tex)
			}
			var vv = vbs[vbcount]
			vertex_begin(vv, FORMAT)
			tex_to_vb[$ tex] = vv
			vb_to_tex[$ vv] = tex
			textures[vbcount] = tex
			vbcount++
		}
		var uvs = sprite_get_uvs(_s, 0)
		cur_uvs[0] = uvs[0]
		cur_uvs[1] = uvs[1]
		cur_uvs[2] = uvs[2]-uvs[0]
		cur_uvs[3] = uvs[3]-uvs[1]
		return tex_to_vb[$ tex]
	}
	
	static end_building = function ()
	{
		for (var i = vbcount; --i >= 0; )
		{
			var vv = vbs[i]
			vertex_end(vv)
		}
	}
	
	static add_top_face = function (_type, _x, _y, _z)
	{
		var vv = get_tex_uvs(_type.sprite)
		
		var ux = cur_uvs[0]
		var uy = cur_uvs[1]
		var uw = cur_uvs[2]
		var uh = cur_uvs[3]
		
		var shapes = _type.render_shapes
		set_cur_colour(_type.colour)
		set_cur_shade(1.0)
		
		for (var i = array_length(shapes); --i>=0;)
		{
			var sh = shapes[i]
			if sh.x0 == sh.x1 or sh.y0 == sh.y1
			{
				continue
			}
			
			var x0 = _x+sh.x0
			var y0 = _y+sh.y0
			var x1 = _x+sh.x1
			var y1 = _y+sh.y1
			var zz = _z+sh.z1
		
			var u0 = sh.x0 * uw + ux
			var v0 = sh.y0 * uh + uy
			var u1 = sh.x1 * uw + ux
			var v1 = sh.y1 * uh + uy
		
			__addv(vv, x0, y1, zz, u0, v0)
			__addv(vv, x1, y1, zz, u1, v0)
			__addv(vv, x0, y0, zz, u0, v1)

			__addv(vv, x1, y1, zz, u1, v0)
			__addv(vv, x1, y0, zz, u1, v1)
			__addv(vv, x0, y0, zz, u0, v1)
		}
	}
	
	static add_bottom_face = function (_type, _x, _y, _z)
	{
		var vv = get_tex_uvs(_type.sprite)
		
		var ux = cur_uvs[0]
		var uy = cur_uvs[1]
		var uw = cur_uvs[2]
		var uh = cur_uvs[3]
		
		set_cur_colour(_type.colour)
		set_cur_shade(0.5)

		var shapes = _type.render_shapes
		for (var i = array_length(shapes); --i>=0;)
		{
			var sh = shapes[i]
			if sh.x0 == sh.x1 or sh.y0 == sh.y1
			{
				continue
			}
			
			var x0 = _x+sh.x0
			var y0 = _y+sh.y0
			var x1 = _x + sh.x1
			var y1 = _y + sh.y1
			var zz = _z + sh.z0
		
			var u0 = sh.x0 * uw + ux
			var v0 = sh.y0 * uh + uy
			var u1 = sh.x1 * uw + ux
			var v1 = sh.y1 * uh + uy
		
			__addv(vv, x0, y0, zz, u0, v0)
			__addv(vv, x1, y0, zz, u1, v0)
			__addv(vv, x0, y1, zz, u0, v1)
		
			__addv(vv, x1, y0, zz, u1, v0)
			__addv(vv, x1, y1, zz, u1, v1)
			__addv(vv, x0, y1, zz, u0, v1)
		}
		

	}
	
	static add_south_face = function (_type, _x, _y, _z)
	{

		set_cur_colour(_type.colour)
		set_cur_shade(0.6)
		
		var vv = get_tex_uvs(_type.sprite)
		
		var ux = cur_uvs[0]
		var uy = cur_uvs[1]
		var uw = cur_uvs[2]
		var uh = cur_uvs[3]

		var shapes = _type.render_shapes
		for (var i = array_length(shapes); --i>=0;)
		{
			var sh = shapes[i]
			
			if sh.x0 == sh.x1 or sh.z0 == sh.z1
			{
				continue
			}
			
			var x0 = _x+sh.x0
			var z0 = _z+sh.z0
			var x1 = _x + sh.x1
			var z1 = _z + sh.z1
			var yy = _y+ sh.y0
		
			var u0 = sh.x0 * uw + ux
			var v0 = sh.z0 * uh + uy
			var u1 = sh.x1 * uw + ux
			var v1 = sh.z1 * uh + uy
		
			__addv(vv, x0, yy, z1, u0, v0)
			__addv(vv, x1, yy, z1, u1, v0)
			__addv(vv, x0, yy, z0, u0, v1)
		
			__addv(vv, x1, yy, z1, u1, v0)
			__addv(vv, x1, yy, z0, u1, v1)
			__addv(vv, x0, yy, z0, u0, v1)
		}
	}
	
	static add_north_face = function (_type, _x, _y, _z)
	{
		
		set_cur_colour(_type.colour)
		set_cur_shade(0.6)
		
		
		var vv = get_tex_uvs(_type.sprite)
		var ux = cur_uvs[0]
		var uy = cur_uvs[1]
		var uw = cur_uvs[2]
		var uh = cur_uvs[3]
		
		var shapes = _type.render_shapes
		for (var i = array_length(shapes); --i>=0;)
		{
			var sh = shapes[i]
			
			if sh.x0 == sh.x1 or sh.z0 == sh.z1
			{
				continue
			}
			
			var x0 = _x+sh.x0
			var z0 = _z+sh.z0
			var x1 = _x + sh.x1
			var z1 = _z + sh.z1
			var yy = _y + sh.y1
		
			var u0 = sh.x0 * uw + ux
			var v0 = sh.z0 * uh + uy
			var u1 = sh.x1 * uw + ux
			var v1 = sh.z1 * uh + uy
		
			__addv(vv, x1, yy, z1, u0, v0)
			__addv(vv, x0, yy, z1, u1, v0)
			__addv(vv, x1, yy, z0, u0, v1)
		
			__addv(vv, x0, yy, z1, u1, v0)
			__addv(vv, x0, yy, z0, u1, v1)
			__addv(vv, x1, yy, z0, u0, v1)
		}
	}
	
	static add_east_face = function (_type, _x, _y, _z)
	{
		set_cur_colour(_type.colour)
		set_cur_shade(0.8)
	
		var vv = get_tex_uvs(_type.sprite)
		var ux = cur_uvs[0]
		var uy = cur_uvs[1]
		var uw = cur_uvs[2]
		var uh = cur_uvs[3]
		
		var shapes = _type.render_shapes
		for (var i = array_length(shapes); --i>=0;)
		{
			var sh = shapes[i]
			
			if sh.y0 == sh.y1 or sh.z0 == sh.z1
			{
				continue
			}
			
			var y0 = _y+sh.y0
			var y1 = _y + sh.y1
			var z0 = _z+sh.z0
			var z1 = _z + sh.z1
			var xx = _x + sh.x1
			var u0 = sh.y0 * uw + ux
			var v0 = sh.z0 * uh + uy
			var u1 = sh.y1 * uw + ux
			var v1 = sh.z1 * uh + uy
		
			__addv(vv, xx, y0, z1, u0, v0)
			__addv(vv, xx, y1, z1, u1, v0)
			__addv(vv, xx, y0, z0, u0, v1)
		
			__addv(vv, xx, y1, z1, u1, v0)
			__addv(vv, xx, y1, z0, u1, v1)
			__addv(vv, xx, y0, z0, u0, v1)
		}
	}
	
	static add_west_face = function (_type, _x, _y, _z)
	{
		set_cur_colour(_type.colour)
		set_cur_shade(0.8)
		var vv = get_tex_uvs(_type.sprite)
		

		
		var vv = get_tex_uvs(_type.sprite)
		var ux = cur_uvs[0]
		var uy = cur_uvs[1]
		var uw = cur_uvs[2]
		var uh = cur_uvs[3]

		var shapes = _type.render_shapes
		for (var i = array_length(shapes); --i>=0;)
		{
			var sh = shapes[i]
			
			if sh.y0 == sh.y1 or sh.z0 == sh.z1
			{
				continue
			}
			
			var y0 = _y+sh.y0
			var y1 = _y + sh.y1
			var z0 = _z+sh.z0
			var z1 = _z +sh.z1
			var xx = _x + sh.x0
			var u0 = sh.y0 * uw + ux
			var v0 = sh.z0 * uh + uy
			var u1 = sh.y1 * uw + ux
			var v1 = sh.z1 * uh + uy
		
			__addv(vv, xx, y1, z1, u0, v0)
			__addv(vv, xx, y0, z1, u1, v0)
			__addv(vv, xx, y0, z0, u1, v1)
		
			__addv(vv, xx, y1, z1, u0, v0)
			__addv(vv, xx, y0, z0, u1, v1)
			__addv(vv, xx, y1, z0, u0, v1)
		}
		
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
	
	static __addv = function (_vb, _x, _y, _z, _u=0, _v=0)
	{
		vertex_position_3d(_vb, _x, _y, _z)
		vertex_texcoord(_vb, _u, _v)
		vertex_color(_vb, cur_mix, 1.0)
	}
end

