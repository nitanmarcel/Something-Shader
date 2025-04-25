vec3 fromLinearToSRGB(vec3 linearRGB, float gamma)
{
	bvec3 cutoff = lessThan(linearRGB, vec3(0.0031308));
	vec3 higher = vec3(1.055)*pow(linearRGB, vec3(1.0/2.2)) - vec3(0.055);
	vec3 lower = linearRGB * vec3(12.92);

	return mix(higher, lower, cutoff);
}

vec3 toLinearSRGB(vec3 sRGB, float gamma)
{
	bvec3 cutoff = lessThan(sRGB, vec3(0.04045));
	vec3 higher = pow((sRGB + vec3(0.055))/vec3(1.055), vec3(2.2));
	vec3 lower = sRGB/vec3(12.92);
	return mix(higher, lower, cutoff);
}