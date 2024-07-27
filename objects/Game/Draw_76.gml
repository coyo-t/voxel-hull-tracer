
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

var c = cam

c.recalculate_vectors()
c.rebuild_matrices()
audio_listener_position(c.x, c.y, c.z)
audio_listener_orientation(c.forward_x, c.forward_y, c.forward_z, c.up_x, c.up_y, c.up_z)


