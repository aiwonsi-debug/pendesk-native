#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float smoothingAmount;
    float pixelStepX;
    float pixelStepY;
};

layout(binding = 1) uniform sampler2D source;

void main()
{
    vec2 stepSize = vec2(pixelStepX, pixelStepY);
    vec4 center = texture(source, qt_TexCoord0);
    vec4 cross = texture(source, qt_TexCoord0 + vec2(stepSize.x, 0.0))
               + texture(source, qt_TexCoord0 - vec2(stepSize.x, 0.0))
               + texture(source, qt_TexCoord0 + vec2(0.0, stepSize.y))
               + texture(source, qt_TexCoord0 - vec2(0.0, stepSize.y));

    // A constrained spatial blend softens the preview edge without temporal buffering.
    vec4 softened = center * 0.60 + cross * 0.10;
    float edgeWeight = smoothingAmount * smoothstep(0.02, 0.78, center.a);
    fragColor = mix(center, softened, edgeWeight) * qt_Opacity;
}
