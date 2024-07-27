#macro REGION_TYPE_NONE 0
#macro REGION_TYPE_2D 1
#macro REGION_TYPE_3D 2

function Region (_x, _y) constructor begin
	id = -1
	scroll_h = 0
	scroll_v = 0
	scroll_zoom = 1
	scroll_rcp_zoom = 1
	
	panel_x = _x
	panel_y = _y
	
	pev_xmouse = 0
	pev_ymouse = 0
	xmouse = 0
	ymouse = 0
	
	x0 = 0
	y0 = 0
	x1 = 1
	y1 = 1
	
	_scalar_x = 1
	_scalar_y = 1
	
	//has_focus = false
	
	render_callback = undefined
	step_callback = undefined
	
	type = REGION_TYPE_NONE
	
	step_priority = 0
	
	name = "NONE"
	
	static set_zoom = function (_z)
	{
		scroll_zoom = _z
		scroll_rcp_zoom = 1 / _z
	}
	
end

__NULL_REGION = new Region(0,0)

x = 8
y = -8
z = 8

camera = begin
	co: vec_create(),
	forward: vec_create(0, 1, 0),
	right: vec_create(1, 0, 0),
	up: vec_create(0, 0, 1),
	flat_forward: vec_create(0, 1, 0),
	
	look_matrix: matrix_build_identity(),
end

cursor_box = begin
	x: 0,
	y: 0,
	z: 0,
	
end


function draw_cursor_box ()
{
	var x0 = cursor_box.x
	var y0 = cursor_box.y
	var z0 = cursor_box.z
	var x1 = x0 + 1
	var y1 = y0 + 1
	var z1 = z0 + 1
	draw_primitive_begin(pr_linelist)
	
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

	draw_primitive_end()
}



view_pitch = 0
view_yaw = 0

view_roto_matrix = [
	1, 0, 0, 0,
	0, 0, 1, 0,
	0, 1, 0, 0,
	0, 0, 0, 1,
]

map = new MapData(16, 16, 8)

map_built = false
builder = new MapModelBuilder()

mouse_grabbed = false

viewport_surf = -1
viewport_x = 0
viewport_y = 0
viewport_wide = -1
viewport_tall = -1

function draw_view_and_bezel (_region)
{
	var _x = _region.x0
	var _y = _region.y0
	gpu_push_state()
	gpu_set_blendmode_ext(bm_one, bm_zero)
	draw_surface(viewport_surf, _x, _y)
	gpu_pop_state()

	
	gpu_push_state()
	if region_has_focus(_region)
	{
		gpu_set_blendmode(bm_add)
		draw_sprite_stretched(spr_region_focused_corners, 0, _x+3, _y+3, viewport_wide-6, viewport_tall-6)
		gpu_set_blendmode(bm_subtract)
		draw_sprite_stretched(spr_region_focused_corners, 1, _x+3, _y+3, viewport_wide-6, viewport_tall-6)
		gpu_set_blendmode(bm_normal)
		draw_sprite_stretched(spr_viewport_focused, 0, _x, _y, viewport_wide, viewport_tall)
	}
	else
	{
		draw_sprite_stretched(spr_viewport_bezel, 0, _x, _y, viewport_wide, viewport_tall)
	}
	gpu_pop_state()
	draw_set_color(c_white)


}

function ensure_surface ()
{
	if not surface_exists(viewport_surf)
	{
		viewport_surf = surface_create(viewport_wide, viewport_tall)
	}
	return viewport_surf
}

function invalidate_surface ()
{
	if surface_exists(viewport_surf)
	{
		surface_free(viewport_surf)
		viewport_surf = -1
	}
}

function grab_mouse ()
{
	if mouse_grabbed
	{
		return
	}
	
	mouse_grabbed = true
	window_mouse_set_locked(true)
}

function release_mouse ()
{
	if not mouse_grabbed
	{
		return
	}
	mouse_grabbed = false
	window_mouse_set_locked(false)
}

function draw_world_axis ()
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

