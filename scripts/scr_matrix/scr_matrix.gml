
global.__MT_W = array_create(32)
global.__MT_V = array_create(32)
global.__MT_P = array_create(32)

global.__MT_WP = 0
global.__MT_VP = 0
global.__MT_PP = 0

function matrix_stack_top_clear ()
{
	var outs = matrix_stack_top()
	matrix_stack_clear()
	return outs
}

function matrix_push (_type, _to=undefined)
{
	switch _type
	{
		case matrix_world:
			global.__MT_W[global.__MT_WP++] = matrix_get(_type)
			break;
		case matrix_view:
			global.__MT_V[global.__MT_VP++] = matrix_get(_type)
			break;
		case matrix_projection:
			global.__MT_P[global.__MT_PP++] = matrix_get(_type)
			break;
	}
	
	if _to <> undefined
	{
		matrix_set(_type, _to)
	}
}

function matrix_pop (_type)
{
	switch _type
	{
		case matrix_world:
			matrix_set(_type, global.__MT_W[--global.__MT_WP])
			break;
		case matrix_view:
			matrix_set(_type, global.__MT_V[--global.__MT_VP])
			break;
		case matrix_projection:
			matrix_set(_type, global.__MT_P[--global.__MT_PP])
			break;
	}
}
