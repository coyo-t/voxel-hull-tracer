
function Block () constructor begin
	static C = 0
	
	render_shapes = []
	collision_shapes = []
	
	runtime_id = C++
	
	colour = c_white
	
	static is = function (_to)
	{
		return runtime_id == _to.runtime_id
	}
end

global.AIR   = new Block()
global.AIR.render_shapes = []
global.AIR.collision_shapes = []

global.SOLID = new Block()
global.SOLID.render_shapes = [{x0:0, y0:0, z0:0, x1:1, y1:1, z1:1}]
global.SOLID.collision_shapes = global.SOLID.render_shapes
global.SOLID.colour = c_ltgrey

global.OUT_OF_BOUNDS   = new Block()
global.OUT_OF_BOUNDS.render_shapes = []
global.OUT_OF_BOUNDS.collision_shapes = global.SOLID.render_shapes
global.OUT_OF_BOUNDS.colour = c_dkgrey

function MapData (_xsize, _ysize, _zsize) constructor begin
	
	xsize = floor(_xsize)
	ysize = floor(_ysize)
	zsize = floor(_zsize)
	
	count = xsize*ysize*zsize
	data = array_create(xsize*ysize*zsize, global.AIR)
	
	static xytoi = function (_x, _y, _z)
	{
		return (_z * ysize + _y) * xsize + _x
	}
	
	static inbounds = function (_x, _y, _z)
	{
		return 0 <= _x and _x < xsize and 0 <= _y and _y < ysize and 0 <= _z and _z < zsize
	}
	
	static get = function (_x, _y, _z)
	{
		if inbounds(_x, _y, _z)
		{
			return data[xytoi(_x, _y, _z)]
		}
		return global.OUT_OF_BOUNDS
	}
	
	static set = function (_x, _y, _z, _type)
	{
		if inbounds(_x, _y, _z)
		{
			var addr = xytoi(_x, _y, _z)
			if not data[addr].is(_type)
			{
				data[addr] = _type
				return true
			}
		}
		return false
	}
end
