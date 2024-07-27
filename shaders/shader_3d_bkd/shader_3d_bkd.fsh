//
// Simple passthrough fragment shader
//
varying vec3 v_vIncoming;

void main ()
{
	//gl_FragColor = vec4(normalize(v_vIncoming), 1.0);
	float ramp = normalize(v_vIncoming).z * 0.5 + 0.5;
	gl_FragColor = vec4(texture2D(gm_BaseTexture, vec2(ramp, 0.5)).rgb, 1.0);
}
