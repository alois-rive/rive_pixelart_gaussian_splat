// Space outpost traffic: ships arrive at the landing pad, wait and leave on a fixed schedule.
//
// A diorama, not a game: nothing is playable (the pointer stays with the preview's orbit) and every
// pose is a pure function of api.time, so a capture at frame N is always the same.
//
// The bones come from scene.bake.json: "shuttle" and "hauler" (each baked parked on the pad) and
// "jet0".."jet3" (exhaust flames, unlit; two per ship, put on its nozzles every frame).
//
// Schedule: a ship every PERIOD seconds, shuttle and hauler in turn, each on a LIFE-second run:
//   approach (drops in from 20 m up on a curved, banking path)  T_APPROACH
//   descent  (from a hover 1.6 m over the pad down onto it)    T_DESCEND
//   parked   (jets off)                                         T_PARK
//   lift-off (up to 1.8 m, turning to its departure heading)    T_LIFT
//   departure (accelerating up and away, out of the frame)      T_DEPART
// LIFE (10.8 s) is under 2 x PERIOD, so one copy of each ship is enough; a ship's lift-off overlaps
// the next one's approach. OFFSET puts ship 0 on the pad at t = 0. Each ship comes in and leaves on
// its own headings (the golden angle per ship), so the traffic does not repeat for a long time.
import { GameApi } from "./game_api";

const PAD_X: f64 = -1.6;
const PAD_Y: f64 = 0.16;      // the pad's top
const PAD_Z: f64 = 1.4;
const PERIOD: f64 = 7.0;
const OFFSET: f64 = 5.0;
const T_APPROACH: f64 = 3.0;
const T_DESCEND: f64 = 1.4;
const T_PARK: f64 = 2.6;
const T_LIFT: f64 = 1.2;
const T_DEPART: f64 = 2.6;
const LIFE: f64 = T_APPROACH + T_DESCEND + T_PARK + T_LIFT + T_DEPART;
const HOVER: f64 = 1.6;
const MOTION_FPS: f64 = 24;   // poses are stepped (pixel-art motion), finer than the 12 fps tracks
const FLICKER_FPS: f64 = 12;

function clamp(v: f64, a: f64, b: f64): f64 { return v < a ? a : (v > b ? b : v); }
function rad(d: f64): f64 { return d * Math.PI / 180.0; }
function deg(r: f64): f64 { return r * 180.0 / Math.PI; }
function lerp(a: f64, b: f64, t: f64): f64 { return a + (b - a) * t; }
function smooth(t: f64): f64 { return t * t * (3.0 - 2.0 * t); }
// the shortest turn from a to b (degrees), a fraction t of the way
function lerpAngle(a: f64, b: f64, t: f64): f64 {
    let d = b - a;
    while (d > 180.0) { d -= 360.0; }
    while (d < -180.0) { d += 360.0; }
    return a + d * t;
}
function hash(n: i32): f64 {
    let h = <u32>n * 2654435761;
    h ^= h >> 15;
    h *= 2246822519;
    h ^= h >> 13;
    return <f64>(h & 0xffff) / 65535.0;
}

export class Game {
    bShip: StaticArray<i32> = new StaticArray<i32>(2);   // 0 shuttle, 1 hauler
    bJet: StaticArray<i32> = new StaticArray<i32>(4);    // ship s uses jets 2s, 2s+1
    // nozzles in the ship's frame as baked (glTF: nose +Z, up +Y; the shuttle is baked at scale 1.2),
    // x = +-nozX; and each ship's jet size
    nozX: StaticArray<f64> = [0.22 * 1.2, 0.25];
    nozY: StaticArray<f64> = [0.52 * 1.2, 0.72];
    nozZ: StaticArray<f64> = [-0.93 * 1.2, -1.22];
    jetSize: StaticArray<f64> = [1.15, 1.3];

    // the pose computed by pose()
    px: f64 = 0; py: f64 = 0; pz: f64 = 0;
    yaw: f64 = 0; pitch: f64 = 0; roll: f64 = 0;
    thrust: f64 = 0;

