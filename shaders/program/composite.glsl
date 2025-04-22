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
uniform sampler2D colortex1;
uniform float rainStrength;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

	color.rgb = pow(color.rgb, vec3(2.2));

	color.rgb = pow(color.rgb, vec3(1.0/GAMMA));

	vec3 hsv = rgb2hsv(color.rgb);
	hsv.y *= SATURATION;

	color.rgb = hsv2rgb(hsv);

	vec3 blur = texture2D(colortex1, texcoord / 4.0).rgb;
	blur = clamp(blur, vec3(0.0), vec3(1.0));
	blur *= blur;

	float luminance = dot(blur, vec3(0.2126, 0.7152, 0.0722));
	float threshold = 0.7;
	float softThreshold = 0.1;

	float brightness = smoothstep(threshold - softThreshold, threshold + softThreshold, luminance);
	blur *= brightness;

	float bloomStrength = BLOOM_STRENGTH * 0.08;
	color.rgb = mix(color.rgb, blur, bloomStrength);

	float blueHueIntensity = 0.01 + (rainStrength * 0.1);
	vec3 blueHueColor = vec3(0.0, 0.4, 0.8);

	color.rgb = mix(color.rgb, color.rgb * blueHueColor, blueHueIntensity);

	color.rgb = unchartedTonemapping(color.rgb * EXPOSURE);
	color.rgb = pow(color.rgb, vec3(1/2.2));

}
#endif // FRAGMENT_SHADER