function build_map_if_not_already ()
{
	if map_built
	{
		return
	}
	builder.begin_building()
	for (var zz = 0; zz < map.zsize; zz++)
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
				
				if array_length(map.get(xx, yy, zz+1).render_shapes) <= 0
				{
					builder.add_top_face(thing, xx, yy, zz)
				}
				
				if array_length(map.get(xx, yy, zz-1).render_shapes) <= 0
				{
					builder.add_bottom_face(thing, xx, yy, zz)
				}
				
				if array_length(map.get(xx, yy+1, zz).render_shapes) <= 0
				{
					builder.add_north_face(thing, xx, yy, zz)
				}
				
				if array_length(map.get(xx, yy-1, zz).render_shapes) <= 0
				{
					builder.add_south_face(thing, xx, yy, zz)
				}
				
				if array_length(map.get(xx+1, yy, zz).render_shapes) <= 0
				{
					builder.add_east_face(thing, xx, yy, zz)
				}
				
				if array_length(map.get(xx-1, yy, zz).render_shapes) <= 0
				{
					builder.add_west_face(thing, xx, yy, zz)
				}
			}
		}
	}
	builder.end_building()
	map_built = true
}


mouse = begin
	x: 0,
	y: 0,
	pev_x: 0,
	pev_y: 0,
end

regions_by_name = {}
region_names = []
regions = []
region_focused = __NULL_REGION
locked_region = __NULL_REGION
acting_region = __NULL_REGION

function add_region (_name, _reg)
{
	_reg.id = array_length(regions)
	array_push(regions, _reg)
	array_push(region_names, _name)
	regions_by_name[$ _name] = _reg
	_reg.name = _name
	return _reg
}

function recalculate_regions ()
{
	viewport_wide = max(room_width >> 1, 1)
	viewport_tall = max(room_height >> 1, 1)
	for (var i = array_length(regions); (--i)>=0;)
	{
		var region = regions[i]
		with region
		{
			x0 = panel_x * other.viewport_wide
			y0 = panel_y * other.viewport_tall
			x1 = x0 + other.viewport_wide
			y1 = y0 + other.viewport_tall
			
			_scalar_x = 1 / (x1 - x0)
			_scalar_y = 1 / (y1 - y0)
		}
	}
}

function set_focused_region (_r=undefined)
{
	region_focused = _r ?? __NULL_REGION
}

function set_locked_region (_r=undefined)
{
	if locked_region.id <= -1 or acting_region.id == locked_region.id
	{
		locked_region = _r ?? __NULL_REGION
	}
}

function region_has_focus (_region)
{
	return get_focused_region().id == _region.id
}

function has_locked_region ()
{
	return locked_region.id > -1
}

function region_setup_mouse_co (_region)
{
	if has_locked_region()
	{
		if _region.id <> locked_region.id
		{
			_region.pev_xmouse = 0
			_region.pev_ymouse = 0
			_region.xmouse = 0
			_region.ymouse = 0
			return
		}
	}
	
	_region.pev_xmouse = _region.xmouse
	_region.pev_ymouse = _region.ymouse
	_region.xmouse = ((mouse.x - _region.x0) / viewport_wide) * (_region.x1-_region.x0)
	_region.ymouse = ((mouse.y - _region.y0) / viewport_tall) * (_region.y1-_region.y0)
}

function region_contains_point (_region, _x, _y)
{
	if has_locked_region()
	{
		if locked_region.id <> _region.id
		{
			return false
		}
	}
	with _region
	{
		return x0 <= _x and _x < x1 and y0 <= _y and _y < y1 
	}
}

function region_try_step (_region)
{
	var cb = _region.step_callback
	if is_callable(cb)
	{
		cb(_region)
	}
}

function region_try_render (_region)
{
	var cb = _region.render_callback
	if is_callable(cb)
	{
		cb(_region)
	}
}

function get_focused_region ()
{
	return has_locked_region() ? locked_region : region_focused 
}

function any_region_focused ()
{
	return get_focused_region().id > -1
}

function is_locked_region (_region)
{
	return locked_region.id == _region.id
}

