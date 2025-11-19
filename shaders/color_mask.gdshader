shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform sampler2D mask_tex : source_color;
uniform vec4 primary_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform sampler2D albedo_tex : source_color;
uniform float albedo_strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec2 uv = UV;

    // Black-to-white mask texture
    float mask_val = texture(mask_tex, uv).r;

    // Blend primary -> secondary based on mask
    vec3 blended_color = mix(primary_color.rgb, secondary_color.rgb, mask_val);

    // Apply optional albedo texture on top
    vec3 albedo_tex_color = texture(albedo_tex, uv).rgb;
    blended_color = mix(blended_color, blended_color * albedo_tex_color, albedo_strength);

    ALBEDO = blended_color;
    ALPHA = 1.0;
}