    start(api: GameApi): void {
        this.bShip[0] = api.bone("shuttle");
        this.bShip[1] = api.bone("hauler");
        for (let j = 0; j < 4; j++) {
            this.bJet[j] = api.bone("jet" + j.toString());
        }
    }

    update(api: GameApi): void {
        let t = Math.floor(api.time * MOTION_FPS) / MOTION_FPS;
        let shown = new StaticArray<bool>(2);
        let newest = <i32>Math.floor((t + OFFSET) / PERIOD);
        for (let n = newest; n > newest - 2; n--) {
            let tau = t + OFFSET - <f64>n * PERIOD;
            if (tau < 0 || tau >= LIFE) {
                continue;
            }
            let s = ((n % 2) + 2) % 2;
            if (shown[s]) {
                continue;
            }
            shown[s] = true;
            this.pose(n, tau);
            api.place(this.bShip[s], this.px, this.py, this.pz, this.yaw, this.pitch, this.roll, 1.0);
            this.placeJets(api, s, t);
        }
        for (let s = 0; s < 2; s++) {
            if (!shown[s]) {
                api.hide(this.bShip[s]);
                api.hide(this.bJet[2 * s]);
                api.hide(this.bJet[2 * s + 1]);
            }
        }
    }

    // ship n's pose tau seconds into its run: px/py/pz, yaw/pitch/roll (degrees, as api.place takes
    // them: yaw 0 = nose to +Z, pitch > 0 = nose down, roll > 0 = left wing up) and thrust (0 = off)
    pose(n: i32, tau: f64): void {
        let th = 40.0 + 137.5 * <f64>n;           // where it comes in from
        let ph = th + 150.0;                       // where it leaves to
        let arrive = this.approachYaw(th, 1.0);
        if (tau < T_APPROACH) {
            let s = tau / T_APPROACH;
            this.bezier(th, s);
            let y0 = this.approachYaw(th, s);
            let rate = (this.approachYaw(th, s + 0.01) - this.approachYaw(th, s - 0.01));
            while (rate > 180.0) { rate -= 360.0; }
            while (rate < -180.0) { rate += 360.0; }
            rate = rate / (0.02 * T_APPROACH);    // degrees a second
            this.yaw = y0;
            this.pitch = lerp(12.0, -14.0, s);
            this.roll = clamp(-0.35 * rate, -25.0, 25.0);
            this.thrust = 0.8 + 0.4 * s;
            return;
        }
        tau -= T_APPROACH;
        if (tau < T_DESCEND) {
            let e = smooth(tau / T_DESCEND);
            this.px = PAD_X; this.pz = PAD_Z;
            this.py = PAD_Y + HOVER * (1.0 - e);
            this.yaw = arrive;
            this.pitch = lerp(-14.0, 0.0, e);
            this.roll = 0;
            this.thrust = tau / T_DESCEND > 0.92 ? 0.0 : lerp(1.0, 0.55, e);
            return;
        }
        tau -= T_DESCEND;
        if (tau < T_PARK) {
            this.px = PAD_X; this.py = PAD_Y; this.pz = PAD_Z;
            this.yaw = arrive; this.pitch = 0; this.roll = 0;
            this.thrust = 0;
            return;
        }
        tau -= T_PARK;
        if (tau < T_LIFT) {
            let e = smooth(tau / T_LIFT);
            this.px = PAD_X; this.pz = PAD_Z;
            this.py = PAD_Y + 1.8 * e;
            this.yaw = lerpAngle(arrive, ph, e);
            this.pitch = lerp(0.0, -10.0, e);
            this.roll = 0;
            this.thrust = tau / T_LIFT < 0.06 ? 0.4 : lerp(0.6, 1.0, e);
            return;
        }
        tau -= T_LIFT;
        let s = tau / T_DEPART;
        let a = s * s;
        let p = rad(ph);
        this.px = PAD_X + 6.0 * Math.sin(p) * a;
        this.py = PAD_Y + 1.8 + 18.0 * a;
        this.pz = PAD_Z + 6.0 * Math.cos(p) * a;
        this.yaw = ph;
        this.pitch = lerp(-10.0, -30.0, s);
        this.roll = 0;
        this.thrust = 1.0 + 0.4 * s;
    }