function draw_cameray_things ()
{
	draw_set_color(c_yellow)
	//draw_cursor_box()
	draw_primitive_begin(pr_linelist)
	draw_set_color(c_yellow)
	draw_vertex_3d(x, y, z)
	draw_vertex_3d(x+camera.forward.x, y+camera.forward.y, z+camera.forward.z)
	draw_set_color(c_red)
	draw_vertex_3d(x, y, z)
	draw_vertex_3d(x+camera.right.x, y+camera.right.y, z+camera.right.z)
	draw_set_color(c_aqua)
	draw_vertex_3d(x, y, z)
	draw_vertex_3d(x+camera.up.x, y+camera.up.y, z+camera.up.z)
	draw_primitive_end()
	
	draw_set_color(c_black)
	matrix_stack_push(matrix_build(x, y, z, 0,0,0, 1,1,1))
	matrix_stack_push(camera.look_matrix)
	matrix_push(matrix_world, matrix_stack_top_clear())
	draw_camera_bauble()
	matrix_pop(matrix_world)
	draw_set_color(c_white)

}

function draw_camera_bauble ()
{
	var cw = room_width/room_height
	var ch = 1
	var cl = 1
		
	var x0 = -cw*0.5
	var z0 = -ch*0.5
	var x1 = +cw*0.5
	var z1 = +ch*0.5
		
	draw_primitive_begin(pr_linelist)
	draw_vertex_3d(0, 0, 0)
	draw_vertex_3d(x0, cl, z0)

	draw_vertex_3d(0, 0, 0)
	draw_vertex_3d(x1, cl, z0)

	draw_vertex_3d(0, 0, 0)
	draw_vertex_3d(x1, cl, z1)

	draw_vertex_3d(0, 0, 0)
	draw_vertex_3d(x0, cl, z1)

	draw_vertex_3d(x0, cl, z0)
	draw_vertex_3d(x1, cl, z0)
		
	draw_vertex_3d(x1, cl, z0)
	draw_vertex_3d(x1, cl, z1)
		
	draw_vertex_3d(x1, cl, z1)
	draw_vertex_3d(x0, cl, z1)
		
	draw_vertex_3d(x0, cl, z1)
	draw_vertex_3d(x0, cl, z0)

	draw_primitive_end()
	
	var tb = 0.2
	draw_primitive_begin(pr_trianglelist)
	draw_vertex_3d(x0+tb, cl, z1+tb)
	draw_vertex_3d(x1-tb, cl, z1+tb)
	draw_vertex_3d((x0+x1)*0.5, cl, z1+tb+(z1-z0)*0.5)
	
	draw_vertex_3d(x1-tb, cl, z1+tb)
	draw_vertex_3d(x0+tb, cl, z1+tb)
	draw_vertex_3d((x0+x1)*0.5, cl, z1+tb+(z1-z0)*0.5)
	draw_primitive_end()
}

function region_ortho_matrix (_region)
{
	return matrix_build_projection_ortho(
		room_width/room_height*_region.scroll_zoom,
		-1*_region.scroll_zoom,
		-100,
		+100
	)
}

var BASE_ZOOM_2D = 20

