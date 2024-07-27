
function Palette () constructor begin
	
	blocks = array_create(argument_count)
	index = 0
	
	for (var i = argument_count; --i >= 0;)
	{
		var a = argument[i]
		if is_string(a)
		{
			blocks[i] = blocks_get_by_name(a)
		}
		else
		{
			blocks[i] = argument[i]
		}
	}
	
	static offset_index = function (_delta)
	{
		index += _delta
		
		var c = array_length(blocks)
		
		while index >= c { index -= c }
		while index < 0  { index += c }
	}
	
	static get_current = function ()
	{
		return blocks[index]
	}
end
