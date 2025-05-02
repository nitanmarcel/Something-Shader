#version 330 compatibility

#ifdef VERTEX_SHADER

out vec2 texcoord;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
#endif // VERTEX_SHADER

#ifdef FRAGMENT_SHADER

#include "/lib/pp/blur.glsl"
#include "/lib/pp/bloom.glsl"
#include "/lib/settings.glsl"
#include "/lib/utils.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;

in vec2 texcoord;

/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 color1;

void main() {
	color = texture(colortex0, texcoord);
	color1 = GetBlurColor(colortex1, texcoord, false);

}
#endif // FRAGMENT_SHADER