region_3d = add_region("3d Viewport", new Region(0, 0))
region_3d.type = REGION_TYPE_3D
region_3d.step_priority = 1
region_3d.render_callback = method(self, function (_region) begin
	static FUCK = vertex_create_buffer()
	static FUCK_FORMAT = function () {
		vertex_format_begin()
		vertex_format_add_position_3d()
		return vertex_format_end()
	}()
	
	matrix_stack_push(view_roto_matrix)
	matrix_stack_push(matrix_build(0, 0, 0, -view_pitch,0,0, 1,1,1))
	matrix_stack_push(matrix_build(0, 0, 0, 0,0,-view_yaw, 1,1,1))
	var cam_rot_mat = matrix_stack_top()
	matrix_stack_clear()
	matrix_push(matrix_view, cam_rot_mat)

	matrix_stack_push(matrix_build_projection_perspective_fov(70, room_width/room_height, 0.001, 100))
	matrix_push(matrix_projection, matrix_stack_top_clear())

	gpu_push_state()
	draw_clear_depth(1)
	
	var asp = room_width/room_height
	var u0 = -asp*0.5+0.5
	var v0 = 0
	var u1 = +asp*0.5+0.5
	var v1 = 1
	shader_set(shader_3d_bkd)
	vertex_begin(FUCK, FUCK_FORMAT)
	vertex_position_3d(FUCK, 0, 0, 1)
	vertex_position_3d(FUCK, 1, 0, 0)
	vertex_position_3d(FUCK, 0, 1, 0)
	
	vertex_position_3d(FUCK, 0, 0, 1)
	vertex_position_3d(FUCK, 0, 1, 0)
	vertex_position_3d(FUCK, -1, 0, 0)
	
	vertex_position_3d(FUCK, 0, 0, 1)
	vertex_position_3d(FUCK, 0, -1, 0)
	vertex_position_3d(FUCK, 1, 0, 0)

	vertex_position_3d(FUCK, 0, 0, 1)
	vertex_position_3d(FUCK, -1, 0, 0)
	vertex_position_3d(FUCK, 0, -1, 0)

	vertex_position_3d(FUCK, 0, 0, -1)
	vertex_position_3d(FUCK, 1, 0, 0)
	vertex_position_3d(FUCK, 0, 1, 0)
	
	vertex_position_3d(FUCK, 0, 0, -1)
	vertex_position_3d(FUCK, 0, 1, 0)
	vertex_position_3d(FUCK, -1, 0, 0)
	
	vertex_position_3d(FUCK, 0, 0, -1)
	vertex_position_3d(FUCK, 0, -1, 0)
	vertex_position_3d(FUCK, 1, 0, 0)

	vertex_position_3d(FUCK, 0, 0, -1)
	vertex_position_3d(FUCK, -1, 0, 0)
	vertex_position_3d(FUCK, 0, -1, 0)
	
	vertex_end(FUCK)
	
	vertex_submit(FUCK, pr_trianglelist, sprite_get_texture(tex_sky_ramp_dark_ice, 0))
	shader_reset()
	
	draw_clear_depth(1)
	gpu_set_ztestenable(true)
	gpu_set_zwriteenable(true)
	gpu_set_cullmode(cull_counterclockwise)

	matrix_pop(matrix_view)
	matrix_stack_push(cam_rot_mat)
	matrix_stack_push(matrix_build(-x, -y, -z, 0,0,0, 1,1,1))
	matrix_push(matrix_view, matrix_stack_top_clear())

	build_map_if_not_already()
	vertex_submit(builder.vb, pr_trianglelist, -1)

	draw_world_axis()

	if trace_hit
	{
		draw_set_color(c_yellow)
		draw_primitive_begin(pr_linelist)
		
		var time = get_timer()/1000000
		
		var pulse = (sin(time * pi * 4) * 0.5 + 0.5) * (0.5/16)
		var margin = 0.01
		var minofs = margin+pulse
		var maxofs = 1 + minofs
		
		var x0 = trace_hit_x - minofs
		var y0 = trace_hit_y - minofs
		var z0 = trace_hit_z - minofs
		var x1 = trace_hit_x + maxofs
		var y1 = trace_hit_y + maxofs
		var z1 = trace_hit_z + maxofs
		
		corners_linelist(x0, y0, z0, x1, y1, z1)
		
		draw_primitive_end()
	}
	
	draw_set_color(c_white)
	matrix_pop(matrix_view)
	matrix_pop(matrix_projection)
	gpu_pop_state()

	draw_clear_depth(1)

	var fa = draw_get_halign()
	var va = draw_get_valign()

	draw_set_halign(fa_right)
	draw_set_valign(fa_bottom)
	draw_set_color(c_yellow)

	draw_text(viewport_wide-32, viewport_tall-32, $"This is HUD TEXT!!\n{x}, {y}, {z}")
	
	draw_set_color(c_white)
	draw_set_halign(fa)
	draw_set_valign(va)
	
	if region_has_focus(_region)
	{
		gpu_push_state()
		gpu_set_blendmode_ext(bm_inv_dest_color, bm_inv_src_alpha)
		var scale = min(ceil(viewport_wide / 320), ceil(viewport_tall / 240))
		
		draw_sprite_ext(spr_crosshair, 0, viewport_wide>>1, viewport_tall>>1, scale, scale, 0, c_white, 1)
		gpu_pop_state()
	}
	
end)
region_3d.step_callback = method(self, function (_region) begin
	
	
	if region_has_focus(_region)
	{
		var clc = keyboard_check_pressed(ord("Z"))
		if mouse_grabbed
		{
			if clc or keyboard_check_pressed(vk_escape)
			{
				release_mouse()
				set_locked_region(undefined)
			}
		}
		else
		{
			if clc
			{
				grab_mouse()
				set_locked_region(_region)
			}
		}
	}
	
	if is_locked_region(_region) and mouse_grabbed
	{
		view_yaw   += window_mouse_get_delta_x() * (1/6)
		view_pitch += window_mouse_get_delta_y() * (1/6)

		view_pitch = clamp(view_pitch, -90, +90)
	}

	var ewinp = keyboard_check(ord("D"))-keyboard_check(ord("A"))
	var nsinp = keyboard_check(ord("W"))-keyboard_check(ord("S"))
	var udinp = keyboard_check(vk_space)-keyboard_check(vk_shift)

	if ewinp <> 0 and nsinp <> 0
	{
		var s = sqrt(0.5)
		ewinp *= s
		nsinp *= s
	}
	
	var dt = delta_time / 1000000
	var spd = dt * 10

	var si = dsin(view_yaw)
	var ci = dcos(view_yaw)

	x += (ewinp * ci + nsinp * si) * spd
	y += (nsinp * ci - ewinp * si) * spd
	z += udinp * spd

	var sv = -dsin(view_pitch)
	var cv = +dcos(view_pitch)

	camera.flat_forward.x = si
	camera.flat_forward.y = ci

	camera.forward.x = si * cv
	camera.forward.y = ci * cv
	camera.forward.z = sv

	camera.right.x = +ci
	camera.right.y = -si
	camera.right.z = 0

	camera.up.x = -si * sv
	camera.up.y = -ci * sv
	camera.up.z = cv

	cursor_box.x = x + camera.forward.x * 4
	cursor_box.y = y + camera.forward.y * 4
	cursor_box.z = z + camera.forward.z * 4
	
	camera.look_matrix = [
		camera.right.x, camera.right.y, camera.right.z, 0,
		camera.forward.x, camera.forward.y, camera.forward.z, 0,
		camera.up.x, camera.up.y, camera.up.z, 0,
		0, 0, 0, 1
	]
	
	audio_listener_position(x, y, z)
	audio_listener_orientation(camera.forward.x, camera.forward.y, camera.forward.z, camera.up.x, camera.up.y, camera.up.z)
	
	var reach = 5
	trace_x0 = x
	trace_y0 = y
	trace_z0 = z
	trace_x1 = x+camera.forward.x*reach
	trace_y1 = y+camera.forward.y*reach
	trace_z1 = z+camera.forward.z*reach
	
	ds_list_clear(trace_boxes)
	trace_hit = map.trace_line(
		trace_x0,
		trace_y0,
		trace_z0,
		trace_x1,
		trace_y1,
		trace_z1,
		method(self, function (_x, _y, _z) {
			ds_list_add(trace_boxes, vec_create(_x, _y, _z))
			trace_hit_x = _x
			trace_hit_y = _y
			trace_hit_z = _z
			
			return array_length(map.get(_x, _y, _z).collision_shapes) > 0
		})
	)
	
	if mouse_grabbed and trace_hit
	{
		var any_change = false
		var m = 0
		
		var ox, oy, oz
		if mouse_check_button_pressed(mb_left)
		{
			ox = trace_hit_x
			oy = trace_hit_y
			oz = trace_hit_z
			any_change = map.set(trace_hit_x, trace_hit_y, trace_hit_z, global.AIR)
			m = 1
		}
		else if mouse_check_button_pressed(mb_right)
		{
			ox = trace_hit_x + trace_normal_x
			oy = trace_hit_y + trace_normal_y
			oz = trace_hit_z + trace_normal_z
			if map.get(ox, oy, oz).replacable
			{
				any_change = map.set(ox, oy, oz, global.DIRT)
			}
			m = 2
		}
		
		if any_change
		{
			map_built = false
			
			if m == 1
			{
				audio_play_sound_at(sfx_break_bloc, ox+0.5, oy+0.5, oz+0.5, 0, 0, 0, false, 1)
			}
			else if m == 2
			{
				audio_play_sound_at(sfx_put_bloc, ox+0.5, oy+0.5, oz+0.5, 0, 0, 0, false, 1)
			}
		}
	}
	
end)

