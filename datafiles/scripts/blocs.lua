
local pev_meta = getmetatable(_G)
local stomached_blocks = {}
local block_eater = {
	__newindex = function (_table, _key, _value)
		if rawget(stomached_blocks, _key) ~= nil then
			error('A block with the name "'.._key..'" already exists!')
		end
		rawset(stomached_blocks, _key, _value)
	end,
}

function Block (_args)
	_args['%%TYPE%%'] = 'Block'
	return _args
end

function GlassBlock (_args)
	_args['%%TYPE%%'] = 'GlassBlock'
	return _args
end

function Eat (_path)
	setmetatable(_G, block_eater)
	-- require'scripts/b'
	require(_path)
	setmetatable(_G, pev_meta)

	return stomached_blocks
end



function GetTheStuff ()
	return stomached_blocks
end

