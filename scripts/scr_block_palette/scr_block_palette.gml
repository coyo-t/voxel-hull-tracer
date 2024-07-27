
function Palette () constructor begin
	
	blocks = array_create(argument_count)
	index = 0
	
	for (var i = argument_count; --i >= 0;)
	{
		blocks[i] = argument[i]
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
