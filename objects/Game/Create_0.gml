
instance_create_depth(0,0,0, obj_init)



font_console = font_add_sprite(spr_kfont2, 1, false, 0)


__NULL_REGION = new Region(0,0)


#region world

palette = new Palette(
	"dirt",
	"solid",
	"precarious",
	"rose",
	"cobblestone_stairs",
	"glass",
	"carpet",
	"super_ramp",
	"core",
	"upper_slab",
)

map = new MapData(16, 16, 8)

map_built = false
builder = new MapModelBuilder()
map_renderer = new MapRenderer(map)


#endregion


#region view

cam = new Camera()

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
		begin
			gpu_set_blendmode(bm_add)
			var rx0 = _x+1
			var ry0 = _y+1
			var rx1 = _x+viewport_wide-1
			var ry1 = _y+viewport_tall-1
			
			var sz = min(viewport_wide, viewport_tall) * 0.5 * (1/10)
			
			var time = get_timer()/1000000
			var pulse = sin(time * pi * 4) * 0.5 + 0.5
			draw_set_color(merge_colour(c_yellow, c_black, pulse * 0.5 + 0.25))
			draw_primitive_begin(pr_linelist)
			draw_vertex(rx0, ry0)
			draw_vertex(rx0+sz, ry0)
			draw_vertex(rx0, ry0)
			draw_vertex(rx0, ry0+sz)

			draw_vertex(rx1, ry0)
			draw_vertex(rx1-sz, ry0)
			draw_vertex(rx1, ry0)
			draw_vertex(rx1, ry0+sz)

			draw_vertex(rx1, ry1)
			draw_vertex(rx1-sz, ry1)
			draw_vertex(rx1, ry1)
			draw_vertex(rx1, ry1-sz)
			
			draw_vertex(rx0, ry1)
			draw_vertex(rx0+sz, ry1)
			draw_vertex(rx0, ry1)
			draw_vertex(rx0, ry1-sz)
			draw_primitive_end()
		end
		draw_set_color(c_white)
	
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

view3d_show_hit_hull = false
view3d_show_votv_cursor = true
views_show_camera_trace = false

mouse = begin
	x: 0,
	y: 0,
	pev_x: 0,
	pev_y: 0,
	
	grabbed: false,
	
	grab: function ()
	{
		if grabbed
		{
			return
		}
		grabbed = true
		window_mouse_set_locked(true)
	},
	
	release: function ()
	{
		if not grabbed
		{
			return
		}
		grabbed = false
		window_mouse_set_locked(false)
	},
	
	
end

#endregion


#region region things

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

function region_ortho_matrix (_region)
{
	return matrix_build_projection_ortho(
		room_width/room_height*_region.scroll_zoom,
		-1*_region.scroll_zoom,
		-100,
		+100
	)
}

function draw_2d_bkd (_region)
{
	draw_rectangle_color(
		0, 0,
		viewport_wide, viewport_tall,
		//#15152d, #15152d,
		//#23234b, #23234b,
		//#23234b, #23234b,
		//#53539f, #53539f,
		c_dkgrey, c_dkgrey,
		c_grey, c_grey,
		false
	)
}

#endregion


#region regions themselves


var BASE_ZOOM_2D = 20

cam_spd_x = 0
cam_spd_y = 0
cam_spd_z = 0

