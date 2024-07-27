local sh_full_bloc = { 0,0,0, 1,1,1 }
local texel = 1.0/16.0

air = Block {
	render_shapes = nil,
	collision_shapes = nil,
	replacable = true,
	opaque = false,
}

out_of_bounds = Block {
	collision_shapes = {sh_full_bloc},
	render_shapes = {sh_full_bloc},
	sprite = 'spr_dark_hull',
}

out_of_bounds_air = Block {
	render_shapes = nil,
	collision_shapes = nil,
	replacable = true,
	opaque = false,
}

solid = Block {
	render_shapes = {sh_full_bloc},
	collision_shapes = {sh_full_bloc},
	sprite = 'spr_stone',
}

dirt = Block {
	render_shapes = {sh_full_bloc},
	collision_shapes = {sh_full_bloc},
	sprite = 'spr_dirt',
}

do
	local pr = texel*2
	local h0 = 0.5-pr
	local h1 = 0.5+pr
	local rsh = { h0, h0, 0, h1, h1, 1 }
	local csh = { h0, h0, 0, h1, h1, 1.5 }
	precarious = Block {
		render_shapes = {rsh},
		collision_shapes = {csh},
		sprite = 'spr_oak_planks',
		opaque = false,
	}
end

do
	local h0 = texel * 5
	local h1 = texel * 11

	local cs = { h0, h0, 0, h1, h1, texel * 10 }
	rose = Block {
		collision_shapes = {cs},
		render_shapes = {
			{0, 0.5, 0, 1, 0.5, 1},
			{0.5, 0, 0, 0.5, 1, 1},
		},
		sprite = 'spr_rose',
		opaque = false,
	}
end

do
	local sh = {
		{0,0,0, 1,1,0.5},
		{0,0,0.5, 1,0.5,1},
	}
	cobblestone_stairs = Block {
		render_shapes = sh,
		collision_shapes = sh,
		sprite = 'spr_cobblestone',
		opaque = false,
	}
end

glass = GlassBlock {
	render_shapes = {sh_full_bloc},
	collision_shapes = {sh_full_bloc},
	sprite = 'spr_glass',
}

do
	local sh = { 0.25, 0.25, 0.25, 0.75, 0.75, 0.75 }
	core = Block {
		render_shapes = {sh},
		collision_shapes = {sh},
		sprite = 'spr_dirt_2',
		opaque = false,
	}
end

do
	local sh = { 0, 0, 0.5, 1, 1, 1 }
	upper_slab = Block {
		render_shapes = {sh},
		collision_shapes ={sh},
		sprite = 'spr_grey_hull',
		opaque = false,
	}
end

do
	local sh = {0,0,0,1,1,texel}
	carpet = Block {
		render_shapes = {sh},
		collision_shapes = {sh},
		sprite = 'spr_carpet',
		opaque = false,
	}
end

do
	local outs = {}
	for i = 1, 16 do
		local j = i - 1
		local i0 = j*texel
		local i1 = i*texel
		outs[i] = {0, i0, i0, 1, 1, i1}
	end

	super_ramp = Block {
		render_shapes = outs,
		collision_shapes = outs,
		sprite = 'spr_direction_debug',
		opaque = false,
	}
end

