#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform Uniforms {
    mat4 qt_Matrix;
    float qt_Opacity;
    float surfaceWidth;
    float surfaceHeight;
    float cornerRadius;
};
layout(binding = 1) uniform sampler2D source;
void main() {
    vec2 size = vec2(surfaceWidth, surfaceHeight);
    vec2 p = abs(qt_TexCoord0 * size - size * 0.5) - (size * 0.5 - vec2(cornerRadius));
    float distance = length(max(p, vec2(0.0))) + min(max(p.x, p.y), 0.0) - cornerRadius;
    float mask = 1.0 - smoothstep(-1.0, 0.0, distance);
    fragColor = texture(source, qt_TexCoord0) * qt_Opacity * mask;
}
