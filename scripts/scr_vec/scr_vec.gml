enum Vec3
{
	x,
	y,
	z,
	sizeof
}

function __Vec (_x, _y, _z) constructor begin
	x = _x
	y = _y
	z = _z
end

function vec_create (_x=0, _y=0, _z=0)
{
	return new __Vec(_x, _y, _z)
}
