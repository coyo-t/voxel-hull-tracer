function copy_sign (_from, _to)
{
	if (_from <= -0 and _to >= +0) or (_from >= +0 and _to <= -0)
	{
		return -_to
	}
	
	return _to
}