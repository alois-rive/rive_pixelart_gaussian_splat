// Pixel-art gaussian splats: the G-buffer pass and the shadow pass.
//
// Every splat is a flat gaussian disc lying in its surface (sigma across the
// surface, sigma * flatness through it). The vertex stage projects that 3D
// covariance to the screen (EWA: Sigma' = J W Sigma W^T J^T, plus a 0.3 px^2
// low-pass) and spans a quad over it. The fragment stage keeps a pixel only
// where the gaussian is above `splat.y` (alpha TEST, not blend: no sorting, a
// depth buffer does the visibility), so each splat is a crisp-edged blob.
//
// Colour is never a colour here: the pass writes palette indices. The sun moves
// each splat up or down its material's ramp (pixel-art shading), with a 4x4
// Bayer dither on the ART pixel grid across the band edges, so the G-buffer
// holds only palette colours. resolve.wgsl turns it into the final picture.
//
// Target: rgba8unorm, 2x the art grid (resolve votes 2x2 into one art pixel).
//   r = palette index / 255, g = ramp / 255, b = step / 255, a = flags / 255

struct Frame {
    view: mat4x4f,          // world -> view
    proj: mat4x4f,          // view -> clip
    lightViewProj: mat4x4f, // world -> shadow clip
    sun: vec4f,             // xyz: direction TO the sun (world, unit), w: key light: the direct light (0..1) that shows a material's base step
    grid: vec4f,            // xy: target size in px, z: px per world unit (ortho) or focal length in px, w: 1 ortho, 0 perspective
    splat: vec4f,           // x: sigma scale, y: alpha threshold 0..1, z: flatness, w: tone jitter (ramp steps, 0 = none)
    shade: vec4f,           // x: steps down in full shade, y: steps up in full sun, z: band dither width 0..1, w: time in s
    shadow: vec4f,          // x: shadow map size (0 = off), y: depth bias, z: normal offset (world), w: dither: 0 Bayer on the art grid, 1 per splat
    wind: vec4f,            // xyz: sway direction * amplitude (world), w: frequency (rad/s)
    tone: vec4f,            // x: highlight: the direct light where steps UP begin (between key and it, the painted step holds)
    fx: vec4f,              // the FX cycle: x time in the cycle (s), y 1 = on, z first of six prism ramps (-1 none), w accent ramp (-1 none)
    fxBox: vec4f,           // the FX splats' bounds: x min x, y max x, z min y, w max y (world, at rest)
    ramps: array<vec4u, 64>,  // ramp r, step s -> palette index: ramps[r * 2 + s / 4][s % 4]
    rampLen: array<vec4u, 8>, // steps of ramp r: rampLen[r / 4][r % 4]
    qmin: vec4f,              // dequantization of the 16-byte splats: box min xyz, sigma min
    qstep: vec4f,             // box step xyz, sigma step
}

@group(0) @binding(0) var<uniform> F: Frame;

// Bone matrices, 3 rows of vec4 each (a 3x4 matrix, row-major), 64 bones. Bone 0 is the
// static world (identity); the script copies each animation track's current frame in.
struct Bones {
    m: array<vec4f, 192>,
}
@group(0) @binding(1) var<uniform> B: Bones;
@group(1) @binding(0) var shadowMap: texture_depth_2d;

const FLAG_UNLIT: u32 = 1u;
const FLAG_DOUBLE: u32 = 2u;
const FLAG_SWAY: u32 = 4u;
const FLAG_NOCAST: u32 = 8u;
const FLAG_FX: u32 = 16u;

// A splat as stored (blob v3, 16 bytes): splat_bake.py upgrade_blob
// (read as four uint8x4: 16-bit vertex formats are not dependable across backends; the u16 fields
// are little endian, rebuilt here)
struct VRaw {
    @builtin(vertex_index) vi: u32,
    @location(0) xy: vec4u,  // x u16, y u16 quantized over the box
    @location(1) zs: vec4u,  // z u16, sigma u8, ramp u8
    @location(2) n: vec4u,   // octahedral normal, u16 x2
    @location(3) b: vec4u,   // step | flags << 3, joint 0, joint 1, weight 0
}

