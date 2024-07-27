
for (var i = array_length(regions); --i >= 0;)
{
	var region = regions[i]
	
	if is_callable(region.render_callback)
	{
		surface_set_target(ensure_surface())
		region.render_callback(region)
		surface_reset_target()
	}
	draw_view_and_bezel(region)
}

draw_set_color(c_white)
draw_set_alpha(1)
