
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
	
	mask_2d_x = 1
	mask_2d_y = 1
	mask_2d_z = 1
	normal_2d_x = 0
	normal_2d_y = 0
	normal_2d_z = 0
	
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
	
	
	static set_2d_plane = function (_x, _y, _z)
	{
		normal_2d_x = _x
		normal_2d_y = _y
		normal_2d_z = _z
		mask_2d_x = _x <> 0 ? 1 : 0
		mask_2d_y = _y <> 0 ? 1 : 0
		mask_2d_z = _z <> 0 ? 1 : 0
	}
	
end
