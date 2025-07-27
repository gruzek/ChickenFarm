shader_type spatial;
// unlit, alpha‑blend, no depth writes, double‑sided
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

// your 3D noise texture
uniform sampler3D cloud_noise;

// controls (preserved exactly as requested)
uniform float noise_scale   : hint_range(0.1, 50.0) = 0.5;
uniform float density       : hint_range(0.0, 1.0)   = 0.1;
uniform float threshold     : hint_range(0.0, 1.0)   = 0.4;
uniform float speed         : hint_range(0.0, 2.0)   = 0.01;
uniform vec4  fog_color     = vec4(1.0, 1.0, 1.0, 1.0);
uniform int   steps         : hint_range(1, 128)     = 48;

// fade begins at this normalized radius (0=center → 1=edge)
uniform float falloff_start : hint_range(0.0, 1.0)   = 0.7;

// pass local-space vertex & camera pos into fragment
varying vec3 local_pos;
varying vec3 ro_local;

void vertex() {
    local_pos = VERTEX;
    ro_local  = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
}

void fragment() {
    vec3 ro = ro_local;
    vec3 rd = normalize(local_pos - ro);

    // intersect ray vs. unit‑cube (extends –0.5 → +0.5)
    vec3 t0     = (-0.5 - ro) / rd;
    vec3 t1     = ( 0.5 - ro) / rd;
    vec3 tmin3  = min(t0, t1);
    vec3 tmax3  = max(t0, t1);
    float t_enter = max(max(tmin3.x, tmin3.y), tmin3.z);
    float t_exit  = min(min(tmax3.x, tmax3.y), tmax3.z);
    if (t_exit < max(t_enter, 0.0)) {
        discard;
    }

    // march through the volume
    float t     = max(t_enter, 0.0);
    float dt    = (t_exit - t) / float(steps);
    vec3  col   = vec3(0.0);
    float a_acc = 0.0;

    for (int i = 0; i < steps; i++) {
        float ti      = t + dt * float(i);
        vec3  p_local = ro + rd * ti;

        // sample noise in world space
        vec3 world_p = (MODEL_MATRIX * vec4(p_local, 1.0)).xyz;
        float n = texture(cloud_noise, world_p * noise_scale + vec3(TIME * speed)).r;
        float d = smoothstep(threshold, 1.0, n) * density;

        // radial falloff: 0 at center → 1 at mesh edge
        float radial = length(p_local) / 0.5;
        float rim    = smoothstep(falloff_start, 1.0, radial);
        d *= (1.0 - rim);

        // front‑to‑back compositing
        float a = d * (1.0 - a_acc);
        col   += fog_color.rgb * a;
        a_acc += a;
        if (a_acc >= 0.99) {
            break;
        }
    }

    ALBEDO = fog_color.rgb;
    ALPHA  = a_acc;
}
