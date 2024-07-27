
function RayRectContext () constructor begin
	
	origin_x = 0
	origin_y = 0
	origin_z = 0
	
	end_x = 0
	end_y = 0
	end_z = 0
	
	direction_x = 0
	direction_y = 0
	direction_z = 0
	inv_direction_x = 1
	inv_direction_y = 1
	inv_direction_z = 1
	
	direction_length = 0
	inv_direction_length = 1
	
	direction_normal_x = 0
	direction_normal_y = 0
	direction_normal_z = 0
	
	hit_x = 0
	hit_y = 0
	hit_z = 0
	
	sign_x_negative = false
	sign_y_negative = false
	sign_z_negative = false
	sign_x = 1
	sign_y = 1
	sign_z = 1
	
	did_hit = false
	
	near_time = 1
	far_time = 1
	
	inflate_x = 0
	inflate_y = 0
	inflate_z = 0
	
	normal_x = 0
	normal_y = 0
	normal_z = 0
	
	static __direct_comp = function (_v)
	{
		// abs should account for +0 and -0?
		return abs(_v) == 0.0 ? infinity : 1.0 / _v
	}
	
	static __setup_direction_values = function ()
	{
		sign_x_negative = direction_x < 0
		sign_y_negative = direction_y < 0
		sign_z_negative = direction_z < 0
		
		sign_x = sign_x_negative ? -1 : +1
		sign_y = sign_y_negative ? -1 : +1
		sign_z = sign_z_negative ? -1 : +1
		
		inv_direction_x = __direct_comp(direction_x)
		inv_direction_y = __direct_comp(direction_y)
		inv_direction_z = __direct_comp(direction_z)
		
		var mag = power(direction_x, 2) + power(direction_y, 2) + power(direction_z, 2)
		
		if mag <= 0
		{
			direction_length = 0
			inv_direction_length = infinity
			direction_normal_x = 0
			direction_normal_y = 0
			direction_normal_z = 0
		}
		else if mag == 1
		{
			direction_length = 1
			inv_direction_length = 1
			direction_normal_x = direction_x
			direction_normal_y = direction_y
			direction_normal_z = direction_z
		}
		else
		{
			direction_length = sqrt(mag)
			inv_direction_length = 1.0 / direction_length
			direction_normal_x = direction_normal_x * inv_direction_length
			direction_normal_y = direction_normal_y * inv_direction_length
			direction_normal_z = direction_normal_z * inv_direction_length
		}
		
	}
	
	static setup = function (_origin_x, _origin_y, _origin_z, _direction_x, _direction_y, _direction_z)
	{
		origin_x = _origin_x
		origin_y = _origin_y
		origin_z = _origin_z
		
		end_x = _origin_x + _direction_x
		end_y = _origin_y + _direction_y
		end_z = _origin_z + _direction_z
		
		direction_x = _direction_x
		direction_y = _direction_y
		direction_z = _direction_z
		
		__setup_direction_values()
		
		inflate_x = 0
		inflate_y = 0
		inflate_z = 0
	}
	
	static setup_endpoints = function (_start_x, _start_y, _start_z, _end_x, _end_y, _end_z)
	{
		origin_x = _start_x
		origin_y = _start_y
		origin_z = _start_z
		
		end_x = _end_x
		end_y = _end_y
		end_z = _end_z
		
		direction_x = _end_x - _start_x
		direction_y = _end_y - _start_y
		direction_z = _end_z - _start_z
		
		__setup_direction_values()
		
		inflate_x = 0
		inflate_y = 0
		inflate_z = 0
	}
	
	static setup_with_corners = function (_x0, _y0, _z0, _x1, _y1, _z1, _direction_x, _direction_y, _direction_z)
	{
		setup(
			(_x0 + _x1) * 0.5,
			(_y0 + _y1) * 0.5,
			(_z0 + _z1) * 0.5,
			_direction_x,
			_direction_y,
			_direction_z
		)
		
		inflate_x = (_x1 - _x0) * 0.5
		inflate_y = (_y1 - _y0) * 0.5
		inflate_z = (_z1 - _z0) * 0.5
		
	}
	
	static test = function (_x0, _y0, _z0, _x1, _y1, _z1)
	{
		did_hit = false
		
		_x0 -= inflate_x
		_y0 -= inflate_y
		_z0 -= inflate_z
		_x1 += inflate_x
		_y1 += inflate_y
		_z1 += inflate_z
		
		if (_x0 <= origin_x and origin_x <= _x1 and
		    _y0 <= origin_y and origin_y <= _y1 and
		    _z0 <= origin_z and origin_z <= _z1)
		{
			return false
		}
		
		var e = math_get_epsilon()
		
		_x0 -= e
		_y0 -= e
		_z0 -= e
		_x1 += e
		_y1 += e
		_z1 += e
		
		
		var t1 = ((sign_x_negative ? _x1 : _x0) - origin_x) * inv_direction_x
		var t2 = ((sign_x_negative ? _x0 : _x1) - origin_x) * inv_direction_x
		
		var hxmin = min(t1, t2)
		
		var tmin = hxmin
		var tmax = max(t1, t2)
		
		
		t1 = ((sign_y_negative ? _y1 : _y0) - origin_y) * inv_direction_y
		t2 = ((sign_y_negative ? _y0 : _y1) - origin_y) * inv_direction_y
		
		var hymin = min(t1, t2)
		
		tmin = max(tmin, hymin)
		tmax = min(tmax, max(t1, t2))


		t1 = ((sign_z_negative ? _z1 : _z0) - origin_z) * inv_direction_z
		t2 = ((sign_z_negative ? _z0 : _z1) - origin_z) * inv_direction_z

		var hzmin = min(t1, t2)
		
		tmin = max(tmin, hzmin)
		tmax = min(tmax, max(t1, t2))
		
		near_time = max(tmin, 0.0)
		far_time  = tmax
		
		var axis = (hxmin > hymin)
			? ((hzmin > hxmin) ? Vec3.z : Vec3.x)
			: ((hzmin > hymin) ? Vec3.z : Vec3.y)
		
		normal_x = axis == Vec3.x ? -sign_x : 0
		normal_y = axis == Vec3.y ? -sign_y : 0
		normal_z = axis == Vec3.z ? -sign_z : 0

		did_hit = far_time > near_time
		
		if did_hit
		{
			hit_x = direction_x * near_time + origin_x
			hit_y = direction_y * near_time + origin_y
			hit_z = direction_z * near_time + origin_z
		}
		
		return did_hit
	}
end

