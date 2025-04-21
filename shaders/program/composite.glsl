#version 330 compatibility

#ifdef VERTEX_SHADER

out vec2 texcoord;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
#endif // VERTEX_SHADER

#ifdef FRAGMENT_SHADER

#include "/lib/utils.glsl"
#include "/lib/uncharted.glsl"
#include "/lib/settings.glsl"

uniform sampler2D colortex0;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	color.rgb = pow(color.rgb, vec3(2.2));

	color.rgb = pow(color.rgb, vec3(1.0/GAMMA));

	vec3 hsv = rgb2hsv(color.rgb);
	hsv.y *= SATURATION;

	color.rgb = hsv2rgb(hsv);

	color.rgb = unchartedTonemapping(color.rgb * EXPOSURE);
	color.rgb = pow(color.rgb, vec3(1/2.2));

}
#endif // FRAGMENT_SHADER
