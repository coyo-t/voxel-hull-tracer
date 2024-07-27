
//grab_mouse()

recalculate_regions()

var fill = global.BLOCKS.SOLID
for (var yy = 0; yy < map.ysize; yy++)
{
	for (var xx = 0; xx < map.xsize; xx++)
	{
		map.set(xx, yy, 0, fill)
	}
}

var c = cam

//camera.co.x = +8
//camera.co.y = -8
//camera.co.z = +8

c.x = map.xsize / 2
c.y = map.ysize / 4 + 0.5
c.z = map.zsize - 0.5

c.pitch = -90

array_sort(regions, false)

cursor_3d_x = map.xsize / 2
cursor_3d_y = map.ysize / 2
cursor_3d_z = map.zsize / 2
