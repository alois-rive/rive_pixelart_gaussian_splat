// Pixel-art gaussian splats: the resolve pass, G-buffer (2x) -> art grid (1x).
//
// For each art pixel it reads the 2x2 G-buffer samples under it and:
//  1. votes: the palette index most of the covered samples hold wins (ties go
//     to the nearest), so the soft, lumpy edges of overlapping splats settle
//     into clean pixel clusters instead of noise;
//  2. inks the silhouette: a drawn pixel next to sky, or in front of something
//     much farther, is moved `ink` steps DOWN ITS OWN RAMP (a darker, hue
//     shifted colour of the same material, never black);
//  3. fogs by distance with an ordered dither towards the fog colour;
//  4. paints the sky as a dithered two-colour gradient.
// Every pixel written is a palette colour, exactly.

struct Look {
    palette: array<vec4f, 64>,  // rgb 0..1 (sRGB values, written as is)
    ramps: array<vec4u, 64>,    // as in splat.wgsl
    rampLen: array<vec4u, 8>,
    grid: vec4f,   // xy: art grid size, z: ink steps (0 = no outline), w: depth edge (world units)
    depth: vec4f,  // x: near, y: far, z: 1 ortho / 0 perspective, w: fog start (world units from the eye)
    fog: vec4f,    // x: fog end, y: fog max 0..1, z: fog palette index, w: min coverage (1..4) for a pixel to be drawn
    sky: vec4f,    // x: top index, y: bottom index, z: horizon (0..1 of the height), w: gradient width (0..1)
    debug: vec4f,  // x: 0 final, 1 votes only (no ink, no fog), 2 depth; y: 1 = magenta sky (masks)
}

@group(0) @binding(0) var<uniform> L: Look;
@group(0) @binding(1) var gbuf: texture_2d<f32>;
@group(0) @binding(2) var depthTex: texture_depth_2d;

@vertex
fn vs_full(@builtin(vertex_index) vi: u32) -> @builtin(position) vec4f {
    var t = array<vec2f, 3>(vec2f(-1.0, -1.0), vec2f(3.0, -1.0), vec2f(-1.0, 3.0));
    return vec4f(t[vi], 0.0, 1.0);
}

fn bayer4(p: vec2i) -> f32 {
    var m = array<f32, 16>(0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
                           3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
    return (m[(p.x & 3) + (p.y & 3) * 4] + 0.5) / 16.0;
}

fn linearDepth(d: f32) -> f32 {
    let n = L.depth.x;
    let f = L.depth.y;
    if (L.depth.z > 0.5) {
        return n + d * (f - n);
    }
    return n * f / max(f - d * (f - n), 1e-6);
}

fn gsize() -> vec2i {
    return vec2i(textureDimensions(gbuf));
}

// Nearest depth under an art pixel, 1 when nothing is there.
fn artDepth(p: vec2i) -> f32 {
    let s = gsize();
    var d = 1.0;
    for (var k = 0; k < 4; k++) {
        let q = clamp(p * 2 + vec2i(k & 1, k >> 1u), vec2i(0), s - 1);
        d = min(d, textureLoad(depthTex, q, 0));
    }
    return d;
}

fn rampIndex(r: u32, s: u32) -> u32 {
    return L.ramps[r * 2u + s / 4u][s % 4u];
}

fn sky(p: vec2i) -> u32 {
    let t = f32(p.y) / max(L.grid.y - 1.0, 1.0);
    let k = clamp((t - L.sky.z) / max(L.sky.w, 1e-3) + 0.5, 0.0, 1.0);
    return select(u32(L.sky.x), u32(L.sky.y), bayer4(p) < k);
}

@fragment
fn fs_resolve(@builtin(position) frag: vec4f) -> @location(0) vec4f {
    let p = vec2i(frag.xy);
    let s = gsize();
    var idx = array<u32, 4>(0u, 0u, 0u, 0u);
    var ramp = array<u32, 4>(0u, 0u, 0u, 0u);
    var step = array<u32, 4>(0u, 0u, 0u, 0u);
    var dep = array<f32, 4>(1.0, 1.0, 1.0, 1.0);
    var covered = 0;
    for (var k = 0; k < 4; k++) {
        let q = clamp(p * 2 + vec2i(k & 1, k >> 1u), vec2i(0), s - 1);
        let g = textureLoad(gbuf, q, 0);
        let d = textureLoad(depthTex, q, 0);
        dep[k] = d;
        if (d < 1.0) {
            covered += 1;
            idx[k] = u32(g.r * 255.0 + 0.5);
            ramp[k] = u32(g.g * 255.0 + 0.5);
            step[k] = u32(g.b * 255.0 + 0.5);
        }
    }
    if (L.debug.x > 1.5) {
        let ad = artDepth(p);
        let v = select(0.0, 1.0 - (linearDepth(ad) - L.depth.x) / (L.depth.y - L.depth.x), ad < 1.0);
        return vec4f(v, v, v, 1.0);
    }
    if (f32(covered) < L.fog.w) {
        if (L.debug.y > 0.5) {
            return vec4f(1.0, 0.0, 1.0, 1.0);
        }
        let c = L.palette[sky(p)];
        return vec4f(c.rgb, 1.0);
    }
    // the vote
    var best = -1;
    var score = 0;
    var bestDepth = 2.0;
    for (var k = 0; k < 4; k++) {
        if (dep[k] >= 1.0) {
            continue;
        }
        var n = 0;
        for (var j = 0; j < 4; j++) {
            if (dep[j] < 1.0 && idx[j] == idx[k]) {
                n += 1;
            }
        }
        if (n > score || (n == score && dep[k] < bestDepth)) {
            best = k;
            score = n;
            bestDepth = dep[k];
        }
    }
    let b = u32(best);
    var out = idx[b];
    if (L.debug.x < 0.5) {
        // silhouette ink: next to an empty art pixel (sky), or in front of something farther
        // than the depth edge. A partly covered pixel inside a surface is NOT an edge.
        let inkSteps = u32(L.grid.z);
        if (inkSteps > 0u) {
            let here = linearDepth(artDepth(p));
            var edge = false;
            let nb = array<vec2i, 4>(vec2i(1, 0), vec2i(-1, 0), vec2i(0, 1), vec2i(0, -1));
            for (var k = 0; k < 4; k++) {
                let dn = artDepth(p + nb[k]);
                if (dn >= 1.0 || linearDepth(dn) - here > L.grid.w) {
                    edge = true;
                }
            }
            if (edge) {
                let st = step[b];
                out = rampIndex(ramp[b], select(0u, st - inkSteps, st >= inkSteps));
            }
        }
        // dithered distance fog
        let z = linearDepth(bestDepth);
        let f = clamp((z - L.depth.w) / max(L.fog.x - L.depth.w, 1e-3), 0.0, 1.0) * L.fog.y;
        if (bayer4(p) < f) {
            out = u32(L.fog.z);
        }
    }
    let c = L.palette[out];
    return vec4f(c.rgb, 1.0);
}
