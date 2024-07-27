//
// Simple passthrough vertex shader
//
attribute vec3 in_Position;                  // (x,y,z)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 v_vTexcoord;
varying vec2 v_vCoord;

uniform vec3 cofs;

void main()
{
	gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position-vec3(vec2(0.0), cofs.z), 1.0);
		
	//v_vTexcoord = in_Position.xy - floor(in_Position.xy) - cofs;
	v_vTexcoord = in_Position.xy+cofs.xy;
	v_vCoord = in_Position.xy;
}
