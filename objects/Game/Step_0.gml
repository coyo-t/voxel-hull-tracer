var dt = delta_time / 1000000

var wmx = display_mouse_get_x() - window_get_x()
var wmy = display_mouse_get_y() - window_get_y()
mouse.pev_x = mouse.x
mouse.pev_y = mouse.y

mouse.x = wmx
mouse.y = wmy

//if has_locked_region()
//{
//	var _focus = get_focused_region()
//	region_setup_mouse_co(_focus)
//	acting_region = _focus
//	region_try_step(_focus)
//	//locked_region.has_focus = true
//	for (var i = array_length(regions); (--i) >= 0; )
//	{
//		var region = regions[i]
//		if region_has_focus(region)
//		{
//			continue
//		}
//		acting_region = region
//		region.xmouse = 0
//		region.ymouse = 0
//		region_try_step(region)
//		//region.has_focus = false
//	}
//	show_debug_message($"FUCK {get_focused_region().name}")
//}
//else
{
	//set_focused_region(undefined)
	
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
}