region_2d_xy = add_region("2d Viewport (XY)", new Region(1, 1))
region_2d_xy.type = REGION_TYPE_2D
region_2d_xy.set_zoom(BASE_ZOOM_2D)
region_2d_xy.render_callback = method(self, function (_region) begin
	var scale = 1/20
	draw_2d_bkd(_region)
	
	matrix_stack_push(matrix_build(0, 0, 0, 180, 0, 0, 1,1,1))
	//matrix_stack_push(matrix_build(0, 0, 0, 0, 0, 180, 1,1,1))
	matrix_stack_push(matrix_build(-_region.scroll_h, -_region.scroll_v, -map.zsize, 0, 0, 0, 1,1,1))
	matrix_push(matrix_view, matrix_stack_top_clear())
	
	matrix_stack_push(region_ortho_matrix(_region))
	matrix_push(matrix_projection, matrix_stack_top_clear())
	
	gpu_push_state()
	
	gpu_set_ztestenable(true)
	gpu_set_zwriteenable(true)
	
	draw_clear_depth(1)
	//draw_clear(c_dkgrey)
	
	//draw_set_color(c_white)
	//draw_primitive_begin(pr_trianglefan)
	//draw_vertex(0, 0)
	//draw_vertex(1, 0)
	//draw_vertex(1, 1)
	//draw_vertex(0, 1)
	//draw_primitive_end()
	
	draw_primitive_begin(pr_linelist)
	draw_set_color(c_grey)
	gpu_set_depth(0)
	draw_vertex(0, 0)
	draw_vertex(map.xsize, 0)
	draw_vertex(0, 0)
	draw_vertex(0, map.ysize)
	
	for (var i = 0; i <= map.xsize; i++)
	{
		draw_vertex(i, 0)
		draw_vertex(i, map.ysize)
	}
	
	for (var i = 0; i <= map.ysize; i++)
	{
		draw_vertex(0, i)
		draw_vertex(map.xsize, i)
	}
	
	
	draw_set_color(c_red)
	draw_vertex(-0.25, -0.25)
	draw_vertex(map.xsize+0.25, -0.25)
	draw_set_color(c_yellow)
	draw_vertex(-0.25, -0.25)
	draw_vertex(-0.25, map.ysize+0.25)
	
	draw_primitive_end()
	
	draw_clear_depth(1)
	
	build_map_if_not_already()
	vertex_submit(builder.vb, pr_trianglelist, -1)
	
	draw_cameray_things()
	draw_trace_stuff()
	
	draw_set_color(c_white)

	matrix_pop(matrix_view)
	matrix_pop(matrix_projection)
	gpu_pop_state()
	
	if region_has_focus(_region)
	{
		draw_line(
			_region.xmouse,
			0,
			_region.xmouse,
			viewport_tall
		)
	
		draw_line(
			0,
			_region.ymouse,
			viewport_wide,
			_region.ymouse
		)
	}
end)
region_2d_xy.step_callback = method(self, function (_region) begin
	static LOCK = false
	
	if region_has_focus(_region)
	{
		var mwdelta = mouse_wheel_down() - mouse_wheel_up()
		
		if mwdelta <> 0
		{
			_region.set_zoom(_region.scroll_zoom * exp(mwdelta * (1/16)))
		}
		
		if mouse_check_button_pressed(mb_middle)
		{
			set_locked_region(_region)
			LOCK = true
		}
	}
	
	if LOCK and region_has_focus(_region)
	{
		if mouse_check_button_released(mb_middle)
		{
			set_locked_region(undefined)
			LOCK = false
			return
		}
		
		var sw = (1/viewport_tall) * _region.scroll_zoom
		_region.scroll_h -= window_mouse_get_delta_x() * sw
		_region.scroll_v += window_mouse_get_delta_y() * sw
		return
	}

end)

