
vec4 GetBlurTexture(sampler2D screenTex, vec2 texCoord, bool horizontal) {
    const float weight[5] = float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
    
    vec2 texSize = 1.0 / textureSize(screenTex, 0).xy;
    vec3 blur = texture(screenTex, texCoord).rgb * weight[0];
    
    if (horizontal) {
        for (int i = 1; i < 5; i++) {
            blur += texture(screenTex, texCoord + vec2(texSize.x * i, 0.0)).rgb * weight[i];
            blur += texture(screenTex, texCoord - vec2(texSize.x * i, 0.0)).rgb * weight[i];
        }
    } else {
        for (int i = 1; i < 5; i++) {
            blur += texture(screenTex, texCoord + vec2(0.0, texSize.y * i)).rgb * weight[i];
            blur += texture(screenTex, texCoord - vec2(0.0, texSize.y * i)).rgb * weight[i];
        }
    }
    
    return vec4(blur, 1.0);
}
