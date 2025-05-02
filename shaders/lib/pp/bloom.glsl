vec4 GetBloomColor(sampler2D screenTex, vec2 texCoord, float bloomStrength) {
    vec4 highlightColor = texture(screenTex, texCoord);
    float brightness = dot(highlightColor.rgb, vec3(0.2126, 0.7152, 0.0722));

    vec4 bloomColor = vec4(0.0, 0.0, 0.0, 1.0);
    if (brightness > 0.15) {
        bloomColor = vec4(highlightColor.rgb * bloomStrength, 1.0);
    }

    return bloomColor;
}