region_2d_xz = add_region("2d Viewport (XZ)", new Region(1, 0))
region_2d_xz.type = REGION_TYPE_2D
region_2d_xz.set_zoom(BASE_ZOOM_2D)
region_2d_xz.render_callback = method(self, function (_region) begin
	var scale = 1/20
	
	draw_2d_bkd(_region)
	
	matrix_stack_push(matrix_build(0, 0, 0, -90, 0, 0, 1,1,1))
	//matrix_stack_push(matrix_build(0, 0, 0, 0, 0, 180, 1,1,1))
	matrix_stack_push(matrix_build(-_region.scroll_h, -map.ysize, -_region.scroll_v, 0, 0, 0, 1,1,1))

	matrix_push(matrix_view, matrix_stack_top_clear())
	
	matrix_stack_push(region_ortho_matrix(_region))
	matrix_push(matrix_projection, matrix_stack_top_clear())
	
	gpu_push_state()
	gpu_set_ztestenable(true)
	gpu_set_zwriteenable(true)
	draw_clear_depth(1)
	//draw_clear(c_dkgrey)
	
	//draw_set_color(c_white)
	//draw_primitive_begin(pr_trianglefan)
	//draw_vertex_3d(0, 0, 0)
	//draw_vertex_3d(1, 0, 0)
	//draw_vertex_3d(1, 0, 1)
	//draw_vertex_3d(0, 0, 1)
	//draw_primitive_end()
	

	draw_primitive_begin(pr_linelist)
	draw_set_color(c_grey)
	//gpu_set_depth(0)
	//draw_vertex(0, 0)
	//gpu_set_depth(map.zsize)
	//draw_vertex(0, 0)
	//gpu_set_depth(0)
	//draw_vertex(0, 0)
	//draw_vertex(0, map.ysize)
	
	for (var i = 0; i <= map.xsize; i++)
	{
		draw_vertex_3d(i, 0, 0)
		draw_vertex_3d(i, 0, map.zsize)
	}
	
	for (var i = 0; i <= map.zsize; i++)
	{
		draw_vertex_3d(0, 0, i)
		draw_vertex_3d(map.xsize, 0, i)
	}
	
	
	draw_set_color(c_aqua)
	draw_vertex_3d(-0.25, 0, -0.25)
	draw_vertex_3d(-0.25, 0, map.zsize+0.25)
	draw_set_color(c_red)
	draw_vertex_3d(-0.25, 0, -0.25)
	draw_vertex_3d(map.xsize+0.25, 0, -0.25)
	
	draw_primitive_end()
	
	draw_clear_depth(1)
		build_map_if_not_already()
	vertex_submit(builder.vb, pr_trianglelist, -1)
	
	draw_cameray_things()
	
	draw_trace_stuff()
	draw_set_color(c_white)
	matrix_pop(matrix_view)
	matrix_pop(matrix_projection)
	gpu_pop_state()
	
	if region_has_focus(_region)
	{
		draw_line(
			_region.xmouse,
			0,
			_region.xmouse,
			viewport_tall
		)
	
		draw_line(
			0,
			_region.ymouse,
			viewport_wide,
			_region.ymouse
		)
	}
end)
region_2d_xz.step_callback = region_2d_xy.step_callback

