
function Camera () constructor begin
	
	x = 0
	y = 0
	z = 0
	
	pitch = 0
	yaw = 0
	
	
	angle_x = 90
	angle_y = 90
	
	fit = FIT_VERTICAL
	
	forward_x = 0
	forward_y = 1
	forward_z = 0
	
	right_x = 1
	right_y = 0
	right_z = 0
	
	up_x = 0
	up_y = 0
	up_z = 1
	
	flat_forward_x = 0
	flat_forward_y = 1
	flat_forward_z = 0
	
	look_matrix = matrix_build_identity()
	
	view_matrix = matrix_build_identity()
	
	__vectors_calcd = false
	__matrix_calcd = false
	
	static rebuild_matrices = function ()
	{
		recalculate_vectors()
		
		if __matrix_calcd
		{
			return
		}
		
		// @_@ ???
		view_matrix[0]  = look_matrix[0]
		view_matrix[1]  = look_matrix[8]
		view_matrix[2]  = look_matrix[4]
		view_matrix[4]  = look_matrix[1]
		view_matrix[5]  = look_matrix[9]
		view_matrix[6]  = look_matrix[5]
		view_matrix[8]  = look_matrix[2]
		view_matrix[9]  = look_matrix[10]
		view_matrix[10] = look_matrix[6]
		
		__matrix_calcd = true
	}
	
	static turn = function (_dp, _dy)
	{
		if _dp == 0 and _dy == 0
		{
			return
		}
		
		__vectors_calcd = false
		__matrix_calcd = false
		yaw += _dy + 180
		
		
		while yaw >= 360
		{
			yaw -= 360
		}
		
		while yaw < 0
		{
			yaw += 360
		}
		
		yaw -= 180
		
		pitch = clamp(pitch + _dp, -90, +90)
		
		recalculate_vectors()
	}
	
	static recalculate_vectors = function ()
	{
		if __vectors_calcd
		{
			return
		}
		var si = dsin(yaw)
		var ci = dcos(yaw)

		var sv = dsin(pitch)
		var cv = dcos(pitch)

		flat_forward_x = si
		flat_forward_y = ci
		flat_forward_z = 0
		
		forward_x = si * cv
		forward_y = ci * cv
		forward_z = sv

		right_x = +ci
		right_y = -si
		right_z = 0

		up_x = -si * sv
		up_y = -ci * sv
		up_z = cv
		
		look_matrix[0]  = right_x
		look_matrix[1]  = right_y
		look_matrix[2]  = right_z
		look_matrix[4]  = forward_x
		look_matrix[5]  = forward_y
		look_matrix[6]  = forward_z
		look_matrix[8]  = up_x
		look_matrix[9]  = up_y
		look_matrix[10] = up_z
		
		__vectors_calcd = true
	}
	
end
