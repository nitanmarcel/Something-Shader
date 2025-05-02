#version 330 compatibility

varying mat3 TBN;
varying vec3 geoNormal;


#ifdef VERTEX_SHADER

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
in vec4 at_tangent;

uniform mat4 gbufferModelViewInverse;

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
    geoNormal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
    TBN = tbnNormalTangent(geoNormal, tagent, at_tangent.w); 
}
#endif // VERTEX_SHADER

#ifdef FRAGMENT_SHADER

#include "/lib/utils.glsl"

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;

uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform float viewWidth;
uniform float viewHeight;
uniform float sunAngle;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

uniform vec3 cameraPosition;

#include "/lib/light.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
    color = texture(gtexture, texcoord) * glcolor;
    color *= texture(lightmap, lmcoord);
    if (color.a < alphaTestRef) {
        discard;
    }

    vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0);
    vec3 viewPos = screenToView(screenPos, gbufferProjectionInverse);

    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

    vec3 worldPos = feetPlayerPos + cameraPosition;
    vec3 viewDir = normalize(cameraPosition - worldPos);

    color.rgb = pow(color.rgb, vec3(1.0 / 2.2));

    float lightBrightness = calculateLightingFactor(worldPos, viewDir, geoNormal);
    color.rgb *= lightBrightness;
}
#endif // FRAGMENT_SHADER