region_2d_yz = add_region("2d Viewport (YZ)", new Region(0, 1))
region_2d_yz.type = REGION_TYPE_2D
region_2d_yz.set_zoom(BASE_ZOOM_2D)
region_2d_yz.render_callback = method(self, function (_region) begin
	
	draw_2d_bkd(_region)
	
	var scale = 1/20
	matrix_stack_push(matrix_build(0, 0, 0, -90, 0, 0, 1,1,1))
	matrix_stack_push(matrix_build(0, 0, 0, 0, 0, 90, 1,1,1))
	matrix_stack_push(matrix_build(map.xsize, -_region.scroll_h, -_region.scroll_v, 0, 0, 0, 1,1,1))

	matrix_push(matrix_view, matrix_stack_top_clear())
	
	matrix_stack_push(region_ortho_matrix(_region))
	matrix_push(matrix_projection, matrix_stack_top_clear())
	
	gpu_push_state()
	gpu_set_ztestenable(true)
	gpu_set_zwriteenable(true)
	draw_clear_depth(1)
	//draw_clear(c_dkgrey)
	
	//draw_set_color(c_white)
	//draw_primitive_begin(pr_trianglefan)
	//draw_vertex_3d(0, 0, 0)
	//draw_vertex_3d(1, 0, 0)
	//draw_vertex_3d(1, 0, 1)
	//draw_vertex_3d(0, 0, 1)
	//draw_primitive_end()

	draw_primitive_begin(pr_linelist)
	draw_set_color(c_grey)
	
	for (var i = 0; i <= map.ysize; i++)
	{
		draw_vertex_3d(0, i, 0)
		draw_vertex_3d(0, i, map.zsize)
	}
	
	for (var i = 0; i <= map.zsize; i++)
	{
		draw_vertex_3d(0, 0, i)
		draw_vertex_3d(0, map.ysize, i)
	}
	
	
	draw_set_color(c_aqua)
	draw_vertex_3d(0, -0.25, -0.25)
	draw_vertex_3d(0, -0.25, map.zsize+0.25)
	draw_set_color(c_yellow)
	draw_vertex_3d(0, -0.25, -0.25)
	draw_vertex_3d(0, map.ysize+0.25, -0.25)
	
	draw_primitive_end()
	
	draw_clear_depth(1)
	
		build_map_if_not_already()
	vertex_submit(builder.vb, pr_trianglelist, -1)
	draw_cameray_things()
	
	draw_trace_stuff()
	
	draw_set_color(c_white)
	matrix_pop(matrix_view)
	matrix_pop(matrix_projection)
	gpu_pop_state()
	
	if region_has_focus(_region)
	{
		draw_line(
			_region.xmouse,
			0,
			_region.xmouse,
			viewport_tall
		)
	
		draw_line(
			0,
			_region.ymouse,
			viewport_wide,
			_region.ymouse
		)
	}
end)
region_2d_yz.step_callback = region_2d_xy.step_callback


