function Corners (_x0, _y0, _z0, _x1, _y1, _z1) constructor begin
	x0 = _x0
	y0 = _y0
	z0 = _z0
	x1 = _x1
	y1 = _y1
	z1 = _z1
end

function rect_create (_x0=0, _y0=0, _z0=0, _x1=1, _y1=1, _z1=1)
{
	return new Corners(_x0, _y0, _z0, _x1, _y1, _z1)
}

function rect_create_from (_r)
{
	return rect_create(_r.x0, _r.y0, _r.z0, _r.x1, _r.y1, _r.z1)
}

function rect_expand_corners_to (_self, _to)
{
	_self.x0 = min(_self.x0, _to.x0)
	_self.y0 = min(_self.y0, _to.y0)
	_self.z0 = min(_self.z0, _to.z0)
	_self.x1 = max(_self.x1, _to.x1)
	_self.y1 = max(_self.y1, _to.y1)
	_self.z1 = max(_self.z1, _to.z1)
	return _self
}