with add_region("3d Viewport", new Region(0, 0))
{
	other.region_3d = self
	type = REGION_TYPE_3D
	step_priority = 1

	action = "NONE"
	HUD_TXT = "This is HUD TEXT!!"
	
	step_callback = method(other, function (_region) begin
		
		if region_has_focus(_region)
		{
			if _region.action == "TYPING"
			{
				var do_quit = false
				if keyboard_check_pressed(vk_escape)
				{
					do_quit = true
					keyboard_string = ""
				}
				else if keyboard_check_pressed(vk_enter)
				{
					do_quit = true
					var sss = string_split(string_trim(string_lower(keyboard_string)), " ", true)
					
					switch sss[0]
					{
						case "pin":
							trace_pinned = true
							break
						case "unpin":
							trace_pinned = false
							break
						case "show_votv":
							view3d_show_votv_cursor = array_length(sss) > 1 and sss[1] == "1"
							break
						case "show_hit_hulls":
							view3d_show_hit_hull = array_length(sss) > 1 and sss[1] == "1"
							break
						case "face_3d_cursor":
							cam.turn_towards(cursor_3d_x, cursor_3d_y, cursor_3d_z)
							break
						case "set":
						{
							try
							{
								var v1 = sss[1]
								var sx = 0
								var sy = 0
								var sz = 0
								var bloc = undefined
								var should = false
								if string_starts_with(v1, "@")
								{
									if v1 == "@cursor"
									{
										sx = floor(cursor_3d_x)
										sy = floor(cursor_3d_y)
										sz = floor(cursor_3d_z)
										bloc = sss[2]
										should = true
									}
									else if v1 == "@camera"
									{
										sx = floor(cam.x)
										sy = floor(cam.y)
										sz = floor(cam.z-1)
										bloc = sss[2]
										should = true
									}
								}
								else
								{
									sx = floor(real(sss[1]))
									sy = floor(real(sss[2]))
									sz = floor(real(sss[3]))
									bloc = sss[4]
									should = true
								}
								
								if should
								{
									var b = blocks_get_by_name(bloc)
									if b == undefined
									{
										_region.HUD_TXT = $"Couldn't set block, \"{bloc}\" is undefined! x_x"
									}
									else
									{
										if map.set(sx, sy, sz, b)
										{
											map_renderer.built = false
											_region.HUD_TXT = $"Block changed to \"{bloc}\". ovo"
										}
										else
										{
											_region.HUD_TXT = "No change occured! ovo\""
										}
									}
								}
								else
								{
									_region.HUD_TXT = "Coouldn't set block for some reason! x_x"
								}
							}
							catch (_e)
							{
								_region.HUD_TXT = $"Couldn't set block, an exeption occured!!!\n{_e}"
								show_debug_message(_e)
							}
							break
						}
						default:
							_region.HUD_TXT = $"I dont know how to \"{sss[0]}\"!"
							break
					}
				}
				
				if do_quit
				{
					_region.action = "NONE"
					set_locked_region(undefined)
					return
				}
			}
			else if keyboard_check_pressed(vk_enter)
			{
				_region.action = "TYPING"
				set_locked_region(_region)
				keyboard_string = ""
				if mouse.grabbed
				{
					mouse.release()
					window_mouse_set((_region.x0+_region.x1)*0.5, (_region.y0+_region.y1)*0.5)
				}
				return
			}
			else
			{
				var clc = keyboard_check_pressed(ord("Z"))
				if mouse.grabbed
				{
					if clc or keyboard_check_pressed(vk_escape)
					{
						mouse.release()
						window_mouse_set((_region.x0+_region.x1)*0.5, (_region.y0+_region.y1)*0.5)
						set_locked_region(undefined)
						_region.action = "NONE"
					}
				}
				else
				{
					if clc
					{
						mouse.grab()
						set_locked_region(_region)
						_region.action = "CAMERA"
					}
				}
			}
		}
		
		var cinp = _region.action == "CAMERA"
		var c = cam
		
		if cinp
		{
			var turn_speed = 1/6
			c.turn(
				(-window_mouse_get_delta_y() * turn_speed),
				(+window_mouse_get_delta_x() * turn_speed)
			)
		}
		
		var dt = delta_time / 1000000
		var cacc_x = 0
		var cacc_y = 0
		var cacc_z = 0
		if region_has_focus(_region) and _region.action <> "TYPING"
		{
			var mdelta = mouse_wheel_down() - mouse_wheel_up()
			
			if mdelta <> 0
			{
				palette.offset_index(mdelta > 0 ? +1 : -1)
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
			
			var hspd = 80
			var vspd = 100
			
			var si = c.flat_forward_x
			var ci = c.flat_forward_y

			cacc_x = (ewinp * ci + nsinp * si) * hspd
			cacc_y += (nsinp * ci - ewinp * si) * hspd
			cacc_z += udinp * vspd

		}
		
		// verlet
		begin
			var pdt = dt * dt * 0.5
			c.x += cam_spd_x * dt + cacc_x * pdt
			c.y += cam_spd_y * dt + cacc_y * pdt
			c.z += cam_spd_z * dt + cacc_z * pdt
			
			var hdecel = 0.91
			var vdecel = 0.85
			cam_spd_x = cam_spd_x + (cacc_x * dt) - (cam_spd_x * (1-hdecel))
			cam_spd_y = cam_spd_y + (cacc_y * dt) - (cam_spd_y * (1-hdecel))
			cam_spd_z = cam_spd_z + (cacc_z * dt) - (cam_spd_z * (1-vdecel))
			
		end
		
		
		var reach = 10//5
		
		if not trace_pinned
		{
			trace_x0 = c.x
			trace_y0 = c.y
			trace_z0 = c.z
		
			if region_has_focus(_region) and _region.action == "NONE"
			{
				var tx1 = (_region.xmouse / viewport_wide) * +2 - 1
				var ty1 = 1
				var tz1 = (_region.ymouse / viewport_tall) * -2 + 1
			
				tx1 *= 1
				tz1 *= room_height/room_width
			
				var mag = 1 / sqrt(power(tx1, 2) + ty1 + power(tz1, 2))
				tx1 *= mag
				ty1 *= mag
				tz1 *= mag
		
				var tr = matrix_transform_vertex(c.look_matrix, tx1, ty1, tz1, 0)
		
				trace_x1 = c.x+tr[0]*reach
				trace_y1 = c.y+tr[1]*reach
				trace_z1 = c.z+tr[2]*reach
			}
			else
			{
				trace_x1 = c.x+c.forward_x*reach
				trace_y1 = c.y+c.forward_y*reach
				trace_z1 = c.z+c.forward_z*reach
			}
		}
		
		trace_update_hull()
		
		ds_list_clear(trace_boxes)
		ds_list_clear(trace_down_boxes)
		ds_list_clear(trace_down_boxes_overlap)
		trace_continue_count = -1
		trace_nearest = infinity
		trace_context.setup_endpoints(trace_x0, trace_y0, trace_z0, trace_x1, trace_y1, trace_z1)
		//trace_hit = map.trace_line(
		//	trace_x0,
		//	trace_y0,
		//	trace_z0,
		//	trace_x1,
		//	trace_y1,
		//	trace_z1,
		//	method(self, trace_predicate_normal)
		//)
		trace_hit = false
		map.trace_line_with_downwards(
			trace_x0,
			trace_y0,
			trace_z0,
			trace_x1,
			trace_y1,
			trace_z1,
			method(self, trace_predicate_down)
		)
		
		
		var jsz = ds_list_size(trace_boxes)
		for (var i = 0; i < ds_list_size(trace_down_boxes); i++)
		{
			var subj = trace_down_boxes[| i]
			var did = false
			for (var j = jsz; --j>=0;)
			{
				var vs = trace_boxes[| j]
				if vs.x == subj.x and vs.y == subj.y and vs.z == subj.z
				{
					did = true
					break
				}
			}
			ds_list_add(trace_down_boxes_overlap, did)
		}
		
		if region_has_focus(_region) and trace_hit
		{
			var any_change = false
			var m = 0
			
			if mouse_check_button_pressed(mb_middle)
			{
				cursor_3d_x = trace_point_x
				cursor_3d_y = trace_point_y
				cursor_3d_z = trace_point_z
			}
			
			var ox, oy, oz
			if mouse_check_button_pressed(mb_left)
			{
				ox = trace_hit_x
				oy = trace_hit_y
				oz = trace_hit_z
				any_change = map.set(trace_hit_x, trace_hit_y, trace_hit_z, global.BLOCKS.AIR)
				m = 1
			}
			else if mouse_check_button_pressed(mb_right)
			{
				ox = trace_hit_x + trace_normal_x
				oy = trace_hit_y + trace_normal_y
				oz = trace_hit_z + trace_normal_z
				if map.get(ox, oy, oz).replacable
				{
					any_change = map.set(ox, oy, oz, palette.get_current())
				}
				m = 2
			}
		
			
			if m == 1 and any_change
			{
				map_renderer.built = false
				audio_play_sound_at(sfx_break_bloc, ox+0.5, oy+0.5, oz+0.5, 0, 0, 0, false, 1)
			}
				
			if m == 2
			{
				if any_change
				{
					audio_play_sound_at(sfx_put_bloc, ox+0.5, oy+0.5, oz+0.5, 0, 0, 0, false, 1)
					map_renderer.built = false
				}
				else
				{
					var ss = audio_play_sound_at(sfx_interactnull, ox+0.5, oy+0.5, oz+0.5, 0, 0, 0, false, 1)
					audio_sound_gain(ss, 0.3, 0)
				}
			}
			
		}
		
	end)

	render_callback = method(other, function (_region) begin
		static BKD_OCT = create_bkd_octohedron()
		var c = cam

		var cam_rot_mat = c.view_matrix
		matrix_push(matrix_view, cam_rot_mat)

		matrix_stack_push(matrix_build_projection_perspective_fov(59, room_width/room_height, 0.001, 100))
		matrix_push(matrix_projection, matrix_stack_top_clear())

		gpu_push_state()

		// skybox
		gpu_push_state()
		gpu_set_zfunc(cmpfunc_always)
		shader_set(shader_3d_bkd)
		gpu_set_tex_filter(true)
		BKD_OCT.submit(sprite_get_texture(tex_skyramp_simplegrey, 0))
		shader_reset()
		gpu_pop_state()

		draw_clear_depth(1)
		gpu_set_ztestenable(true)
		gpu_set_zwriteenable(true)
		gpu_set_cullmode(cull_counterclockwise)
		gpu_set_alphatestenable(true)

		begin
			var psh = sh_3d_infini_floor
			shader_set(psh)
			shader_set_uniform_f(shader_get_uniform(psh, "cofs"), c.x, c.y, c.z)
			var spr = spr_dark_hull
			var uvs = sprite_get_uvs(spr, 0)
			var sz = 50
			shader_set_uniform_f(shader_get_uniform(psh, "uvs"), uvs[0], uvs[1], uvs[2], uvs[3])
			shader_set_uniform_f(shader_get_uniform(psh, "radius"), sz)

			draw_primitive_begin_texture(pr_trianglefan, sprite_get_texture(spr, 0))
			draw_vertex(-sz, +sz)
			draw_vertex(+sz, +sz)
			draw_vertex(+sz, -sz)
			draw_vertex(-sz, -sz)
		
			draw_primitive_end()
			shader_reset()
		end
		
		matrix_pop(matrix_view)

		
		matrix_stack_push(cam_rot_mat)
		matrix_stack_push(matrix_build(-c.x, -c.y, -c.z, 0,0,0, 1,1,1))
		matrix_push(matrix_view, matrix_stack_top_clear())
		
		map_renderer.draw()
		map_renderer.draw_world_axis()

		begin // trace hull
			if region_has_focus(_region)
			{
				if keyboard_check_pressed(ord("1"))
				{
					trace_hull_x = c.x
					trace_hull_y = c.y
					trace_hull_z = c.z
				}
				if keyboard_check_pressed(ord("2"))
				{
					trace_hull_xd = trace_x1-trace_x0
					trace_hull_yd = trace_y1-trace_y0
					trace_hull_zd = trace_z1-trace_z0
				}
			}
		
			global.__TRACE_NEAREST = infinity
			trace_hull_did_hit = false
			trace_hull_hit_time = infinity
			ds_list_clear(trace_hull_boxes)
		
			trace_update_hull()
		
			trace_context.setup_with_corners(
				trace_hull.x0, trace_hull.y0, trace_hull.z0,
				trace_hull.x1, trace_hull.y1, trace_hull.z1,
				trace_hull_xd, trace_hull_yd, trace_hull_zd
			)
		
			map.trace_hull(
				trace_hull.x0, trace_hull.y0, trace_hull.z0-1,
				trace_hull.x1, trace_hull.y1, trace_hull.z1,
				trace_hull_xd, trace_hull_yd, trace_hull_zd,
				trace_predicate_hull
			)
		end

		var votv_ovrride = trace_hit and _region.action <> "TYPING" and keyboard_check(ord("Q")) and region_has_focus(_region)

		if trace_pinned and views_show_camera_trace
		{
			draw_primitive_begin(pr_linelist)
			draw_set_color(c_yellow)
			var asz0 = 0.001
			var asz1 = 1-asz0
			for (var j = ds_list_size(trace_boxes); --j >= 0;)
			{
				var box = trace_boxes[| j]
				corners_linelist(box.x+asz0, box.y+asz0, box.z+asz0, box.x+asz1, box.y+asz1, box.z+asz1)
			}
			draw_primitive_end()

			draw_primitive_begin(pr_linelist)
			draw_set_color(c_fuchsia)
			var bsz0 = 0.1
			var bsz1 = 1-bsz0
			for (var j = ds_list_size(trace_down_boxes); --j >= 0;)
			{
				var box = trace_down_boxes[| j]
				draw_set_color(trace_down_boxes_overlap[| j] ? c_red : c_aqua)
				corners_linelist(box.x+bsz0, box.y+bsz0, box.z+bsz0, box.x+bsz1, box.y+bsz1, box.z+bsz1)
			}
			draw_primitive_end()
				
			draw_set_color(c_white)
				
		}

		draw_trace_hull()

		if trace_hit
		{
			gpu_push_state()
			draw_set_color(c_white)
			
			var hitp_x = global.__HIT_POINT[0]
			var hitp_y = global.__HIT_POINT[1]
			var hitp_z = global.__HIT_POINT[2]
			
			var hitn_x = -c.forward_x * math_get_epsilon()
			var hitn_y = -c.forward_y * math_get_epsilon()
			var hitn_z = -c.forward_z * math_get_epsilon()
			
			draw_set_alpha(0.2)
			
			gpu_set_blendequation(bm_eq_subtract)
			var time = get_timer()/1000000
		
			var pulse = (sin(time * pi * 4) * 0.5 + 0.5) * (0.25/16)
			var margin = 0.004
			var minofs = margin
			var maxofs = 1 + minofs
			
			var type = map.get(trace_hit_x, trace_hit_y, trace_hit_z)
			var shapes = type.collision_shapes
			
			var tx = trace_hit_x
			var ty = trace_hit_y
			var tz = trace_hit_z
			
			var m = matrix_multiply(matrix_get(matrix_view), matrix_get(matrix_projection))
			
			votv_box_x0 = infinity
			votv_box_y0 = infinity
			votv_box_x1 = -infinity
			votv_box_y1 = -infinity
			
			draw_primitive_begin(pr_linelist)
			for (var i = array_length(shapes); --i >= 0;)
			{
				var shape = shapes[i]
				var xx0 = tx + shape.x0
				var yy0 = ty + shape.y0
				var zz0 = tz + shape.z0
				var xx1 = tx + shape.x1
				var yy1 = ty + shape.y1
				var zz1 = tz + shape.z1
				corners_linelist(
					xx0-margin,
					yy0-margin,
					zz0-margin,
					xx1+margin,
					yy1+margin,
					zz1+margin
				)
				
				if view3d_show_votv_cursor or votv_ovrride
				{
					for (var j = 0b000; j <= 0b111; j++)
					{
						var xj = (j & 0b001) <> 0
						var yj = (j & 0b010) <> 0
						var zj = (j & 0b100) <> 0
						var tf0 = matrix_transform_vertex(m, xj ? xx0 : xx1, yj ? yy0 : yy1, zj ? zz0 : zz1, 1)
						var tf1 = matrix_transform_vertex(m, xj ? xx1 : xx0, yj ? yy1 : yy0, zj ? zz1 : zz0, 1)
						var i0 = 1/tf0[2]
						var i1 = 1/tf1[2]
						var tx0 = tf0[0] * i0
						var ty0 = tf0[1] * i0
						var tx1 = tf1[0] * i1
						var ty1 = tf1[1] * i1
				
						votv_box_x0 = min(votv_box_x0, min(tx0, tx1))
						votv_box_y0 = min(votv_box_y0, min(ty0, ty1))
						votv_box_x1 = max(votv_box_x1, max(tx1, tx0))
						votv_box_y1 = max(votv_box_y1, max(ty1, ty0))
					}
				}
			}
			draw_primitive_end()
			
			draw_set_color(c_white)
			draw_set_alpha(1)
			gpu_pop_state()
			
			if view3d_show_hit_hull begin
				var fuck = 0.01 + pulse
				draw_primitive_begin(pr_linelist)
				draw_set_color(c_yellow)
				corners_linelist(
					trace_hit_hull.x0-fuck, trace_hit_hull.y0-fuck, trace_hit_hull.z0-fuck,
					trace_hit_hull.x1+fuck, trace_hit_hull.y1+fuck, trace_hit_hull.z1+fuck
				)
				draw_primitive_end()
				draw_set_color(c_white)
				
				draw_primitive_begin(pr_linelist)
				
				var hx0 = trace_point_x
				var hy0 = trace_point_y
				var hz0 = trace_point_z
				var hx1 = hx0 + trace_normal_x
				var hy1 = hy0 + trace_normal_y
				var hz1 = hz0 + trace_normal_z
				
				draw_vertex_3d(hx0, hy0, hz0)
				draw_vertex_3d(hx1, hy1, hz1)
				
				draw_primitive_end()
			end
		}
	
		draw_3d_cursor()

		
		draw_set_color(c_white)
		matrix_pop(matrix_view)
		matrix_pop(matrix_projection)
		gpu_pop_state()

		draw_clear_depth(1)

		var fa = draw_get_halign()
		var va = draw_get_valign()
		
		{
			draw_set_halign(fa_right)
			draw_set_valign(fa_bottom)
			
			var s = string_join("\n", 
				_region.HUD_TXT,
			)
			
			
			var sw = string_width(s)
			var sh = string_height(s)
			
			var sx = viewport_wide-32
			var sy = viewport_tall-16
			var p = 8
			draw_set_color(c_black)
			draw_set_alpha(0.75)
			
			draw_primitive_begin(pr_trianglefan)
			draw_vertex(sx-sw-p, sy-sh-p)
			draw_vertex(sx+p, sy-sh-p)
			draw_vertex(sx+p, sy+p)
			draw_vertex(sx-sw-p, sy+p)
			draw_primitive_end()
			
			draw_set_color(c_yellow)
			draw_set_alpha(1)
			draw_text(sx, sy, s)
		}
		
		if _region.action == "TYPING"
		{
			draw_set_halign(fa_left)
			draw_set_valign(fa_bottom)
			draw_set_font(font_console)
			var blink = ((get_timer() * 2 / 1000000) & 1) == 0 ? "_" : " "
			var t = $"==> {keyboard_string}{blink}"
			draw_set_color(c_black)
			var chw = string_width("A")
			var chh = string_height("A")
			var tw = string_width(t) + chw
			var th = string_height(t) + chh
			draw_rectangle(0, viewport_tall-16-th, 16+tw, viewport_tall, false)
			draw_set_color(c_yellow)
			draw_text(16, viewport_tall-16, t)
			draw_set_font(-1)
			
		}
		
		draw_set_color(c_white)
		draw_set_halign(fa)
		draw_set_valign(va)
		
		var scale = max(min(ceil(viewport_wide / 320), ceil(viewport_tall / 240)), 1)
		
		var pal = palette.get_current()
		
		matrix_push(matrix_world, matrix_build(16, 16, 0, 0,0,0, scale, scale, 1))
		draw_sprite_stretched(pal.sprite, 0, 0, 0, 32, 32)
		draw_set_color(c_black)
		draw_primitive_begin(pr_linestrip)
		draw_vertex(0, 0)
		draw_vertex(32, 0)
		draw_vertex(32, 32)
		draw_vertex(0, 32)
		draw_vertex(0, 0)
		draw_primitive_end()
		draw_set_color(c_white)
		var me = 0.5
		draw_primitive_begin(pr_linestrip)
		draw_vertex(-me, -me)
		draw_vertex(32+me, -me)
		draw_vertex(32+me, 32+me)
		draw_vertex(-me, 32+me)
		draw_vertex(-me, -me)
		draw_primitive_end()
		//draw_text(0, 32, pal.name)
		
		matrix_pop(matrix_world)
		
		if votv_ovrride or (view3d_show_votv_cursor and trace_hit)
		{
			var spr = spr_votv_sel_box

			var vx0 = (+votv_box_x0*0.5+0.5)*viewport_wide
			var vy0 = (-votv_box_y0*0.5+0.5)*viewport_tall
			var vx1 = (+votv_box_x1*0.5+0.5)*viewport_wide
			var vy1 = (-votv_box_y1*0.5+0.5)*viewport_tall
			var tmp = vx0
			vx0 = min(tmp, vx1)
			vx1 = max(tmp, vx1)
			tmp = vy0
			vy0 = min(tmp, vy1)
			vy1 = max(tmp, vy1)
			
			vx0 -= sprite_get_bbox_left(spr)
			vy0 -= sprite_get_bbox_top(spr)
			vx1 += sprite_get_width(spr)-sprite_get_bbox_right(spr)
			vy1 += sprite_get_height(spr)-sprite_get_bbox_bottom(spr)
			
			var vw = floor(abs(vx1-vx0))
			var vh = floor(abs(vy1-vy0))
			vx0 = floor(vx0)
			vy0 = floor(vy0)
			vx1 = floor(vx1)
			vy1 = floor(vy1)
			
			draw_sprite_stretched(spr, 0, vx0, vy0, vw, vh)
			
			draw_set_font(font_console)
			var votvtext = string_join("\n",
				map.get(trace_hit_x, trace_hit_y, trace_hit_z).name,
				$"@{trace_hit_x}, {trace_hit_y}, {trace_hit_z}",
			)
			var fh = draw_get_halign()
			var fv = draw_get_valign()
			var strw = string_width(votvtext)
			var strh = string_height(votvtext)
			
			var sx0 = vx0+vw
			var sy0 = vy0
			var sx1 = vx0+vw+strw
			var sy1 = vy0+strh
			
			if sy0 < 0
			{
				sy0 = vy0+vh-strh
				sy1 = vy0+vh
			}
			
			if sx1 > viewport_wide
			{
				sx0 = vx0-strw
				sx1 = vx0
			}
			
			draw_set_color(c_black)
			draw_primitive_begin(pr_trianglefan)
			draw_vertex(sx0, sy0)
			draw_vertex(sx1, sy0)
			draw_vertex(sx1, sy1)
			draw_vertex(sx0, sy1)
			draw_primitive_end()
			draw_set_color(c_yellow)
			draw_text(sx0, sy0, votvtext)
			
			draw_set_font(-1)
			draw_set_color(c_white)
			draw_set_halign(fh)
			draw_set_valign(fv)
		}
		
		if cursor_3d_should_draw
		{
			var c3d_x = (+cursor_3d_draw_x * 0.5 + 0.5) * viewport_wide
			var c3d_y = (-cursor_3d_draw_y * 0.5 + 0.5) * viewport_tall
			var cs = max(scale >> 1, 1)
			draw_sprite_ext(spr_3d_cursor, 0, c3d_x, c3d_y, cs, cs, 0, c_white, 1)
		}
		if region_has_focus(_region)
		{
			gpu_push_state()
			gpu_set_blendmode_ext(bm_inv_dest_color, bm_inv_src_alpha)
			
			var cx = viewport_wide>>1
			var cy = viewport_tall>>1
			
			if _region.action == "NONE"
			{
				cx = floor(_region.xmouse)
				cy = floor(_region.ymouse)
			}
			
			draw_sprite_ext(spr_crosshair, trace_hit ? 1 : 0, cx, cy, scale, scale, 0, c_white, 1)
			gpu_pop_state()
		
		}
	
	end)
}

#region 2d regions

with add_region("2d Viewport (XY)", new Region(1, 1))
{
	other.region_2d_xy = self
	type = REGION_TYPE_2D
	set_zoom(BASE_ZOOM_2D)
	
	set_hull_hv = method(other, function (_h, _v) {
		var tx1 = trace_hull_x+trace_hull_xd
		var ty1 = trace_hull_y+trace_hull_yd
		trace_hull_x = _h
		trace_hull_y = _v
		trace_hull_xd = tx1-trace_hull_x
		trace_hull_yd = ty1-trace_hull_y
	})
	
	set_hull_d = method(other, function (_h, _v) {
		trace_hull_xd = _h-trace_hull_x
		trace_hull_yd = _v-trace_hull_y
	})
	
	render_callback = method(other, function (_region) begin
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
		
		map_renderer.draw()
		
		draw_trace_hull()
		
		draw_cameray_things()
		draw_trace_stuff()
		draw_3d_cursor()
	
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
	step_callback = method(other, function (_region) begin
		static LOCK = false
	
		if region_has_focus(_region)
		{
			var mwdelta = mouse_wheel_down() - mouse_wheel_up()
		
			if mwdelta <> 0
			{
				_region.set_zoom(_region.scroll_zoom * exp(mwdelta * (1/8)))
			}

			if mouse_check_button_pressed(mb_middle)
			{
				set_locked_region(_region)
				LOCK = true
			}
			
			if mouse_check_button_pressed(mb_left)
			{
				set_locked_region(_region)
				LOCK = true
			}
			
			if mouse_check_button_pressed(mb_right)
			{
				set_locked_region(_region)
				LOCK = true
			}
		}
	
		var sw = (1/viewport_tall) * _region.scroll_zoom
		if LOCK and region_has_focus(_region)
		{
			var mmd = mouse_check_button(mb_middle)
			var mld = mouse_check_button(mb_left)
			var mrd = mouse_check_button(mb_right)
			
			if not (mmd or mld or mrd)
			{
				set_locked_region(undefined)
				LOCK = false
				return
			}
			
			if mmd
			{
				_region.scroll_h -= window_mouse_get_delta_x() * sw
				_region.scroll_v += window_mouse_get_delta_y() * sw
			}
			var mh = (_region.xmouse-viewport_wide*0.5) * +sw + _region.scroll_h
			var mv = (_region.ymouse-viewport_tall*0.5) * -sw + _region.scroll_v
			if mrd
			{
				_region.set_hull_hv(mh, mv)
			}
			
			if mld
			{
				_region.set_hull_d(mh, mv)
			}
			return
		}
		
	end)
}

with add_region("2d Viewport (XZ)", new Region(1, 0))
{
	other.region_2d_xz = self
	type = REGION_TYPE_2D
	set_zoom(BASE_ZOOM_2D)
	set_hull_hv = method(other, function (_h, _v)
	{
		var tx1 = trace_hull_x+trace_hull_xd
		var tz1 = trace_hull_z+trace_hull_zd
		trace_hull_x = _h
		trace_hull_z = _v
		trace_hull_xd = tx1-trace_hull_x
		trace_hull_zd = tz1-trace_hull_z
	})
	set_hull_d = method(other, function (_h, _v) {
		trace_hull_xd = _h-trace_hull_x
		trace_hull_zd = _v-trace_hull_z
	})
	render_callback = method(other, function (_region) begin
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
	

		draw_primitive_begin(pr_linelist)
		draw_set_color(c_grey)
	
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
		map_renderer.draw()
	
		draw_cameray_things()
	draw_trace_hull()
		draw_trace_stuff()
		draw_3d_cursor()
	
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
	step_callback = other.region_2d_xy.step_callback
}

with add_region("2d Viewport (YZ)", new Region(0, 1))
{
	other.region_2d_yz = self
	set_2d_plane(1, 0, 0)
	type = REGION_TYPE_2D
	set_zoom(BASE_ZOOM_2D)
	set_hull_hv = method(other, function (_h, _v)
	{
		var ty1 = trace_hull_y+trace_hull_yd
		var tz1 = trace_hull_z+trace_hull_zd
		trace_hull_y = _h
		trace_hull_z = _v
		trace_hull_yd = ty1-trace_hull_y
		trace_hull_zd = tz1-trace_hull_z
	})
	set_hull_d = method(other, function (_h, _v) {
		trace_hull_yd = _h-trace_hull_y
		trace_hull_zd = _v-trace_hull_z
	})
	render_callback = method(other, function (_region) begin
	
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
	
		map_renderer.draw()
		draw_cameray_things()
	
		draw_trace_stuff()
		draw_trace_hull()
		draw_3d_cursor()
	
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
	step_callback = other.region_2d_xy.step_callback
}

#endregion

#endregion


#region trace stuff

trace_context = new RayRectContext()

trace_boxes = ds_list_create()
trace_down_boxes = ds_list_create()
trace_down_boxes_overlap = ds_list_create()
trace_continue_count = -1
trace_pinned = false
trace_nearest = infinity
trace_x0 = 0
trace_y0 = 0
trace_z0 = 0
trace_x1 = 0
trace_y1 = 0
trace_z1 = 0
trace_hit = false
trace_hit_time = 1
trace_hit_x = 0
trace_hit_y = 0
trace_hit_z = 0
trace_normal_x = 0
trace_normal_y = 0
trace_normal_z = 1
trace_point_x = 0
trace_point_y = 0
trace_point_z = 0
trace_hit_hull = rect_create()

var p_radius = (0.6) * 0.5
var p_height = 1.8

trace_source_hull = rect_create(-p_radius, -p_radius, 0, +p_radius, +p_radius, p_height)
trace_hull = rect_create()
trace_hull_x = 0
trace_hull_y = 0
trace_hull_z = 0
trace_hull_xd = 1
trace_hull_yd = 0
trace_hull_zd = 0
trace_hull_did_hit = false
trace_hull_hit_time = 1
trace_hull_hit_hull = rect_create()
trace_hull_hit_x = 0
trace_hull_hit_y = 0
trace_hull_hit_z = 0
trace_hull_point_x = 0
trace_hull_point_y = 0
trace_hull_point_z = 0
trace_hull_boxes = ds_list_create()

trace_predicate_normal = method(self, function (_x, _y, _z) {
	ds_list_add(trace_boxes, vec_create(_x, _y, _z))
				
	var shapes = map.get(_x, _y, _z).collision_shapes
	var did = false
	var nearest = infinity
				
	for (var i = array_length(shapes); --i >= 0;)
	{
		var shape = shapes[i]
					
		var x0 = shape.x0 + _x
		var y0 = shape.y0 + _y
		var z0 = shape.z0 + _z
		var x1 = shape.x1 + _x
		var y1 = shape.y1 + _y
		var z1 = shape.z1 + _z
					
		if trace_context.test(x0, y0, z0, x1, y1, z1)
		{
			if trace_context.near_time < nearest
			{
				nearest = trace_context.near_time
				rect_set_corners(trace_hit_hull, x0, y0, z0, x1, y1, z1)
				did = true
							
				trace_hit_x = _x
				trace_hit_y = _y
				trace_hit_z = _z
				trace_normal_x = trace_context.normal_x
				trace_normal_y = trace_context.normal_y
				trace_normal_z = trace_context.normal_z
				trace_point_x = trace_context.hit_x
				trace_point_y = trace_context.hit_y
				trace_point_z = trace_context.hit_z
				
				trace_hit_time = nearest
			}
		}
	}
	return did
})

trace_predicate_down = method(self, function (_x, _y, _z, _downsearch) {
	
	ds_list_add(_downsearch ? trace_down_boxes : trace_boxes, vec_create(_x, _y, _z))
	
	var shapes = map.get(_x, _y, _z).collision_shapes
	
	var cc = array_length(shapes)
	if cc <= 0
	{
		if trace_continue_count > -1
		{
			--trace_continue_count
			if trace_continue_count == -1
			{
				return TRACE_COLLIDED
			}
		}
		
		return TRACE_FALSE
	}
	
	
	var did = false
				
	for (var i = array_length(shapes); --i >= 0;)
	{
		var shape = shapes[i]
		var taller = shape.z1 > 1
		var x0 = shape.x0 + _x
		var y0 = shape.y0 + _y
		var z0 = shape.z0 + _z
		var x1 = shape.x1 + _x
		var y1 = shape.y1 + _y
		var z1 = shape.z1 + _z
					
		if trace_context.test(x0, y0, z0, x1, y1, z1)
		{
			var tt = trace_context.near_time
			if tt < trace_nearest
			{
				if taller and trace_continue_count == -1
				{
					trace_continue_count = 1
				}
				trace_nearest = tt
				rect_set_corners(trace_hit_hull, x0, y0, z0, x1, y1, z1)
				did = true
							
				trace_hit_x = _x
				trace_hit_y = _y
				trace_hit_z = _z
				trace_normal_x = trace_context.normal_x
				trace_normal_y = trace_context.normal_y
				trace_normal_z = trace_context.normal_z
				trace_point_x = trace_context.hit_x
				trace_point_y = trace_context.hit_y
				trace_point_z = trace_context.hit_z
				
				trace_hit_time = tt
			}
		}
	}
	
	trace_hit |= did
	
	if did and trace_continue_count > 0
	{
		trace_continue_count -= 1
		return TRACE_CEL_CONTAINED_COLLIDERS
	}
	
	if trace_continue_count == 0
	{
		return TRACE_CEL_CONTAINED_COLLIDERS | TRACE_COLLIDED
	}
	
	return TRACE_CEL_CONTAINED_COLLIDERS | (TRACE_COLLIDED * did)
})

trace_predicate_hull = method(self, function (_x, _y, _z) {
	if global.__TRACE_HULL_STAGE == 1
	{
		ds_list_add(trace_hull_boxes, vec_create(_x, _y, _z))
	}
	
	var shapes = map.get(_x, _y, _z).collision_shapes
	
	if array_length(shapes) <= 0
	{
		return false
	}
	
	var did = false
				
	for (var i = array_length(shapes); --i >= 0;)
	{
		var shape = shapes[i]
					
		var x0 = shape.x0 + _x
		var y0 = shape.y0 + _y
		var z0 = shape.z0 + _z
		var x1 = shape.x1 + _x
		var y1 = shape.y1 + _y
		var z1 = shape.z1 + _z
					
		if trace_context.test(x0, y0, z0, x1, y1, z1)
		{
			var tt = trace_context.near_time
			if tt < trace_hull_hit_time
			{
				trace_hull_did_hit=true
				trace_hull_hit_time = tt
				global.__TRACE_NEAREST = tt

				rect_set_corners(trace_hull_hit_hull, x0, y0, z0, x1, y1, z1)
				did = true

				trace_hull_hit_x = _x
				trace_hull_hit_y = _y
				trace_hull_hit_z = _z
				//trace_normal_x = trace_context.normal_x
				//trace_normal_y = trace_context.normal_y
				//trace_normal_z = trace_context.normal_z
				trace_hull_point_x = trace_context.hit_x
				trace_hull_point_y = trace_context.hit_y
				trace_hull_point_z = trace_context.hit_z
				
			}
		}
	}
	return did
})

function trace_update_hull ()
{
	//trace_hull_x = cursor_3d_x
	//trace_hull_y = cursor_3d_y
	//trace_hull_z = cursor_3d_z
	rect_set_from(trace_hull, trace_source_hull)
	rect_offset(trace_hull, trace_hull_x, trace_hull_y, trace_hull_z)
}

function draw_trace_stuff ()
{
	if not views_show_camera_trace
	{
		return
	}
	
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
	
	draw_primitive_begin(pr_linelist)
	var bsz0 = 0.1
	var bsz1 = 1-bsz0
	for (var i = 0; i < ds_list_size(trace_down_boxes); i++)
	{
		var box = trace_down_boxes[| i]
		draw_set_color(trace_down_boxes_overlap[| i] ? c_red : c_aqua)
		var x0 = box.x+bsz0
		var y0 = box.y+bsz0
		var z0 = box.z+bsz0
		var x1 = box.x+bsz1
		var y1 = box.y+bsz1
		var z1 = box.z+bsz1
		
		corners_linelist(x0, y0, z0, x1, y1, z1)
	}
	draw_primitive_end()
	
	draw_set_color(c_white)
	draw_primitive_begin(pr_linelist)
	draw_vertex_3d(trace_x0, trace_y0, trace_z0)
	draw_vertex_3d(trace_x1, trace_y1, trace_z1)
	draw_primitive_end()
}

function draw_trace_hull ()
{
	gpu_push_state()
	gpu_set_ztestenable(true)
	gpu_set_zwriteenable(true)
	draw_primitive_begin(pr_linelist)
	
	var tx = trace_hull_x
	var ty = trace_hull_y
	var tz = trace_hull_z
	var txd = trace_hull_xd
	var tyd = trace_hull_yd
	var tzd = trace_hull_zd
	
	var tex = tx+txd
	var tey = ty+tyd
	var tez = tz+tzd
	
	var tx0 = trace_source_hull.x0
	var ty0 = trace_source_hull.y0
	var tz0 = trace_source_hull.z0
	var tx1 = trace_source_hull.x1
	var ty1 = trace_source_hull.y1
	var tz1 = trace_source_hull.z1

	draw_set_color(trace_hull_did_hit ? c_lime : c_white)
	corners_linelist(tx0+tx, ty0+ty, tz0+tz, tx1+tx, ty1+ty, tz1+tz)
	
	
	draw_set_color(c_red)
	draw_vertex_3d(tx, ty, tz)
	draw_vertex_3d(tx+txd, ty+tyd, tz+tzd)
	
	draw_set_color(c_yellow)
	corners_linelist(tx0+tex, ty0+tey, tz0+tez, tx1+tex, ty1+tey, tz1+tez)
	
	draw_set_color(c_lime)
	for (var j = 0b000; j <= 0b111; j++)
	{
		var xc = ((j & 0b001) <> 0 ? tx1 : tx0)+tx
		var yc = ((j & 0b010) <> 0 ? ty1 : ty0)+ty
		var zc = ((j & 0b100) <> 0 ? tz1 : tz0)+tz
		
		draw_vertex_3d(xc, yc, zc)
		draw_vertex_3d(xc+txd, yc+tyd, zc+tzd)
		
	}
	
	if trace_hull_did_hit
	{
		draw_set_color(c_red)
		var thx = tx+txd * trace_hull_hit_time
		var thy = ty+tyd * trace_hull_hit_time
		var thz = tz+tzd * trace_hull_hit_time
		corners_linelist(tx0+thx, ty0+thy, tz0+thz, tx1+thx, ty1+thy, tz1+thz)
	}
	
	draw_primitive_end()
	
	static vfff = function () {
		vertex_format_begin()
		vertex_format_add_position_3d()
		vertex_format_add_colour()
		return vertex_format_end()
	}()
	static vvvv = vertex_create_buffer()
	
	vertex_begin(vvvv, vfff)
	draw_set_color(c_aqua)
	var asz0 = 0.001
	var asz1 = 1-asz0
	for (var j = ds_list_size(trace_hull_boxes); --j >= 0;)
	{
		var box = trace_hull_boxes[| j]
		corners_vlist_aaa(vvvv, box.x+asz0, box.y+asz0, box.z+asz0, box.x+asz1, box.y+asz1, box.z+asz1)
	}
	vertex_end(vvvv)
	vertex_submit(vvvv, pr_linelist, -1)
	gpu_pop_state()
	
}

#endregion


#region 3d cursor

function draw_3d_cursor ()
{
	gpu_push_state()
	gpu_set_zfunc(cmpfunc_always)
	draw_set_color(c_white)
	
	var m = matrix_multiply(matrix_get(matrix_view), matrix_get(matrix_projection))
	
	var p = matrix_transform_vertex(m, cursor_3d_x, cursor_3d_y, cursor_3d_z, 1)
	
	cursor_3d_should_draw = p[2] > 0
	
	if cursor_3d_should_draw
	{
		var iv = 1/p[2]
		cursor_3d_draw_x = p[0] *iv
		cursor_3d_draw_y = p[1] * iv
	}

	draw_set_color(c_white)
	gpu_pop_state()
}

cursor_3d_x = 0
cursor_3d_y = 0
cursor_3d_z = 0
cursor_3d_should_draw = false
cursor_3d_draw_x = 0
cursor_3d_draw_y = 0
cursor_3d_display_radius = 0.5



#endregion


#region misc

votv_box_x0 = 0
votv_box_y0 = 0
votv_box_x1 = 0
votv_box_y1 = 0


function draw_axis_bauble (_xs=1, _ys=1, _zs=1)
{
	draw_primitive_begin(pr_linelist)
	draw_set_color(c_yellow)
	draw_vertex_3d(0, 0, 0)
	draw_vertex_3d(_xs, 0, 0)
	draw_set_color(c_red)
	draw_vertex_3d(0, 0, 0)
	draw_vertex_3d(0, _ys, 0)
	draw_set_color(c_aqua)
	draw_vertex_3d(0, 0, 0)
	draw_vertex_3d(0, 0, _zs)
	draw_primitive_end()
}

function draw_cameray_things ()
{
	static sc_m = [
		0.5, 0,0,0,
		0, 0.5, 0,0,
		0, 0, 0.5, 0,
		0,0,0,1
	]
	draw_set_color(c_yellow)
	
	var c = cam
	var cx = c.x
	var cy = c.y
	var cz = c.z
	
	draw_set_color(c_black)
	matrix_stack_push(matrix_build(cx, cy, cz, 0,0,0, 1,1,1))
	matrix_stack_push(c.look_matrix)
	matrix_stack_push(sc_m)
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

#endregion
