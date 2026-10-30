#version 440
layout(location = 0) in vec2 coord;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform Uniforms { mat4 qt_Matrix; float qt_Opacity; };
vec3 hsv2rgb(vec3 c) {
    vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
    return c.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), c.y);
}
void main() {
    const float PI = 3.14159265358979323846;
    float s = length(coord);
    if (s > 0.5) { fragColor = vec4(0.0); return; }
    float h = -atan(coord.y / coord.x);
    if (coord.x >= 0.0) h += PI;
    fragColor = vec4(hsv2rgb(vec3(h / (2.0 * PI), s * 2.0, 1.0)), 1.0) * qt_Opacity;
}
