#version 330 compatibility

varying vec2 lmcoord;
varying vec4 glcolor;
varying vec2 texcoord;
varying mat3 TBN;
varying vec3 normal;

#define FOG_DENSITY 0.1

const float alphaTestRef = 0.1;

#ifdef VERTEX_SHADER

uniform mat4 gbufferModelViewInverse;

in vec4 at_tangent;

mat3 tbnNormalTangent(vec3 normal, vec3 tangent, float handedness) {
    vec3 bitangent = normalize(cross(tangent,normal) * handedness);
    return mat3(tangent, bitangent, normal);
}

void main() {
	gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

    vec3 tagent = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * at_tangent.xyz));
    normal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
    TBN = tbnNormalTangent(normal, tagent, at_tangent.w); 
}

#endif // VERTEX_SHADER


#ifdef FRAGMENT_SHADER

#include "/lib/utils.glsl"
#include "/lib/sky/atmosphere.glsl"

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;

uniform float viewWidth;
uniform float viewHeight;
uniform vec3 cameraPosition;

uniform sampler2D depthtex0;
uniform int isEyeInWater;
uniform vec3 fogColor;

#include "/lib/light.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

float fogFactor(
    const float dist,
    const float density
) {
    const float LOG2 = -1.442695;
    float d = density * dist;
    return 1.0 - clamp(exp2(d * d * LOG2), 0.0, 1.0);
}


void ApplyFog() {

    if (isEyeInWater == 1) {
        float fogDistance = gl_FragCoord.z / gl_FragCoord.w;
        float fogAmount = fogFactor(fogDistance, FOG_DENSITY);
        color.rgb = mix(color.rgb, fogColor, fogAmount);
    }
}


void main() {
	color = texture(gtexture, texcoord) * glcolor;
	color *= texture(lightmap, lmcoord);
	if (color.a < alphaTestRef) {
		discard;
	}

    #ifdef DISTANT_WATER
        vec2 dhTextcoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
        float depth = texture(depthtex0, dhTextcoord).r;
        if (depth != 1.0) {
            discard;
        }
        vec3 shadowLightDirection = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
        float lightBrightness = clamp(dot(shadowLightDirection, normal), 0.2,1.0);
        color *= lightBrightness;
    #else
        vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0);
        vec3 viewPos = screenToView(screenPos, gbufferProjectionInverse);

        vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

        vec3 worldPos = feetPlayerPos + cameraPosition;
        vec3 viewDir = normalize(cameraPosition - worldPos);

        float lightBrightness = calculateLightingFactor(worldPos, viewDir);
        color.rgb *= lightBrightness;
    #endif // DISTANT_WATER
}
#endif // FRAGMENT_SHADER