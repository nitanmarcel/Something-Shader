#version 330 compatibility

out vec4 glcolor;
uniform int renderStage;

void main() {
	gl_Position = ftransform();
	glcolor = gl_Color;
}