fn u16at(lo: u32, hi: u32) -> f32 {
    return f32(lo | (hi << 8u));
}

// A splat decoded
struct VIn {
    vi: u32,
    pos: vec3f,
    nrm: vec4f,
    info: vec4u,     // ramp, step, flags, 0
    sigma: f32,
    joints: vec4u,   // up to 2 bones
    weights: vec4f,  // their weights, summing to 1
}

fn decodeSplat(r: VRaw) -> VIn {
    var v: VIn;
    v.vi = r.vi;
    let q = vec3f(u16at(r.xy.x, r.xy.y), u16at(r.xy.z, r.xy.w), u16at(r.zs.x, r.zs.y));
    v.pos = F.qmin.xyz + q * F.qstep.xyz;
    v.sigma = F.qmin.w + f32(r.zs.z) * F.qstep.w;
    let e = vec2f(u16at(r.n.x, r.n.y), u16at(r.n.z, r.n.w)) / 65535.0 * 2.0 - 1.0;
    var n = vec3f(e.x, e.y, 1.0 - abs(e.x) - abs(e.y));
    let t = clamp(-n.z, 0.0, 1.0);
    n.x += select(t, -t, n.x >= 0.0);
    n.y += select(t, -t, n.y >= 0.0);
    v.nrm = vec4f(normalize(n), 0.0);
    v.info = vec4u(r.zs.w, r.b.x & 7u, r.b.x >> 3u, 0u);
    v.joints = vec4u(r.b.y, r.b.z, 0u, 0u);
    let w0 = f32(r.b.w) / 255.0;
    v.weights = vec4f(w0, 1.0 - w0, 0.0, 0.0);
    return v;
}

struct VOut {
    @builtin(position) clip: vec4f,
    @location(0) d: vec2f,      // offset from the splat centre in target px, y up
    @location(1) conic: vec3f,  // inverse 2D covariance (a, b, c)
    @location(2) look: vec4f,   // ramp, base step, flags, direct light 0..1 after shadow (constant over the splat)
    @location(3) noise: vec2f,  // two per-splat random numbers 0..1, fixed to the splat (world-stable)
}

fn corner(vi: u32) -> vec2f {
    var c = array<vec2f, 6>(vec2f(-1.0, -1.0), vec2f(1.0, -1.0), vec2f(1.0, 1.0),
                            vec2f(-1.0, -1.0), vec2f(1.0, 1.0), vec2f(-1.0, 1.0));
    return c[vi % 6u];
}

fn culled() -> VOut {
    var o: VOut;
    o.clip = vec4f(-4.0, -4.0, 2.0, 1.0); // a zero-area triangle outside the clip volume
    o.d = vec2f(0.0);
    o.conic = vec3f(0.0);
    o.look = vec4f(0.0);
    o.noise = vec2f(0.0);
    return o;
}

fn hash2(p: vec3f) -> vec2f {
    var q = fract(p * vec3f(0.1031, 0.1030, 0.0973) * 97.0);
    q += dot(q, q.yzx + 33.33);
    return fract((q.xx + q.yz) * q.zy);
}

fn boneApply(b: u32, p: vec4f) -> vec3f {
    return vec3f(dot(B.m[b * 3u], p), dot(B.m[b * 3u + 1u], p), dot(B.m[b * 3u + 2u], p));
}

// linear blend skinning; a rigid part is one bone at weight 1, the static world bone 0
fn skinPoint(v: VIn) -> vec3f {
    var o = vec3f(0.0);
    for (var k = 0u; k < 4u; k++) {
        let w = v.weights[k];
        if (w > 0.0) {
            o += w * boneApply(v.joints[k], vec4f(v.pos, 1.0));
        }
    }
    return o;
}

fn skinNormal(v: VIn) -> vec3f {
    var o = vec3f(0.0);
    for (var k = 0u; k < 4u; k++) {
        let w = v.weights[k];
        if (w > 0.0) {
            o += w * boneApply(v.joints[k], vec4f(v.nrm.xyz, 0.0));
        }
    }
    return normalize(o);
}

