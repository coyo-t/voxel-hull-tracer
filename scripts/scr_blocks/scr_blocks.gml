#region registyr
function BlockRegistry () constructor begin
	
	_all = []
	_by_name = {}
	_full_blocs = []
	
	static add = function (_name, _block, _init=undefined)
	{
		_block.runtime_id = array_length(_all)
		_block.name = _name
		
		_by_name[$ _name] = _block
		array_push(_all, _block)
		
		if is_callable(_init)
		{
			var FUCK = method(_block, _init)
			FUCK()
		}
		
		return _block
	}
	
	static finalize = function ()
	{
		var bc = array_length(_all)
		var empty_array = []
		_full_blocs = array_create(bc, false)
		for (var i = bc; --i >= 0;)
		{
			var bloc = _all[i]
			
			if array_length(bloc.render_shapes) == 0
			{
				bloc.render_shapes = empty_array
			}
			
			var sh = bloc.collision_shapes
			switch array_length(sh)
			{
				case 0:
					bloc.collision_shapes = empty_array
					break
				case 1:
				{
					sh = sh[0]
					if sh.x0 == 0 and sh.y0 == 0 and sh.z0 == 0
					{
						if sh.x1 == 1 and sh.y1 == 1 and sh.z1 == 1
						{
							_full_blocs[bloc.runtime_id] = true
						}
					}
					break
				}
			}
		}
		gc_collect()
	}
end

global.BLOCK_REGISTRY = new BlockRegistry()

function blocks_register (_name, _block, _init=undefined)
{
	return global.BLOCK_REGISTRY.add(_name, _block, _init)
}

function blocks_get_by_name (_name)
{
	return global.BLOCK_REGISTRY._by_name[$ _name]
}

function blocks_get_by_id (_id)
{
	return global.BLOCK_REGISTRY._all[_id]
}

function blocks_get_all_registered ()
{
	return global.BLOCK_REGISTRY._all
}

#endregion

function Block () constructor begin	
	render_shapes = []
	collision_shapes = []
	
	runtime_id = -1
	name = "NONE"
	
	colour = c_white
	
	replacable = false
	
	sprite = spr_terrain__2_
	
	static is = function (_to)
	{
		return runtime_id == _to.runtime_id
	}
	
	static is_full_block = function ()
	{
		return global.BLOCK_REGISTRY._full_blocs[runtime_id]
	}
end


global.BLOCKS = {
	AIR: blocks_register("air", new Block(), function () {
		render_shapes = []
		collision_shapes = []
		replacable = true
	}),
	OUT_OF_BOUNDS: blocks_register("out_of_bounds", new Block(), function () {
		collision_shapes = [rect_create(0, 0, 0, 1, 1, 1)]
		render_shapes = collision_shapes
		colour_2d = c_dkgrey
		sprite = spr_dark_hull
	}),
	
	OUT_OF_BOUNDS_AIR: blocks_register("out_of_bounds_air", new Block(), function () {
		render_shapes = []
		collision_shapes = []
		replacable = true
	}),
	
	SOLID: blocks_register("solid", new Block(), function () {
		render_shapes = [rect_create(0, 0, 0, 1, 1, 1)]
		collision_shapes = render_shapes
		colour_2d = c_ltgrey
		sprite = spr_grey_hull
	}),
	
	DIRT: blocks_register("dirt", new Block(), function () {
		render_shapes = [rect_create(0, 0, 0, 1, 1, 1)]
		collision_shapes = render_shapes
		colour_2d = c_orange
		sprite = spr_dirt
	}),
}


global.BLOCK_REGISTRY.finalize()
