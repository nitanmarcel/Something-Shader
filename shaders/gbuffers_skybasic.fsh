#version 330 compatibility

#include "/lib/sky/atmosphere.glsl"
#include "/lib/sky/stars.glsl"
#include "/lib/utils.glsl"

uniform int renderStage;
uniform float viewHeight;
uniform float viewWidth;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 fogColor;
uniform vec3 sunPosition;
uniform vec3 cameraPosition;
uniform int worldTime;

in vec4 glcolor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;


void main() {

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0);
	vec3 viewPos = screenToView(screenPos, gbufferProjectionInverse);

	vec3 viewDir = normalize(viewPos);

	vec3 worldViewDir = mat3(gbufferModelViewInverse) * viewDir;
	vec3 worldSunDir = mat3(gbufferModelViewInverse) * sunPosition;

	vec3 skyColor = calculateSkyColor(worldViewDir, worldSunDir);

	vec3 stars = getStars(worldViewDir, worldTime);

    if (renderStage == MC_RENDER_STAGE_STARS) {
        skyColor = mix(skyColor, vec3(stars), 0.15);
    }

	color = vec4( mix(skyColor, fogColor, .25), 1.0 );
}