// ---- THIS SCENE'S FX (the template's fxApply is an empty hook): the Rive brand cycle on the wordmark.
// Stepped at 12 fps, in the brand's motion vocabulary (rive-branding references/motion.md): a cascade in with a flicker, a prism sweep, a glitch, a scan, a dissolve.
// Colours stay palette indices (a ramp and a step), so the pixel resolve applies on top.
struct Fx {
    p: vec3f,
    visible: bool,
    ramp: f32,
    step: f32,
    glow: bool,
}

fn fxHash(a: f32, b: f32) -> f32 {
    return fract(sin(a * 127.1 + b * 311.7) * 43758.5453);
}

fn fxApply(p0: vec3f, h: vec2f, ramp0: f32, step0: f32) -> Fx {
    var r: Fx;
    r.p = p0;
    r.visible = true;
    r.ramp = ramp0;
    r.step = step0;
    r.glow = false;
    let t = floor(F.fx.x * 12.0) / 12.0;
    let u = clamp((p0.x - F.fxBox.x) / max(F.fxBox.y - F.fxBox.x, 1e-3), 0.0, 1.0); // 0 left .. 1 right
    let v = clamp((p0.y - F.fxBox.z) / max(F.fxBox.w - F.fxBox.z, 1e-3), 0.0, 1.0); // 0 bottom .. 1 top
    let prism = F.fx.z;   // fxRampA: the first of the six Portal Prism ramps
    let accent = F.fx.w;  // fxRampB: Rive Amber
    if (t < 1.6) {
        // cascade: left to right, each part flickering in (0.2, 1, 0.5, 1) as it slides home
        let local = t - (0.1 + u * 0.9);
        if (local < 0.0) {
            r.visible = false;
            return r;
        }
        let k = floor(local * 12.0);
        var level = 1.0;
        if (k < 1.0) {
            level = 0.2;
        } else if (k > 1.5 && k < 2.5) {
            level = 0.5;
        }
        r.visible = h.x <= level;
        r.p.x -= max(0.0, 0.25 - local) * 1.6;
    } else if (t < 5.0) {
        // prism sweep: a band of the six prism colours, in order, crosses left to right and pushes forward
        let b = (t - 1.6) / 3.4 * 1.6 - 0.3;
        let d = u - b;
        if (abs(d) < 0.2) {
            r.p.z += 0.15 * cos(d / 0.2 * 1.5708);
            if (prism >= 0.0) {
                r.ramp = prism + floor((d + 0.2) / 0.4 * 5.999);
                r.step = 0.0;
                r.glow = true;
            }
        }
    } else if (t < 7.0) {
        // glitch: horizontal slices jump sideways in steps, a few flash the accent, the whole flickers
        let slice = floor(v * 9.0);
        let g = floor(t * 15.0);
        let q = fxHash(slice, g);
        if (q > 0.62) {
            r.p.x += (fxHash(slice + 17.0, g) - 0.5) * 0.6;
        }
        if (q > 0.88 && accent >= 0.0) {
            r.ramp = accent;
            r.step = 0.0;
            r.glow = true;
        }
        let f = u32(floor(t * 15.0)) % 4u;
        var level = 1.0;
        if (f == 1u) {
            level = 0.55;
        } else if (f == 3u) {
            level = 0.85;
        }
        r.visible = h.x <= level;
    } else if (t < 10.0) {
        // scan: an accent line descends while the surface ripples
        let line = 1.0 - (t - 7.0) / 3.0;
        r.p.z += 0.06 * sin(u * 14.0 - t * 5.0);
        if (abs(v - line) < 0.07 && accent >= 0.0) {
            r.ramp = accent;
            r.step = 0.0;
            r.glow = true;
        }
    } else {
        // dissolve: the parts drift up and blink out, right to left, before the next cascade
        let k = clamp((t - 10.0 - (1.0 - u) * 0.6) / 0.9, 0.0, 1.0);
        r.p.y += k * k * 1.2 * (0.4 + h.y);
        r.p.x += (h.x - 0.5) * k * 0.8;
        r.visible = h.y >= k;
    }
    return r;
}

fn swayed(p: vec3f, flags: u32) -> vec3f {
    if ((flags & FLAG_SWAY) == 0u) {
        return p;
    }
    let phase = dot(p, vec3f(2.1, 0.7, 1.7));
    return p + F.wind.xyz * sin(F.shade.w * F.wind.w + phase);
}

