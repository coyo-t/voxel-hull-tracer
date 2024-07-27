//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec2 v_vCoord;
uniform vec4 uvs;
uniform float radius;

void main()
{
	//gl_FragColor = v_vColour * texture2D(gm_BaseTexture, v_vTexcoord);
	
	vec2 tc = v_vTexcoord.xy - floor(v_vTexcoord.xy);
	tc.y = 1.0 - tc.y;
	
	vec4 pix = texture2D(gm_BaseTexture, mix(uvs.xy, uvs.zw, tc));
	
	float dep = radius * 0.3;
	float start = radius-dep;
	float m = (length(v_vCoord)-start)/dep;
	gl_FragColor = mix(pix, vec4(pix.rgb, 0.0), clamp(m, 0.0, 1.0));
	//gl_FragColor = vec4(vec3(), 1.0);
}
