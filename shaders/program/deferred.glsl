
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

float fbm(vec3 x, int octaves) {
    float v = 0.0;
    float a = 0.5;
    float frequency = 1.0;

    float warpStrength = 0.35 * (1.0 + 0.5 * sin(frameTimeCounter * 0.001));
    vec3 warpOffset = vec3(0.0);

    for (int i = 0; i < octaves; ++i) {
        vec3 warpedPos = x + warpOffset;

        if (i > 0) {
            vec3 curlVec = curlNoise(warpedPos * frequency * 0.5) * (warpStrength * 0.7);
            warpedPos += curlVec;
        }

        v += a * noise(warpedPos * frequency);

        warpOffset.x = noise(warpedPos * frequency * 0.5 + vec3(1.7, 9.2, 3.1));
        warpOffset.y = noise(warpedPos * frequency * 0.5 + vec3(8.3, 2.8, 7.1));
        warpOffset.z = noise(warpedPos * frequency * 0.5 + vec3(4.2, 5.9, 3.4));
        warpOffset *= warpStrength;
        frequency *= 2.0;
        a *= 0.5;
    }

    return v;
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

    if (rayDir.y > 0.0 && depth >= 1.0) {
        float cloudHeight = (600 - feetPlayerPos.y) / rayDir.y;
        vec3 cloudPos = feetPlayerPos + cloudHeight * rayDir;

        vec3 cloudSamplePos = vec3(cloudPos.xz * 0.01, wind);
        float cloudDensity = fbm(cloudSamplePos, 6);
        cloudDensity = mix(cloudDensity, 1.0, stormFactor * 0.7);

        float cloudCoverage = mix(0.7, 0.3, stormFactor);
        float detailNoise = fbm(cloudSamplePos * 2.0, 3) * 0.3;
        cloudDensity = smoothstep(cloudCoverage, cloudCoverage + 0.2, cloudDensity);
        cloudDensity = pow(cloudDensity, 1.5);

        float distanceFade = 1.0 - clamp(length(cloudPos) / 10000.0, 0.0, 1.0);
        cloudDensity *= distanceFade;

        vec3 worldSunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);
        float sunAngle = dot(normalize(rayDir), worldSunDir);

        float dayFactor = clamp(worldSunDir.y * 0.5 + 0.5, 0.1, 1.0);
        vec3 cloudColor = vec3(1.0, 1.0, 1.0) * dayFactor;
        cloudColor = mix(cloudColor, cloudColor * 0.4, rainStrength);

        float cloudAlpha = mix(0.5, 0.9, stormFactor);
        color.rgb = mix(color.rgb, cloudColor, cloudDensity * cloudAlpha);
    }
}

#endif // FRAGMENT_SHADER
