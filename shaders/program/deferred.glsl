
#version 330 compatibility

#ifdef VERTEX_SHADER

out vec2 texcoord;

uniform mat4 gbufferModelView;

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
#endif // VERTEX_SHADER

#ifdef FRAGMENT_SHADER

#include "/lib/utils.glsl"
#include "/lib/noise.glsl"

uniform sampler2D colortex0;

uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
#ifdef IS_IRIS
uniform float thunderStrength;
#endif
uniform float frameTimeCounter;
uniform vec3 sunPosition;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

float fbm(vec3 p)
{
    mat3 m = mat3(0.0, 1.60,  1.20, -1.6, 0.72, -0.96, -1.2, -0.96, 1.28);
    float f = 0.0;
    f += noise(p) / 2; p = m * p * 1.1;
    f += noise(p) / 4; p = m * p * 1.2;
    f += noise(p) / 6; p = m * p * 1.3;
    f += noise(p) / 12; p = m * p * 1.4;
    f += noise(p) / 24;
    return f;
}

void main() {
    color = texture(colortex0, texcoord);

    vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0);
    vec3 ndcPos = screenPos * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);

    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    vec3 feetPlayerPos = eyePlayerPos + gbufferModelViewInverse[3].xyz;

    vec3 rayDir = normalize(mat3(gbufferModelViewInverse) * viewPos);

    float depth = texture(depthtex0, texcoord).r;

    float wind = 0.0006 * frameTimeCounter * 10;
    
    float stormFactor = rainStrength;
    #ifdef IS_IRIS
        stormFactor += thunderStrength;
    #endif

    float cirrus = 0.25 + stormFactor * 0.3;
    float cumulus = 0.45 + stormFactor * 0.6;

    if (rayDir.y > 0.0 && depth >= 1.0) {
        float cloudHeight = (1024 - feetPlayerPos.y) / rayDir.y;
        vec3 cloudPos = feetPlayerPos + cloudHeight * rayDir;


        vec3 worldSunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);
        float sunAngle = dot(normalize(rayDir), worldSunDir);

        float dayFactor = clamp(worldSunDir.y * 0.5 + 0.5, 0.1, 1.0);
        vec3 cloudColor = vec3(1.0, 1.0, 1.0) * dayFactor;
        cloudColor = mix(cloudColor, cloudColor * 0.4, rainStrength);

        float density = smoothstep(1.0 - cirrus, 1.0, fbm(cloudPos.xyz / cloudPos.y * 2.0 + wind * 0.05)) * 0.3;

        float distanceFade = 1.0 - clamp(length(cloudPos) / 10000.0, 0.0, 1.0);
        density *= distanceFade;

        color.rgb = mix(color.rgb, cloudColor, density);

        for (int i = 0; i < 12; i++) {
            float density = smoothstep(1.0 - cumulus, 1.0, fbm((0.7 + float(i) * 0.01) * cloudPos.xyz / cloudPos.y + wind * 0.3));
            float distanceFade = 1.0 - clamp(length(cloudPos) / 10000.0, 0.0, 1.0);
            density *= distanceFade;
            color.rgb = mix(color.rgb, cloudColor, density);        
        }

    }
}

#endif // FRAGMENT_SHADER
