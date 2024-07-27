var dt = delta_time / 1000000

var wmx = display_mouse_get_x() - window_get_x()
var wmy = display_mouse_get_y() - window_get_y()
mouse.pev_x = mouse.x
mouse.pev_y = mouse.y

mouse.x = wmx
mouse.y = wmy


for (var i = array_length(regions); (--i) >= 0; )
{
	var region = regions[i]
	acting_region = region
	region_setup_mouse_co(region)
		
	if region_contains_point(region, mouse.x, mouse.y)
	{
		set_focused_region(region)
	}
		
	region_try_step(region)
}




