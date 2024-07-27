
//grab_mouse()

recalculate_regions()

for (var yy = 0; yy < map.ysize; yy++)
{
	for (var xx = 0; xx < map.xsize; xx++)
	{
		map.set(xx, yy, 0, global.SOLID)
	}
}

camera.co.x = +8
camera.co.y = -8
camera.co.z = +8

array_sort(regions, false)
