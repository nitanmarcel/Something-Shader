float calculateLightingFactor(vec3 worldPos, vec3 viewDir) {
    vec3 shadowLightDirection = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

    vec4 normalData = texture(normals, texcoord)*2.0-1.0;

    vec3 normalNormal = vec3(normalData.xy, sqrt(1.0 - dot(normalData.xy, normalData.xy))*2.0-1.0);

    vec3 normalWorld = TBN * normalNormal;
    
    vec4 specularData = texture(specular, texcoord);

    float perceptualSmoothness = specularData.r;

    float roughness = pow(1.0 - perceptualSmoothness, 2.0);

    float smoothness = 1-roughness;

    vec3 reflectionDir = reflect(-shadowLightDirection, normalWorld);
    
    float diffuseLight = roughness * clamp(dot(shadowLightDirection, normalWorld), 0.0,1.0);

    float shininess = (1+(smoothness) * 100);

    float specularLight = clamp(smoothness * pow(dot(reflectionDir, viewDir), shininess), 0.0, 1.0);

    float ambientLight = 0.2;

    return ambientLight + diffuseLight + specularLight;
}