// The quad of one splat around its projected centre. Returns false when culled.
fn project(v: VIn, p: vec3f, nWorld: vec3f, o: ptr<function, VOut>) -> bool {
    let pv = (F.view * vec4f(p, 1.0)).xyz;
    let nv = normalize((F.view * vec4f(nWorld, 0.0)).xyz);
    let ortho = F.grid.w > 0.5;
    if (!ortho && pv.z > -0.05) {
        return false;
    }
    // 3D covariance of a disc in view space: st^2 I + (sn^2 - st^2) n n^T
    let st = v.sigma * F.splat.x;
    let sn = st * F.splat.z;
    let k = sn * sn - st * st;
    let S = mat3x3f(vec3f(st * st, 0.0, 0.0), vec3f(0.0, st * st, 0.0), vec3f(0.0, 0.0, st * st))
          + mat3x3f(nv * (k * nv.x), nv * (k * nv.y), nv * (k * nv.z));
    // Jacobian of view -> target px (rows j0, j1)
    var j0 = vec3f(F.grid.z, 0.0, 0.0);
    var j1 = vec3f(0.0, F.grid.z, 0.0);
    if (!ortho) {
        let z = -pv.z;
        let f = F.grid.z;
        j0 = vec3f(f / z, 0.0, f * pv.x / (z * z));
        j1 = vec3f(0.0, f / z, f * pv.y / (z * z));
    }
    let a = dot(j0, S * j0) + 0.3;
    let b = dot(j0, S * j1);
    let c = dot(j1, S * j1) + 0.3;
    let det = a * c - b * b;
    if (det <= 1e-8) {
        return false;
    }
    // reach of the kept part: g >= threshold  <=>  r^2 <= -2 ln(threshold) sigma^2
    let reach = sqrt(-2.0 * log(max(F.splat.y, 1e-3))) + 0.1;
    let ext = min(vec2f(sqrt(a), sqrt(c)) * reach + 0.5, vec2f(64.0));
    let off = corner(v.vi) * ext;
    var clip = F.proj * vec4f(pv, 1.0);
    clip = vec4f(clip.xy + off * 2.0 / F.grid.xy * clip.w, clip.zw);
    (*o).clip = clip;
    (*o).d = off;
    (*o).conic = vec3f(c, -b, a) / det;
    return true;
}

fn shadowed(p: vec3f, n: vec3f) -> f32 {
    if (F.shadow.x <= 0.0) {
        return 0.0;
    }
    let lc = F.lightViewProj * vec4f(p + n * F.shadow.z, 1.0);
    let uv = vec2f(lc.x * 0.5 + 0.5, 0.5 - lc.y * 0.5);
    if (uv.x <= 0.0 || uv.y <= 0.0 || uv.x >= 1.0 || uv.y >= 1.0) {
        return 0.0;
    }
    let size = i32(F.shadow.x);
    let t = clamp(vec2i(uv * F.shadow.x), vec2i(0), vec2i(size - 1));
    let d = textureLoad(shadowMap, t, 0);
    return select(0.0, 1.0, lc.z - F.shadow.y > d);
}

@vertex
fn vs_main(raw: VRaw) -> VOut {
    let v = decodeSplat(raw);
    var flags = v.info.z;
    var p = swayed(skinPoint(v), flags);
    var ramp = f32(v.info.x);
    var base = f32(v.info.y);
    if ((flags & FLAG_FX) != 0u && F.fx.y > 0.5) {
        let fx = fxApply(p, hash2(v.pos), ramp, base);
        if (!fx.visible) {
            return culled();
        }
        p = fx.p;
        ramp = fx.ramp;
        base = fx.step;
        if (fx.glow) {
            flags = flags | FLAG_UNLIT;
        }
    }
    var n = skinNormal(v);
    // face the camera: a one-sided splat that looks away is skipped, a two-sided one turns round
    let pv = (F.view * vec4f(p, 1.0)).xyz;
    let toEye = select(normalize(-pv), vec3f(0.0, 0.0, 1.0), F.grid.w > 0.5);
    let facing = dot(normalize((F.view * vec4f(n, 0.0)).xyz), toEye);
    if (facing < 0.0) {
        if ((flags & FLAG_DOUBLE) != 0u) {
            n = -n;
        } else if (facing < -0.25) {
            return culled();
        }
    }
    var o: VOut;
    if (!project(v, p, n, &o)) {
        return culled();
    }
    var light = 0.5;
    if ((flags & FLAG_UNLIT) == 0u) {
        let ndl = dot(n, F.sun.xyz);
        var direct = max(ndl, 0.0);
        if (ndl > 0.0) {
            direct = direct * (1.0 - shadowed(p, n));
        }
        light = direct;
    }
    o.look = vec4f(ramp, base, f32(flags), light);
    o.noise = hash2(v.pos);
    return o;
}

