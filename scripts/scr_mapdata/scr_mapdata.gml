
global.__HIT_NORMAL = [0,0,0]
global.__HIT_POINT  = [0,0,0]
global.__HIT_TIME = 1
global.__HIT_DISTANCE = 0
global.__HIT_NORMALIZED = [0,0,0]
global.__HIT_IS_DOWN_CHECK = false
global.__TRACE_NEAREST = 0
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
	
	global.__TRACE_HULL_STAGE = 0
	static trace_hull = function (
		_x0, _y0, _z0,
		_x1, _y1, _z1,
		_xd, _yd, _zd,
		_predicate = undefined
	)
	{
		static vec = function (_x=0,_y=0,_z=0) { return [_x,_y,_z] }
		static calciter = function (_x, _y, _z, _xd, _yd, _zd) {
			return (
				abs(floor(_x+_xd)-floor(_x))+
				abs(floor(_y+_yd)-floor(_y))+
				abs(floor(_z+_zd)-floor(_z))
			)
		}
		
		global.__TRACE_HULL_STAGE = 0
		var time_max = (_xd*_xd)+(_yd*_yd)+(_zd*_zd)
		
		if time_max <= 0
		{
			return false
		}
		
		_predicate ??= function (_x, _y, _z) { return true }
		
		var box_direction = vec(_xd, _yd, _zd)
		
		var box_min = vec(_x0, _y0, _z0)
		var box_max = vec(_x1, _y1, _z1)
		
		var eps = math_get_epsilon()
		var ep2 = 1 - eps
		var bx0 = floor(box_min[0] + eps)
		var by0 = floor(box_min[1] + eps)
		var bz0 = floor(box_min[2] + eps)
		var bx1 = floor(box_max[0] + ep2)
		var by1 = floor(box_max[1] + ep2)
		var bz1 = floor(box_max[2] + ep2)
		
		var did = false
		
		// check the hull area. not elegant but it works :/
		begin
			var xx, yy, zz
			
			for (zz = bz0; zz < bz1; zz++)
			{
				for (yy = by0; yy < by1; yy++)
				{
					for (xx = bx0; xx < bx1; xx++)
					{
						did |= _predicate(xx, yy, zz)
					}
				}
			}
			
		end
		
		var trailing_corner = vec()
		var leading_corner = vec()
		
		var trailing_cel = vec()
		var leading_cel = vec()
		
		var step = vec()
		var time_delta = vec()
		
		var time_next = vec()
		var normalized = vec()
		
		time_max = sqrt(time_max)
		var inverse_time_max = 1.0 / time_max
		
		for (var i = 0; i < Vec3.sizeof; i++)
		{
			var rd = box_direction[i]
			var dir_positive = rd >= 0
			step[i] = dir_positive ? +1 : -1
		
			leading_corner[i]  = dir_positive ? box_max[i] : box_min[i]
			trailing_corner[i] = dir_positive ? box_min[i] : box_max[i]
		
			var jit = step[i] * eps
		
			leading_cel[i]  = floor(leading_corner[i]  - jit)
			trailing_cel[i] = floor(trailing_corner[i] + jit)
		
			time_delta[i] = rd == 0 ? infinity : abs(1.0 / rd)
		
			time_next[i] = dir_positive
				? (leading_cel[i] + 1 - leading_corner[i])
				: (leading_corner[i] - leading_cel[i])
			time_next[i] *= time_delta[i]
		
			normalized[i] = rd * inverse_time_max
		}
		
		var stepx = step[Vec3.x]
		var stepy = step[Vec3.y]
		var stepz = step[Vec3.z]
	
		var leading_total  = vec(
			stepx > 0 ? bx1 : bx0,
			stepy > 0 ? by1 : by0,
			stepz > 0 ? bz1 : bz0
		)
		var trailing_total = vec(
			stepx > 0 ? bx0 : bx1,
			stepy > 0 ? by0 : by1,
			stepz > 0 ? bz0 : bz1
		)
		
		var trailing_start = vec(trailing_corner[0],trailing_corner[1],trailing_corner[2])
		var leading_start = vec(leading_corner[0],leading_corner[1],leading_corner[2])
		
		var axis = Vec3.sizeof
		
		var maxiter = calciter(
			leading_corner[0]-eps*stepx,
			leading_corner[1]-eps*stepy,
			leading_corner[2]-eps*stepz,
			box_direction[0],
			box_direction[1],
			box_direction[2]
		)
		
		var time = 0
		
		var ddid = did
		var xx, yy, zz
		// "Search" bounds
		var sx0, sy0, sz0
		var sx1, sy1, sz1
		
		static lesser_axis = function (_time_next)
		{
			return (_time_next[Vec3.x] < _time_next[Vec3.y])
				? (_time_next[Vec3.z] < _time_next[Vec3.x] ? Vec3.z : Vec3.x)
				: (_time_next[Vec3.z] < _time_next[Vec3.y] ? Vec3.z : Vec3.y)
		}
		
		while (--maxiter) >= 0
		{
			axis = lesser_axis(time_next)
		
			begin
				time = time_next[axis]

				leading_cel[axis] += step[axis]
				time_next[axis] += time_delta[axis]
		
				for (var i = 0; i < Vec3.sizeof; i++)
				{
					var nf = normalized[i] * time * time_max
					leading_corner[i] = leading_start[i] + nf
					trailing_corner[i] = trailing_start[i] + nf
					trailing_cel[i] = floor(trailing_corner[i] + step[i] * eps)
				}
			end
		
			if ddid
			{
				break
			}
		
			sx0 = (axis == Vec3.x) ? leading_cel[Vec3.x] : trailing_cel[Vec3.x]
			sx1 = leading_cel[Vec3.x] + stepx

			sy0 = (axis == Vec3.y) ? leading_cel[Vec3.y] : trailing_cel[Vec3.y]
			sy1 = leading_cel[Vec3.y] + stepy

			sz0 = (axis == Vec3.z) ? leading_cel[Vec3.z] : trailing_cel[Vec3.z]
			sz1 = leading_cel[Vec3.z] + stepz
			
			leading_total[axis] += step[axis]
			
			var xcount = abs(sx1-sx0)
			var ycount = abs(sy1-sy0)
			var zcount = abs(sz1-sz0)
			
			var yc, zc
			for (xx = sx0; --xcount >= 0; xx+=stepx)
			{
				yc = ycount
				for (yy = sy0; --yc >= 0; yy+=stepy)
				{
					zc = zcount
					for (zz = sz0; --zc >= 0; zz+=stepz)
					{
						ddid |= _predicate(xx, yy, zz)
					}
				}
			}
		
			did |= ddid
			if ddid then break
		}
	
		if did
		{
			global.__TRACE_HULL_STAGE = 1
			// fixme: icky hack!!!
			var nearest = global.__TRACE_NEAREST
			var tmp
		
			var cur_lx0 = trailing_corner[0]
			var cur_ly0 = trailing_corner[1]
			var cur_lz0 = trailing_corner[2]
			var cur_lx1 = leading_corner[0]
			var cur_ly1 = leading_corner[1]
			var cur_lz1 = leading_corner[2]
		
			tmp = cur_lx0
			cur_lx0 = min(tmp, cur_lx1)
			cur_lx1 = max(tmp, cur_lx1)
			tmp = cur_ly0
			cur_ly0 = min(tmp, cur_ly1)
			cur_ly1 = max(tmp, cur_ly1)
			tmp = cur_lz0
			cur_lz0 = min(tmp, cur_lz1)
			cur_lz1 = max(tmp, cur_lz1)
		
		
			while (--maxiter) >= 0
			{
				var land_x = box_direction[Vec3.x] * nearest
				var land_y = box_direction[Vec3.y] * nearest
				var land_z = box_direction[Vec3.z] * nearest
		
				var lsx0 = trailing_start[0] + land_x
				var lsy0 = trailing_start[1] + land_y
				var lsz0 = trailing_start[2] + land_z
				var lsx1 = leading_start[0] + land_x
				var lsy1 = leading_start[1] + land_y
				var lsz1 = leading_start[2] + land_z
		
				tmp = lsx0
				lsx0 = min(tmp, lsx1)
				lsx1 = max(tmp, lsx1)
				tmp = lsy0
				lsy0 = min(tmp, lsy1)
				lsy1 = max(tmp, lsy1)
				tmp = lsz0
				lsz0 = min(tmp, lsz1)
				lsz1 = max(tmp, lsz1)
			
				lsx0 = min(lsx0, cur_lx0)
				lsy0 = min(lsy0, cur_ly0)
				lsz0 = min(lsz0, cur_lz0)
				lsx1 = max(lsx1, cur_lx1)
				lsy1 = max(lsy1, cur_ly1)
				lsz1 = max(lsz1, cur_lz1)
			
				lsx0 = floor(lsx0+eps)
				lsy0 = floor(lsy0+eps)
				lsz0 = floor(lsz0+eps)
				lsx1 = floor(lsx1+1-eps)
				lsy1 = floor(lsy1+1-eps)
				lsz1 = floor(lsz1+1-eps)
		
				var ignore_x0 = min(trailing_total[0], leading_total[0])
				var ignore_y0 = min(trailing_total[1], leading_total[1])
				var ignore_z0 = min(trailing_total[2], leading_total[2])
				var ignore_x1 = max(leading_total[0], trailing_total[0])
				var ignore_y1 = max(leading_total[1], trailing_total[1])
				var ignore_z1 = max(leading_total[2], trailing_total[2])
			
				var xcount = abs(lsx1-lsx0)
				var ycount = abs(lsy1-lsy0)
				var zcount = abs(lsz1-lsz0)
				
				var yc, zc
				for (xx = lsx0; --xcount >= 0; xx++)
				{
					var ignx = ignore_x0 <= xx and xx < ignore_x1
					yc = ycount
					for (yy = lsy0; --yc >= 0; yy++)
					{
						var igny = ignore_y0 <= yy and yy < ignore_y1
						zc = zcount
						for (zz = lsz0; --zc >= 0; zz++)
						{
							if ignx and igny and ignore_z0 <= zz and zz < ignore_z1
							{
								continue
							}
							ddid |= _predicate(xx, yy, zz)
						}
					}
				}
				if global.__TRACE_NEAREST >= nearest
				{
					break
				}
				nearest = global.__TRACE_NEAREST
			}
		}
	
		return did
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
	
	#macro TRACE_FALSE (0)
	#macro TRACE_CEL_CONTAINED_COLLIDERS (0b0000_0001)
	#macro TRACE_COLLIDED (0b0000_0010)
	
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
		
		_predicate ??= function (_x, _y, _z, _downsearch) { return true }
		
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
		
		var pev_x = infinity * -step[0]
		var pev_y = infinity * -step[1]
		var pev_z = infinity * -step[2]
		
		var cel_x, cel_y, cel_z
		
			// line goes upwards or would draw a line of cels that is entirely horizontal
		var downsearch_prereq = step[Vec3.z] >= 0 or cel[Vec3.z] == floor(ray_origin[Vec3.z] + ray_direction[Vec3.z])
		var axis = Vec3.sizeof
		while (--max_iter) >= 0
		{
			cel_x = cel[0]
			cel_y = cel[1]
			cel_z = cel[2]
			
			var pev_axis = axis
			var axis = (next_distance[0] < next_distance[1])
				? ((next_distance[2] < next_distance[0]) ? 2 : 0)
				: ((next_distance[2] < next_distance[1]) ? 2 : 1)
			
			var down_search
			var hdiff = pev_x <> cel_x or pev_y <> cel_y
			if downsearch_prereq
			{
				down_search = hdiff
			}
			else
			{
				down_search = (
					max_iter == 0 or
					(axis <> Vec3.z and (hdiff or (pev_axis == Vec3.z and cel_z < pev_z)))
				)
			}
			
			var did = _predicate(cel_x, cel_y, cel_z, false)
			var did_down = TRACE_FALSE
			if down_search and (did & TRACE_CEL_CONTAINED_COLLIDERS) == 0
			{
				did_down = _predicate(cel_x, cel_y, cel_z - 1, true)
			}
		
			if ((did | did_down) & TRACE_COLLIDED) <> 0
			{
				return true
			}
			
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
			
			// technically only one needs to change but whatv
			pev_x = cel_x
			pev_y = cel_y
			pev_z = cel_z
			next_distance[axis] += slope[axis]
			cel[axis] += step[axis]
		}

		return false
	}
end
