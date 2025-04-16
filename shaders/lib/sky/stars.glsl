#include "/lib/noise.glsl"

vec3 getStars(vec3 pos, float time) {
	vec3 stars_direction = pos;

	float stars_threshold = 8.0f;
	float stars_exposure = 16.0f;

	float stars_brightness = noise(stars_direction * 100.0f + vec3(time));

	float stars = pow(clamp(noise(stars_direction * 200.0f), 0.0f, 1.0f), stars_threshold) * stars_brightness * stars_exposure;
	stars *= mix(0.4, 1.4, noise(stars_direction * 100.0f + vec3(time)));
    return vec3(stars);
}