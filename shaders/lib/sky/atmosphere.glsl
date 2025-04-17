// https://github.com/wwwtyro/glsl-atmosphere/blob/master/index.glsl

#define PI 3.141592

#include "/lib/settings.glsl"
#include "/lib/noise.glsl"

uniform int renderStage;
uniform int worldTime;

#if SKY_QUALITY == SKY_QUALITY_LOW
    #define iSteps 6
    #define jSteps 3
#elif SKY_QUALITY == SKY_QUALITY_MEDIUM
    #define iSteps 10
    #define jSteps 5
#else
    #define iSteps 16
    #define jSteps 8
#endif

vec2 rsi(vec3 r0, vec3 rd, float sr) {
    // ray-sphere intersection that assumes
    // the sphere is centered at the origin.
    // No intersection when result.x > result.y
    float a = dot(rd, rd);
    float b = 2.0 * dot(rd, r0);
    float c = dot(r0, r0) - (sr * sr);
    float d = (b*b) - 4.0*a*c;
    if (d < 0.0) return vec2(1e5,-1e5);
    return vec2(
        (-b - sqrt(d))/(2.0*a),
        (-b + sqrt(d))/(2.0*a)
    );
}

vec3 atmosphere(vec3 r, vec3 r0, vec3 pSun, float iSun, float rPlanet, float rAtmos, vec3 kRlh, float kMie, float shRlh, float shMie, float g) {
    
    float moonRadius = 100.0;
    // Normalize the sun and view directions.
    pSun = normalize(pSun);
    r = normalize(r);

    // Calculate the step size of the primary ray.
    vec2 p = rsi(r0, r, rAtmos);
    if (p.x > p.y) return vec3(0,0,0);
    p.y = min(p.y, rsi(r0, r, rPlanet).x);
    float iStepSize = (p.y - p.x) / float(iSteps);

    // Initialize the primary ray time.
    float iTime = 0.0;

    // Initialize accumulators for Rayleigh and Mie scattering.
    vec3 totalRlh = vec3(0,0,0);
    vec3 totalMie = vec3(0,0,0);

    // Initialize optical depth accumulators for the primary ray.
    float iOdRlh = 0.0;
    float iOdMie = 0.0;

    // Calculate the Rayleigh and Mie phases.
    float mu = dot(r, pSun);
    float mumu = mu * mu;
    float gg = g * g;
    float pRlh = 3.0 / (16.0 * PI) * (1.0 + mumu);
    float pMie = 3.0 / (8.0 * PI) * ((1.0 - gg) * (mumu + 1.0)) / (pow(1.0 + gg - 2.0 * mu * g, 1.5) * (2.0 + gg));

    // Sample the primary ray.
    for (int i = 0; i < iSteps; i++) {

        // Calculate the primary ray sample position.
        vec3 iPos = r0 + r * (iTime + iStepSize * 0.5);

        // Calculate the height of the sample.
        float iHeight = length(iPos) - rPlanet;

        // Calculate the optical depth of the Rayleigh and Mie scattering for this step.
        float odStepRlh = exp(-iHeight / shRlh) * iStepSize;
        float odStepMie = exp(-iHeight / shMie) * iStepSize;

        // Accumulate optical depth.
        iOdRlh += odStepRlh;
        iOdMie += odStepMie;

        // Calculate the step size of the secondary ray.
        float jStepSize = rsi(iPos, pSun, rAtmos).y / float(jSteps);

        // Initialize the secondary ray time.
        float jTime = 0.0;

        // Initialize optical depth accumulators for the secondary ray.
        float jOdRlh = 0.0;
        float jOdMie = 0.0;

        // Sample the secondary ray.
        for (int j = 0; j < jSteps; j++) {

            // Calculate the secondary ray sample position.
            vec3 jPos = iPos + pSun * (jTime + jStepSize * 0.5);

            // Calculate the height of the sample.
            float jHeight = length(jPos) - rPlanet;

            // Accumulate the optical depth.
            jOdRlh += exp(-jHeight / shRlh) * jStepSize;
            jOdMie += exp(-jHeight / shMie) * jStepSize;

            // Increment the secondary ray time.
            jTime += jStepSize;
        }

        // Calculate attenuation.
        vec3 attn = exp(-(kMie * (iOdMie + jOdMie) + kRlh * (iOdRlh + jOdRlh)));

        // Accumulate scattering.
        totalRlh += odStepRlh * attn;
        totalMie += odStepMie * attn;

        // Increment the primary ray time.
        iTime += iStepSize;

    }

    // Add custom sun.

    float spot = smoothstep(0.0, 1000.0, pMie)*10.0;
 
    // Calculate and return the final color.
    
    vec3 scatteredLight = iSun * (spot*totalMie+pRlh * kRlh * totalRlh + pMie * kMie * totalMie);
    
    vec3 nightSkyColor = vec3(0.05, 0.1, 0.2) * 0.2;
    float dayNightFactor = max(0.0, pSun.y);
    dayNightFactor = smoothstep(-0.1, 0.1, dayNightFactor);

    return mix(nightSkyColor, scatteredLight, dayNightFactor);
}

vec3 getStars(vec3 pos) {
	vec3 stars_direction = pos;

	float stars_threshold = 8.0f;
	float stars_exposure = 16.0f;

	float stars_brightness = noise(stars_direction * 100.0 + vec3(worldTime * 0.01));

	float stars = pow(clamp(noise(stars_direction * 200.0), 0.0f, 1.0), stars_threshold) * stars_brightness * stars_exposure;
	
    vec3 color = mix(
        vec3(0.8, 0.8, 1.0),
        vec3(1.0, 0.8, 0.6),
        noise(stars_direction * 50.0 + vec3(worldTime * 0.02))
    );

    return vec3(stars) * color;
}

vec3 calculateSkyColor(vec3 pos, vec3 sun) {
	vec3 skyColor = atmosphere(
		pos,        // normalized ray direction
		vec3(0,6372e3,0),               // ray origin
		sun,                            // position of the sun
		22.0,                           // intensity of the sun
		6371e3,                         // radius of the planet in meters
		6471e3,                         // radius of the atmosphere in meters
		vec3(5.5e-6, 13.0e-6, 22.4e-6), // Rayleigh scattering coefficient
		21e-6,                          // Mie scattering coefficient
		8e3,                            // Rayleigh scale height
		1.2e3,                          // Mie scale height
		0.758                           // Mie preferred scattering direction
		);

    if (renderStage == MC_RENDER_STAGE_STARS) {
        vec3 stars = getStars(pos);
        skyColor = mix(skyColor, stars, 0.15);
    }


    return skyColor;
}