fn bayer4(p: vec2u) -> f32 {
    var m = array<f32, 16>(0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
                           3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
    return (m[(p.x & 3u) + (p.y & 3u) * 4u] + 0.5) / 16.0;
}

fn rampIndex(r: u32, s: u32) -> u32 {
    return F.ramps[r * 2u + s / 4u][s % 4u];
}

fn rampLength(r: u32) -> u32 {
    return F.rampLen[r / 4u][r % 4u];
}

@fragment
fn fs_main(i: VOut) -> @location(0) vec4f {
    let d = i.d;
    let power = -0.5 * (i.conic.x * d.x * d.x + 2.0 * i.conic.y * d.x * d.y + i.conic.z * d.y * d.y);
    if (exp(power) < F.splat.y) {
        discard;
    }
    let ramp = u32(i.look.x + 0.5);
    let base = i32(i.look.y + 0.5);
    let flags = u32(i.look.z + 0.5);
    var step = base;
    if ((flags & FLAG_UNLIT) == 0u) {
        // direct light 0..1 -> a continuous offset along the ramp:
        //   0 (full shade) .. key      : -shade.x .. 0 steps
        //   key .. highlight           : 0, the painted step holds (most lit surfaces)
        //   highlight .. 1 (faces sun) : 0 .. +shade.y steps
        // dithered only across each band edge (shade.z wide)
        let key = clamp(F.sun.w, 0.05, 0.95);
        let hl = clamp(F.tone.x, key, 0.99);
        let dl = i.look.w;
        var o = select(F.shade.y * max(dl - hl, 0.0) / (1.0 - hl), -F.shade.x * (1.0 - dl / key), dl < key);
        o += (i.noise.y - 0.5) * F.splat.w;
        let lo = floor(o);
        let fr = o - lo;
        let w = max(F.shade.z, 1e-3);
        let t = clamp((fr - 0.5) / w + 0.5, 0.0, 1.0);
        let art = vec2u(i.clip.xy * 0.5); // the G-buffer is 2x the art grid
        let threshold = select(bayer4(art), i.noise.x, F.shadow.w > 0.5);
        step = base + i32(lo) + select(0, 1, threshold < t);
    }
    let len = i32(rampLength(ramp));
    let s = u32(clamp(step, 0, max(len - 1, 0)));
    let idx = rampIndex(ramp, s);
    return vec4f(f32(idx), f32(ramp), f32(s), f32(flags)) / 255.0;
}

@vertex
fn vs_shadow(raw: VRaw) -> VOut {
    let v = decodeSplat(raw);
    let flags = v.info.z;
    if ((flags & (FLAG_NOCAST | FLAG_UNLIT)) != 0u) {
        return culled();
    }
    var p = swayed(skinPoint(v), flags);
    if ((flags & FLAG_FX) != 0u && F.fx.y > 0.5) {
        let fx = fxApply(p, hash2(v.pos), 0.0, 0.0);
        if (!fx.visible) {
            return culled();
        }
        p = fx.p;
    }
    var o: VOut;
    if (!project(v, p, skinNormal(v), &o)) {
        return culled();
    }
    o.look = vec4f(0.0);
    o.noise = vec2f(0.0);
    return o;
}

@fragment
fn fs_shadow(i: VOut) {
    let d = i.d;
    let power = -0.5 * (i.conic.x * d.x * d.x + 2.0 * i.conic.y * d.x * d.y + i.conic.z * d.y * d.y);
    if (exp(power) < F.splat.y) {
        discard;
    }
}
