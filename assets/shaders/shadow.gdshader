shader_type canvas_item;

uniform float compress : hint_range(0.0, 1.0) = 0.5;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float shadow_alpha : hint_range(0.0, 1.0) = 1.0;
uniform vec2 offset = vec2(0.0, 0.0);
uniform bool flip_h = false;

void vertex() {
    // 沿 Y 轴压缩顶点
    VERTEX.y *= compress;

    // 如果需要水平翻转
    if (flip_h) {
        VERTEX.x = -VERTEX.x;
    }

    // 应用整体偏移
    VERTEX.xy += offset;
}

void fragment() {
    // 采样原始纹理
    vec4 tex = texture(TEXTURE, UV);

    // 输出阴影颜色，透明度 = 纹理透明度 × 阴影透明度系数
    COLOR = shadow_color;
    COLOR.a = tex.a * shadow_alpha;
}