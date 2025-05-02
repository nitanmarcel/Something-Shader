#version 330 compatibility

#ifdef VERTEX_SHADER

out vec2 texcoord;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
#endif // VERTEX_SHADER

#ifdef FRAGMENT_SHADER

#include "/lib/pp/bloom.glsl"
#include "/lib/uncharted.glsl"
#include "/lib/settings.glsl"
#include "/lib/utils.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;

in vec2 texcoord;

/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 color;

void main() {
	vec4 sceneColor = texture2D(colortex0, texcoord);
	vec4 bloomColor = texture2D(colortex1, texcoord);
	color = sceneColor + bloomColor;

	color.rgb = unchartedTonemapping(color.rgb * EXPOSURE);

	color.rgb = pow(color.rgb, vec3(2.2));

	vec3 hsv = rgb2hsv(color.rgb);
	hsv.y *= SATURATION;
	color.rgb = hsv2rgb(hsv);
}
#endif // FRAGMENT_SHADER