    // the approach: a quadratic Bezier from 20 m up (6 m out at heading th) through a control point
    // 5 m up (4 m out, 80 degrees round) to the hover point; eased out so it slows into the hover
    bezier(th: f64, s: f64): void {
        let u = 1.0 - (1.0 - s) * (1.0 - s);
        let a = rad(th), c = rad(th + 80.0);
        let sx = PAD_X + 6.0 * Math.sin(a), sy = 20.0, sz = PAD_Z + 6.0 * Math.cos(a);
        let cx = PAD_X + 4.0 * Math.sin(c), cy = 5.0, cz = PAD_Z + 4.0 * Math.cos(c);
        let hx = PAD_X, hy = PAD_Y + HOVER, hz = PAD_Z;
        let w0 = (1.0 - u) * (1.0 - u), w1 = 2.0 * u * (1.0 - u), w2 = u * u;
        this.px = w0 * sx + w1 * cx + w2 * hx;
        this.py = w0 * sy + w1 * cy + w2 * hy;
        this.pz = w0 * sz + w1 * cz + w2 * hz;
    }

    // the heading along the approach at fraction s: the curve's horizontal tangent
    approachYaw(th: f64, s: f64): f64 {
        let u = clamp(1.0 - (1.0 - s) * (1.0 - s), 0.0, 1.0);
        let a = rad(th), c = rad(th + 80.0);
        let sx = 6.0 * Math.sin(a), sz = 6.0 * Math.cos(a);
        let cx = 4.0 * Math.sin(c), cz = 4.0 * Math.cos(c);
        let dx = 2.0 * (1.0 - u) * (cx - sx) + 2.0 * u * (0.0 - cx);
        let dz = 2.0 * (1.0 - u) * (cz - sz) + 2.0 * u * (0.0 - cz);
        return deg(Math.atan2(dx, dz));
    }

    // the two jets on ship s's nozzles, turned like the ship, scaled by thrust and a stepped flicker
    placeJets(api: GameApi, s: i32, t: f64): void {
        if (this.thrust <= 0.05) {
            api.hide(this.bJet[2 * s]);
            api.hide(this.bJet[2 * s + 1]);
            return;
        }
        let cy = Math.cos(rad(this.yaw)), sy = Math.sin(rad(this.yaw));
        let cp = Math.cos(rad(this.pitch)), sp = Math.sin(rad(this.pitch));
        let cr = Math.cos(rad(this.roll)), sr = Math.sin(rad(this.roll));
        // R = Ry * Rx * Rz, as api.place builds it
        let r00 = cy * cr + sy * sp * sr, r01 = -cy * sr + sy * sp * cr, r02 = sy * cp;
        let r10 = cp * sr, r11 = cp * cr, r12 = -sp;
        let r20 = -sy * cr + cy * sp * sr, r21 = sy * sr + cy * sp * cr, r22 = cy * cp;
        let f = <i32>Math.floor(t * FLICKER_FPS);
        for (let k = 0; k < 2; k++) {
            let lx = k == 0 ? -this.nozX[s] : this.nozX[s];
            let ly = this.nozY[s], lz = this.nozZ[s];
            let wx = this.px + r00 * lx + r01 * ly + r02 * lz;
            let wy = this.py + r10 * lx + r11 * ly + r12 * lz;
            let wz = this.pz + r20 * lx + r21 * ly + r22 * lz;
            let flick = 0.8 + 0.35 * hash(f * 13 + (2 * s + k) * 7 + 1);
            let sc = this.jetSize[s] * this.thrust * flick;
            api.place(this.bJet[2 * s + k], wx, wy, wz, this.yaw, this.pitch, this.roll, sc);
        }
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool { return false; }

    hud(api: GameApi): void {}
}
