
var ww = max(window_get_width(), 1)
var wh = max(window_get_height(), 1)
if ww <> room_width or wh <> room_height
{
	room_width = ww
	room_height = wh
	surface_resize(application_surface, ww, wh)
	invalidate_surface()
	recalculate_regions()
}

