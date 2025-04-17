
vec3 screenToView(vec3 pos, mat4 projInverse) {
	vec4 ndcPos = vec4(pos, 1.0) * 2.0 - 1.0;
	vec4 tmp = projInverse * ndcPos;
	return tmp.xyz / tmp.w;
}

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}