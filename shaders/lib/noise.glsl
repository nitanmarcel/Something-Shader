float random(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 78.233, 151.7182))) * 43758.5453);
}

float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);

    // Hash coordinates
    float a = random(i);
    float b = random(i + vec3(1.0, 0.0, 0.0));
    float c = random(i + vec3(0.0, 1.0, 0.0));
    float d = random(i + vec3(1.0, 1.0, 0.0));
    float e = random(i + vec3(0.0, 0.0, 1.0));
    float f1 = random(i + vec3(1.0, 0.0, 1.0));
    float g = random(i + vec3(0.0, 1.0, 1.0));
    float h = random(i + vec3(1.0, 1.0, 1.0));

    // Interpolate between the values
    vec3 u = smoothstep(0.0, 1.0, f);
    float x0 = mix(a, b, u.x);
    float x1 = mix(c, d, u.x);
    float y0 = mix(x0, x1, u.y);
    
    x0 = mix(e, f1, u.x);
    x1 = mix(g, h, u.x);
    float y1 = mix(x0, x1, u.y);
    
    return mix(y0, y1, u.z);
}

vec3 curlNoise(vec3 p) {
    const float epsilon = 0.0001;
    vec3 dx = vec3(epsilon, 0.0, 0.0);
    vec3 dy = vec3(0.0, epsilon, 0.0);
    vec3 dz = vec3(0.0, 0.0, epsilon);
    
    float x1 = noise(p + dx) - noise(p - dx);
    float y1 = noise(p + dy) - noise(p - dy);
    float z1 = noise(p + dz) - noise(p - dz);
    
    float x2 = noise(p + dx) - noise(p - dx);
    float y2 = noise(p + dy) - noise(p - dy);
    float z2 = noise(p + dz) - noise(p - dz);
    
    return normalize(vec3(y2 - z1, z2 - x1, x2 - y1));
}