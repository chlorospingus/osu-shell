#version 440
layout(location = 0) in vec2 coord;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    bool fadeDirection; // true: fade top, false: fade bottom
};
layout(binding = 1) uniform sampler2D src;
layout(binding = 2) uniform sampler2D mask;
void main() {
    vec4 tex = texture(src, coord);
    float a = texture(mask, coord).a * tex.a * (fadeDirection ? coord.y : 1-coord.y);
    fragColor = vec4(tex.r * a, tex.g * a, tex.b * a, a);
}
