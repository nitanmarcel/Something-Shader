#include "/lib/noise.glsl"

vec3 getStars(vec3 pos, float time) {
	vec3 stars_direction = pos;

	float stars_threshold = 8.0f;
	float stars_exposure = 16.0f;

	float stars_brightness = noise(stars_direction * 100.0 + vec3(time * 0.01));

	float stars = pow(clamp(noise(stars_direction * 200.0), 0.0f, 1.0), stars_threshold) * stars_brightness * stars_exposure;
	
    vec3 color = mix(
        vec3(0.8, 0.8, 1.0),
        vec3(1.0, 0.8, 0.6),
        noise(stars_direction * 50.0 + vec3(time * 0.02))
    );

    return vec3(stars) * color;
}