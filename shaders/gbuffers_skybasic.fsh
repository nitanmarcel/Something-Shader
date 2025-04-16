#version 330 compatibility

#include "/lib/atmosphere.glsl"
#include "/lib/noise.glsl"

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

vec3 screenToView(vec3 screenPos) {
	vec4 ndcPos = vec4(screenPos, 1.0) * 2.0 - 1.0;
	vec4 tmp = gbufferProjectionInverse * ndcPos;
	return tmp.xyz / tmp.w;
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;


void main() {

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0);
	vec3 viewPos = screenToView(screenPos);

	vec3 viewDir = normalize(viewPos);

	vec3 worldViewDir = mat3(gbufferModelViewInverse) * viewDir;
	vec3 worldSunDir = mat3(gbufferModelViewInverse) * sunPosition;


	vec3 skyColor = atmosphere(
		normalize(worldViewDir),        // normalized ray direction
		vec3(0,6372e3,0),               // ray origin
		worldSunDir,                    // position of the sun
		22.0,                           // intensity of the sun
		6371e3,                         // radius of the planet in meters
		6471e3,                         // radius of the atmosphere in meters
		vec3(5.5e-6, 13.0e-6, 22.4e-6), // Rayleigh scattering coefficient
		21e-6,                          // Mie scattering coefficient
		8e3,                            // Rayleigh scale height
		1.2e3,                          // Mie scale height
		0.758                           // Mie preferred scattering direction
		);

  	vec3 horizonColor = vec3(1, 1, 1) * 0.8;

	vec2 uv = gl_FragCoord.xy * vec2(viewHeight, viewWidth);
	vec3 stars_direction = worldViewDir;

	float stars_threshold = 8.0f;
	float stars_exposure = 16.0f;
	float stars = pow(clamp(noise(stars_direction * 200.0f), 0.0f, 1.0f), stars_threshold) * stars_exposure;
	stars *= mix(0.4, 1.4, noise(stars_direction * 100.0f + vec3(worldTime)));

    if (renderStage == MC_RENDER_STAGE_STARS) {
        skyColor = mix(skyColor, vec3(stars), 0.15);
    }

	color = vec4( mix(skyColor, fogColor, .25), 1.0 );
}
