
function digest_blocks (_path)
{
	if string_ends_with(_path, ".lua")
	{
		_path = string_trim_end(_path, [".lua"])
	}
	var res = lua_call(L, "Eat", _path)

	var nametable = variable_struct_get_names(res)
	var namecount = array_length(nametable)

	var set_if_n = function (_src, _dst, _n)
	{
		var v = _src[$ _n]
		if v <> undefined
		{
			_dst[$ _n] = v
		}
	}

	for (var i = namecount; --i >= 0;)
	{
		var name = nametable[i]
		var entry = res[$ name]
	
		var ctor = variable_global_get(entry[$ "%%TYPE%%"])
		var outs = new ctor()
	
		set_if_n(entry, outs, "opaque")
		set_if_n(entry, outs, "replacable")
	
		var sn = entry[$ "sprite"] ?? ""
		var spr = asset_get_index(sn)
		if spr <> -1 and asset_get_type(sn) == asset_sprite
		{
			outs[$ "sprite"] = spr
		}
		else
		{
			outs[$ "sprite"] = spr_block_missing
		}
	
		var rs = entry[$ "render_shapes"]
		if rs <> undefined and is_array(rs)
		{
			for (var j = array_length(rs); --j>=0;)
			{
				var b = rs[j]
				rs[j] = rect_create(b[0], b[1], b[2], b[3], b[4], b[5])
			}
			outs[$ "render_shapes"] = rs
		}
	
		var cs = entry[$ "collision_shapes"]
		if cs <> undefined and is_array(cs)
		{
			for (var j = array_length(cs); --j>=0;)
			{
				var b = cs[j]
				cs[j] = rect_create(b[0], b[1], b[2], b[3], b[4], b[5])
			}
			outs[$ "collision_shapes"] = cs
		}
	
		blocks_register(name, outs)
	}
}

L = lua_state_create()

lua_add_file(L, "scripts/blocs.lua")

begin

	var bp = "blocks"
	var p = file_find_first($"{bp}/*.lua", fa_none)

	do {
		digest_blocks($"{bp}/{p}")
		p = file_find_next()
	} until p == ""
end

global.BLOCK_REGISTRY.finalize()

global.BLOCKS = {
	AIR: blocks_get_by_name("air"),
	OUT_OF_BOUNDS: blocks_get_by_name("out_of_bounds"),
	OUT_OF_BOUNDS_AIR: blocks_get_by_name("out_of_bounds_air"),
}

instance_destroy(id)
//lua_state_destroy(L)
