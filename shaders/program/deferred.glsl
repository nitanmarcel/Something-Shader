#version 330 compatibility

#define CLOUD_SCALE 0.004
#define FOG_DENSITY 0.5

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
#include "/lib/sky/atmosphere.glsl"

uniform sampler2D colortex0;

uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform vec3 sunPosition;
uniform int isEyeInWater;
uniform vec3 fogColor;

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex0;
#endif

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

float fbm(vec3 p) {
    float total = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float lacunarity = 2.0;
    float persistence = 0.5;
    
    for (int i = 0; i < 6; i++) {
        float n = noise(p * frequency);
        total += n * amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
        
        p += vec3(n * 0.2);
    }
    
    return total;
}

vec3 CloudIntersection(vec3 rayOrigin, vec3 rayDir) {
    float cloudAltitude = 100.0;
    
    float planeRayDist = 100000000.0;
    vec3 intersectionPos = rayDir * planeRayDist;
    
    float rayPlaneAngle = rayDir.y;
    
    if (rayPlaneAngle > 0.0001) {
        planeRayDist = (cloudAltitude - rayOrigin.y) / rayPlaneAngle;
        
        intersectionPos = rayOrigin + rayDir * planeRayDist;
    }
    
    return intersectionPos;
}

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
    color = texture(colortex0, texcoord);

    vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0);
    vec3 ndcPos = screenPos * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);

    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    vec3 feetPlayerPos = eyePlayerPos + gbufferModelViewInverse[3].xyz;

    vec3 rayDir = normalize(mat3(gbufferModelViewInverse) * viewPos);

    float depth = texture(depthtex0, texcoord).r;
    
    #ifdef DISTANT_HORIZONS
        float dhDepth = texture(dhDepthTex0, texcoord).r;
        depth = min(dhDepth, depth);
    #endif

    float wind = 0.005 * frameTimeCounter;
    vec2 windDirection = vec2(0.8, 0.2);

    float cirrus = 0.25 + rainStrength * 0.3;
    float cumulus = 0.45 + rainStrength * 0.6;
    if (rayDir.y > 0.0 && depth >= 1.0) {
        float rayPlaneAngle = rayDir.y;
        if (rayPlaneAngle > 0.0001) {
            vec3 worldSunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);
            float sunAngle = dot(normalize(rayDir), worldSunDir);

            vec3 extinction = calculateExtinction(rayDir, worldSunDir);
            float dayFactor = clamp(worldSunDir.y * 0.5 + 0.5, 0.1, 1.0);
            
            vec3 cloudColor = vec3(1.0, 1.0, 1.0) * dayFactor;

            cloudColor *= extinction * 1.5;

            cloudColor = mix(cloudColor, cloudColor * 0.4, rainStrength);

            vec3 cirrusPos = CloudIntersection(feetPlayerPos, rayDir);
            cirrusPos.xz += windDirection * wind * 2.0;

            float cirrusShape = mix(fbm(cirrusPos * CLOUD_SCALE * 1.5), worleyNoise(cirrusPos * CLOUD_SCALE * 0.5), 0.3);
             cirrusShape *= smoothstep(0.4, 0.6, noise(cirrusPos * CLOUD_SCALE * 0.2 + vec3(0, 0, wind * 0.5)));
             float cirrusDensity = smoothstep(1.0 - cirrus, 1.0, cirrusShape) * 0.3;

            vec3 cumulusPos = CloudIntersection(feetPlayerPos, rayDir);
            cumulusPos.xz += windDirection * wind;

            float cloudShape = mix(fbm(cumulusPos * CLOUD_SCALE), worleyNoise(cumulusPos * CLOUD_SCALE * 0.5), 0.5);

            float cloudDetail = fbm(cumulusPos * CLOUD_SCALE * 3.0) * 0.2;

            cloudShape += cloudDetail;

            float cumulusDensity = smoothstep(1.0 - cumulus, 1.0 - cumulus + 0.1, cloudShape);

            float shadow = smoothstep(0.3, 0.7, cloudShape);
            vec3 shadowedColor = mix(cloudColor * 0.7, cloudColor, shadow);

            color.rgb = mix(color.rgb, cloudColor, cirrusDensity);
            color.rgb = mix(color.rgb, shadowedColor, cumulusDensity);
        }
    }

    ApplyFog();
}
#endif // FRAGMENT_SHADER