trace_boxes = ds_list_create()
trace_x0 = 0
trace_y0 = 0
trace_z0 = 0
trace_x1 = 0
trace_y1 = 0
trace_z1 = 0
trace_hit = false
trace_hit_x = 0
trace_hit_y = 0
trace_hit_z = 0
trace_normal_x = 0
trace_normal_y = 0
trace_normal_z = 1

function draw_2d_bkd (_region)
{
	draw_rectangle_color(
		0, 0,
		viewport_wide, viewport_tall,
		//#15152d, #15152d,
		//#23234b, #23234b,
		#23234b, #23234b,
		#53539f, #53539f,
		false
	)
}

function draw_trace_stuff ()
{
	
	draw_set_color(c_yellow)
	draw_primitive_begin(pr_linelist)
	for (var i = 0; i < ds_list_size(trace_boxes); i++)
	{
		var box = trace_boxes[| i]
		var x0 = box.x
		var y0 = box.y
		var z0 = box.z
		var x1 = x0 + 1
		var y1 = y0 + 1
		var z1 = z0 + 1
		
		corners_linelist(x0, y0, z0, x1, y1, z1)
	}
	draw_primitive_end()
	
	draw_set_color(c_white)
	draw_primitive_begin(pr_linelist)
	draw_vertex_3d(trace_x0, trace_y0, trace_z0)
	draw_vertex_3d(trace_x1, trace_y1, trace_z1)
	draw_primitive_end()
}
