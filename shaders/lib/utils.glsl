
vec3 screenToView(vec3 pos, mat4 projInverse) {
	vec4 ndcPos = vec4(pos, 1.0) * 2.0 - 1.0;
	vec4 tmp = projInverse * ndcPos;
	return tmp.xyz / tmp.w;
}