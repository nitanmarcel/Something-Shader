
#version 330 compatibility

#include "/lib/noise.glsl"

#ifdef VERTEX_SHADER

varying vec4 pos;
varying vec3 normal;

uniform mat4 gbufferModelViewInverse;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

    pos = gl_ModelViewMatrix * gl_Vertex;

	normal = gl_NormalMatrix * gl_Normal;
	normal = mat3(gbufferModelViewInverse) * normal;	
}
#endif // VERTEX_SHADER

#ifdef FRAGMENT_SHADER

varying vec4 pos;
varying vec3 normal;

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D noisetex;
uniform mat4 gbufferModelViewInverse;
uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;

uniform float alphaTestRef = 0.1;
uniform float far;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

out vec4 color;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	color *= texture(lightmap, lmcoord);
	if (color.a < alphaTestRef) {
		discard;
	}

	float distanceFromCamera = length(pos);
	if (distanceFromCamera < far) {
		discard;
	}

	vec3 shadowLightDirection = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
	float lightBrightness = clamp(dot(shadowLightDirection, normal), 0.2,1.0);
	color *= lightBrightness;
    
	vec3 worldPos = mat3(gbufferModelViewInverse) * pos.xyz + cameraPosition;
	vec3 noisePos = vec3(noise(worldPos));
    
	vec4 albedo = color;

    albedo.rgb *= mix(0.95, 1.05, texelFetch(noisetex, ivec2(noisePos.xy), 0).r);

    gl_FragData[0] = albedo;    
}
#endif // FRAGMENT_SHADER
