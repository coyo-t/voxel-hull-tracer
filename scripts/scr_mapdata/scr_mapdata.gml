



global.__HIT_NORMAL = [0,0,0]
global.__HIT_POINT  = [0,0,0]
global.__HIT_TIME = 1
global.__HIT_DISTANCE = 0
global.__HIT_NORMALIZED = [0,0,0]
global.__HIT_IS_DOWN_CHECK = false
function MapData (_xsize, _ysize, _zsize) constructor begin
	
	xsize = floor(_xsize)
	ysize = floor(_ysize)
	zsize = floor(_zsize)
	
	count = xsize*ysize*zsize
	data = array_create(xsize*ysize*zsize, global.BLOCKS.AIR)
	
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
		if _z < 0
		{
			return global.BLOCKS.OUT_OF_BOUNDS
		}
		return global.BLOCKS.OUT_OF_BOUNDS_AIR
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
	
	static trace_line = function (_start_x, _start_y, _start_z, _end_x, _end_y, _end_z, _predicate=undefined)
	{
		global.__HIT_IS_DOWN_CHECK = false
		static calc_iter_count = function (_start, _direction)
		{
			static calc_iter_count_sep = function (_x, _y, _z, _xd, _yd, _zd)
			{
				return abs(floor(_x+_xd)-floor(_x))+abs(floor(_y+_yd)-floor(_y))+abs(floor(_z+_zd)-floor(_z))+1
			}
			return calc_iter_count_sep(_start[0], _start[1], _start[2], _direction[0], _direction[1], _direction[2])
		}
		
		_predicate ??= function (_x, _y, _z) { return true }
		
		var ray_origin = [_start_x, _start_y, _start_z]
		var ray_end = [_end_x, _end_y, _end_z]
		
		var ray_direction = [_end_x-_start_x,_end_y-_start_y,_end_z-_start_z]
		
		var length = power(ray_direction[0], 2)+power(ray_direction[1], 2)+power(ray_direction[2], 2)
		
		if length <= 0
		{
			return false
		}
		
		length = sqrt(length)
		var inverse_length = 1.0 / length
		
		var step = [0,0,0]
		var slope = [1,1,1]
		var normalized=[0,0,0]
		var cel = [0,0,0]
		var next_distance = [0,0,0]
		
		var time = 0
		
		for (var i = 0; i < 3; i++)
		{
			var dp = ray_direction[i] >= 0
			step[i] = dp ? +1 : -1
			slope[i] = abs(ray_direction[i]) <= 0 ? infinity : abs(1/ray_direction[i])
			normalized[i] = ray_direction[i] * inverse_length
			cel[i] = floor(ray_origin[i])
			
			next_distance[i] = (dp ? (cel[i] + 1 - ray_origin[i]) : (ray_origin[i] - cel[i])) * slope[i]
		}
		
		global.__HIT_NORMALIZED[0] = normalized[0]
		global.__HIT_NORMALIZED[1] = normalized[1]
		global.__HIT_NORMALIZED[2] = normalized[2]
		
		var max_iter = calc_iter_count(ray_origin, ray_direction)

		while (--max_iter) >= 0
		{
			
			if _predicate(cel[0], cel[1], cel[2])
			{
				return true
			}
			
			var axis = (next_distance[0] < next_distance[1])
				? ((next_distance[2] < next_distance[0]) ? 2 : 0)
				: ((next_distance[2] < next_distance[1]) ? 2 : 1)
			
			time = next_distance[axis]
			
			// FIXME: icky hack!!!
			global.__HIT_NORMAL[0] = axis == 0 ? -step[0] : 0
			global.__HIT_NORMAL[1] = axis == 1 ? -step[1] : 0
			global.__HIT_NORMAL[2] = axis == 2 ? -step[2] : 0
			global.__HIT_POINT[0] = ray_direction[0] * time + ray_origin[0]
			global.__HIT_POINT[1] = ray_direction[1] * time + ray_origin[1]
			global.__HIT_POINT[2] = ray_direction[2] * time + ray_origin[2]
			global.__HIT_TIME = time
			global.__HIT_DISTANCE = length * time
			
			next_distance[axis] += slope[axis]
			cel[axis] += step[axis]
		}

		return false
	}
	
	static trace_line_with_downwards = function (_start_x, _start_y, _start_z, _end_x, _end_y, _end_z, _predicate=undefined)
	{
		global.__HIT_IS_DOWN_CHECK = false
		static calc_iter_count = function (_start, _direction)
		{
			static calc_iter_count_sep = function (_x, _y, _z, _xd, _yd, _zd)
			{
				return abs(floor(_x+_xd)-floor(_x))+abs(floor(_y+_yd)-floor(_y))+abs(floor(_z+_zd)-floor(_z))+1
			}
			return calc_iter_count_sep(_start[0], _start[1], _start[2], _direction[0], _direction[1], _direction[2])
		}
		
		_predicate ??= function (_x, _y, _z) { return true }
		
		var ray_origin = [_start_x, _start_y, _start_z]
		var ray_end = [_end_x, _end_y, _end_z]
		
		var ray_direction = [_end_x-_start_x,_end_y-_start_y,_end_z-_start_z]
		
		var length = power(ray_direction[0], 2)+power(ray_direction[1], 2)+power(ray_direction[2], 2)
		
		if length <= 0
		{
			return false
		}
		
		length = sqrt(length)
		var inverse_length = 1.0 / length
		
		var step = [0,0,0]
		var slope = [1,1,1]
		var normalized=[0,0,0]
		var cel = [0,0,0]
		var next_distance = [0,0,0]
		
		var time = 0
		
		for (var i = 0; i < 3; i++)
		{
			var dp = ray_direction[i] >= 0
			step[i] = dp ? +1 : -1
			slope[i] = abs(ray_direction[i]) <= 0 ? infinity : abs(1/ray_direction[i])
			normalized[i] = ray_direction[i] * inverse_length
			cel[i] = floor(ray_origin[i])
			
			next_distance[i] = (dp ? (cel[i] + 1 - ray_origin[i]) : (ray_origin[i] - cel[i])) * slope[i]
		}
		
		global.__HIT_NORMALIZED[0] = normalized[0]
		global.__HIT_NORMALIZED[1] = normalized[1]
		global.__HIT_NORMALIZED[2] = normalized[2]
		
		var max_iter = calc_iter_count(ray_origin, ray_direction)

		while (--max_iter) >= 0
		{
			
			if _predicate(cel[0], cel[1], cel[2])
			{
				return true
			}
			
			var axis = (next_distance[0] < next_distance[1])
				? ((next_distance[2] < next_distance[0]) ? 2 : 0)
				: ((next_distance[2] < next_distance[1]) ? 2 : 1)
			
			time = next_distance[axis]
			
			// FIXME: icky hack!!!
			global.__HIT_NORMAL[0] = axis == 0 ? -step[0] : 0
			global.__HIT_NORMAL[1] = axis == 1 ? -step[1] : 0
			global.__HIT_NORMAL[2] = axis == 2 ? -step[2] : 0
			global.__HIT_POINT[0] = ray_direction[0] * time + ray_origin[0]
			global.__HIT_POINT[1] = ray_direction[1] * time + ray_origin[1]
			global.__HIT_POINT[2] = ray_direction[2] * time + ray_origin[2]
			global.__HIT_TIME = time
			global.__HIT_DISTANCE = length * time
			
			next_distance[axis] += slope[axis]
			cel[axis] += step[axis]
		}

		return false
	}
end
